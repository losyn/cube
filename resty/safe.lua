-- Created by losyn on 12/8/16

local Lock = require "resty.lock"
local cacheNgx = "cube_cache_lock"
local unlock = function(lock)
    local ok, error = lock:unlock()
    if not ok then
        ngx.log(ngx.ERR, "failed to unlock: ", error)
        return false
    end
    return true
end

local doResponse = function(lock, value)
    if unlock(lock) and value then
        return true, value
    else
        return false, nil
    end
end

return {
    invoke = function(fun, ...)
        return pcall(fun, ...);
    end,

    import = function(lua)
        return pcall(require, lua);
    end,

    effect = function(key, lightF, weightF, cacheF, expire)
        -- get from cache
        local ok, res = lightF(key)
        if not ok then
            -- cache miss Locked
            local lock = Lock:new(cacheNgx)
            ok, res = lock:lock(key)
            if not ok then
                ngx.log(ngx.ERR, "failed to acquire the lock: ", res)
                return false, nil
            end
            -- try get from cache agin, someone might have already put the value into the cache
            ok, res = lightF(key)
            if ok then
                return doResponse(lock, res)
            end
            -- get from weight function
            ok, res = weightF(key)
            if not ok then
                ngx.log(ngx.ERR, "get value by weightF error: ", res)
                -- we should handle the backend miss more carefully here, like inserting a stub value into the cache.
                return doResponse(lock, nil)
            end
            -- update cache by new value
            local ret, error = cacheF(key, res, expire)
            if not ret then
                ngx.log(ngx.ERR, "update cache by new value error: ", error)
                return doResponse(lock, nil)
            end
            -- return new value
            return doResponse(lock, res)
        end
        return true, res
    end
}

