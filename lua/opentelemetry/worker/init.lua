local attr = require("opentelemetry.attribute")
local batch_span_processor = require("opentelemetry.trace.batch_span_processor")
local exporter_client = require("opentelemetry.trace.exporter.http_client")
local otlp_exporter = require("opentelemetry.trace.exporter.otlp")
local tracer_provider = require("opentelemetry.trace.tracer_provider")
local resource = require("opentelemetry.resource")

local exporter_url = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT_LUA")
if exporter_url == nil then
  ngx.log(ngx.WARN, "opentelemetry exporter disabled")
  return
end

local client = exporter_client.new(exporter_url, 3)
local exporter = otlp_exporter.new(client)

local span_procesor = batch_span_processor.new(exporter)
local provider = tracer_provider.new(span_procesor, {
  resource = resource.new(
    attr.string("service.name", "nginx")
  ),
})

local global = require("opentelemetry.global")
global.set_tracer_provider(provider)
