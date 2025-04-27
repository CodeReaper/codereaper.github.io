---
title: Docker on the CLI
date: 2025-04-27T22:00:00+02:00
draft: false
---

It is always useful to be able to do your work from the command line.

For some time now, [Docker Desktop](https://www.docker.com) have been dulling the collective common knowledge about how to use `docker` on the command line.

Let us address this knowledge gap - _while avoiding the basics_ - with a [Housekeeping](#housekeeping) section before we dive into [Tools](#tools).

## Housekeeping

For general housekeeping we need to check which images and containers exist, monitor their resource usage, and clean up any unnecessary or unused items.

### A Good Tip

As quick aside I need to mention that a lot of housekeeping can be avoided with the option `--rm` for instance when running an image:

```sh
% docker run --rm hello-world
```

The option `--rm` effectively cleans up after itself.
> Automatically remove the container and its associated anonymous volumes when it exits

### Listing

```sh
% docker ps # alias for `docker container ls`
CONTAINER ID   IMAGE               COMMAND                  CREATED      STATUS      PORTS                      NAMES
90217dfd7c27   hugomods/hugo:git   "docker-entrypoint.s…"   7 days ago   Up 7 days   127.0.0.1:1313->1313/tcp   codereapergithubio-render-run-d1f5fc2bea43

% docker images # alias for `docker image ls`
REPOSITORY                TAG          IMAGE ID       CREATED         SIZE
hugomods/hugo             git          cd0d7c15f208   3 weeks ago     99.2MB
hello-world               latest       f1f77a0f96b7   5 weeks ago     5.2kB
```

### Resource Usage

```sh
% docker stats --no-stream
CONTAINER ID   NAME                                         CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
90217dfd7c27   codereapergithubio-render-run-d1f5fc2bea43   1.33%     47.91MiB / 1.914GiB   2.45%     2.05MB / 26.2MB   0B / 0B     40

% docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          4         1         192.9MB   101.9MB (52%)
Containers      1         1         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     5         0         199B      199B
```

The option `--no-stream` can be omitted to use the `stats` subcommand as a `top` command.
> Disable streaming stats and only pull the first result

### Cleaning Up

**Note** that following command will remove everything not currently in use without confirmation.

```sh
% docker system prune -af --volumes
Deleted Containers:
... skipped ...

Deleted Images:
... skipped ...

Deleted build cache objects:
... skipped ...

Total reclaimed space: 93.68MB
```

## Tools

We will not be installing any tools, but instead we are going to run the tools using `docker run` commands. That way we only need to maintain an `alias` file or some similar.

### CVE Scanning

It can be good to have options for scanning your images, so let us take a look at two scanning tool options.

#### [Grype](https://anchore.com/opensource/)

{{<code language="plain" source="grype.output">}}

{{<collapsed-code summary="Show alias" language="sh" source="grype.alias">}}

#### [Trivy](https://trivy.dev/)

{{<code language="plain" source="trivy.output">}}

{{<collapsed-code summary="Show alias" language="sh" source="trivy.alias">}}

### Explore Image Contents

#### [Dive](https://github.com/wagoodman/dive)

Allows you to view each layers command, directories and files which can be very helpful in a debugging situation. This is an interactive tool, so it is hard to show the output from `dive` therefore I am borrowing their own introduction gif:

![Animation showing the functions in dive](dive-demo.gif)

{{<collapsed-code summary="Show alias" language="sh" source="dive.alias">}}

**Note** you cannot view the contents of a file (yet - see [#336](https://github.com/wagoodman/dive/issues/336)).

### SBOMs with [Syft](https://github.com/anchore/syft)

Syft is an easy-to-use tool for generating Software Bill of Materials for container images (and filesystems).

{{<code language="plain" source="syft.output">}}

{{<collapsed-code summary="Show alias" language="sh" source="syft.alias">}}

### Reverse-engineer a Dockerfile with [dfimage](https://github.com/LanikSJ/dfimage)

Take a peak at how others have made their Dockerfile.

{{<code language="plain" source="dfimage.output">}}

{{<collapsed-code summary="Show alias" language="sh" source="dfimage.alias">}}

## Missing Out

You might be wondering, what are we missing out on by not using Docker Desktop and you _are_ missing three things:

- Docker Scout
- Docker Cloud
- Docker Debug

### Docker Scout

Scout can present you with an assessment score of an images vulnerabilities. This score is meaningless if you ignoring the "high number, bad" and "low number, good" arguments. You still need evaluate the risks of your application, its use-cases and risk profile.

You have tools above to generate a list of software and versions used in an image or a list of vulnerabilities to evaluate.

### Docker Cloud

Docker Build Cloud and Testcontainers Cloud are both ... ridiculous. They are marketed as time-saving tools and they are both the ability to do `docker build` and `docker run`, but in the cloud.

Your builds and tests should not take long, and the solution is not to send your code to a third-party and have them run it.

If - _and there should not be a need for it_ - you really need to offload building and testing from the developers machine, use your own build server, or a free one from [GitHub](github.com).

### [Docker Debug](https://docs.docker.com/reference/cli/docker/debug/)

This is the ability to have a shell on a distroless image. This could be really useful.

The `dive` tool mentioned above should be enough, especially once we have the ability to view the contents of a file.
