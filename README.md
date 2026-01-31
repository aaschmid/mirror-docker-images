# Mirror Docker Images

Container images mirrored from Docker Hub to GitHub Container Registry using Dependabot for automated version updates.

## Architecture

```
.github/
  workflows/
    build-images.yaml    ← Builds Dockerfiles on push (dynamic discovery)
  dependabot.yml         ← Checks Docker Hub weekly for updates (wildcard)
images/
  $IMAGE_NAME/
    Dockerfile           ← FROM $IMAGE_SOURCE_NAME:$IMAGE_VERSION
```

## Adding New Images

Simply create a directory with a Dockerfile:

```bash
mkdir -p images/$IMAGE_NAME
echo "FROM $IMAGE_NAME:$IMAGE_VERSION" > images/$IMAGE_NAME/Dockerfile
```

That's it! The workflow automatically discovers and builds all images. No configuration changes needed.

## How It Works

1. **Dependabot** checks Docker Hub weekly for updates of all `images/*` (using wildcard monitoring)
2. When new version available, it creates a PR updating `FROM` instruction
3. On merge, dynamic discovery in workflow `build-images.yaml` searches `images/` for subdirectories
4. Multi-arch Docker `buildx` builds images for all platforms
6. Images are pushed to GHCR with both `latest` and version tags

## Features

- ✅ Zero-configuration image addition
- ✅ Dynamic matrix discovery (no manual updates)
- ✅ Dependabot wildcard monitoring
- ✅ Multi-architecture support (amd64, arm64, arm/v7)
- ✅ Version pinning via Dockerfiles
- ✅ Manual approval for Dependabot PRs

## Usage

Pull images from GHCR, either latest or specific version:
```bash
docker pull ghcr.io/aaschmid/$IMAGE_NAME:latest
docker pull ghcr.io/aaschmid/$IMAGE_NAME:$IMAGE_VERSION
```
