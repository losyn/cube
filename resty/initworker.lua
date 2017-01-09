-- Created by losyn on 12/2/16

local Environment = require("environment");
local Lfs = require("lfs");
local Safe = require("safe");

local init = function()
    for p in Lfs.dir(Environment.root) do
        if p ~= "." and p ~= ".." and "directory" == Lfs.attributes(Environment.root .. p).mode then
            ngx.log(ngx.INFO, Environment.root .. p);
            local ret, InitWrk = Safe.import(p .. ".InitWrk");
            if ret then InitWrk.initial(ngx) end
        end
    end
end

init();