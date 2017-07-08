--
-- User: 周广
-- Date: 2017/7/7
-- Time: 19:38
-- 
--

local _M = {}

function _M.get_request_method(request_method_str)
    if request_method_str == "POST" then
        return ngx.HTTP_POST
    elseif request_method_str == "GET" then
        return ngx.HTTP_GET
    end
end

return _M
