local mysql = require("resty.mysql")
local Cjosn = require("cjson.safe")
local Safe = require("safe")
local Functionality = require("functionality")
local Nameservice = require("nameservice")

local Conf = loading("resources.application")

local _M = {_VERSION = "1.0.0"}

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
        if(ngx.ctx[_M].OPTIONS.show_sql) then
            ngx.log(ngx.INFO, "queryId: ", queryId, ", sql: ", query, ", size: ", size)
        end
        return true, query, size
    end
    return false, "not found query id", 0
end

local function connect()

    if ngx.ctx[_M] then
        return ngx.ctx[_M]
    end

    local db, msg = mysql:new()
    if not db then
        ngx.log(ngx.ERR, "failed to mysql socket: ", msg);
        return nil;
    end

    local options = getOptions();
    local ok, address = Nameservice.address(options.host)
    if not ok then
        ngx.log(ngx.ERR, "failed to resolv domain to address")
        return nil
    end
    options.host = address

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
    ngx.ctx[_M] = db;
    return ngx.ctx[_M]
end

local function close()
    if ngx.ctx[_M] then
        local options = ngx.ctx[_M].OPTIONS;
        local ok, error = ngx.ctx[_M]:set_keepalive(options.keepalive, options.poolsize);
        ngx.ctx[_M] = nil
        if not ok then
            ngx.log(ngx.ERR, "failed to close mysql, error: ", error)
            return false
        end
        return true
    end
end

local invokeReturnDB = function(func, flag)
    ngx.log(ngx.INFO, "mysql db connect")
    if flag then
        if not Functionality.isFunction(func) then
            ngx.log(ngx.ERR, "mysql correct first arg except function but error.....");
            return false, nil
        end
    end
    local db = connect();
    if not db then
        ngx.log(ngx.ERR, "failed to connect mysql... ");
        return false, nil
    end
    return true, db
end

local dbResponse = function(ret, res)
    ngx.log(ngx.INFO, "mysql db close")
    if close() then
        return ret, res
    else
        return false, nil
    end
end

local doExecute = function(func, f, overt, params, flag)
    local okF, db = invokeReturnDB(f, flag)
    if not okF then
        return false, nil
    end

    if overt then
        ngx.log(ngx.INFO, "start transaction")
        local rs, error, code, sqlstate = db:query("START  TRANSACTION")
        if not rs then
            ngx.log(ngx.ERR, "failed to start transaction, error: ", error, ", code: ", code, ", sqlstate: ", sqlstate)
            return false, nil
        end
    end

    local ret, res = func(db, f, overt, params)

    if overt then
        ngx.log(ngx.INFO, "transaction commit")
        local rs, error, code, sqlstate = db:query("COMMIT")
        if not rs then
            ngx.log(ngx.ERR, "failed to commit transaction, error: ", error, ", code: ", code, ", sqlstate: ", sqlstate)
            local res, err, rcode, state = db:query("ROLLBACK")
            if not res then
                ngx.log(ngx.ERR, "failed to rollback, error: ", err, ", code: ", rcode, ", sqlstate: ", state);
                return false, nil;
            end
            return false, nil
        end
    end
    return dbResponse(ret, res)
end

-- 代理函数中执行 SQL, 参数 db 、overt 是代理执行函数决定， queryId 、params 由项目功能业务决定
_M.query = function(db, overt, queryId, params)
    if not db then
        ngx.log(ngx.ERR, "failed to connect mysql... ");
        return false, nil;
    end
    local ok, statement, size = formatQuery(queryId, params);
    if not ok then
        ngx.log(ngx.ERR, "failed to create sql statement, error: ", statement, ", queryId: ", queryId, ", size: ", size);
        return false, nil;
    end
    local rs, error, code, sqlstate = db:query(statement, size);
    if not rs then
        ngx.log(ngx.ERR, "failed to query data, error: ", error, ", code: ", code, ", sqlstate: ", sqlstate);
        if overt then
            ngx.log(ngx.INFO, "transaction rollback")
            local res, err, rcode, state = db:query("ROLLBACK")
            if not res then
                ngx.log(ngx.ERR, "failed to rollback, error: ", err, ", code: ", rcode, ", sqlstate: ", state);
                return false, nil;
            end
        end
        return false, nil;
    end
    return true, rs;
end

-- 直接执行 SQL, overt 是否显示开启事务
_M.exec = function(queryId, params, overt)
    return doExecute(function(db, f, o, p)
        return _M.query(db, o, f, p)
    end, queryId, overt or false, params, false);
end

-- 代理执行 DB SQL, overt 是否显示开启事务
_M.invoke = function(func, params, overt)
    return doExecute(function(db, f, o, p)
        return f(db, o, p)
    end, func, overt or false, params, true);
end

return _M