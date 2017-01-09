-- Created by losyn on 12/19/16
local Safe = require("safe")

local success = function()
    return "Success"
end

local failed = function()
    error("Failed")
end

local lightT = function(key)
    return true, key .. ": value"
end

local lightF = function(key)
    return false, key .. ": value"
end

local weightT = function(key)
    ngx.sleep(2)
    return true, key .. ": value"
end

local weightF = function(key)
    ngx.sleep(2)
    return false, key .. ": value"
end

local cacheT = function(key, value, expire)
    return true, ngx.say("cache " ..key .. ": " .. value .. " by expire " .. expire)
end

local cacheF = function(key, value, expire)
    return false, ngx.say("cache " ..key .. ": " .. value .. " by expire " .. expire)
end

return {
    init = function(tcx)
        tcx.log("cube safe.lua init complete")
    end,

    testInvoke = function(tcx)
        -- success invoke
        local ok, res = Safe.invoke(success)
        tcx.assertTrue(ok)
        tcx.assertEquals("Success", res)
        -- failed invoke
        local ok, _ = Safe.invoke(failed)
        tcx.assertFalse(ok)
    end,

    testImport = function(tcx)
        -- success import module
        local ok, res = Safe.import("safe")
        tcx.assertTrue(ok)
        tcx.assertTrue(res.import)
        -- failed import module
        local ok, _ = Safe.import("abcde")
        tcx.assertFalse(ok)
    end,

    testEffect = function(tcx)
        -- lightT ignore weightT, cacheF
        local ok, res = Safe.effect("key", lightT, weightT, cacheF, 1)
        tcx.assertTrue(ok)
        tcx.assertEquals("key: value", res)

        -- lightF invoke weightT, cacheT
        local ok, res = Safe.effect("key", lightF, weightT, cacheT, 1)
        tcx.assertTrue(ok)
        tcx.assertEquals("key: value", res)

        local ok, res = Safe.effect("key", lightF, weightF, cacheF, 1)
        tcx.assertFalse(ok)
        tcx.assertEquals(nil, res)
    end
}

