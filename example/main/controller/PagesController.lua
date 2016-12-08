-- Created by losyn on 12/8/16

local Cjson = require("cjson.safe");

local Template = loading("lib.resty.template");
local Application = loading("resources.application");

Template.caching(Application.viewCache or false);
return {
    index = function(ngx)
        Template.render("index.html", {
            title = "Cube Example";
            message = "Hello Cube Example!"
        });
    end
}

