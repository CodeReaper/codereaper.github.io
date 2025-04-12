---
title: Docker on the CLI
date: 2025-02-24T00:00:00+02:00
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

FIXME: .. and below

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




### more

https://github.com/project-copacetic/copacetic

https://github.com/LanikSJ/dfimage

https://github.com/anchore/syft
docker run --rm ghcr.io/anchore/syft 


## Missing Out

paid features: 
- https://www.docker.com/blog/november-2024-updated-plans-announcement/
- Debug of distroless images
	- https://docs.docker.com/reference/cli/docker/debug/
- Docker Desktop, Docker Hub, Docker Build Cloud, Docker Scout, and Testcontainers Cloud
