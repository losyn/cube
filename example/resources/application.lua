-- Created by losyn on 12/5/16
local Environment = require("environment");

local conf = {
    dev = {
        viewCache = false;
        mysqlUrl = "xxxxx"
    },
    test = {},
    uat = {},
    prod = {}
}

return conf[Environment.env];