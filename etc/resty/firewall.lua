-- Created by losyn on 12/7/16

--字符串分割函数
--传入字符串和分隔符，返回分割后的table
local Exception = require("exception");
local Cjson = require("cjson.safe");

local split = function(str, delimiter)
    if str == nil or str == '' or delimiter == nil then
        return {};
    end
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local firewall = function()
    local acl = split(ngx.var.acc_ctrl_ls, ",");
    ngx.log(ngx.INFO, "request uri acl: ", Cjson.encode(acl));
    for _, v in ipairs(acl) do
        local ret, Ctrl = Exception.try(require, v);
        if not ret or not Ctrl then
            ngx.log(ngx.ERR, "acl conf not found, " .. v);
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR);
            return;
        end
        local rs, res = Exception.try(Ctrl.access);
        if not rs then
            ngx.log(ngx.ERR, "request uri exec acl error: " .. res);
            ngx.exit(ngx.HTTP_FORBIDDEN);
            return;
        end
        if not res then
            ngx.log(ngx.ERR, "request uri: " .. ngx.var.uri .. " access not forbidden...");
            ngx.exit(ngx.HTTP_FORBIDDEN);
        end
    end
end

firewall();