--
-- User: 周广
-- Date: 2017/9/13
-- Time: 15:48
-- 
--
local math = math
local json = require("cjson")

local function get_interface_path()
    local document_uri = "/red-packet/test3/queryCacheByPhone"
    local start = string.find(document_uri, "/", 2)
    return string.sub(document_uri, 1, start - 1)
end


local balancer_conf_json = json.decode([[{
        "/red-packet": [
            {
                "serverId": 3,
                "serverIp": "192.168.198.164",
                "serverPort": 6678,
                "weight": 50,
                "interfacePath": "/red-packet",
                "createTime": 1506078671000
            },
            {
                "serverId": 4,
                "serverIp": "192.168.199.22",
                "serverPort": 6678,
                "weight": 50,
                "interfacePath": "/red-packet",
                "createTime": 1506064407000
            }
        ]
    }]])
local conf = balancer_conf_json[get_interface_path()]
if conf then

    ngx.log(ngx.ERR, "读取到匹配负载均衡:" .. conf)
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
            print("选中的ip:" .. choose_conf.serverIp)
            return
        end
    end
end
