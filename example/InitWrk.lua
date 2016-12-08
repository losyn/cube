-- Created by losyn on 12/2/16
-- init_worker_by_lua_file invok

return {
    initial = function(ngx)
        ngx.log(ngx.INFO, "performance, worker initial.....");
    end
}