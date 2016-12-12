-- Created by losyn on 12/2/16

-- require module relative project root directory

_G.loading = function(path)
    if nil == ngx.var.project or "" == ngx.var.project then
        return require(path);
    else
        return require(ngx.var.project .. "." .. path);
    end
end

local Environment = require("environment");
local Lfs = require("lfs");
local Safe = require("safe");
local Cjson = require("cjson.safe")
local Functionality = require("functionality")

-- check routing uri duplicating and return uri list alias
local duplicateUriList = function(routinglist)
    if not Functionality.isArray(routinglist) then
        ngx.log(ngx.ERR, "Routing array format error..... ");
        return ngx.exit(ngx.NGX_ERROR);
    end

    local aliasList = {};
    for i, v in ipairs(routinglist) do
        local alias = (string.gsub(v.path, "/", "_")) .. "_" .. v.action;
        aliasList[alias] = i;
    end
    local checkList = {}
    for key, _ in pairs(aliasList) do
        table.insert(checkList, key);
    end
    if #checkList ~= #routinglist then
        ngx.log(ngx.ERR, "Routing uri duplication..... ");
        return ngx.exit(ngx.NGX_ERROR);
    end
    return aliasList or {};
end

local initResolv = function()
    local file = Environment.resolv or "/etc/resolv.conf"
    if not Functionality.fileExists(file) then
        ngx.log(ngx.ERR, "can not find dns resolv conf file")
        return {}
    end

    local dns = {}
    for line in io.lines(file) do
        if 1 == string.find(line, "nameserver") then
            Functionality.push(dns, Functionality.trim(string.sub(line, 11)))
        end
    end
    ngx.log(ngx.INFO, "dns servers: ", Cjson.encode(dns))
    return dns
end


local init = function()
    Environment.DNS = initResolv()
    for p in Lfs.dir(Environment.root) do
        if p ~= "." and p ~= ".." and "directory" == Lfs.attributes(Environment.root .. p).mode then
            ngx.log(ngx.INFO, Environment.root .. p);

            local rs1, Routing = Safe.import(p .. ".resources.RouterList");
            if rs1 then Routing.aliasList = duplicateUriList(Routing) end

            local rs, InitNgx = Safe.import(p .. ".InitNgx");
            if rs then InitNgx.initial(ngx) end
        end
    end
end

init();