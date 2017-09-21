--
-- User: 周广
-- Date: 2017/9/21
-- Time: 15:45
--  接收后端服务的推送配置处理
--

local ngx = ngx
local bottom_dict = ngx.shared.bottom
local json = require("cjson.safe")
local string = string

--不带参数的uri
local document_uri = ngx.var.document_uri


--处理黑名单配置的重推
if string.find(document_uri, "denyIpConf") then
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    if data then
        local result = json.decode(data)

        bottom_dict:set("unit_time", result.unitTime)
        bottom_dict:set("max_call", result.maxCall)
        bottom_dict:set("deny_time", result.denyTime)
        ngx.log(ngx.ERR,
            "装载新配置" ..
                    " 单位时间:" .. result.unitTime ..
                    " 最大访问:" .. result.maxCall ..
                    " 延迟时间:" .. result.denyTime)
    end
end

