# ============================================================
#  Multi-Cluster Kubernetes Dashboard — Docker Image
#  Multi-stage build: compile with CGO (sqlite) → slim runtime
# ============================================================

# ---- Stage 1: Build ----
FROM golang:1.21-bookworm AS builder

WORKDIR /build

# Cache dependency downloads
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build with CGO enabled (required for go-sqlite3)
RUN CGO_ENABLED=1 GOOS=linux go build -o /build/dashboard -ldflags="-s -w" ./cmd/server/

# ---- Stage 2: Runtime ----
FROM debian:bookworm-slim

# Install runtime deps: ca-certs, curl (healthcheck), kubectl (metrics-server auto-install)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled binary
COPY --from=builder /build/dashboard .

# Copy templates and static assets
COPY --from=builder /build/templates/ ./templates/
COPY --from=builder /build/static/ ./static/

# Create default directories
RUN mkdir -p /app/data /app/k8s-configs

# Copy default cluster config (users can override via volume mount)
COPY --from=builder /build/k8s-configs/clusters.yaml ./k8s-configs/clusters.yaml

# Environment defaults
ENV PORT=8080 \
    GIN_MODE=release \
    CLUSTER_CONFIG=/app/k8s-configs/clusters.yaml \
    DB_PATH=/app/data/metrics.db

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["./dashboard"]
