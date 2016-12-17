-- Created by losyn on 12/7/16

local Cjson = require("cjson.safe");
local Safe = require("safe");

local Conf = loading("resources.application");

local firewall = function()
    local acls = Conf.acls or {}
    for _, v in ipairs(acls) do
        local ret, Ctrl = Safe.import(ngx.var.project .. "." .. v);
        if not ret or not Ctrl then
            ngx.log(ngx.ERR, "acl conf not found, " .. v);
            return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR);
        end
        local rs, res = Safe.invoke(Ctrl.access);
        if not rs then
            ngx.log(ngx.ERR, "request uri exec acl error: " .. Cjson.encode(res));
            return ngx.exit(ngx.HTTP_FORBIDDEN);
        end
        if not res then
            ngx.log(ngx.ERR, "request uri: " .. ngx.var.uri .. " access not forbidden...");
            return ngx.exit(ngx.HTTP_FORBIDDEN);
        end
    end
end

firewall();
