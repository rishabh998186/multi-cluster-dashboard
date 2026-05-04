#!/usr/bin/env bash
set -euo pipefail

IMAGE="shivmi/multi-cluster-dashboard"
TAG="v1.0.0"

echo "=== Building Docker image ==="
docker build -t "${IMAGE}:latest" -t "${IMAGE}:${TAG}" .

echo ""
echo "=== Build complete! ==="
docker images "${IMAGE}"

echo ""
echo "=== Pushing to Docker Hub ==="
docker push "${IMAGE}:latest"
docker push "${IMAGE}:${TAG}"

echo ""
echo "✅ Published: https://hub.docker.com/r/${IMAGE}"
