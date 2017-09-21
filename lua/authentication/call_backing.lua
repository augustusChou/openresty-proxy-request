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
local remote_config = require "config/db_config"


local _M = { _VERSION = '0.01', CACHE_PREFIX = "GW" }
_M.initialized = false

local function init()
    local data_redis_config = remote_config.get_data_redis_config()
    if not data_redis_config then
        return false
    end
    ngx.log(ngx.INFO, " start init data cache")
    local ip = data_redis_config[1].ip
    local port = data_redis_config[1].port
    local password = data_redis_config[1].password
    if string.len(password) == 0 then
        password = nil
    end

    local deny_ip_config = remote_config.get_deny_ip_config()
    if not deny_ip_config then
        return false
    end
    _M.unit_time = deny_ip_config.unit_time
    _M.max_call = deny_ip_config.max_call
    _M.deny_time = deny_ip_config.deny_time


    ngx.log(ngx.ERR, "单位时间:" .. _M.unit_time .. "最大访问:" .. _M.max_call .. "延迟时间:" .. _M.deny_time)

    _M.ip = ip
    _M.port = port
    _M.password = password
    _M.initialized = true
    return true
end

function _M.save_call_record(document_uri, remote_ip)
    if not _M.initialized then
        if not init() then
            return
        end
    end

    local redis = redis_i:new({
        host = _M.ip,
        port = _M.port,
        password = _M.password
    })


    local key = document_uri .. remote_ip
    if string.sub(key, 1, 1) == "/" then
        key = string.sub(key, 2)
    end
    key = "" .. string.gsub(key, "/", ":")


    --缓存过期时间
    local expire = _M.unit_time
    --单位时间内最大访问次数
    local time_max_call = _M.max_call
    local res, err = redis:eval([[
    local current = redis.call("incr",KEYS[1])
    if 1 == tonumber(current) then
        redis.call("expire",KEYS[1],KEYS[2])
    end
    return current
    ]], 2, key, expire)

    if not res then
        ngx.log(ngx.ERR, "设置访问失败 " .. err)
        return
    end
    ngx.log(ngx.ERR, "缓存key:" .. key .. "访问次数:" .. res)

    if time_max_call <= tonumber(res) then
        remote_config.add_deny_ip(remote_ip)
    end
end

return _M