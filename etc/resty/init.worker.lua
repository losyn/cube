-- Created by losyn on 12/2/16

local Environment = require("environment");
local Lfs = require("lfs");

local INIT_WRK = "InitWrk";

local init = function()
    for p in Lfs.dir(Environment.root) do
        if p ~= "." and p ~= ".." and "directory" == Lfs.attributes(Environment.root .. p).mode then
            ngx.log(ngx.INFO, Environment.root .. p);
            if Environment.exists(Environment.root .. p .. "/" .. INIT_WRK .. ".lua") then
                local InitWrk = require(p .. "." .. INIT_WRK);
                InitWrk.initial();
            end
        end
    end
end

init();