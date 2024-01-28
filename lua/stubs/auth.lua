local responses = require("responses")

local EVENTS = {
  testing = 2,
  wafflehacks = 1,
  ["wafflehacks-2020"] = 1,
}
local CUSTOM_DOMAINS = {
  ["testing.example"] = "testing",
  ["wafflehacks.org"] = "wafflehacks",
  ["2020.wafflehacks.org"] = "wafflehacks-2020",
}
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

--@param args table
---@return string
local function determine_scope(args)
  local domain = args.domain
  if domain == nil then
    return "event"
  end

  if
      domain == "manage.thehacker.int"
      or domain == "account.thehacker.int"
      or domain == "register.thehacker.int"
  then
    return "user"
  elseif domain == "admin.thehacker.int" then
    return "admin"
  else
    return "event"
  end
end

---@param args table<string, string>
---@return string|nil
local function get_event_slug(args)
  if args.slug ~= nil then
    return args.slug
  elseif args.domain ~= nil then
    local hosted = args.domain:match("^([%l%d-]+)%.myhacker%.int$")
    if hosted ~= nil then
      return hosted
    end

    return CUSTOM_DOMAINS[args.domain]
  else
    return nil
  end
end

local function add_scope_type(type)
  ngx.header["request-scope"] = type
end

local function add_event_headers(slug, organization_id)
  ngx.header["event-slug"] = slug
  ngx.header["event-organization-id"] = tostring(organization_id)
end

local args, err = ngx.req.get_uri_args()
if err == "truncated" then
  return responses.error("bad request", ngx.HTTP_BAD_REQUEST)
end

local scope = determine_scope(args)
add_scope_type(scope)

if scope == "event" then
  local slug = get_event_slug(args)
  if slug == nil then
    return responses.error("unknown event", 422)
  end

  local organization_id = EVENTS[slug]
  if organization_id == nil then
    if args.domain ~= nil then
      return responses.fatal(
        "missing organization id for event `" .. slug
        .. "` from domain `" .. args.domain .. "`"
      )
    else
      return responses.error("unknown event", 422)
    end
  end

  add_event_headers(slug, organization_id)
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
