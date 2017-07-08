--
-- User: 周广
-- Date: 2017/7/7
-- Time: 22:51
-- 
--
local redis_i = require "resty/redis_iresty"
local redis = redis_i:new()
local bottom_dict = ngx.shared.bottom
local _M = {}


--获取数据在缓存的key
--request_uri: 请求uri 带参数
--document_uri 不带参数版uri
--request_method 请求方式 ngx.HTTP_GET 这种
--request_body 请求body
local function get_data_key(request_uri, document_uri, request_method, request_body)
    if request_method == ngx.HTTP_GET then
        return ngx.md5(request_uri)
    elseif request_method == ngx.HTTP_POST then
        if not request_body then
            return ngx.md5(request_uri)
        else
            return ngx.md5(request_uri .. request_body)
        end
    end
end

--尝试更新托底数据，通过worker间共享的shared.dict如果已经存在
function _M.try_update_bottom_data(request_uri, document_uri, request_method, request_body, response_body)
    local key = get_data_key(request_uri, document_uri, request_method, request_body)

    if not bottom_dict:get(key) then
        --设置key5分钟后过期，代表5分钟更新一次托底数据，value只是占位
        bottom_dict:set(key, "data", 300)
        redis:hset("BOTTOM_DATA", key, response_body)
    end
end

--尝试获取托底数据
function _M.try_get_bottom_data(request_uri, document_uri, request_method, request_body)
    local key = get_data_key(request_uri, document_uri, request_method, request_body)
    return redis:hget("BOTTOM_DATA", key)
end

--递增服务器超时次数，并返回更新后的次数
function _M.incr_server_timeout_num(document_uri)
    local key = "SERVER_TIMEOUT_INCR_" .. ngx.md5(document_uri)
    local ok, err = bottom_dict:add(key, 0)
    ngx.log(ngx.ERR, "尝试设置托底", ok, err)
    if not ok then
        ok, err = bottom_dict:incr(key, 1)
        ngx.log(ngx.ERR, "尝试递增", ok, err)
        return ok
    else
        bottom_dict:incr(key, 1, 1)
        return 1
    end
end

--设置不健康uri，超时时间为60秒
function _M.set_unhealtht(document_uri)
    local key = "UNHEALTHT_" .. ngx.md5(document_uri)
    bottom_dict:set(key, "timeout", 60)
end

--检查document_uri健康程度
function _M.check_document_uri_healtht(document_uri)
    local key = "UNHEALTHT_" .. ngx.md5(document_uri)
    local ok, _ = bottom_dict:get(key)
    if ok then
        return true
    end
    return false
end


return _M