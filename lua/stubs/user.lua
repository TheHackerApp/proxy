local responses = require("responses")

local SESSIONS = {
  admin = {
    kind = "authenticated",
    id = "1",
    given_name = "Alex",
    family_name = "Krantz",
    email = "alex@krantz.dev",
    admin = true,
  },
  user = {
    kind = "authenticated",
    id = "2",
    given_name = "James",
    family_name = "Smith",
    email = "james.smith@gmail.com",
    admin = false,
  },
  registering = { kind = "registration-needed" },
  authenticating = {
    kind = "oauth",
    provider = "google",
    id = "123456789",
    email = "test@user.com",
  },
}

local args, err = ngx.req.get_uri_args()
if err == "truncated" then
  return responses.error("bad request", ngx.HTTP_BAD_REQUEST)
end

local session = SESSIONS[args.token]
if session == nil then
  return responses.error("invalid token", ngx.HTTP_UNAUTHORIZED)
end

if session.kind == "unauthenticated" then
  ngx.header["user-session"] = "unauthenticated"
elseif session.kind == "registration-needed" then
  ngx.header["user-session"] = "registration-needed"
elseif session.kind == "oauth" then
  ngx.header["user-session"] = "oauth"
  ngx.header["oauth-provider-slug"] = session.provider
  ngx.header["oauth-user-id"] = session.id
  ngx.header["oauth-user-email"] = session.email
elseif session.kind == "authenticated" then
  ngx.header["user-session"] = "authenticated"
  ngx.header["user-id"] = session.id
  ngx.header["user-given-name"] = session.given_name
  ngx.header["user-Family-name"] = session.family_name
  ngx.header["user-email"] = session.email
  ngx.header["user-is-admin"] = tostring(session.admin)
else
  return responses.fatal("invalid session configuration for token: " .. args.token)
end

responses.empty()
