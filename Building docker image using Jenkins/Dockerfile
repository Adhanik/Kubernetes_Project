
# Create a Dockerfile that sets up a simple web server using Python's built-in HTTP server.

FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 8000

CMD ["python3", "-m", "http.server", "8000"]


