-- Created by losyn on 12/19/16

local MysqlOperations = require("provider.mysqloperations")

local Functionality = require("functionality")

local find = function(db, overt, params)
    local ok, rs = MysqlOperations.query(db, overt, "UserSql:findByName", params)
    -- your business code
    return ok, rs[1]
end

return {
    init = function(tcx)
        tcx.log("cube mysqloperations.lua init complete")
    end,

    testExec = function(tcx)
        local ok, rs = MysqlOperations.exec("UserSql:findByName", {username = "root", size = 1}, false)
        tcx.assertTrue(ok)
        tcx.assertTrue(Functionality.isArray(rs))
        tcx.assertTrue(Functionality.size(rs) == 1)
        tcx.assertEquals("root", rs[1].User)

        local ok, rs = MysqlOperations.exec("UserSql:findByName", {username = "abc", size = 5}, true)
        tcx.assertTrue(ok)
        tcx.assertTrue(Functionality.isEmpty(rs))
    end,

    testInvoke = function(tcx)
        local ok, rs = MysqlOperations.invoke(find, {username = "root", size = 1}, false)
        tcx.assertTrue(ok)
        tcx.assertEquals("root", rs.User)

        local ok, rs = MysqlOperations.invoke(find, {username = "abc", size = 1}, false)
        tcx.assertTrue(ok)
        tcx.assertEquals(nil, rs)
    end
}