--
-- User: 周广
-- Date: 2017/9/21
-- Time: 10:51
-- 
--

local ngx = ngx
local bottom_dict = ngx.shared.bottom
local remote_config = require "config/db_config"

local data_redis_config = remote_config.get_data_redis_config()
local deny_ip_config = remote_config.get_deny_ip_config()
if not data_redis_config or not deny_ip_config then
    ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

bottom_dict:set("unit_time",deny_ip_config.unit_time)
bottom_dict:set("max_call",deny_ip_config.max_call)
bottom_dict:set("deny_time",deny_ip_config.deny_time)
bottom_dict:set("data_redis_ip",deny_ip_config.data_redis_config[1].ip)
bottom_dict:set("data_redis_port",deny_ip_config.data_redis_config[1].port)
bottom_dict:set("data_redis_password",deny_ip_config.data_redis_config[1].password)

ngx.log(ngx.ERR, "单位时间:" .. _M.unit_time .. "最大访问:" .. _M.max_call .. "延迟时间:" .. _M.deny_time)

