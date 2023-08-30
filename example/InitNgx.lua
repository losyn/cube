-- Created by losyn on 12/2/16
-- init_by_lua_file invoke
return {
    initial = function(ngx)
        ngx.log(ngx.INFO, "performance ngx initial.....");
    end
}
