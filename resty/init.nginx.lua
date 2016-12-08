-- Created by losyn on 12/2/16

-- check obj is pure array
table.isArray = function(obj)
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

-- split a str by delimiter as a table
string.split = function(str, delimiter)
    if type(str) ~= "string" or type(delimiter) ~= "string" then
        return {};
    end
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- check file exists
io.exists = function(path)
    local file, err = io.open(path);
    if file then
        file.close();
    end
    return file ~= nil, err;
end

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

-- check routing uri duplicating and return uri list alias
local duplicateUriList = function(routinglist)
    if not table.isArray(routinglist) then
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

local init = function()
    for p in Lfs.dir(Environment.root) do
        if p ~= "." and p ~= ".." and "directory" == Lfs.attributes(Environment.root .. p).mode then
            ngx.log(ngx.INFO, Environment.root .. p);

            local rs1, Routing = Safe.import(p .. ".resources.RouterList");
            if rs1 then Routing.aliasList = duplicateUriList(Routing) end

            local rs2, InitNgx = Safe.import(p .. ".InitNgx");
            if rs2 then InitNgx.initial(ngx) end
        end
    end
end

init();