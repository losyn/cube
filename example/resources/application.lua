-- Created by losyn on 12/5/16
local Environment = require("environment");
local Functionality = require("functionality")

-- conf = {dev = {}, test ={}, uat = {}, prod = {}}
local conf = {
    common = {
        rootAction = "/!index",
        routerList = "main.RouterList",
        ajaxHeader = "X-Requested-With=XMLHttpRequest",
        acls = {"main.common.Authentication"}
    },
    dev = {
        enableT = true,
        viewCache = false,
        mysqlc = {
            host = "localhost",
            port = 3306,
            database = "mysql",
            user = "root",
            password = "root",
            show_sql = true
        },
        redisc = {
            host = "localhost",
            port = 6379,
            database = 0
        },
        memcachec = {

        }
    },
    test = {
        enableT = false,
        viewCache = true;
        mysqlc = {
            host = "localhost",
            port = 3306,
            database = "mysql",
            user = "root",
            password = "root"
        }
    },
    uat = {
        enableT = false,
        viewCache = true;
        mysqlc = {
            host = "localhost",
            port = 3306,
            database = "mysql",
            user = "root",
            password = "root"
        }
    },
    prod = {
        enableT = false,
        viewCache = true;
        mysqlc = {
            host = "localhost",
            port = 3306,
            database = "mysql",
            user = "root",
            password = "root"
        }
    }
}

return Functionality.defaults(conf.common, conf[Environment.env]);