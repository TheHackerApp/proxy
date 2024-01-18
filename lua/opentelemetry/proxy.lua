local context = require("opentelemetry.context").new()

local current = context.current()
current:span():finish()
