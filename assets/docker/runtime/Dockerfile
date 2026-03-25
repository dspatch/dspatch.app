# ── Stage 1: Build dspatch-router ─────────────────────────────────────
FROM --platform=$BUILDPLATFORM rust:1.87-alpine AS router-builder
RUN apk add --no-cache musl-dev protobuf-dev git
ARG ROUTER_VERSION=main
RUN git clone --depth=1 --branch=${ROUTER_VERSION} \
    https://github.com/dspatch/dspatch.router.git /build
WORKDIR /build
RUN cargo build --release --bin dspatch-router

FROM docker:dind
COPY --from=router-builder /build/target/release/dspatch-router /usr/local/bin/dspatch-router

# System utilities (yq for YAML config parsing)
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    yq \
    openssh-client \
    ca-certificates

# Python 3.12
RUN apk add --no-cache \
    python3 \
    py3-pip \
    python3-dev

# Node.js 22
RUN apk add --no-cache nodejs npm

# UV — fast Python package manager
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# WebSocket support for v2 SDK
RUN pip install --no-cache-dir --break-system-packages websockets

# Bundle entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Disable Python output buffering globally so logs appear in real-time.
# Also set in entrypoint.sh, but this covers any Python process in the container.
ENV PYTHONUNBUFFERED=1

# Working directory for agent code
WORKDIR /workspace

# Health-check label
LABEL com.dspatch.managed="true"

ENTRYPOINT ["/entrypoint.sh"]
