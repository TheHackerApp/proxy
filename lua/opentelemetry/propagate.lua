local opentelemetry = require("opentelemetry")
local context = require("opentelemetry.context").new()

local current = context.current()
opentelemetry.propagator:inject(current, ngx.req)
