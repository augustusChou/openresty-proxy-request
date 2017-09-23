--
-- User: 周广
-- Date: 2017/9/22
-- Time: 10:45
-- 动态的负载均衡
--

local ngx = ngx
local table = table
local bottom_dict = ngx.shared.bottom
local balancer = require "ngx.balancer"
local json = require("cjson.safe")
local string = string
local math = math

--获取接口项目上下文
local function get_interface_path()
    local document_uri = ngx.var.document_uri
    local start = string.find(document_uri, "/", 2)
    return string.sub(document_uri, 1, start - 1)
end


local balancer_conf = bottom_dict:get("balancer_conf")
if not balancer_conf then
    ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

local interface_path = get_interface_path()


--在这里将字符串解析为json对象
local balancer_conf_json = json.decode(balancer_conf).data
local conf = balancer_conf_json[interface_path]
if conf then

    local tmpBalancer = {}
    local start_index = 0
    local max_index = 0
    for i = 1, #conf do
        if conf[i].weight > 0 then
            table.insert(tmpBalancer, {
                conf_index = i,
                start_scope = start_index + 1,
                end_scope = start_index + conf[i].weight
            })
            start_index = conf[i].weight
            max_index = max_index + conf[i].weight
        end
    end

    local r = math.random(1, max_index)


    for i = 1, #tmpBalancer do
        if tmpBalancer[i].start_scope <= r and tmpBalancer[i].end_scope >= r then
            local choose_conf = conf[tmpBalancer[i].conf_index]

            local ok, err = balancer.set_current_peer(choose_conf.serverIp, choose_conf.serverPort)
            if not ok then
                ngx.log(ngx.ERR, "设置负载服务器失败: ", err)
                return ngx.exit(500)
            end
            return
        end
    end
end

