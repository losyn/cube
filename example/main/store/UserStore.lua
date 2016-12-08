-- Created by losyn on 12/8/16

return {
    find = function()
        return {
            {name = "zhangsan", age = 12, gender = "male" }
        };
    end,

    update = function()
        ngx.log(ngx.INFO, "user updated.....");
    end,

    delete = function()
        ngx.log(ngx.INFO, "user deleted.....");
    end
}

