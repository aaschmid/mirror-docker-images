#!/bin/bash
set -euo pipefail

SOURCE_IMAGE="${1:?Source image required}"
TARGET_IMAGE="${2:?Target image required}"

SOURCE_LATEST="${SOURCE_IMAGE}:latest"

echo "Source image: $SOURCE_LATEST"
echo "Target image: $TARGET_IMAGE"

if ! docker buildx imagetools inspect "$SOURCE_LATEST" >/dev/null 2>&1; then
  echo "Error: Image $SOURCE_LATEST not found"
  exit 1
fi

ARCHS=$(docker buildx imagetools inspect "$SOURCE_LATEST" --format '{{range .Manifest.Manifests}}{{.Platform.Architecture}}{{if .Platform.Variant}}/{{.Platform.Variant}}{{end}} {{end}}' 2>/dev/null | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ',' | sed 's/,$//')

if [ -n "$ARCHS" ]; then
  echo "Available architectures: $ARCHS"

  if echo "$ARCHS" | grep -q "arm64"; then
    echo "✓ arm64 architecture found"
  else
    echo "⚠ Warning: arm64 architecture not found for $SOURCE_LATEST"
  fi
else
  echo "Note: Could not determine architectures (may be single-arch image)"
fi

echo "Pulling image for version inspection..."
VERSION=""
if docker pull --platform linux/amd64 "$SOURCE_LATEST" >/dev/null 2>&1; then
  VERSION=$(docker inspect "$SOURCE_LATEST" --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null)

  if [ -z "$VERSION" ] || [ "$VERSION" = "<no value>" ]; then
    VERSION=$(docker inspect "$SOURCE_LATEST" --format '{{index .Config.Labels "version"}}' 2>/dev/null)
  fi

  if [ -z "$VERSION" ] || [ "$VERSION" = "<no value>" ]; then
    VERSION=$(docker inspect "$SOURCE_LATEST" --format '{{index .Config.Labels "VERSION"}}' 2>/dev/null)
  fi

  docker rmi "$SOURCE_LATEST" >/dev/null 2>&1 || true
else
  echo "Warning: Could not pull image for inspection, will use latest tag only"
fi

if [ -z "$VERSION" ] || [ "$VERSION" = "<no value>" ]; then
  echo "⚠ Warning: Could not determine version from image labels"
  echo "Will tag image as 'latest' only"
  VERSION=""
else
  echo "Detected version: $VERSION"
fi

echo "Copying multi-arch manifest from $SOURCE_LATEST to ${TARGET_IMAGE}:latest"
if ! docker buildx imagetools create --tag "${TARGET_IMAGE}:latest" "$SOURCE_LATEST"; then
  echo "✗ Error: Failed to copy image $SOURCE_LATEST"
  exit 1
fi
echo "✓ Successfully mirrored $SOURCE_LATEST -> ${TARGET_IMAGE}:latest"

if [ -n "$VERSION" ]; then
  echo "Tagging with version: ${TARGET_IMAGE}:${VERSION}"
  if docker buildx imagetools create --tag "${TARGET_IMAGE}:${VERSION}" "$SOURCE_LATEST"; then
    echo "✓ Successfully tagged ${TARGET_IMAGE}:${VERSION}"
  else
    echo "⚠ Warning: Failed to tag with version, but latest tag succeeded"
  fi
fi