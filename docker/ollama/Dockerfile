# Use the official Ollama image as the base
FROM ollama/ollama:latest

# Install curl and other necessary tools
USER root
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Switch back to the non-root user
USER 1000:1000

# Use the default command from the base image
ENTRYPOINT ["/bin/ollama"]
CMD ["serve"]
