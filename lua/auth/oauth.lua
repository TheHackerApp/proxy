local opentelemetry = require("opentelemetry")

-- No additional authn/authz is done here as it is all handled by the upstream identity service

local tctx, _ = opentelemetry.proxy("proxy")
tctx:attach()
opentelemetry.propagator:inject(tctx, ngx.req)
