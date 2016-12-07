-- 根据项目修改相应的 root, env 值
return {
	root = "/home/losyn/custumer-soft-install/openresty-1.11.2.2/nginx/apps/",
	env  = "dev",	-- env = ["dev", "test", "uat", "prod"]
	exists = function(path)
		local file, err = io.open(path);
		if file then
		    file.close();
		end
		return file ~= nil, err;
	end
};

