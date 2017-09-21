--
-- User: 周广
-- Date: 2017/9/14
-- Time: 17:57
-- 
--
local ngx = ngx
local redis_i = require "resty.redis-util"
local bottom_dict = ngx.shared.bottom


local _M = {}
local CACHE_PREFIX = "GW_DENY_IP"


function _M.ip_validity_is_deny(ip_address)
    local redis = redis_i:new({
        host = bottom_dict:get("data_redis_ip"),
        port = bottom_dict:get("data_redis_port"),
        password = bottom_dict:get("data_redis_password")
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