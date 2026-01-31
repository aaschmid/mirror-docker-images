# Mirror Docker Images

GitHub Actions workflow that mirrors Docker images from Docker Hub to GitHub Container Registry (GHCR).

## Features

- Multi-architecture support (amd64, arm64, arm/v7, arm/v6)
- Automatic version detection from OCI labels
- Independent builds per image (matrix strategy)
- Syncs are scheduled
