local attr = require("opentelemetry.attribute")
local set = require("set")

local _M = {}

local RESTRICTED_HEADERS = set.new({
  --common headers
  "cookie", "authorization",
  --authenticated session headers
  "user-email", "user-given-name", "user-family-name",
  --oauth session headers
  "oauth-user-email",
})
local RESTRICTED_QUERY_PARAMS = set.new({ "token" })

---Scrub values from request or response headers and add the scrubbed values as OpenTelemetry
---attributes to the `attributes` array
---@param headers table<string, string|string[]>
---@param attributes table[]
function _M.headers(headers, attributes)
  for key, value in pairs(headers) do
    local attr_name = "http.request.header." .. key

    if RESTRICTED_HEADERS:contains(key) then
      table.insert(attributes, attr.string(attr_name, "[REDACTED]"))
    else
      local attr_value

      if type(value) == "table" then
        attr_value = attr.array(attr_name, value)
      else
        attr_value = attr.string(attr_name, value)
      end

      table.insert(attributes, attr_value)
    end
  end
end

---Scrub values from request query parameters and add the scrubbed values as OpenTelemetry
---attributes to the `attributes` array
---@param params table<string, string>|string
---@params attributes table[]
function _M.query_params(params, attributes)
  if type(params) == "string" then
    params = ngx.decode_args(ngx.unescape_uri(params))
  end

  if #params == 0 then
    return
  end

  local query = ""

  for key, value in pairs(params) do
    if RESTRICTED_QUERY_PARAMS:contains(key) then
      query = query .. key .. "=[REDACTED]&"
    else
      query = query .. key .. "=" .. value .. "&"
    end
  end

  table.insert(attributes, attr.string("url.query", query:sub(0, -2)))
end

return _M
