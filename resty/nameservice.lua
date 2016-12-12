-- Created by losyn on 12/12/16

local Lrucache = require("resty.lrucache")
local Resolver = require("resty.dns.resolver")
local Functionality = require("functionality")
local Environment = require("environment")

local CacheStorage = Lrucache.new(200)

local isAddress = function(hostname)
    return ngx.re.find(hostname, [[\d+?\.\d+?\.\d+?\.\d+$]], "jo")
end

local getAddress = function(hostname)
    if isAddress(hostname) then
        return hostname, hostname
    end

    local addr = CacheStorage:get(hostname)
    if addr then
        return addr, hostname
    end

    if Functionality.isEmpty(Environment.DNS) then
        return nil, "can not find dns resolv service"
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
        return nil, "hostname can not resolv address"
    end

    local answers, err = r:query(hostname, { qtype = r.TYPE_A })

    if not answers or answers.errcode then
        ngx.log(ngx.ERR, "hostname: " .. hostname .. " can not resolv address, errcode: ", answers.errcode)
        return nil, "hostname can not resolv address"
    end

    for _, ans in ipairs(answers) do
        if ans.address then
            -- cache 300s
            CacheStorage:set(hostname, ans.address, 300)
            return ans.address, hostname
        end
    end

    ngx.log(ngx.ERR, "hostname: " .. hostname .. " can not resolv address, error: ", err)
    return nil, "hostname can not resolv address"
end

return {
    address = getAddress
}