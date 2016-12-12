local mysql = require("resty.mysql")
local Cjosn = require("cjson.safe")
local Safe = require("safe")
local Functionality = require("functionality")
local Nameservice = require("nameservice")

local Conf = loading("resources.application")

local MySqlOperations = {}

local function getOptions()
    return Functionality.defaults(Conf.mysqlc, {
        host = "127.0.0.1",
        port = 3306,
        database = "mysql",
        user = "root",
        password = "root",
        poolsize = 100,
        -- 10s
        timeout = 10000,
        -- 60s
        keepalive = 60000,
        show_sql = false,
        compact_arrays = false,
        -- 1M
        max_packet_size = 1024 * 1024,
        -- user default pool name
        pool = nil,
        ssl = false,
        ssl_verify = false
    });
end

local function formatQuery(queryId, params)
    if not params or not Functionality.isObject(params) then
        return false, "query params error, params must be table", 0
    end
    local idx = Functionality.split(queryId, ":")
    if #idx ~= 2 then
        return false, "query id error", 0
    end
    local ret, SQL = Safe.import(ngx.var.project .. ".resources.sql." .. idx[1])
    if ret and SQL[idx[2]] then
        if not Functionality.isString(SQL[idx[2]]) then
            return false, "query sql not a string error", 0
        end
        local query = require("template").compile(SQL[idx[2]], "UserSql.sql", true)(params)
        local size = (not Functionality.isNumber(params.size) or params.size <= 0) and 1 or params.size
        if(ngx.ctx[MySqlOperations].OPTIONS.show_sql) then
            ngx.log(ngx.INFO, "queryId: ", queryId, ", sql: ", query, ", size: ", size)
        end
        return true, query, size
    end
    return false, "not found query id", 0
end

local function connect()

    if ngx.ctx[MySqlOperations] then
        return ngx.ctx[MySqlOperations]
    end

    local db, msg = mysql:new()
    if not db then
        ngx.log(ngx.ERR, "failed to mysql socket: ", msg);
        return nil;
    end

    local options = getOptions();
    options.host = Nameservice.address(options.host)

    db:set_timeout(options.timeout);

    local rs, error, code, sqlstate = db:connect(options);
    if not rs then
        ngx.log(ngx.ERR, "failed to connect mysql, error: ", error, ", code: ", code, ", sqlstate: ", sqlstate);
        ngx.log(ngx.ERR, "mysql options: ", Cjosn.encode(options));
        return nil;
    end

    rs, error, code, sqlstate = db:query("SET NAMES UTF8");
    if not rs then
        ngx.log(ngx.ERR, "bad query: SET NAMES UTF8, error: ", error, ", code: ", code, ", sqlstate: ", sqlstate);
        return nil;
    end

    db.OPTIONS = options;
    ngx.ctx[MySqlOperations] = db;
    return ngx.ctx[MySqlOperations]
end

local function close()
    local db = ngx.ctx[MySqlOperations];
    if db then
        local options = db.OPTIONS;
        db:set_keepalive(options.keepalive, options.poolsize);
        ngx.ctx[MySqlOperations] = nil
    end
end

local invokeReturnDB = function(func, flag)
    if flag then
        if not Functionality.isFunction(func) then
            ngx.log(ngx.ERR, "mysql correct first arg except function but error.....");
            return false, "mysql correct first arg except function but error"
        end
    end
    local db = connect();
    if not db then
        ngx.log(ngx.ERR, "failed to connect mysql... ");
        return false, "failed to connect mysql"
    end
    return true, db
end

local dbResponse = function(ret, res)
    close()
    return ret, res
end

local doExecute = function(func, f, overt, flag)
    local okF, db = invokeReturnDB(f, flag)
    if not okF then
        ngx.log(ngx.ERR, "invokeReturnDB error: ", db);
        return false, db
    end

    if overt then
        local rs, error, code, sqlstate = db:query("START  TRANSACTION")
        if not rs then
            ngx.log(ngx.ERR, "failed to start transaction, error: ", error, ", code: ", code, ", sqlstate: ", sqlstate)
            return false, "failed to start transaction"
        end
    end

    local ret, res = func(db)

    if overt then
        local rs, error, code, sqlstate = db:query("COMMIT")
        if not rs then
            ngx.log(ngx.ERR, "failed to commit transaction, error: ", error, ", code: ", code, ", sqlstate: ", sqlstate)
            local res, err, rcode, state = db:query("ROLLBACK")
            if not res then
                ngx.log(ngx.ERR, "failed to rollback, error: ", err, ", code: ", rcode, ", sqlstate: ", state);
                return false, "failed to rollback";
            end
            return false, "failed to commit transaction"
        end
    end
    return dbResponse(ret, res)
end

-- 代理函数中执行 SQL, 参数 db 、overt 是代理执行函数决定， queryId 、params 由项目功能业务决定
function MySqlOperations:query(db, overt, queryId, params)
    if not db then
        ngx.log(ngx.ERR, "failed to connect mysql... ");
        return false, "failed to connect mysql";
    end
    local ok, statement, size = formatQuery(queryId, params);
    if not ok then
        ngx.log(ngx.ERR, "failed to create sql statement, error: ", statement, ", queryId: ", queryId, ", size: ", size);
        return false, "failed to create sql statement";
    end
    local rs, error, code, sqlstate = db:query(statement, size);
    if not rs then
        ngx.log(ngx.ERR, "failed to query data, error: ", error, ", code: ", code, ", sqlstate: ", sqlstate);
        if overt then
            local res, err, rcode, state = db:query("ROLLBACK")
            if not res then
                ngx.log(ngx.ERR, "failed to rollback, error: ", err, ", code: ", rcode, ", sqlstate: ", state);
                return false, "failed to rollback";
            end
        end
        return false, error;
    end
    return true, rs;
end

-- 直接执行 SQL, overt 是否显示开启事务
function MySqlOperations:exec(queryId, params, overt)
    return doExecute(function(db)
        return self:query(db, overt or false, queryId, params)
    end, nil, overt, false);
end

-- 代理执行 DB 操作
function MySqlOperations:invoke(func, params)
    local okF, db = invokeReturnDB(func, true)
    if not okF then
        ngx.log(ngx.ERR, "invokeReturnDB error: ", db);
        return false, db
    end
    local ret, res = func(db, false, params)
    return dbResponse(ret, res)
end

-- 代理执行 DB 显示事务操作
function MySqlOperations:correct(func, params)
    return doExecute(function(db)
        return func(db, true, params)
    end, func, true, false);
end

return MySqlOperations