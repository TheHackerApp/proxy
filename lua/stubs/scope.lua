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

---@param args table
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
    return responses.error("not found", ngx.HTTP_NOT_FOUND)
  end

  local organization_id = EVENTS[slug]
  if organization_id == nil then
    if args.domain ~= nil then
      return responses.fatal(
        "missing organization id for event `" .. slug
        .. "` from domain `" .. args.domain .. "`"
      )
    else
      return responses.error("not found", ngx.HTTP_NOT_FOUND)
    end
  end

  add_event_headers(slug, organization_id)
end

responses.empty()
