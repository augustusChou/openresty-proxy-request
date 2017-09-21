--
-- User: 周广
-- Date: 2017/9/13
-- Time: 19:37
-- 
--

local redis_config = require "config/db_config"
local ngx = ngx
local redis_i = require "resty.redis-util"
local consistent_hash = require "common/chash"
local _M = {}
_M.redis_list = {}
_M.initialized = false
_M.hash = consistent_hash

function _M.init()
    local session_cache_config = redis_config.get_session_redis_config()
    ngx.log(ngx.INFO, " start init session cache")
    for i = 1, #session_cache_config do
        local ip = session_cache_config[i].ip
        local port = session_cache_config[i].port
        local password = session_cache_config[i].password
        if string.len(password) == 0 then
            password = nil
        end

        local redis = redis_i:new({
            host = ip,
            port = port,
            password = password
        })

        _M.hash.add_upstream(ip)
        table.insert(_M.redis_list, { ip = ip, redis = redis })
    end
    _M.initialized = true
end


local function getRedis(match_ip)
    for i = 1, #_M.redis_list do
        if _M.redis_list[i].ip == match_ip then
            return _M.redis_list[i].redis
        end
    end
end


function _M.set(self, key, value)
    if not _M.initialized then
        _M.init()
    end
    local match_ip = _M.hash.get_upstream(key)
    local redis_server = getRedis(match_ip)
    local ok, err = redis_server:set(key, value)
    if not ok then
        ngx.log(ngx.ERR, "set fail", err)
    end
end

function _M.get(self, key)
    if not _M.initialized then
        _M.init()
    end

    local match_ip = _M.hash.get_upstream(key)
    local redis_server = getRedis(match_ip)

    local cache_value = redis_server:get(key)
    if cache_value then
        return cache_value
    else
        for i = 1, #_M.redis_list do
            local ip = _M.redis_list[i].ip
            if ip ~= match_ip then
                local redis = _M.redis_list[i].redis
                cache_value = redis:get(key)
                if cache_value then
                    return cache_value
                end
            end
        end
        return
    end
end


return _M