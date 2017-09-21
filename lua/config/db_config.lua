--
-- User: 周广
-- Date: 2017/9/13
-- Time: 20:11
-- 
--
local ngx = ngx
local http = require "resty.http"
local json = require("cjson.safe")

local _M = {}
--local server_address = "http://192.168.198.164:8080"
local server_address = "http://192.168.100.15:8080"


local function load_remote_config(config_name)
    local httpc = http.new()
    httpc:set_timeout(2000)
    local res, err = httpc:request_uri(server_address .. "/api-gateway-manage/redisConfig/queryRedisListByName?redisName=" .. config_name)

    if res == nil or 200 ~= res.status then
        ngx.log(ngx.ERR, "connect api-gateway-manage fail ", err)
        return nil
    end

    local session_redis = {}
    local result = json.decode(res.body)
    for i = 1, #result.data do
        local info = result.data[i]
        table.insert(session_redis, { ip = info.redisIp, port = info.redisPort, password = info.redisPasswd })
    end

    return session_redis
end

function _M.get_session_redis_config()
    local session_conf
    if not _M.session_conf then
        session_conf = load_remote_config("session")
        if not session_conf then
            return nil
        end
        _M.session_conf = session_conf
    else
        session_conf = _M.session_conf
    end
    return session_conf
end

function _M.get_data_redis_config()
    local data_conf
    if not _M.data_conf then
        data_conf = load_remote_config("data")
        if not data_conf then
            return nil
        end
        _M.data_conf = data_conf
    else
        data_conf = _M.data_conf
    end
    return data_conf
end

function _M.add_deny_ip(bad_ip)
    local httpc = http.new()
    httpc:set_timeout(2000)
    local request_param = json.encode({ badIp = bad_ip })
    local res, err = httpc:request_uri(server_address .. "/api-gateway-manage/denyIp/addDenyIp", {
        method = "POST",
        body = request_param,
        headers = {
            ["Content-Type"] = "application/json",
        }
    })

    if not res then
        ngx.log(ngx.ERR, "添加黑名单ip失败", err)
    end
end

function _M.get_deny_ip_config()
    local deny_ip_conf
    if not _M.deny_ip_conf then
        local httpc = http.new()
        httpc:set_timeout(2000)
        local res, err = httpc:request_uri(server_address .. "/api-gateway-manage/denyIp/getDenyIpConfig")
        if res == nil or 200 ~= res.status then
            ngx.log(ngx.ERR, "connect api-gateway-manage fail ", err)
            return nil
        end
        local result = json.decode(res.body)
        deny_ip_conf = { unit_time = result.data.unitTime, max_call = result.data.maxCall, deny_time = result.data.denyTime }
        _M.deny_ip_conf = deny_ip_conf
    else
        deny_ip_conf = _M.deny_ip_conf
    end
    return deny_ip_conf
end

return _M

