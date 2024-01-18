local headers = require("headers")
local opentelemetry = require("opentelemetry")
local context = require("opentelemetry.context").new()
local responses = require("responses")
local subrequest = require("subrequest")

local FORWARDED_HEADERS = {
  --common headers
  "request-scope",
  --event headers
  "event-slug", "event-organization-id"
}

local _M = {}

---@class auth.scope.context
---@field scope   string            # the request scope
---@field event   auth.scope.event? # details about the event, only present if the scope is "event"

---@class auth.scope.event
---@field slug            string # the resolved slug for the event
---@field organization_id number # the organization that runs the event

---Get the event's details from the request headers
---@param scope string
---@param h table<string, string|string[]>
---@return auth.scope.event|nil
local function get_event_details(scope, h)
  if scope ~= "event" then
    return nil
  end

  local event = {
    slug = headers.get_first(h, "event-slug"),
    organization_id = tonumber(headers.get_first(h, "event-organization-id")),
  }

  local current = context.current()
  current:span():set_attributes(
    opentelemetry.attr.string("event.slug", event.slug),
    opentelemetry.attr.int("event.organization_id", event.organization_id)
  )

  return event
end

---Resolve the request scope
---@return auth.scope.context, table<string, string>
function _M.context()
  local tctx, span = opentelemetry.span("context::scope")
  local token = tctx:attach()

  local args = {
    slug = ngx.var.http_event_slug,
    domain = ngx.var.http_event_domain,
  }
  local res = subrequest.request("/internal/auth/scope", { args = args })
  subrequest.forward_on_failure(res, { exclude_headers = FORWARDED_HEADERS })

  local scope_type = headers.get_first(res.header, "request-scope")
  if scope_type == nil then
    span:record_error("missing scope header")
    span:finish()
    tctx:detach(token)

    ---@diagnostic disable-next-line: return-type-mismatch
    return responses.fatal("missing scope header")
  end

  span:set_attributes(opentelemetry.attr.string("request.scope", scope_type))

  local scope = { scope = scope_type, event = get_event_details(scope_type, res.header) }
  local headers_to_forward = headers.get_subset(res.header, FORWARDED_HEADERS)

  span:finish()
  tctx:detach(token)

  return scope, headers_to_forward
end

return _M
