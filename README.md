# Docker Images Basics

Understanding what a Docker image really is.

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

## Introduction

This repository explains the fundamental concepts behind Docker images.

Before running containers effectively, it is essential to understand how images are structured, stored, and referenced. Containers are created from images — therefore, understanding images means understanding the foundation of Docker.
This repository focuses on clarity and mental models rather than complexity.

## What Is a Docker Image?

A Docker image is a read-only template used to create containers.

It contains:

- A filesystem snapshot
- Application code
- Dependencies
- Metadata
- A default command (CMD or ENTRYPOINT)

Images are immutable. Once built, they do not change. Any modification results in a new image layer.

## Images vs Containers

An image is a blueprint.

A container is a running instance of that blueprint.

You can create multiple containers from the same image.  
Each container has its own writable layer, but the underlying image remains unchanged.

Think of it like this:

- Image → Class definition
- Container → Object instance

Or:

- Image → Snapshot
- Container → Running process with isolated filesystem

When you run:

```Dockerfile
docker run nginx
```

Docker performs the following steps:

1. Pulls the image (if not available locally)
2. Creates a new container from the image
3. Adds a writable layer on top
3. Starts the main process (PID 1)

The image never changes.
Only the container’s writable layer changes.

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

Each of these instructions creates a separate read-only layer.

Layers are:

- Immutable
- Cached
- Reused across images when possible

Docker uses a union filesystem to stack these layers on top of each other.

When a container is created, Docker adds a writable layer on top of the image layers. All runtime changes happen there.

## Tags vs Digests

Images are referenced using:

- Tags
- Digests

### Tags

A tag is a mutable reference.

Example:

nginx:latest
nginx:1.25

Tags can be moved to point to a different image.
latest is not special. It is just a tag.

### Digests

A digest is an immutable reference.

Example:

nginx@sha256:abc123...

A digest points to a specific image content hash. It cannot change. If you need reproducibility, use digests.

## Image Immutability

Docker images are immutable.
Once an image is built, it cannot be modified.
If you change anything in a Dockerfile and rebuild, Docker creates a new image.

This guarantees:

- Predictability
- Reproducibility
- Safe deployments

Containers may change at runtime.
Images do not.

## Build Cache Behavior

Docker caches layers during build.
If a layer has not changed, Docker reuses it.

Example:

```dockerfile
COPY package.json .
RUN npm install
COPY . .
```

If only application code changes but package.json does not, Docker reuses the npm install layer.

Layer ordering matters.
Place stable instructions first. Place frequently changing instructions later. This reduces build time.

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
