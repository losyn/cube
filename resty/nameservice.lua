-- Created by losyn on 12/12/16

local Lrucache = require("resty.lrucache")
local Resolver = require("resty.dns.resolver")
local Functionality = require("functionality")
local Environment = require("environment")
local Safe = require("safe")

local CacheStorage, err = Lrucache.new(200)
if not CacheStorage then
    ngx.log(ngx.ERR, "create a new chche storage error: ", err)
end

local isAddress = function(hostname)
    return ngx.re.find(hostname, [[\d+?\.\d+?\.\d+?\.\d+$]], "jo")
end

local getAddrFromCache = function(hostname)
    local addr = CacheStorage:get(hostname)
    if addr then
        return true, addr
    end
    return false, nil
end

local setAddr2Cache = function(hostname, value, expire)
    return Safe.invoke(Lrucache.set, CacheStorage, hostname, value, expire)
end

local getFromResolver = function(hostname)
    if Functionality.isEmpty(Environment.DNS) then
        ngx.log(ngx.ERR, "can not find dns resolv service")
        return false, nil
    end

    local r, error = Resolver:new({
        nameservers = Environment.DNS,
        -- 5 retransmissions on receive timeout
        retrans = 5,
        -- 2 sec
        timeout = 2000,
    })

    if not r then
        ngx.log(ngx.ERR, "hostname: " .. hostname .. " can not resolv address, error: ", error)
        return false, nil
    end

    local answers, err = r:query(hostname, { qtype = r.TYPE_A })

    if not answers or answers.errcode then
        ngx.log(ngx.ERR, "hostname: " .. hostname .. " can not resolv address, errcode: ", answers.errcode)
        return false, nil
    end

    for _, ans in ipairs(answers) do
        if ans.address then
            return true, ans.address
        end
    end
    ngx.log(ngx.ERR, "hostname: " .. hostname .. " can not resolv address, error: ", err)
    return false, nil
end

local getAddress = function(hostname)
    if isAddress(hostname) then
        return true, hostname
    end
    -- cache 300s
    return Safe.effect(hostname, getAddrFromCache, getFromResolver, setAddr2Cache, 300)
end

return {
    address = getAddress
}