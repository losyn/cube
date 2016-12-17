-- Created by losyn on 12/2/16

local Functionality = require("functionality")
local Cjson = require("cjson.safe");
local Safe = require("safe");
local UnitTest = require("unittest")

local Conf = loading("resources.application")

local response = function(status)
    local ah = Functionality.split(Conf.ajaxHeader, "=");
    ngx.log(ngx.INFO, "ajax header: ", Cjson.encode(ah));
    if nil == ah[1] or nil == ah[2] then
        ah[1] = "X-Requested-With";
        ah[2] = "XMLHttpRequest";
    end
    local rh = ngx.req.get_headers(0);
    ngx.log(ngx.INFO, "request header: ", Cjson.encode(rh));
    if ah[2] == rh[ah[1]] then
        ngx.header["Content-Type"] = "application/json";
        return ngx.say(Cjson.encode({ result = false, code = status }));
    end
    ngx.header["Content-Type"] = "text/html";
    return ngx.exit(status);
end

-- invok routing ctrl action
local invokCtrlAction = function(route)
    ngx.header["Content-Type"] = route.dt;
    ngx.log(ngx.ERR, ngx.var.project .. "." .. route.ctrl);
    local ret, Ctrl = Safe.import(ngx.var.project .. "." .. route.ctrl);
    if not ret or not Ctrl then
        ngx.log(ngx.ERR, "request ctrl not found: " .. route.ctrl, Cjson.encode(Ctrl));
        return response(ngx.HTTP_INTERNAL_SERVER_ERROR);
    end
    local rs, msg = Safe.invoke(Ctrl[route.action], ngx);
    if not rs then
        ngx.log(ngx.ERR, "exec request ctrl action error, msg: ", Cjson.encode(msg));
        return response(ngx.HTTP_INTERNAL_SERVER_ERROR);
    end
    return true
end

-- handle uri do dispactcher routing
local doRouting = function(route)
    -- check uri route valid
    if nil == route or nil == route.action or nil == route.method or nil == route.ctrl then
        ngx.log(ngx.ERR, "request route: ", Cjson.encode(route));
        return response(ngx.HTTP_NOT_FOUND);
    end
    -- check request method valid
    if ngx.var.request_method ~= route.method then
        ngx.log(ngx.ERR, "request method not allowed, expect: " .. handle.method .. " but receive: " .. ngx.var.request_method);
        return response(ngx.HTTP_NOT_ALLOWED);
    end
    -- invok ctrl action
    return invokCtrlAction(route);
end

local AC_SP = "!";
local dispatcher = function()
    if ngx.var.uri == "/T" then
        if Conf.enableT then
            return UnitTest.run(ngx.var.arg_P, ngx.var.arg_M, ngx.var.arg_U)
        end
        ngx.log(ngx.ERR, "request uri: /T not enabled");
        return response(ngx.HTTP_NOT_FOUND);
    end

    if ngx.var.uri == "/" then
        if not Conf.rootAction then
            ngx.log(ngx.ERR, "request uri: / not found");
            return response(ngx.HTTP_NOT_FOUND);
        end
        ngx.log(ngx.INFO, "request uri: / redirect to " .. Conf.rootAction);
        return ngx.redirect(Conf.rootAction);
    end

    local sInx = string.find(ngx.var.uri, AC_SP);
    if (nil == sInx or sInx == string.len(ngx.var.uri)) then
        ngx.log(ngx.ERR, "request uri: " .. ngx.var.uri .. " routing not found.....");
        return response(ngx.HTTP_NOT_FOUND);
    end

    local action = string.sub(ngx.var.uri, sInx + 1, -1);
    local path = string.sub(ngx.var.uri, 1, sInx - 1);
    ngx.log(ngx.INFO, "request path: " .. path .. ", action: " .. action);

    local ret, Routing = Safe.import(ngx.var.project .. "." .. Conf.routerList);
    if not ret or not Routing then
        ngx.log(ngx.ERR, "router list conf error, file: " .. ngx.var.project .. ".resources.RouterList");
        return response(ngx.HTTP_INTERNAL_SERVER_ERROR);
    end
    local alias = (string.gsub(path, "/", "_")) .. "_" .. action;
    local routIdx = Routing.aliasList[alias];
    if not routIdx then
        ngx.log(ngx.ERR, "request uri: " .. ngx.var.uri .. " routing not found.....");
        return response(ngx.HTTP_NOT_FOUND);
    end
    return doRouting(Routing[routIdx]);
end

dispatcher();