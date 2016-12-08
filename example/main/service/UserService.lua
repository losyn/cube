-- Created by losyn on 12/8/16

local UserStore = loading("main.store.UserStore");

return {
    find = function()
        return UserStore.find();
    end,

    update = function()
        UserStore.update();
    end,

    delete = function()
        UserStore.delete();
    end
}

