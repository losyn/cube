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

local C = { black = 30, green = 32, red = 31, yellow = 33, blue = 34, purple = 35, dark_green = 36, white = 37 }

local function formatColor(color)
    return "\x1b[" .. color .. "m"
end

local log = function(color, message)
    ngx.print(formatColor(C.green) .. message.title .. "\t\x1b[m")
    ngx.say(formatColor(color) .. message.msg .. "\x1b[m")
end

return {
    index = function(ngx)
        --local fun = Template.compile(UserSql.sql, "UserSql:sql", true)
        --ngx.say(fun({username = "root"}))
        --[[local ok, res = RedisOperations.get("dog")
        ngx.say(Cjson.encode({ok, res}))
        ngx.say("ngx.worker.count(): ",  ngx.worker.count())
        ngx.timer.at(0, function(p)
            if p then return end
            ngx.log(ngx.ERR, Cjson.encode({a = 1, b = 2}))
        end)
        RedisOperations.subscribe("channel", function(rs)
            ngx.log(ngx.ERR, Cjson.encode(rs))
        end, 3)
        ngx.sleep(3)
        ngx.say("sleep to publish")
        ngx.log(ngx.ERR, "publish channel value hello")
        RedisOperations.publish("channel", "hello")]]
        log(C.red, {time = 100, title = "abc", msg = "bcdabc"})
        ngx.say(string.format("[%s]", "abc"))
        ngx.say(string.format("[%s]", ngx.now() * 1000))
        ngx.say(string.format("[%s]", ngx.now() * 1000))
        ngx.say(string.format("[%s]", Functionality.fileExtension("abcdefg.lua")))
        ngx.say(Cjson.encode(ngx.req.get_uri_args()))
        ngx.say(Cjson.encode(ngx.var.arg_a))
        --[[Template.render("index.html", {
            title = "Cube Example";
            message = "Hello Cube Example!"
        });]]
    end
}

