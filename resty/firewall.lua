-- Created by losyn on 12/7/16

local Functionality = require("functionality")
local Cjson = require("cjson.safe");
local Safe = require("safe");

local Conf = loading("resources.application");

local firewall = function()
    local acls = Conf.acls or {}
    for _, v in ipairs(acls) do
        local ret, Ctrl = Safe.import(ngx.var.project .. "." .. v);
        if not ret or not Ctrl then
            ngx.log(ngx.ERR, "acl conf not found, " .. v);
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR);
            return;
        end
        local rs, res = Safe.invoke(Ctrl.access);
        if not rs then
            ngx.log(ngx.ERR, "request uri exec acl error: " .. Cjson.encode(res));
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
