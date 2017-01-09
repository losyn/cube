-- Created by losyn on 12/14/16

local Memcached = require("resty.memcached")
local Cjosn = require("cjson.safe")
local Functionality = require("functionality")
local Nameservice = require("nameservice")

local Conf = loading("resources.application")

local cmds = {
    "set", "add", "replace", "append", "prepend",
    "get", "gets", "cas", "touch", "delete",
    "incr", "decr", "stats", "version", "quit", "verbosity"
}

local McacheOperations = {}

local getOptions = function()
    return Functionality.defaults(Conf.memcachec, {
        host = "127.0.0.1",
        port = 6379,
        -- 2s
        timeout = 2000,
        -- 10s
        keepalive = 10000,
        poolsize = 100
    });
end

local connect = function()
    if ngx.ctx[McacheOperations] then
        return ngx.ctx[McacheOperations]
    end

    local db, msg = Memcached:new()
    if not db then
        ngx.log(ngx.ERR, "failed to memcached socket: ", msg)
        return nil
    end
    local options = getOptions()
    local ok, address = Nameservice.address(options.host)
    if not ok then
        ngx.log(ngx.ERR, "failed to resolv domain to address")
        return nil
    end
    options.host = address

    db:set_timeout(options.timeout)
    local ret, error = db:connect(options.host, options.port)
    if not ret then
        ngx.log(ngx.ERR, "failed to connect memcached, error", error)
        ngx.log(ngx.ERR, "memcached options: ", Cjosn.encode(options));
        return nil
    end

    db.OPTIONS = options
    ngx.ctx[McacheOperations] = db
    return ngx.ctx[McacheOperations]
end

local close = function()
    if ngx.ctx[McacheOperations] then
        local options = ngx.ctx[McacheOperations].OPTIONS;
        local ok, error = ngx.ctx[McacheOperations]:set_keepalive(options.keepalive, options.poolsize);
        ngx.ctx[McacheOperations] = nil
        if not ok then
            ngx.log(ngx.ERR, "failed to close memcached, error: ", error)
            return false
        end
    end
    return true
end

local doResponse = function(ret, res)
    ngx.log(ngx.INFO, "memcached db close")
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
            ngx.log(ngx.ERR, "memcached do exec error: ", error)
            return false, nil
        end
        return doResponse(true, rs)
    end
    return false, nil
end

for i = 1, #cmds do
    local cmd = cmds[i]
    McacheOperations[cmd] = function(...)
        return doExec(function(db, param, ...)
            return Memcached[param](db, ...)
        end, cmd, ...)
    end
end

McacheOperations.flushAll = function(time)
    return doExec(function(db, param)
        return db:flush_all(param)
    end, time)
end


return McacheOperations