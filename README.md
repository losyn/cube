#### Cube 配置使用

##### 安装 openresty 

1. download openresty 中文官网 http://openresty.org/cn/

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
        # include ../apps/example/resources/nginx.conf;
    }
```    

3. 在 /YYY/openresty/nginx 目录下新建目录 apps

##### 安装 Cube

1. 源码安装 github 地址： https://github.com/wtclosyn/cube
 
2. 将 1 中下载的 resty 目录复制到 /YYY/openresty/nginx 目录下，保证与 apps 目录同级

##### Cube example 项目

1. example github 地址： 

``` 
    windows link命令如下：
        mklink /j /XXX/example /YYY/openresty/apps/example
    
    linux/mac link命令如下：
        ln -s /XXX/example /YYY/openresty/apps/example
        
        
  注意： /XXX 是 example 的项目目录， /YYY 是您系统中 openresty 的安装目录
```    

6. 修改 nginx.conf 配置 添加自己项目需要的conf文件

```
    include ../apps/example/resources/nginx.conf;
```

7. 直接启动 /YYY/openresty/nginx/sbin 运行项目， 项目的停止，重启等与操作Nginx一样

8. 新添加请求路由只需要修改 ×××/RouterList.lua 文件
