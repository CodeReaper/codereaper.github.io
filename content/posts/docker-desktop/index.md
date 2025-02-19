---
title: Docker desktop
date: 2025-01-26T00:00:00+02:00
draft: false
---

Once upon a time something happened to [Docker](https://www.docker.com), the CLI tool for managing images and containers on your machine. Docker had begun changing and with change by change over time had become something different at least for those on Windows and macOS.

The most evident changes being:

- A license is required for certain use cases
- The installation now includes a desktop application

Seemingly innocent enough changes - _but read on_ - however they do introduce annoyances in the form of:

- Constant updates
- Being logged out every time you update
- Needing to have an actual application running

Having been annoyed for long enough I wanted to investigate what my alternatives on macOS were and find an alternative.

## Podman Desktop

Everywhere you look for alternatives to Docker you find people mentioning [Podman](https://podman.io) as a free drop-in replacement for Docker.

These are people who do not understand the meaning of [drop-in replacement](https://en.wikipedia.org/wiki/Drop-in_replacement). I am not saying Podman is not more secure or faster or does not have more or better features. I am saying you cannot install Podman and alias `podman` to `docker` and have everything *just work*.

Pros:
- No required license
- No user login

Cons:
- Same constant updates
- Still need to have an actual application running
- New pitfalls with incorrect setup

Should you want to try it out for yourself there is an excellent [in-depth Podman comparison](https://betterstack.com/community/guides/scaling-docker/podman-vs-docker/).

## Rancher Desktop

Spend a little more time searching and you will find [Rancher Desktop](https://rancherdesktop.io) which is a "replacement" for Docker Desktop. You will need to configure certain things about the container runtime which can seem daunting unless you already know way too much about what is under the hood in the world of containers.

Pros:
- No required license
- No user login

Cons:
- Same constant updates
- Still need to have an actual application running
- New pitfalls with incorrect setup

## Docker

Instead of Docker Desktop you can simply use `docker` - as in the same way that docker is used on Linux.

Pros:
- No required license[¹](#license-caveat)
- No user login
- No update nagging
- Runs as a daemon

Cons:
- More complex installation

### Installation Guide

Let us install `docker` via Homebrew - see [brew.sh](https://brew.sh) for setting up `brew`.

**1** - Install docker CLI, its plugins and a virtual machine

```sh
brew install docker \
  docker-compose \
  docker-buildx \
  docker-credential-helper \
  colima
```

**2** - Configure docker plugins and virtual machine

```sh
sed 's/^X//' > ~/.docker/config.json << '44efc9cfeb966'
X{
X  "auths": {},
X  "credsStore": "osxkeychain",
X  "currentContext": "colima",
X  "cliPluginsExtraDirs": [
X    "/opt/homebrew/lib/docker/cli-plugins"
X  ]
X}
44efc9cfeb966
```

*Note* that `osxkeychain` is only for macOS - but there are other [available options](https://github.com/docker/docker-credential-helpers#available-programs).

**3** - Configure virtual machine resource usage

```sh
colima start --cpu 1 --memory 2 --disk 40
```

#FIXME: more here

**4** - Set up virtual machine daemon

```sh
brew services start colima
```

**5** - Install kubernetes tooling (Optional)

```sh
brew install kind helm kubectl
```

```sh
kind create cluster
```

#### Updating tho
#FIXME:

### CLI How To

For those needing a little help to get comfortable using the `docker` CLI there are "How To"s for a few common tasks that were usually done in the Docker Desktop application.

#### Listing running containers

```sh
% docker ps
CONTAINER ID   IMAGE               COMMAND                  CREATED      STATUS      PORTS                      NAMES
90217dfd7c27   hugomods/hugo:git   "docker-entrypoint.s…"   7 days ago   Up 7 days   127.0.0.1:1313->1313/tcp   codereapergithubio-render-run-d1f5fc2bea43
```

#### Checking resource usage of containers

```sh
% docker container stats --no-stream -a
CONTAINER ID   NAME                                         CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
90217dfd7c27   codereapergithubio-render-run-d1f5fc2bea43   1.33%     47.91MiB / 1.914GiB   2.45%     2.05MB / 26.2MB   0B / 0B     40
```

#### Stopping a running container

```sh
% docker container stop 90217dfd7c27
90217dfd7c27
```

#### Checking which images are present

```sh
% docker images
REPOSITORY                  TAG       IMAGE ID       CREATED          SIZE
codereapergithubio-tester   latest    4e104ff00f74   17 minutes ago   66.7MB
hugomods/hugo               git       cd0d7c15f208   9 days ago       99.2MB
hadolint/hadolint           latest    2d306e4c9d04   2 years ago      24MB
mrtazz/checkmake            latest    bcda60562f17   2 years ago      11.2MB
```

#### Checking disk usage of containers/images/volumes

```sh
% docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          4         1         192.9MB   101.9MB (52%)
Containers      1         1         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     5         0         199B      199B
```

#### Reclaiming all not-in-use disk usage

```sh
% docker system prune -a --volumes
WARNING! This will remove:
  - all stopped containers
  - all networks not used by at least one container
  - all anonymous volumes not used by at least one container
  - all images without at least one container associated to them
  - all build cache

Are you sure you want to continue? [y/N] y
Deleted Images:
... skipped ...

Deleted build cache objects:
... skipped ...

Total reclaimed space: 93.68MB
```

#### Scanning an image for CVEs

#FIXME:
https://www.pomerium.com/blog/docker-image-scanning-tools


```sh
docker run -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/Library/Caches:/root/.cache/ aquasec/trivy:0.59.1 image python:3.4-alpine
```

```sh
docker run --rm \
--volume /var/run/docker.sock:/var/run/docker.sock \
-e GRYPE_DB_CACHE_DIR=/tmp/grype \
-v $HOME/Library/Caches:/tmp/grype/ \
--name Grype anchore/grype:latest \
python:3.4-alpine
```


### License Caveat

I am **not** a lawyer and nothing here is legal advice. I conferred with ChatGPT and below are some relevant quotes from our conversation.

#### In regards to using the CLI tools available for Linux
> When you install only the open source Docker CLI tools (and related tools like Compose) on macOS—using, for example, Homebrew—and then pair them with an alternative engine like Colima, you are essentially running the same open source components used on Linux. In this configuration, Docker Desktop is not involved, and therefore, you are not subject to Docker Desktop’s licensing requirements.

#### In regards to pushing and pulling to Docker servers
> In summary, both fetching and pushing images are interactions with external services (like Docker Hub) and are governed by those services’ own terms of service—not by Docker Desktop licensing. As long as you’re using the open source command-line tools and an alternative engine (like Colima), you’re not incurring Docker Desktop licensing requirements regardless of whether you pull or push images.

Based on mine and ChatGPTs "understanding" of the licenses it should be legally safe to use the `docker` CLI as a replacement for Docker Desktop regardless of your use case.
