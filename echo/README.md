# Echo

A simple [Flask][flask] server that accepts any request and responds with the request data in JSON
format. The response includes the:

- Method
- Path
- Query parameters
- Headers
- Body (attempts to parse as JSON and form data)

The server is also instrumented with [OpenTelemetry][opentelemetry] to allow for tracing of requests
using the [Flask auto-instrumentation][flask-opentelemetry]. Incoming traces are expected to be
propagated using the [W3C Trace Context][w3c-trace-context] format.

[flask]: https://flask.palletsprojects.com
[flask-opentelemetry]: https://github.com/open-telemetry/opentelemetry-python-contrib/tree/main/instrumentation/opentelemetry-instrumentation-flask
[opentelemetry]: https://opentelemetry.io
[w3c-trace-context]: https://www.w3.org/TR/trace-context/
