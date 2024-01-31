local headers = require("headers")
local opentelemetry = require("opentelemetry")
local context = require("opentelemetry.context").new()
local responses = require("responses")

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
---@field role string|nil
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
    role = headers.get_first(h, "user-role"),
    admin = headers.get_first(h, "user-is-admin") == "true",
  }
end

---Resolve the requesting user
---@param h table<string, string|string[]>
---@return auth.user.context
function _M.context(h)
  local span = context:current():span()

  local session = headers.get_first(h, "user-session")
  if session == nil then
    span:record_error("missing session header")
    span:finish()

    ---@diagnostic disable-next-line: return-type-mismatch
    return responses.fatal("missing session header")
  end

  span:set_attributes(opentelemetry.attr.string("session.kind", session))

  return {
    session = session,
    oauth = get_oauth_details(session, h),
    authenticated = get_user_details(session, h),
  }
end

return _M
