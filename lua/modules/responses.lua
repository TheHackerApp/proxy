local json = require("cjson")

local _M = {}

---Encode the message as JSON
---@param message string
---@return string
local function format_message(message)
  return json.encode({ message = message })
end

---Send an empty successful response
---@param code? integer
function _M.empty(code)
  ngx.status = code or ngx.HTTP_NO_CONTENT
  ngx.exit(ngx.status)
end

---Send a non-fatal error message
---@param message string
---@param code? integer
function _M.error(message, code)
  ngx.status = code or ngx.HTTP_BAD_REQUEST
  ngx.header["Content-Type"] = "application/json"
  ngx.say(format_message(message))
  ngx.exit(ngx.status)
end

---Send a fatal error message
---@param message string
function _M.fatal(message)
  ngx.log(ngx.ERR, message)
  _M.error(message, ngx.HTTP_INTERNAL_SERVER_ERROR)
end

return _M
