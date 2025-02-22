---
title: Setting Docker free
date: 2025-02-24T00:00:00+02:00
draft: false
---

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




- minifying images - https://github.com/slimtoolkit/examples
- exploring images - https://github.com/wagoodman/dive



paid features: 
- https://www.docker.com/blog/november-2024-updated-plans-announcement/
- Debug of distroless images
	- https://docs.docker.com/reference/cli/docker/debug/
- Docker Desktop, Docker Hub, Docker Build Cloud, Docker Scout, and Testcontainers Cloud



