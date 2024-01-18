local attr = require("opentelemetry.attribute")
local context = require("opentelemetry.context").new()
local opentelemetry = require("opentelemetry.global")
-- luacheck: push no max line length
local trace_context_propagator = require("opentelemetry.trace.propagation.text_map.trace_context_propagator")
-- luacheck: pop
local span_context = require("opentelemetry.trace.span_context")
local span_kind = require("opentelemetry.trace.span_kind")
local span_status = require("opentelemetry.trace.span_status")
local tables = require("tables")

local scrub = require("opentelemetry.scrub")

local _M = {
  KIND_INTERNAL = span_kind.internal,
  KIND_SERVER = span_kind.server,
  KIND_CLIENT = span_kind.client,
  STATUS_OK = span_status.OK,
  STATUS_ERROR = span_status.ERROR,
  attr = attr,
  propagator = trace_context_propagator.new(),
  scrub = scrub,
  tracer = opentelemetry.tracer("lua")
}

local HTTP_METHODS = {
  [ngx.HTTP_GET] = "GET",
  [ngx.HTTP_HEAD] = "HEAD",
  [ngx.HTTP_POST] = "POST",
  [ngx.HTTP_PUT] = "PUT",
  [ngx.HTTP_DELETE] = "DELETE",
  [ngx.HTTP_OPTIONS] = "OPTIONS",
  __index = function()
    return "UNKNOWN"
  end,
}

---Get the context to use for a span
---@param provided? table
---@return table
local function current_context_or_default(provided)
  if provided ~= nil then
    return provided
  end

  local current = context.current()
  if current == nil then
    current = context.new()
  end
  if current:span_context():is_valid() then
    return current
  end

  local span_ctx = span_context.new(ngx.var.otel_trace_id, ngx.var.otel_span_id, 1, false)
  return current:with_span_context(span_ctx)
end

---@alias opentelemetry.span.kind
---| `opentelemetry.KIND_INTERNAL`
---| `opentelemetry.KIND_SERVER`
---| `opentelemetry.KIND_CLIENT`

---@class opentelemetry.span.options
---@field kind? opentelemetry.span.kind
---@field ctx? table

---Create a new OpenTelemetry span
---@param name string
---@param attrs? table[]
---@param config? opentelemetry.span.options
---@return table
---@return table
function _M.span(name, attrs, config)
  config = tables.with_defaults(config, { kind = _M.KIND_INTERNAL, ctx = nil })

  local ctx, span = _M.tracer:start(current_context_or_default(config.ctx), name, {
    kind = config.kind,
    attributes = attrs,
  })
  return ctx, span
end

---Create a new OpenTelemetry span and finish it when the function returns
---@param name string
---@param fn function
---@param attrs? table[]
---@param config? opentelemetry.span.options
---@return unknown
function _M.instrument(name, fn, attrs, config)
  local tctx, span = _M.span(name, attrs, config)
  local token = tctx:attach()

  local result = fn()

  span:finish()
  tctx:detach(token)

  return result
end

---@class opentelemetry.request.options
---@field path string
---@field args? table<string, string>|string
---@field method? ngx.http.method|string
---@field headers? table<string, string|string[]>
---@field internal? boolean

---Get span attributes for a subrequest
---@param config opentelemetry.request.options
---@return table[]
function _M.request_attributes(config)
  config = tables.with_defaults(config, {
    args = {},
    method = ngx.HTTP_GET,
    headers = {},
    internal = false,
  })

  if type(config.method) == "number" then
    config.method = HTTP_METHODS[config.method]
  end

  local attributes = {
    attr.string("http.request.method", config.method),
    attr.string("url.path", config.path),
  }

  if config.internal then
    table.insert(attributes, attr.string("network.protocol.name", "nginx"))
    table.insert(attributes, attr.string("network.protocol.version", ngx.var.nginx_version))
    table.insert(attributes, attr.string("network.transport", "ipc"))
  else
    table.insert(attributes, attr.string("network.protocol.name", "http"))
    table.insert(attributes, attr.string("network.protocol.version", "1.1"))
    table.insert(attributes, attr.string("network.transport", "tcp"))
  end

  scrub.query_params(config.args, attributes)
  scrub.headers(config.headers, attributes)

  return attributes
end

---Set up a span to be used for a location containing a proxy_pass directive
---@param name string
---@param config? opentelemetry.span.options
---@return table
---@return table
function _M.proxy(name, config)
  local args, _ = ngx.req.get_uri_args()
  local headers, _ = ngx.req.get_headers()

  local attributes = _M.request_attributes({
    path = ngx.var.uri,
    args = args,
    method = ngx.req.get_method(),
    headers = headers,
  })

  return _M.span(name, attributes, config)
end

return _M
