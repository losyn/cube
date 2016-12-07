-- Created by losyn on 12/2/16

local Environment = require("environment");
local Lfs = require("lfs");

-- check obj is pure array
local isArray = function(obj)
    if type(obj) ~= "table" then
        return false;
    end
    local size = #obj;
    for index, _ in pairs(obj) do
        if type(index) ~= "number" or index > size then
            return false;
        end
    end
    return true;
end

-- check routing uri duplicating and return uri list alias
local duplicateUriList = function(routinglist)
    if not isArray(routinglist) then
        ngx.log(ngx.ERR, "Routing array format error..... ");
        -- TODO: start error immediately stop nginx
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
        -- TODO: start error immediately stop nginx
    end
    return aliasList or {};
end

local ROUTE, INIT_NGX = "RouterList", "InitNgx";

-- set up routing
local setUpRouting = function(path)
    if Environment.exists(Environment.root .. path .. "/resources/" .. ROUTE .. ".lua") then
        local Routing = require(path .. ".resources." .. ROUTE);
        Routing.aliasList = duplicateUriList(Routing);
    end
end

local init = function()
    for p in Lfs.dir(Environment.root) do
        if p ~= "." and p ~= ".." and "directory" == Lfs.attributes(Environment.root .. p).mode then
            ngx.log(ngx.INFO, Environment.root .. p);
            setUpRouting(p);
            if Environment.exists(Environment.root .. p .. "/" .. INIT_NGX .. ".lua") then
                local InitNgx = require(p .. "." .. INIT_NGX);
                InitNgx.initial();
            end
        end
    end
end

init();