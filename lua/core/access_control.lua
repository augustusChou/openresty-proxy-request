--
-- User: 周广
-- Date: 2017/9/15
-- Time: 9:17
--   IP 准入、接口权限等情况集中处理
--

local ngx = ngx
local ip_filter = require "authentication/ip_filter"
local request_headers_filter = require "authentication/request_headers_filter"
local call_baking = require "authentication/call_backing"

local remote_ip = ngx.var.remote_addr
local headers = ngx.req.get_headers()
--不带参数的uri
local document_uri = ngx.var.document_uri



--检查ip合法性
if ip_filter.ip_validity_is_deny(remote_ip) then
    ngx.log(ngx.ERR, "非法ip访问:" .. remote_ip)
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

--检查请求头合法性
if  request_headers_filter.headers_check_fail(headers) then
    ngx.log(ngx.ERR, "头部检查失败非法头部信息 ip:" .. remote_ip)
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

ngx.log(ngx.ERR, "远程ip:" .. remote_ip .. " 接口地址:" .. document_uri)
call_baking.save_call_record(document_uri, remote_ip)