--
-- User: 周广
-- Date: 2017/9/14
-- Time: 17:57
-- 
--
local ngx = ngx
local string = string
local redis_i = require "resty.redis-util"
local remote_config = require "config/db_config"

local _M = {}
_M.initialized = false
local CACHE_PREFIX = "GW_DENY_IP"

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

    _M.ip = ip
    _M.port = port
    _M.password = password
    _M.initialized = true
    return true
end

function _M.ip_validity_is_deny(ip_address)
    if not _M.initialized then
        if not init() then
            return false
        end
    end

    local redis = redis_i:new({
        host = _M.ip,
        port = _M.port,
        password = _M.password
    })


    local result = redis:hexists(CACHE_PREFIX, ip_address)

    --如果ip在黑名单中 返回true
    if result ~= nil and result == 1 then
        return true
    else
        return false
    end
end

return _M