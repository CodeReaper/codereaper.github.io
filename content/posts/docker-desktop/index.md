---
title: Docker desktop
date: 2025-01-26T00:00:00+02:01
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

Having been annoyed for long enough I wanted to investigate what my alternatives on macOS were... but you do not have to read about them, if you do not want to, by skipping ahead to [The Alternative](#the-alternative).

## Rancher Desktop

Spend a little time searching and you will find [Rancher Desktop](https://rancherdesktop.io) which is a "replacement" for Docker Desktop. You will need to configure certain things about the container runtime which can seem daunting unless you already know way too much about what is under the hood in the world of containers.

Pros:
- No required license
- No user login

Cons:
- Same constant updates
- Still need to have an actual application running
- New pitfalls with incorrect setup

FIXME:
summation about moby at
https://www.reddit.com/r/docker/comments/y3svky/docker_vs_moby_engine/?rdt=50381

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


FIXME:
summation with differences: https://betterstack.com/community/guides/scaling-docker/podman-vs-docker/

## The Alternative

Instead of Docker Desktop you can simply use `docker` - as in the same way that docker is used on Linux.

Pros:
- No required license[¹](#license-caveat)
- No user login
- No update nagging
- Runs as a daemon

Cons:
- More complex installation

### Installation Guide

- brew
- brew install docker colima docker-compose docker-buildx docker-credential-helper
- colima start --cpu 1 --memory 2 --disk 40
- brew services start colima
```
"cliPluginsExtraDirs" to ~/.docker/config.json:
  "cliPluginsExtraDirs": [
      "/opt/homebrew/lib/docker/cli-plugins"
  ]
```

If k8s:

- brew install kind, helm and kubectl
- `kind create cluster`


### CLI How To

- `docker system df`
- `docker system prune`
- scan
- whats running
- stopping them

### License Caveat

I am **not** a lawyer and nothing here is legal advice. I conferred with ChatGPT and below are some relevant quotes from our conversation.

#### In regards to using the CLI tools available for Linux
> When you install only the open source Docker CLI tools (and related tools like Compose) on macOS—using, for example, Homebrew—and then pair them with an alternative engine like Colima, you are essentially running the same open source components used on Linux. In this configuration, Docker Desktop is not involved, and therefore, you are not subject to Docker Desktop’s licensing requirements.

#### In regards to pushing and pulling to Docker servers
> In summary, both fetching and pushing images are interactions with external services (like Docker Hub) and are governed by those services’ own terms of service—not by Docker Desktop licensing. As long as you’re using the open source command-line tools and an alternative engine (like Colima), you’re not incurring Docker Desktop licensing requirements regardless of whether you pull or push images.

Based on mine and ChatGPTs "understanding" of the licenses it should be legally safe to use the `docker` CLI as a replacement for Docker Desktop regardless of your use case.
