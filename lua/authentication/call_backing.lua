--
-- User: 周广
-- Date: 2017/9/15
-- Time: 17:32
-- 
--访问限制

local ngx = ngx
local string = string
local tonumber = tonumber
local redis_i = require "resty.redis-util"
local bottom_dict = ngx.shared.bottom
local remote_config = require "config/db_config"

local _M = { _VERSION = '0.01', CACHE_PREFIX = "GW" }

function _M.save_call_record(document_uri, remote_ip)

    local ip = bottom_dict:get("data_redis_ip")
    local port = bottom_dict:get("data_redis_port")
    local password = bottom_dict:get("data_redis_password")
    if not password or string.len(password) == 0 then
        password = nil
    end

    local redis = redis_i:new({
        host = ip,
        port = port,
        password = password
    })


    local key = document_uri .. remote_ip
    if string.sub(key, 1, 1) == "/" then
        key = string.sub(key, 2)
    end
    key = "" .. string.gsub(key, "/", ":")


    --缓存过期时间
    local expire = bottom_dict:get("unit_time")
    --单位时间内最大访问次数
    local time_max_call = bottom_dict:get("max_call")
    local res, err = redis:eval([[
    local current = redis.call("incr",KEYS[1])
    if 1 == tonumber(current) then
        redis.call("expire",KEYS[1],KEYS[2])
    end
    return current
    ]], 2, key, expire)

    if not res then
        ngx.log(ngx.ERR, "设置redis访问记录失败 " .. err)
        return
    end

    if time_max_call <= tonumber(res) then
        remote_config.add_deny_ip(remote_ip)
    end
end

return _M