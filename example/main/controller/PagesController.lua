-- Created by losyn on 12/8/16

local Cjson = require("cjson.safe");
local Functionality = require("functionality")
local Template = require("template");
local MySqlOperations = require("db.mysqloperations")
local RedisOperations = require("db.redisoperations")

local Application = loading("resources.application")
local Conf = loading("resources.application");
local UserSql = loading("resources.sql.UserSql")

--Template.caching(Application.viewCache or false);

local voke = function(db, overt, params)
    local ret, res = MySqlOperations.query(db, overt, "UserSql:sql", params)
    return ret, res;
end

return {
    index = function(ngx)
        --local fun = Template.compile(UserSql.sql, "UserSql:sql", true)
        --ngx.say(fun({username = "root"}))
        local ok, res = RedisOperations.get("dog")
        ngx.say(Cjson.encode({ok, res}))
        --[[Template.render("index.html", {
            title = "Cube Example";
            message = "Hello Cube Example!"
        });]]
    end
}

