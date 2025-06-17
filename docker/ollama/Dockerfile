# Use the official Ollama image as the base
FROM ollama/ollama:latest

# Install curl and other necessary tools
USER root
RUN apt-get update && \
    apt-get install -y curl && \
    # Install curl in a location accessible to the non-root user
    cp /usr/bin/curl /usr/local/bin/ && \
    chmod +x /usr/local/bin/curl && \
    rm -rf /var/lib/apt/lists/*

# Create the .ollama directory and set the correct permissions
RUN mkdir -p /.ollama && \
    chown -R 1000:1000 /.ollama && \
    chmod -R 700 /.ollama

# Create a simple health check script
RUN echo '#!/bin/sh\n/usr/local/bin/curl -f http://localhost:11434/api/tags || exit 1' > /healthcheck.sh && \
    chmod +x /healthcheck.sh

# Set the OLLAMA_MODELS environment variable to a writable directory
ENV OLLAMA_MODELS=/.ollama/models

# Create the models directory with the correct permissions
RUN mkdir -p /.ollama/models && \
    chown -R 1000:1000 /.ollama/models

# Switch to the non-root user
USER 1000:1000

# Use the default command from the base image
ENTRYPOINT ["/bin/ollama"]
CMD ["serve"]
