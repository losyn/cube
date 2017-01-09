-- Created by losyn on 12/10/16

return {
    findByName = [[
        select * from user where User = '{{username}}' limit {{size}}
    ]]
}
