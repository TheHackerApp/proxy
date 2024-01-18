local opentelemetry = require("opentelemetry")
local tables = require("tables")

local _M = {}

---Make a subrequest with sane defaults tailored to client authentication.
---@param path string
---@param options? ngx.location.capture.options
---@return ngx.location.capture.response
function _M.request(path, options)
  local opts = tables.with_defaults(options, { ctx = ngx.ctx, always_forward_body = true })

  local headers, _ = ngx.req.get_headers()
  local attributes = opentelemetry.request_attributes({
    method = opts.method,
    path = path,
    args = opts.args,
    headers = headers,
    internal = true,
  })

  return opentelemetry.instrument("subrequest", function()
    return ngx.location.capture(path, opts)
  end, attributes, { kind = opentelemetry.KIND_CLIENT })
end

---@class subrequest.forward_on_failure.options
---@field exclude_headers? string[] # the headers to exclude from the response

---Forward a subrequest response to the client if it failed
---@param res ngx.location.capture.response
---@param options? subrequest.forward_on_failure.options
function _M.forward_on_failure(res, options)
  local opts = tables.with_defaults(options, { exclude_headers = nil })

  if res.status >= 200 and res.status < 300 then
    return
  end

  if opts.exclude_headers ~= nil then
    for _, header in ipairs(opts.exclude_headers) do
      res.header[header] = nil
    end
  end

  for name, value in pairs(res.header) do
    ngx.header[name] = value
  end

  ngx.status = res.status
  ngx.print(res.body)
  ngx.exit(ngx.status)
end

return _M
