# Dockerfile to create a helper image containing the rke2 binary.
# This allows fetching the CLI help output from a specific version of RKE2
# in a clean, containerized environment.

# Use a lightweight and common base image.
FROM alpine:latest

# Use ARG to allow build-time configuration of the RKE2 version.
# Default to a recent, stable version.
ARG RKE2_VERSION="v1.30.2+rke2r1"

# Allow specifying architecture for cross-building, defaults to amd64.
# On `docker buildx`, this is set automatically.
ARG TARGETARCH=amd64

# Install necessary tools. coreutils provides a standard sha256sum.
RUN apk add --no-cache curl tar gzip coreutils

# Download the RKE2 binary, verify its checksum, and install it.
# This method is more robust than using the install script as it downloads
# assets directly from GitHub releases.
RUN set -ex; \
    FILENAME="rke2.linux-${TARGETARCH}.tar.gz"; \
    # Define URLs based on version and architecture
    URL="https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/${FILENAME}"; \
    SHA_URL="https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/sha256sum-${TARGETARCH}.txt"; \
    \
    # Download binary and its checksum file
    curl -o ${FILENAME} -sfL ${URL}; \
    curl -o checksum.txt -sfL ${SHA_URL}; \
    \
    # Verify the checksum of the downloaded tarball
    echo "Verifying checksum..." >&2; \
    grep "${FILENAME}" checksum.txt | sha256sum -c -; \
    \
    # Extract the tarball and install the binary to a standard location
    tar -xzf ${FILENAME}; \
    install -m 755 bin/rke2 /usr/local/bin/rke2; \
    \
    # Clean up downloaded files and extracted directories
    rm -rf ${FILENAME} checksum.txt bin share

# Set the entrypoint to the rke2 binary. This makes the container executable.
ENTRYPOINT ["/usr/local/bin/rke2"]

# The default command to run when the container starts.
# This provides the server help output needed for the generation script.
CMD ["server", "--help"]
