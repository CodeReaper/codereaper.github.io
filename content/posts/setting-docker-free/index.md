---
title: Setting Docker free
date: 2025-02-23T00:00:00+02:00
draft: false
---

Once upon a time something happened to [Docker](https://www.docker.com), the CLI tool for managing images and containers on your machine. Docker had begun changing and with change by change over time had become something different at least for those using macOS (or Windows is outside the scope of this post).

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
- No update notification at all

The more complex installation downside can be addressed with the installation guide below and then we can take a look at handling updates.

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

**2** - Add configuration for the plugins and virtual machine

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

**3** - Configure virtual machine resource usage (Optional)

By default `colima` will create a virtual machine with 2 CPUs, 2GiB memory and 100GiB storage, but you can tweak those settings with the first start command:

```sh
colima start --cpu 1 --memory 2 --disk 40
```

*Note* if you want to change those settings after it was started, you will need to stop it first.

**4** - Set up virtual machine daemon

```sh
brew services start colima
```

### Handling Updates

It is up to your self to stay up to date with the update nagging from any of the desktop applications. This was always the case if you had anything else installed via `brew`.

Applying the latest updates can be done with the following command:

```sh
brew upgrade
```

You need to find an update strategy that suits your requirements:
- Automated crontab action
- [Homebrew Autoupdate](https://github.com/DomT4/homebrew-autoupdate)
- Reoccurring calendar event
- Monday morning updates
- When I think of it
- When I try to use a feature that is too new

### License Caveat

I am **not** a lawyer and nothing here is legal advice. I conferred with ChatGPT and below are some relevant quotes from our conversation.

#### In regards to using the CLI tools available for Linux
> When you install only the open source Docker CLI tools (and related tools like Compose) on macOS—using, for example, Homebrew—and then pair them with an alternative engine like Colima, you are essentially running the same open source components used on Linux. In this configuration, Docker Desktop is not involved, and therefore, you are not subject to Docker Desktop’s licensing requirements.

#### In regards to pushing and pulling to Docker servers
> In summary, both fetching and pushing images are interactions with external services (like Docker Hub) and are governed by those services’ own terms of service—not by Docker Desktop licensing. As long as you’re using the open source command-line tools and an alternative engine (like Colima), you’re not incurring Docker Desktop licensing requirements regardless of whether you pull or push images.

Based on mine and ChatGPTs "understanding" of the licenses it should be legally safe to use the `docker` CLI as a replacement for Docker Desktop regardless of your use case.
