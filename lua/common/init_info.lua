--
-- User: 周广
-- Date: 2017/7/5
-- Time: 15:15
-- 初始化信息模块用于在nginx worker共享只读数据
--


local _M = {}

local uri_data_arr = {
    "/red-packet/apis/v1/clientRedPacket/query",
    "/red-packet/test3/queryCacheByPhone"
}

function _M.uri_match(uri)
    for _, v in ipairs(uri_data_arr) do
        if v == uri then
            return true
        end
    end
    return false
end

return _M
