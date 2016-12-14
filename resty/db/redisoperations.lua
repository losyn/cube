-- Created by losyn on 12/11/16

local Redis = require("resty.redis")
local Cjosn = require("cjson.safe")
local Safe = require("safe")
local Functionality = require("functionality")
local Nameservice = require("nameservice")

local Conf = loading("resources.application")

local cmds = {
    "get", "set", "mget", "mset",
    "del", "incr", "decr", -- Strings
    "llen", "lindex", "lpop", "lpush",
    "lrange", "linsert", -- Lists
    "hexists", "hget", "hset", "hmget",
    --[[ "hmset", ]] "hdel", -- Hashes
    "smembers", "sismember", "sadd", "srem",
    "sdiff", "sinter", "sunion", -- Sets
    "zrange", "zrangebyscore", "zrank", "zadd",
    "zrem", "zincrby", -- Sorted Sets
    "auth", "eval", "expire", "script",
    "sort" -- Others
}

local SP_CACHE = {}

local RedisOperations = {}

local getOptions = function()
    return Functionality.defaults(Conf.redisc, {
        host = "127.0.0.1",
        port = 6379,
        database = 0,
        password = nil,
        -- 2s
        timeout = 2000,
        -- 10s
        keepalive = 10000,
        poolsize = 100,
        pipeline = 4
    });
end

local doConnect = function()
    local db, msg = Redis:new()
    if not db then
        ngx.log(ngx.ERR, "failed to mysql socket: ", msg)
        return nil
    end
    local options = getOptions()
    options.host = Nameservice.address(options.host)

    db:set_timeout(options.timeout)
    local ret, error = db:connect(options.host, options.port)
    if not ret then
        ngx.log(ngx.ERR, "failed to connect redis, error", error)
        ngx.log(ngx.ERR, "redis options: ", Cjosn.encode(options));
        return nil
    end

    if nil ~= options.password then
        local count, err = db:get_reused_times()
        if 0 == count then
            ret, error = red:auth(options.password)
            if not ret then
                ngx.log(ngx.ERR, "failed to authentication redis, error: ", error)
                return nil
            end
        elseif err then
            ngx.log(ngx.ERR, "failed to get redis reused times, error: ", err)
            return nil
        end
    end
    ret, error = db:select(options.database)
    if not ret then
        ngx.log(ngx.ERR, "failed to select redis database, error: ", error)
        return nil
    end

    db.OPTIONS = options
    return db
end

local connect = function()
    if ngx.ctx[RedisOperations] then
        return ngx.ctx[RedisOperations]
    end
    local db = doConnect()
    if not db then
        return nil
    end

    ngx.ctx[RedisOperations] = db
    return ngx.ctx[RedisOperations]
end

local close = function()
    if ngx.ctx[RedisOperations] then
        local options = ngx.ctx[RedisOperations].OPTIONS;
        local ok, error = ngx.ctx[RedisOperations]:set_keepalive(options.keepalive, options.poolsize);
        ngx.ctx[RedisOperations] = nil
        if not ok then
            ngx.log(ngx.ERR, "failed to close redis, error: ", error)
            return false
        end
    end
    return true
end

local doResponse = function(ret, res)
    ngx.log(ngx.INFO, "redis db close")
    if close() then
        return ret, res
    else
        return false, nil
    end
end

local doExec = function(func, param, ...)
    local db = connect()
    if db then
        local rs, error = func(db, param, ...)
        if not rs then
            ngx.log(ngx.ERR, "redis do exec error: ", error)
            return false, nil
        end
        return doResponse(true, rs)
    end
    return false, nil
end

local unsubscribe = function(db, channel)
    if db then
        db:unsubscribe(channel)
        local options = db.OPTIONS
        db:set_keepalive(options.keepalive, options.poolsize)
    end
end

local validation = function(channel)
    return SP_CACHE[channel]
end

local doSubscribe = function(channel, func, valid)
    local db = doConnect()
    if not db then
        ngx.log(ngx.ERR, "connect redis error")
        return false
    end
    local res, error = db:subscribe(channel)
    if not res then
        ngx.log(ngx.ERR, "subscribe redis channel: " .. channel .. ", error: ", error)
        unsubscribe(db, channel)
        return false
    end
    while true do
        if valid(channel) then
            res, error = db:read_reply()
            if not res and error ~= "timeout" then
                unsubscribe(db, channel)
                break
            end
            if res then
                res, error = Safe.invoke(func, res)
                if not res then
                    ngx.log(ngx.ERR, "subscribe channel handle read reply error: ", error)
                end
            end
        else
            ngx.log(ngx.INFO, "exec unsubscribe redis channel: " .. channel)
            unsubscribe(db, channel)
            return true
        end
    end
    return false
end

for i = 1, #cmds do
    local cmd = cmds[i]

    RedisOperations[cmd] = function(...)
        return doExec(function(db, param, ...)
            return Redis[param](db, ...)
        end, cmd, ...)
    end
end

RedisOperations.addCommands = function(...)
    return doExec(function(db, param)
        return db:add_commands(param)
    end, ...)
end

RedisOperations.hmset = function(hashName, ...)
    return doExec(function(db, param, ...)
        return db:hmset(param, ...)
    end, hashName, ...)
end

RedisOperations.pipeline = function(fun, params)
    return doExec(function(db, f, ...)
        db:init_pipeline(db.OPTIONS.pipeline)
        f(db, ...)
        return db:commit_pipeline()
    end, fun, params)
end

RedisOperations.array2Hash = function(array)
    return doExec(function(db, param)
        return db:array_to_hash(param)
    end, array)
end

RedisOperations.subscribe = function(channel, func, retry)
    local ok, error = ngx.timer.at(0, function(p, cn, fun, rt, valid)
        if p then return end
        SP_CACHE[channel] = true
        repeat
            local ds = doSubscribe(cn, fun, valid)
            if not ds then
                ngx.sleep(rt)
                ngx.log(ngx.ALERT, "listen channel: " .. cn .. " error about " .. rt .. "s will resubscribe")
            end
        until ds
    end, channel, func, retry or 3, validation)
    if not ok then
        ngx.log(ngx.ERR, "failed to create timer subscribe channel: " .. channel, ", error: ", error)
    end
end

RedisOperations.unsubscribe = function(channel)
    SP_CACHE[channel] = false
    return  "submit unsub channel = " .. channel
end

RedisOperations.publish = function(channel, value)
    return doExec(function(db, param, ...)
        return db:publish(param, Cjosn.encode(...))
    end, channel, value)
end

return RedisOperations