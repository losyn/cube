-- Created by losyn on 12/8/16

return {
    invoke = function(fun, ...)
        return pcall(fun, ...);
    end,

    import = function(lua)
        return pcall(require, lua);
    end
}

