local global = require("opentelemetry.global")

local provider = global.get_tracer_provider()
provider:shutdown()
