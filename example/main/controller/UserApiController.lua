-- Created by losyn on 12/2/16 10:05 AM
local Cjson = require("cjson.safe");

local UserService = loading("main.service.UserService");

return {
    find = function()
        ngx.say(Cjson.encode(UserService.find()));
    end,

    update = function()
        UserService.update();
    end,

    delete = function()
        UserService.delete();
    end
};
