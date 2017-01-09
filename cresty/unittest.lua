-- Created by losyn on 12/16/16

local Environment = require("environment");
local Functionality = require("functionality")
local Cjson = require("cjson.safe")
local Safe = require("safe")
local Lfs = require("lfs")

local TEST_ROOT = Environment.root .. ngx.var.project

local _M = { _VERSION = '0.01' }

-- 字颜色: 30--37; 30: 黑, 31: 红, 32: 绿, 33: 黄, 34: 蓝, 35: 紫, 36: 深绿, 37: 白色
local C = { black = 30, green = 32, red = 31, yellow = 33, blue = 34, purple = 35, darkGreen = 36, white = 37 }
local default = "00000"

local message = function(time, title, msg)
    return {
        time = time,
        title = title,
        msg = msg
    }
end

local formatColor = function(color)
    return "\x1b[" .. color .. "m"
end

local formatStr = function(msg)
    if Functionality.isString(msg) then
        return msg
    end
    return Cjson.encode(msg)
end

local log = function(color, message)
    ngx.print(formatColor(C.white) .. message.time .. "    \x1b[m")
    ngx.print(formatColor(C.green) .. message.title .. "    \x1b[m")
    ngx.say(formatColor(color) .. formatStr(message.msg) .. "\x1b[m")
    ngx.flush()
end

local titleF = function(title, flag)
    return flag and string.format("[%s]", title) or string.format("    \\_[%s]", title)
end

local timeF = function(time)
    ngx.update_time()
    return string.format("%05d", (ngx.now() - time) * 1000)
end

local stasticF = function(num1, num2, num3, summary)
    return summary
            and "modules: " .. num1 .. " methods: " .. num2 .. " success: " .. num3 .. " failures: " .. (num2 - num3)
            or "methods: " .. num1 .. "  success: " .. num2 .. "  failures: " .. num3
end

local startLog = function(title)
    log(C.green, message(default, titleF(title, true), "unit test start"))
end

local endLog = function(time, title, all, success, failures)
    log(C.blue, message(timeF(time), titleF(title, true), "stastic > " .. stasticF(all, success, failures)))
end

local fCount = 0
local fSuccess = 0
local doExec = function(init, name, func)
    --noinspection UnusedDef
    fCount = fCount + 1
    local start = ngx.now()
    if init then
        local _, error = Safe.invoke(init, _M)
        if error then
            log(C.red, message(timeF(start), titleF(name), "FAIL when exec init..." .. error))
            return false
        end
    end
    local _, error = Safe.invoke(func, _M)
    if error then
        log(C.red, message(timeF(start), titleF(name), "FAIL ..." .. error))
        return false
    end
    log(C.darkGreen, message(timeF(start), titleF(name), "PASS"))
    --noinspection UnusedDef
    fSuccess = fSuccess + 1
    return true
end

local mCount = 0
local runTargetmm = function(target, mou, md)
    --noinspection UnusedDef
    mCount = mCount + 1
    local file = (string.gsub(ngx.var.project .. target .. "/" .. mou, "/", "."))
    local ok, M = Safe.import(file)
    if not ok then
        return log(C.red, message(default, titleF(mou, true), "can not find test module in the path: " .. target))
    end
    if not Functionality.isObject(M) or Functionality.isEmpty(M) then
        return log(C.yellow, message(default, titleF(mou, true), "can not find test method in module"))
    end
    if not md then
        local start = ngx.now()
        local stastic = { success = 0, failures = 0 }
        --for _ = 1, count do
        local all = 0
        for k, v in pairs(M) do
            -- not init method
            if "init" ~= k then
                all = all + 1
                if doExec(M.init, k, v) then
                    stastic.success = stastic.success + 1
                else
                    stastic.failures = stastic.failures + 1
                end
            end
        end
        --end
        return endLog(start, file, all, stastic.success, stastic.failures)
    end
    if "init" == md then
        return log(C.red, message(default, titleF(file, true), "your run test method can not be named init"))
    end
    if not M[md] then
        return log(C.red, message(default, titleF(file, true), "can not find test method in the module"))
    end
    local start = ngx.now()
    startLog(file)
    if doExec(M.init, md, M[md]) then
        return endLog(start, file, 1, 1, 0)
    end
    return endLog(start, file, 1, 0, 1)
end

local runTargetms
runTargetms = function(target)
    local root = TEST_ROOT .. target
    for p in Lfs.dir(root) do
        local fMode = Lfs.attributes(root .. "/" .. p).mode
        if "lua" == Functionality.fileExtension(p) and "directory" ~= fMode then
            runTargetmm(target, Functionality.fileName(p), nil)
        elseif p ~= "." and p ~= ".." and "directory" == fMode then
            runTargetms(target .. "/" .. p)
        end
    end
end

local clearCount = function()
    mCount = 0
    fCount = 0
    fSuccess = 0
end

local run = function(path, mou, md)
    clearCount()
    local target = path or "/test"
    if not Functionality.fileExists(TEST_ROOT .. target) then
        return log(C.red, message(default, titleF(path, true), "can not find the test path"))
    end
    local time = ngx.now()
    if 1 ~= string.find(target, "/test") then
        log(C.yellow, message(default, titleF(path, true), "your give path not in test folder"))
    end
    local title = mou and (target .. "/" .. mou) or target
    startLog(title)
    if mou then
        runTargetmm(target, mou, md)
    else
        runTargetms(target)
    end
    log(C.darkGreen, message(timeF(time), titleF(title, true), "summary stastic > " .. stasticF(mCount, fCount, fSuccess, true)))
    log(C.green, message(timeF(time), titleF(title, true), "unit test complete"))
end


_M.log = function(msg)
    log(C.white, message("     ", "     ↓-*-*-*-*-*", msg))
end

_M.assertEquals = function(expect, actual)
    if expect ~= actual then
        error("expect: " .. expect .. " but actual: " .. formatStr(actual))
    end
end

_M.assertTrue = function(actual)
    if not actual then
        error("expect not (nil or false) but actual: " .. Cjson.encode(actual))
    end
end

_M.assertFalse = function(actual)
    if actual then
        error("expect nil or false but actual: " .. Cjson.encode(actual))
    end
end

_M.run = function(path, mou, md)
    return run(path, mou, md)
end

return _M
