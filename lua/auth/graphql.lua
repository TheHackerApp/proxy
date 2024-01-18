local auth = require("auth")
local opentelemetry = require("opentelemetry")
local responses = require("responses")

opentelemetry.instrument("access", function()
  local ctx = auth.context()

  if ctx.user.session ~= auth.SESSION_AUTHENTICATED then
    return responses.error("forbidden", ngx.HTTP_FORBIDDEN)
  end

  if ctx.scope.scope == auth.SCOPE_ADMIN and not ctx.user.authenticated.admin then
    return responses.error("forbidden", ngx.HTTP_FORBIDDEN)
  end
end)

local tctx, _ = opentelemetry.proxy("proxy")
tctx:attach()
opentelemetry.propagator:inject(tctx, ngx.req)
