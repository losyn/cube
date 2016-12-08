-- Created by losyn on 12/4/16

return {
    access = function()
        ngx.ctx.Authentication = "Authentication OK";
        return true;
    end
}
