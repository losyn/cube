-- Created by losyn on 12/2/16 10:05 AM
local Cjson = require("cjson.safe");

local User = {};
User.find = function()
--    ngx.header["Set-Cookie"] = "abc";
    ngx.say("user add invoke.....");
    ngx.say(ngx.var.prefix);
--    ngx.say(ngx.HTTP_POST);
    ngx.say(Cjson.encode(ngx.ctx.Authentication));
--    local res = ngx.location.capture("/inner/!sayUser");
--    ngx.say(res.body);
--    ngx.say()
end

User.index = function()
    ngx.say("index page.....");
end

User.sayUser = function()
    ngx.say("capture user.....");
end

return User;
