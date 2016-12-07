-- Created by losyn on 12/2/16 2:08 PM

--[[
接口路由定义使用了类似 Strust2 的 DMI 方式 {path = "", method = "", dt = "", action = "", ctrl = ""}
exemple: {uri = "/user!add", method = POST, dt = JSON, ctrl = "controller.user"}
表示定义了一个添加用户的API接口:
      请求URL：/user!add, 请求方式：POST, 返回数据类型： JSON, 执行操作： add, 控制器： performance/controller/User.lua
]]

-- HTTP 请求方式
local GET, PUT, POST, DELETE, OPTIONS, HEAD = "GET", "PUT", "POST", "DELETE", "OPTIONS", "HEAD";
-- 接口返回类型（OCTET: 用于文件下载）
local JSON, XML, HTML, TEXT, OCTET = "application/json", "application/xml", "text/html", "text/plain", "application/octet-stream";
return {
    {path = "/", action="index", method = GET, dt = HTML, ctrl = "performance.src.controller.User" },

    {path = "/user", action= "find", method = GET, dt = JSON, ctrl = "performance.src.controller.User" },
    {path = "/user", action= "modify", method = POST, dt = JSON, ctrl = "performance.src.controller.User" },
    {path = "/user", action= "remove", method = POST, dt = JSON, ctrl = "performance.src.controller.User" }
};