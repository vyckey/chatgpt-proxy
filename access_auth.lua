local ngx = require "ngx";
local headers = ngx.req.get_headers(); --获取请求中 header 头的列表.
local secret = headers["AppSecret"];
local password = "PASSWORD";  --定义密钥.
if not secret or secret ~= password then
    ngx.status = ngx.HTTP_FORBIDDEN --返回错误码
    ngx.say("AppSecret authentiation failed.")  --返回错误消息
    ngx.exit(200)
end
