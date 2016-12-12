#### cube 介绍

* openresty 介绍： OpenResty(又称：ngx_openresty) 是一个基于 NGINX 的可伸缩的 Web 平台，由中国人章亦春发起，提供了很多高质量的第三方模块。
                OpenResty 是一个强大的 Web 应用服务器，Web 开发人员可以使用 Lua 脚本语言调动 Nginx 支持的各种 C 以及 Lua 模块,更主要的是在性能方面，OpenResty可以 快速构造出足以胜任 10K 以上并发连接响应的超高性能 Web 应用系统。基于 openresty 开发项目的门槛是用户既要懂 nginx 配置又要会 Lua 语言，这样让很多开发者力不人心。
                
* cube 是基于 openresty 的服务插件框架，方便开发者更容易的使用 openresty 开发项目，cube 简单的实现了 struts2 的 DMI 功能。开发者只需要关注业务逻辑省去的 Nginx 配置的难题
 
##### cube 目前的功能

1. 实现了 struts2 DMI 方式的路由，开发者只需要配置 ×××/resources/RouterList.lua 中的路由写自己的业务逻辑

2. 用户权限认证注册 ACL 用户中需要在 ×××/resources/nginx.conf 的 $acc_ctrl_ls 中注入自己的访问控制类，访问控制类要提供一个能返回布尔类型的 access 方法

3. 用户可以实现项目启动初始化任务， 只需要在 InitNgx.lua 或 InitWrk.lua 文件中添加自己的逻辑代码

4. 利用 openresty 实现类似 Tomcat 容器的功能，在机器上安装一个 openresty 运行多个项目只需要按照 example 项目的配置 （server 配置端口不冲突即可） 

5. cube 要求项目结构如下

```
    /project             项目根目录
    
        /lib             第三方依赖包目录
        
        /logs            日志文件目录
        
        /main            主业务文件目录
        
        /resources       资源配置文件目录
        
        /test            单元测试目录
        
        InitNgx.lua      系统启动初始化任务业务代码文件
        
        InitWrk.lua
```

6. 支持 mysql 简单实现了 mybatis 的功能

```
    local ok, res = MySqlOperations:exec("UserSql:sql", {username = "root", size = 10})
    ngx.say(Cjson.encode(res))
    
    local ok, res = MySqlOperations:invoke(function(db, overt, params)
        ngx.log(ngx.ERR, "invoke params", Cjson.encode(params))
        return = MySqlOperations:query(db, overt, "UserSql:sql", params)
    end, {username = "root", size = 10})
    ngx.say(Cjson.encode(res))
```

#### cube 配置使用

##### 安装 openresty 

1. download openresty 中文官网 http://openresty.org/cn/

2. 在 /YYY/openresty/nginx 目录下新建目录 apps

3. 配置 openresty 

* 修改 /YYY/openresty/nginx/conf/nginx.conf 文件, 非开发环境请配置 lua_code_cache on;

```
    #user  openresty;
    ### 根据项目配置
    worker_processes  1;

    #pid        logs/nginx.pid;

    events {
        worker_connections  1024;
    }

    http {
        include       mime.types;
        default_type  application/octet-stream;
        charset 	  utf-8;
        server_names_hash_bucket_size 128;
        #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
        #                  '$status $body_bytes_sent "$http_referer" '
        #                  '"$http_user_agent" "$http_x_forwarded_for"';
        error_log   off;
        access_log  off;

        sendfile        on;
        #tcp_nopush     on;

        #keepalive_timeout  0;
        keepalive_timeout  65;

        gzip  on;

        fastcgi_intercept_errors on;

        ### lua package path conf, product env cache must on 
        lua_package_path "$prefix/apps/?.lua;$prefix/resty/?.lua;;";
        lua_package_cpath "$prefix/apps/?.so;$prefix/resty/?.so;;";
        
        ### when environment.env != dev you must set it's on
        lua_code_cache off;

        init_by_lua_file          resty/init.nginx.lua;
        init_worker_by_lua_file   resty/init.worker.lua;

        ### To add your start app service used conf 
        # include ../apps/example/resources/nginx.conf;
    }
```  

##### 安装 cube

1. 源码安装 github 地址： https://github.com/wtclosyn/cube
 
2. 将 1 中下载的 resty 目录复制到 /YYY/openresty/nginx 目录下，保证与 apps 目录同级

3. 修改 environment.lua 中的内容符合你自己的项目

###### 注意： cube 扩展了一个全局方法 loading，实现以项目相对路径加载模块（等同于 require 的功能如 loading("main.service.UserService")）

##### Cube example 项目

1. 配置

``` 
    windows link命令如下：
        mklink /j /XXX/example /YYY/openresty/apps/example
    
    linux/mac link命令如下：
        ln -s /XXX/example /YYY/openresty/apps/example
        
    修改 openresty 安装目录中对应 nginx 的配置添加自己项目需要的 conf 文件如下
    
        include ../apps/example/resources/nginx.conf;
        
  注意： /XXX 是 example 的项目目录， /YYY 是您系统中 openresty 的安装目录
  
```    

2. 直接启动 /YYY/openresty/nginx/sbin 运行项目， 项目的停止，重启等与操作Nginx一样

3. 新添加请求路由只需要修改 ×××/RouterList.lua 文件中的路由及添加自己的业务代码
