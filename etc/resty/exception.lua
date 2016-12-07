-- Created by losyn on 12/7/16
local Cjson = require("cjson.safe");

return {
    try = function(fun, ...)
        local ret, msg = pcall(fun, ...);
        if not ret then
            ngx.log(ngx.ERR, ret, Cjson.encode(msg));
        end
        return ret, msg;
    end
}
