-- Created by losyn on 12/8/16
local _M = {_VERSION = "1.0.0"}

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

_M.invoke = function(fun, ...)
    return pcall(fun, ...);
end

_M.import = function(lua)
    return pcall(require, lua);
end

_M.effect = function(key, lightF, weightF, cacheF, expire)
    -- get from cache
    local ret, ok, res = _M.invoke(lightF, key)
    if not ret or not ok then
        -- cache miss Locked
        local lock = Lock:new(cacheNgx)
        ok, res = lock:lock(key)
        if not ok then
            ngx.log(ngx.ERR, "failed to acquire the lock: ", res)
            return false, nil
        end
        -- try get from cache agin, someone might have already put the value into the cache
        ret, ok, res = _M.invoke(lightF, key)
        if ret and ok then
            return doResponse(lock, res)
        end
        -- get from weight function
        ret, ok, res = _M.invoke(weightF, key)
        if not ret or not ok then
            ngx.log(ngx.ERR, "get value by weightF error: ", res)
            -- we should handle the backend miss more carefully here, like inserting a stub value into the cache.
            return doResponse(lock, nil)
        end
        -- update cache by new value
        local ret, ok, error = _M.invoke(cacheF, key, res, expire)
        if not ret or not ok then
            ngx.log(ngx.ERR, "update cache by new value error: ", error)
            return doResponse(lock, nil)
        end
        -- return new value
        return doResponse(lock, res)
    end
    return true, res
end

return _M