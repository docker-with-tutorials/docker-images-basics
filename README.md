# Docker Images Basics

Docker images are the foundation of everything that happens in Docker. Every container starts from an image, but many people use images without really understanding what they are.
An image is not just “something you pull and run”. It is a structured, layered, immutable filesystem snapshot that defines how a container should start and behave. It contains the application code, its dependencies, system libraries, metadata, and the default command that will run when a container is created.
If you don’t understand images, containers will feel magical. If you do understand images, Docker becomes predictable.
This repository focuses on building that mental model. The goal is not to memorize commands, but to understand what is happening behind them. Once the concepts are clear, everything else in Docker starts to make sense.


## 📌 Table of Contents

- [Introduction](#introduction)
- [What Is a Docker Image?](#what-is-a-docker-image)
- [Images vs Containers](#images-vs-containers)
- [Image Layers](#image-layers)
- [Tags vs Digests](#tags-vs-digests)
  - [Tags](#tags)
  - [Digests](#digests)
- [Image Immutability](#image-immutability)
- [Build Cache Behavior](#build-cache-behavior)
- [Registry vs Repository](#registry-vs-repository)
  - [Registry](#registry)
  - [Repository](#repository)
- [Inspecting Images](#inspecting-images)
- 
## Introduction

This repository was created to explain what Docker images really are and why they are so important in the container ecosystem.

Many people start using Docker by learning commands and following tutorials, but without understanding images in depth, containers often feel like a black box. You run a command and something works, but the internal logic behind it is not always clear. Since every container is created from an image, understanding images is the key to understanding how Docker behaves.

An image defines the filesystem, the dependencies, the metadata, and the default process that will start when a container is created. It is the blueprint that shapes everything that happens at runtime. If the structure of the image is clear in your mind, concepts like layers, caching, immutability, and even build optimization become much easier to grasp.
The purpose of this repository is to build that mental model step by step, focusing on understanding rather than memorizing commands.


## What Is a Docker Image?

A Docker image is a read-only template used to create containers, but in practice it is more accurate to think of it as a packaged filesystem snapshot that contains everything required for an application to run.

An image typically includes:

- The base operating system layer
- Application source code or binaries
- System libraries and runtime dependencies
- Configuration files
- Metadata about how the container should start
- A default command defined by CMD or ENTRYPOINT

All of this is assembled during the build process and stored as a series of layers. These layers form a complete and self-contained environment that Docker can use to create containers consistently across different machines.

One of the most important properties of a Docker image is immutability. Once an image is built, it does not change. If you modify the Dockerfile and build again, Docker creates a new image rather than altering the existing one. This design ensures reproducibility and makes deployments predictable, since a specific image version will always behave the same way.

## Images vs Containers

Understanding the difference between images and containers is essential to understanding Docker.

An image defines what the environment looks like. It contains the filesystem, dependencies, metadata, and the default process that should start. However, an image does not run by itself. It is a definition, not an execution.

A container is what you get when that definition is executed.

You can think of it like this:

- Image → Blueprint
- Container → Running instance of that blueprint

Or in programming terms:

- Image → Class definition
- Container → Object instance

Multiple containers can be created from the same image, and they will all share the same underlying read-only layers. What makes them independent is the writable layer that Docker adds on top of the image when a container is created.

The structure looks like this:

<img width="1400" height="467" alt="image" src="https://github.com/user-attachments/assets/70480720-e003-426b-87ce-01be4eb3f4ed" />

Any file created, modified, or deleted at runtime exists only in the container’s writable layer. The original image remains unchanged.

When you run:

```bash
docker run nginx
```

Docker performs the following steps:

1. Checks if the image exists locally and pulls it if necessary.
2. Creates a new container from that image.
3. Adds a writable layer on top of the image layers.
4. Starts the main process defined in the image as PID 1.

The image is never modified during this process. Containers are ephemeral runtime instances. Images are immutable definitions.

## Image Layers

Docker images are built in layers. Each instruction in a Dockerfile creates a new layer.

Example:

```dockerfile
FROM ubuntu:22.04
WORKDIR /app
COPY . .
RUN apt-get update && apt-get install -y curl
CMD ["bash"]
```

In this example, each instruction generates a separate read-only layer. Docker does not merge them into a single filesystem during build. Instead, it keeps them as independent layers that are stacked together using a union filesystem.

This layered model provides important properties:

- Layers are immutable once created.
- Layers are cached during builds.
- Layers can be reused across different images.

For example, if two images use the same base image, they share those base layers. Docker does not duplicate them on disk, which makes storage and distribution more efficient.

When a container is created from an image, Docker adds one additional layer on top of all existing image layers. This top layer is writable and belongs exclusively to that container. Any file created or modified at runtime exists only in this writable layer. The image layers remain untouched. They are read-only and shared. The container layer is temporary and isolated.

## Tags vs Digests

Docker images are not referenced only by name. They are identified using either tags or digests, and understanding the difference between them is important for version control and reproducibility.

### Tags

A tag is a human-readable reference attached to an image within a repository.

Examples:

- nginx:latest  
- nginx:1.25  

A tag points to a specific image, but it is mutable. This means it can be reassigned to another image at any time. If someone pushes a new version of `nginx:latest`, the tag will now reference a different image than before.

It is important to understand that `latest` is not a special keyword. It is simply the default tag name used when no tag is specified. It does not guarantee that you are using the newest or safest version.
Tags are convenient for development and versioning, but they do not guarantee immutability.

### Digests

A digest is a content-based identifier generated from the image itself.

Example:

nginx@sha256:abc123...

Unlike tags, a digest is immutable. It is derived from the image’s content hash, which means that if the image changes, the digest also changes. A digest always points to exactly one specific image and can never be reassigned.
If you need strict reproducibility, such as in production environments or CI pipelines, referencing images by digest ensures that you are running the exact same image every time.

## Image Immutability

Docker images are immutable by design. Once an image is built, its layers cannot be modified. If you change anything in the Dockerfile and run the build process again, Docker does not update the existing image. Instead, it creates a new image with a new set of layers.

This behavior is intentional and fundamental to how Docker works. Immutability guarantees that a specific image version will always behave the same way, regardless of where it is executed. If two environments run the same image reference, they are running the exact same filesystem and configuration.
This property provides predictability, reproducibility, and safer deployments. Rather than modifying running environments, the correct workflow is to build a new image and redeploy.
Containers, however, are not immutable. They can change at runtime because they include a writable layer. The image remains unchanged, while the container instance can evolve during execution.

## Build Cache Behavior

Docker uses a layer-based caching mechanism during the build process. When building an image, Docker evaluates each instruction in the Dockerfile in order. If an instruction has already been executed before and its inputs have not changed, Docker reuses the cached layer instead of rebuilding it.

For example:

```dockerfile
COPY package.json .
RUN npm install
COPY . .
```

If you modify only your application source code but do not change package.json, Docker can reuse the cached layer generated by RUN npm install. Since the dependency definition did not change, there is no need to reinstall them. Only the layers after the modified instruction will be rebuilt.

This is why instruction order matters. Stable instructions, such as installing system packages or dependencies, should appear earlier in the Dockerfile. Frequently changing instructions, such as copying application source code, should appear later. Proper ordering improves build performance and makes development workflows significantly faster.

## Registry vs Repository

Registry and repository are not the same thing.

### Registry

A registry is a service that stores Docker images.

Examples:

- Docker Hub
- GitHub Container Registry
- Amazon ECR

### Repository

A repository is a collection of images within a registry.

Example:

```dockerfile
docker.io/library/nginx
```

- docker.io → registry
- library/nginx → repository
- latest → tag

## Inspecting Images

Useful commands:

List images:

```dockerfile
docker images
```

Inspect image metadata:

```dockerfile
docker inspect nginx
```

View layer history:

```dockerfile
docker history nginx
```

Pull a specific version:

```dockerfile
docker pull nginx:1.25
```

Pull using digest:

```dockerfile
docker pull nginx@sha256:...
```
