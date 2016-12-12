-- Created by losyn on 12/8/16

local Cjson = require("cjson.safe");
local Functionality = require("functionality")
local Template = require("template");
local MySqlOperations = require("db.mysqloperations");

local Application = loading("resources.application");
local Conf = loading("resources.application");
local UserSql = loading("resources.sql.UserSql")

--Template.caching(Application.viewCache or false);

return {
    index = function(ngx)
        --local fun = Template.compile(UserSql.sql, "UserSql:sql", true)
        --ngx.say(fun({username = "root"}))
        local ok, res = MySqlOperations:exec("UserSql:sql", {username = "root", size = 10})
        ngx.say(Cjson.encode(res))
        ngx.say("----------------------------------------------------------------------")
        local ok, res = MySqlOperations:invoke(function(db, overt, params)
            ngx.log(ngx.ERR, "invoke params", Cjson.encode(params))
            local ret, res = MySqlOperations:query(db, overt, "UserSql:sql", params)
            return ret, res;
        end, {username = "root", size = 10})
        ngx.say(Cjson.encode(res))

        --[[Template.render("index.html", {
            title = "Cube Example";
            message = "Hello Cube Example!"
        });]]
    end
}

