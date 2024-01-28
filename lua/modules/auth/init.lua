local scope = require("auth.scope")
local user = require("auth.user")
local headers = require("headers")
local opentelemetry = require("opentelemetry")
local subrequest = require("subrequest")

local FORWARDED_HEADERS = {
  --common headers
  "request-scope", "user-session",
  --event headers
  "event-slug", "event-organization-id",
  --authenticated headers
  "user-id", "user-given-name", "user-family-name", "user-email", "user-is-admin",
  --oauth headers
  "oauth-provider-slug", "oauth-user-id", "oauth-user-email",
}

local _M = {
  SCOPE_ADMIN = "admin",
  SCOPE_USER = "user",
  SCOPE_EVENT = "event",
  SESSION_AUTHENTICATED = "authenticated",
  SESSION_OAUTH = "oauth",
  SESSION_REGISTRATION_NEEDED = "registration-needed",
  SESSION_UNAUTHENTICATED = "unauthenticated",
}

---@class auth.context
---@field scope auth.scope.context
---@field user auth.user.context

---Retrieve the access context for the request
---@return auth.context
function _M.context()
  local tctx, span = opentelemetry.span("context")
  local token = tctx:attach()

  local args = {
    token = ngx.var.cookie_session, -- TODO: change to dedicated header
    slug = ngx.var.http_event_slug,
    domain = ngx.var.http_event_domain,
  }
  local res = subrequest.request("/internal/auth", { args = args })
  subrequest.forward_on_failure(res, { exclude_headers = FORWARDED_HEADERS })

  local scope_ctx = scope.context(res.header)
  local user_ctx = user.context(res.header)

  local forwarded_headers = headers.get_subset(res.header, FORWARDED_HEADERS)
  headers.add_to_request(forwarded_headers)

  span:finish()
  tctx:detach(token)

  return {
    scope = scope_ctx,
    user = user_ctx,
  }
end

return _M
