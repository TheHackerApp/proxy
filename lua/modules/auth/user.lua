local headers = require("headers")
local opentelemetry = require("opentelemetry")
local context = require("opentelemetry.context").new()
local responses = require("responses")
local subrequest = require("subrequest")

local FORWARDED_HEADERS = {
  --common headers
  "user-session",
  --authenticated headers
  "user-id", "user-given-name", "user-family-name", "user-email", "user-is-admin",
  --oauth headers
  "oauth-provider-slug", "oauth-user-id", "oauth-user-email",
}

local _M = {}

---@class auth.user.context
---@field session string
---@field oauth auth.user.oauth?
---@field authenticated auth.user.authenticated?

---@class auth.user.oauth
---@field provider string
---@field id string
---@field email string

---@class auth.user.authenticated
---@field id number
---@field given_name string
---@field family_name string
---@field email string
---@field admin boolean

---Get the oauth details from the request headers
---@param session string
---@param h table<string, string|string[]>
---@return auth.user.oauth|nil
local function get_oauth_details(session, h)
  if session ~= "oauth" then
    return nil
  end

  local provider = headers.get_first(h, "oauth-provider-slug")
  local user_id = headers.get_first(h, "oauth-user-id")

  local current = context.current()
  current:span():set_attributes(
    opentelemetry.attr.string("oauth.id", user_id),
    opentelemetry.attr.string("oauth.provider", provider)
  )

  return {
    provider = provider,
    id = user_id,
    email = headers.get_first(h, "oauth-user-email"),
  }
end

---Get the authenticated user details from the request headers
---@param session string
---@param h table<string, string|string[]>
---@return auth.user.authenticated|nil
local function get_user_details(session, h)
  if session ~= "authenticated" then
    return nil
  end

  local user_id = tonumber(headers.get_first(h, "user-id"))

  local current = context.current()
  current:span():set_attributes(opentelemetry.attr.int("user.id", user_id))

  return {
    id = user_id,
    given_name = headers.get_first(h, "user-given-name"),
    family_name = headers.get_first(h, "user-family-name"),
    email = headers.get_first(h, "user-email"),
    admin = headers.get_first(h, "user-is-admin") == "true",
  }
end

---Resolve the requesting user
---@return auth.user.context, table<string, string>
function _M.context()
  local tctx, span = opentelemetry.span("context::user")
  local token = tctx:attach()

  local args = {
    token = ngx.var.cookie_session,
  }
  local res = subrequest.request("/internal/auth/user", { args = args })
  subrequest.forward_on_failure(res, { exclude_headers = FORWARDED_HEADERS })

  local session = headers.get_first(res.header, "user-session")
  if session == nil then
    span:record_error("missing session header")
    span:finish()
    tctx:detatch()

    ---@diagnostic disable-next-line: return-type-mismatch
    return responses.fatal("missing session header")
  end

  span:set_attributes(opentelemetry.attr.string("session.kind", session))

  local user = {
    session = session,
    oauth = get_oauth_details(session, res.header),
    authenticated = get_user_details(session, res.header),
  }
  local headers_to_forward = headers.get_subset(res.header, FORWARDED_HEADERS)

  span:finish()
  tctx:detach(token)

  return user, headers_to_forward
end

return _M
