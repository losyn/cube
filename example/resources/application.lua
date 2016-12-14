-- Created by losyn on 12/5/16
local Environment = require("environment");

-- conf = {dev = {}, test ={}, uat = {}, prod = {}}
local conf = {
    dev = {
        viewCache = false;
        mysqlc = {
            host = "localhost",
            port = 3306,
            database = "mysql",
            user = "root",
            password = "root",
            show_sql = true
        },
        redisc = {
            host = "127.0.0.1",
            port = 6379,
            database = 0
        }
    },
    test = {
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

return conf[Environment.env];