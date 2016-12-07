###项目配置搭建与部署启动

#####注意： 

* 如果安装配置过 openresty 则下面 1, 2, 3, 4 步骤直接跳过，非开发环境中 对 nginx.conf 中配置一定为 "on" lua_code_cache on; 
* InitNgx.lua, InitWrk.lua, RouterList.lua 放在项目的根路径且名字不能修改

##### 步骤

1. 安装 openresty 中文官网 http://openresty.org/cn/

2. 配置 openresty 

* 修改 /YYY/openresty/nginx/conf/nginx.conf 文件

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

        lua_code_cache off;

        init_by_lua_file          resty/init.nginx.lua;
        init_worker_by_lua_file   resty/init.worker.lua;

        ### To add your start app service used conf 
        include ../apps/default/default.conf;

        include ../apps/cube/resources/nginx.conf;
    }
```    

3. 在 /YYY/openresty/nginx 目录下新建目录 apps, resty

4. 将项目 /×××/etc/resty 目录中的所有文件拷贝到上面创建的 resty 目录中并且配置好 environment.lua 中 root 对应的 openresty apps 目录，及环境变量 env

5. 将整个项目代码link到 openresty目录下的 apps 目录中

``` 
    windows link命令如下：
        mklink /j /XXX/cube /YYY/openresty/apps/cube
    
    linux/mac link命令如下：
        ln -s /XXX/cube /YYY/openresty/apps/cube
  注意： /XXX 是 cube 的项目目录， /YYY 是您系统中 openresty 的安装目录
```    

6. 修改 nginx.conf 配置 添加自己项目需要的conf文件

```
    include ../apps/cube/resources/default.conf;
```

7. 直接启动 /YYY/openresty/nginx/sbin 运行项目， 项目的停止，重启等与操作Nginx一样

8. 新添加请求路由只需要修改 ×××/RouterList.lua 文件
