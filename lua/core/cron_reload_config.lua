--
-- User: 周广
-- Date: 2017/9/21
-- Time: 10:51
-- 
--

local ngx = ngx
local bottom_dict = ngx.shared.bottom
local remote_config = require "config/db_config"
local string = string
local timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local cron_fun

cron_fun = function(premature)
    if premature then
        return
    end

    local data_redis_config = remote_config.get_data_redis_config()
    local deny_ip_config = remote_config.get_deny_ip_config()
    if not data_redis_config or not deny_ip_config then
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end

    local new_deny_conf_version = deny_ip_config.version_num
    local old_deny_conf_version = bottom_dict:get("deny_conf_version")
    if not old_deny_conf_version then
        old_deny_conf_version = -1
    end

    if new_deny_conf_version > old_deny_conf_version then
        bottom_dict:set("deny_conf_version", new_deny_conf_version)
        bottom_dict:set("unit_time", deny_ip_config.unit_time)
        bottom_dict:set("max_call", deny_ip_config.max_call)
        bottom_dict:set("deny_time", deny_ip_config.deny_time)
        log(ERR,
            "装载新配置 版本号:" .. deny_ip_config.version_num ..
                    "单位时间:" .. deny_ip_config.unit_time ..
                    "最大访问:" .. deny_ip_config.max_call ..
                    "延迟时间:" .. deny_ip_config.deny_time)
    end

    local old_data_redis_conf_version = bottom_dict:get("data_redis_conf_version")
    if not old_data_redis_conf_version then
        bottom_dict:set("data_redis_ip", data_redis_config[1].ip)
        bottom_dict:set("data_redis_port", data_redis_config[1].port)
        local password = data_redis_config[1].password
        if password ~= nil and string.len(password) > 0 then
            bottom_dict:set("data_redis_password", password)
        end
        bottom_dict:set("data_redis_conf_version", data_redis_config[1].version_num)
        log(ERR, "数据缓存ip:" .. data_redis_config[1].ip .. "数据缓存端口:" .. data_redis_config[1].port)
    end

end

--因为这个定时器会为每一个worker进程启动一个 所以指定workerId为0才执行，这样就只执行一次
if 0 == ngx.worker.id() then
    local ok, err = timer(0, cron_fun)
    if not ok then
        log(ERR, "执行定时装载配置任务失败", err)
        return
    end
end

