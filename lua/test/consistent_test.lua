--
-- User: 周广
-- Date: 2017/9/13
-- Time: 15:48
-- 
--

local session_cache = require "common.session_cache"
local call_baking=require "authentication/call_backing"


local remote_ip = ngx.var.remote_addr
--不带参数的uri
local document_uri = ngx.var.document_uri

call_baking.save_call_record(document_uri,remote_ip)

ngx.say(session_cache:get("new_test"))





