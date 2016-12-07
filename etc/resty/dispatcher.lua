-- Created by losyn on 12/2/16

local Cjson = require("cjson.safe");
local Exception = require("exception");

local split = function(str, delimiter)
    local result = {};
    if str == nil or str == '' or delimiter == nil then
        return result;
    end
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local response = function(status)
    local ah = split(ngx.var.ajax_header, "=");
    ngx.log(ngx.INFO, "ajax header: ", Cjson.encode(ah));
    if nil == ah[1] or nil == ah[2] then
        ah[1] = "X-Requested-With";
        ah[2] = "XMLHttpRequest";
    end
    local rh = ngx.req.get_headers(0);
    ngx.log(ngx.INFO, "request header: ", Cjson.encode(rh));
    if ah[2] == rh[ah[1]] then
        ngx.header["Content-Type"] = "application/json";
        ngx.say(Cjson.encode({result = false, code = status}));
    else
        ngx.header["Content-Type"] = "text/html";
        ngx.exit(status);
    end
end

-- invok routing ctrl action
local invokCtrlAction = function(route)
    ngx.header["Content-Type"] = route.dt;
    local ret, Ctrl = Exception.try(require, route.ctrl);
    if not ret then
        ngx.log(ngx.ERR, "request ctrl not found: " .. route.ctrl);
        response(ngx.HTTP_INTERNAL_SERVER_ERROR);
    end
    local rs, msg = Exception.try(Ctrl[route.action]);
    if not rs then
        ngx.log(ngx.ERR, "exec request ctrl action error, msg: " .. Cjson.encode(msg));
        response(ngx.HTTP_INTERNAL_SERVER_ERROR);
    end
end

-- handle uri do dispactcher routing
local doRouting = function(route)
    -- check uri route valid
    if nil == route or nil == route.action or nil == route.method or nil == route.ctrl then
        ngx.log(ngx.ERR, "request route: ", Cjson.encode(route));
        response(ngx.HTTP_NOT_FOUND);
        return;
    end
    -- check request method valid
    if ngx.var.request_method ~= route.method then
        ngx.log(ngx.ERR, "request method not allowed, expect: " .. handle.method .. " but receive: " .. ngx.var.request_method);
        response(ngx.HTTP_NOT_ALLOWED);
        return;
    end
    -- invok ctrl action
    invokCtrlAction(route);
end

local AC_SP = "!";
local dispatcher = function()
    if ngx.var.uri == "/" then
        if not ngx.var.root_action then
            ngx.log(ngx.ERR, "request uri: / not found");
            response(ngx.HTTP_NOT_FOUND);
        else
            ngx.log(ngx.INFO, "request uri: / redirect to " .. ngx.var.root_action);
            ngx.redirect(ngx.var.root_action);
        end
        return;
    end

    local sInx = string.find(ngx.var.uri, AC_SP);
    if (nil == sInx or sInx == string.len(ngx.var.uri)) then
        ngx.log(ngx.ERR, "request uri: " .. ngx.var.uri .. " routing not found.....");
        response(ngx.HTTP_NOT_FOUND);
        return;
    end

    local action = string.sub(ngx.var.uri, sInx + 1, -1);
    local path = string.sub(ngx.var.uri, 1, sInx - 1);
    ngx.log(ngx.INFO, "request path: " .. path .. ", action: " .. action);

    local ret, Routing = Exception.try(require, ngx.var.router_list);
    if not ret or not Routing then
        ngx.log(ngx.ERR, "router list conf error, $router_list");
        response(ngx.HTTP_INTERNAL_SERVER_ERROR);
        return;
    end
    local alias = (string.gsub(path, "/", "_")) .. "_" .. action;
    local routIdx = Routing.aliasList[alias];
    if not routIdx then
        ngx.log(ngx.ERR, "request uri: " .. ngx.var.uri .. " routing not found.....");
        response(ngx.HTTP_NOT_FOUND);
    end
    doRouting(Routing[routIdx]);
end

dispatcher();