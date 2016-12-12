-- 根据项目修改相应的 root, env 值
return {
	root = "/home/losyn/custumer-soft-install/openresty-1.11.2.2/nginx/apps/",
	-- env = ["dev", "test", "uat", "prod"]
	env  = "dev",
	-- dns 服务配置文件，默认取 linux 的 "/etc/resolv.conf" 这个文件
	resolv = "/etc/resolv.conf"
};

