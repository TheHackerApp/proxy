import platform
from functools import partial

from flask import Flask, request
from opentelemetry import propagate, trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.resources import (
    HOST_NAME,
    SERVICE_VERSION,
    ProcessResourceDetector,
    Resource,
)
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

provider = TracerProvider(
    resource=Resource.create(
        {SERVICE_VERSION: "0.1.0", HOST_NAME: platform.node()}
    ).merge(ProcessResourceDetector().detect())
)
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))

propagate.set_global_textmap(TraceContextTextMapPropagator())
trace.set_tracer_provider(provider)

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
route = partial(
    app.route,
    methods=["HEAD", "GET", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"],
)


@route("/", defaults={"path": "/"})
@route("/<path:path>")
def echo(path: str):
    info = {
        "method": request.method,
        "path": path,
        "args": dict(request.args),
        "headers": dict(request.headers),
    }

    if (json := request.get_json(silent=True)) is not None:
        info["json"] = json
    elif len(request.form) != 0:
        info["form"] = dict(request.form)
    elif len(request.data) != 0:
        info["raw"] = request.data.decode("utf-8")

    return info


if __name__ == "__main__":
    app.run()
