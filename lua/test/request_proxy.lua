--
-- User: 周广
-- Date: 2017/7/7
-- Time: 14:01
-- 
--

local method_util = require "common/request_method_util"
local init_info = require "common/init_info"
local bottom = require "common/bottom_data"

local request_uri = ngx.var.request_uri
--不带参数的uri
local document_uri = ngx.var.document_uri
local method = method_util.get_request_method(ngx.var.request_method)



--使用document_uri进行匹配是因为get请求uri会带参数
local match = init_info.uri_match(document_uri)

if match then
    --检查服务document_uri健康
    local ok = bottom.check_document_uri_healtht(document_uri)

    if ok then
        --服务异常，尝试获取托底数据
        local ok, _ = bottom.try_get_bottom_data(request_uri, document_uri, method, req_body)
        if ok then
            ngx.say(ok)
            ngx.exit(ngx.HTTP_OK)
        else
            --获取不到托底数据返回504
            ngx.exit(ngx.HTTP_GATEWAY_TIMEOUT)
        end
    end
end


--子查询代理完成请求
ngx.req.read_body()
local res = ngx.location.capture('/backend' .. request_uri, {
    method = method,
    always_forward_body = true
})

local status_code = res.status
--如果服务器状态为不可用，就递增其失败次数，如果达到3次就加入不健康服务列表。直接走托底数据
if 504 == status_code then
    local ok, _ = bottom.incr_server_timeout_num(document_uri)
    if ok then
        if tonumber(ok) >= 3 then
            bottom.set_unhealtht(document_uri)
        end
    end
end



if not match then
    --如果不是预设的uri 就发送响应结束请求
    ngx.say(res.body)
else
    local req_body = ngx.req.get_body_data
    --以状态码小于400作为成功的标记，如果成功就返回响应并尝试更新托底数据
    if tonumber(status_code) < 400 then
        ngx.say(res.body)
        ngx.eof()
        --尝试更新托底数据
        bottom.try_update_bottom_data(request_uri, document_uri, method, req_body, res.body)
    else
        --服务异常，尝试获取托底数据
        local ok, _ = bottom.try_get_bottom_data(request_uri, document_uri, method, req_body)
        if ok then
            ngx.say(ok)
        else
            ngx.say(res.body)
        end
    end
end

