local scope = require("auth.scope")
local user = require("auth.user")
local headers = require("headers")

local _M = {
  SCOPE_ADMIN = "admin",
  SCOPE_USER = "user",
  SCOPE_EVENT = "event",
  SESSION_AUTHENTICATED = "authenticated",
  SESSION_OAUTH = "oauth",
  SESSION_REGISTRATION_NEEDED = "registration-needed",
  SESSION_UNAUTHENTICATED = "unauthenticated",
  scope = scope,
  user = user,
}

---@class auth.context
---@field scope auth.scope.context
---@field user auth.user.context

---Retrieve the access context for the request
---@return auth.context
function _M.context()
  local scope_ctx, scope_headers = scope.context()
  headers.add_to_request(scope_headers)

  local user_ctx, user_headers = user.context()
  headers.add_to_request(user_headers)

  return {
    scope = scope_ctx,
    user = user_ctx,
  }
end

return _M
