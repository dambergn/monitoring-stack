from opentelemetry import trace
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor

# Configure the tracer
tracer = trace.get_tracer(__name__)

# Instrument the requests library
RequestsInstrumentor().instrument(tracer)

# Instrument the logging library
LoggingInstrumentor().instrument(tracer)

import requests

def main():
    response = requests.get('https://www.example.com')
    print(response.text)

if __name__ == "__main__":
    main()