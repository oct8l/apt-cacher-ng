[![apt-cacher-ng](https://github.com/oct8l/apt-cacher-ng/actions/workflows/build.yml/badge.svg)](https://github.com/oct8l/apt-cacher-ng/actions/workflows/build.yml)

# oct8l/apt-cacher-ng

- [Introduction](#introduction)
  - [Contributing](#contributing)
  - [Issues](#issues)
- [Getting started](#getting-started)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
  - [Command-line arguments](#command-line-arguments)
  - [Persistence](#persistence)
  - [Docker Compose](#docker-compose)
  - [Usage](#usage)
  - [Logs](#logs)
- [Testing](#testing)
  - [Local tests](#local-tests)
  - [Pull request CI](#pull-request-ci)
  - [Other CI runs](#other-ci-runs)
- [Maintenance](#maintenance)
  - [Cache expiry](#cache-expiry)
  - [Upgrading](#upgrading)
  - [Shell Access](#shell-access)

# Introduction

`Dockerfile` to create a [Docker](https://www.docker.com/) container image for [Apt-Cacher NG](https://www.unix-ag.uni-kl.de/~bloch/acng/).

Apt-Cacher NG is a caching proxy, specialized for package files from Linux distributors, primarily for [Debian](http://www.debian.org/) (and [Debian based](https://en.wikipedia.org/wiki/List_of_Linux_distributions#Debian-based)) distributions but not limited to those.

## Contributing

If you find this image useful here's how you can help:

- Send a pull request with your awesome features and bug fixes

Fork-based contributions are supported. Create a branch in your fork, make your
changes, run [`./test-local.sh`](#local-tests), and open a pull request against
`main`. GitHub may require a maintainer to approve the first workflow run from a
new contributor.

## Issues

Before reporting your issue please try updating Docker to the latest version and check if it resolves the issue. Refer to the Docker [installation guide](https://docs.docker.com/installation) for instructions.

SELinux users should try disabling SELinux using the command `setenforce 0` to see if it resolves the issue.

If the above recommendations do not help then [report your issue](../../issues/new) along with the following information:

- Output of the `docker version` and `docker info` commands
- The `docker run` command or `docker-compose.yml` used to start the image. Mask out the sensitive bits.
- Please state if you are using [Boot2Docker](http://www.boot2docker.io), [VirtualBox](https://www.virtualbox.org), etc.

# Getting started

## Installation

Automated builds of the image are available in this [GitHub repo](https://github.com/users/oct8l/packages/container/package/apt-cacher-ng) and is the recommended method of installation.

```bash
docker pull ghcr.io/oct8l/apt-cacher-ng:latest
```

Alternatively you can build the image yourself.

```bash
docker build -t apt-cacher-ng github.com/oct8l/apt-cacher-ng
```

## Quickstart

Start Apt-Cacher NG using:

```bash
docker run --name apt-cacher-ng --init -d --restart=always \
  --publish 3142:3142 \
  --volume ${PWD}/apt-cacher-ng:/var/cache/apt-cacher-ng \
  ghcr.io/oct8l/apt-cacher-ng:latest
```

*Alternatively, you can use the sample [docker-compose.yml](docker-compose.yml) file to start the container using [Docker Compose](https://docs.docker.com/compose/)*

## Command-line arguments

You can customize the launch command of Apt-Cacher NG server by specifying arguments to `apt-cacher-ng` on the `docker run` command. For example the following command prints the help menu of `apt-cacher-ng` command:

```bash
docker run --name apt-cacher-ng --init -it --rm \
  --publish 3142:3142 \
  --volume ${PWD}/apt-cacher-ng:/var/cache/apt-cacher-ng \
  ghcr.io/oct8l/apt-cacher-ng:latest -h
```

## Persistence

For the cache to preserve its state across container shutdown and startup you should mount a volume at `/var/cache/apt-cacher-ng`.

> *The [Quickstart](#quickstart) command already mounts a volume for persistence.*

SELinux users should update the security context of the host mountpoint so that it plays nicely with Docker:

```bash
mkdir -p ${PWD}/apt-cacher-ng
chcon -Rt svirt_sandbox_file_t ${PWD}/apt-cacher-ng
```

## Docker Compose

To run Apt-Cacher NG with Docker Compose, create the following `docker-compose.yml` file

```yaml
---
services:
  apt-cacher-ng:
    image: ghcr.io/oct8l/apt-cacher-ng:latest
    container_name: apt-cacher-ng
    ports:
      - "3142:3142"
    volumes:
      - apt-cacher-ng:/var/cache/apt-cacher-ng
    restart: always

volumes:
  apt-cacher-ng:
```

The Apt-Cache NG service can then be started in the background with:

```bash
docker compose up -d
```

## Usage

To start using Apt-Cacher NG on your Debian (and Debian based) host, create the configuration file `/etc/apt/apt.conf.d/01proxy` with the following content:

```config
Acquire::HTTP::Proxy "http://172.17.0.1:3142";
Acquire::HTTPS::Proxy "false";
```

Similarly, to use Apt-Cacher NG in you Docker containers add the following line to your `Dockerfile` before any `apt-get` commands.

```dockerfile
RUN echo 'Acquire::HTTP::Proxy "http://172.17.0.1:3142";' >> /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy
```

## Logs

To access the Apt-Cacher NG logs, located at `/var/log/apt-cacher-ng`, you can use `docker exec`. For example, if you want to tail the logs:

```bash
docker exec -it apt-cacher-ng tail -f /var/log/apt-cacher-ng/apt-cacher.log
```

# Testing

## Local tests

The local test suite requires Docker with the Compose plugin. It builds the
image for your machine's architecture and uses
[`docker-compose.test.yml`](docker-compose.test.yml) to run the same functional,
performance, and error-handling scripts used by the main CI workflow.

```bash
./test-local.sh
```

The script verifies package downloads through the proxy, the health and report
pages, multiple package installs, and handling of a nonexistent package. It
also repeats package downloads to exercise the cache and records performance
timings. The tests access upstream package repositories and may download
several packages.

## Pull request CI

[`build.yml`](.github/workflows/build.yml) runs the following checks for pull
requests targeting `main`:

- Builds test images for `linux/amd64` and `linux/arm64`, then passes them to
  downstream jobs as short-lived workflow artifacts. Pull requests do not push
  test images or release images to GHCR, so the workflow can run for
  contributions from forks without package-write permission.
- Runs the functional, performance, error-handling, and configuration-override
  checks on both test-image architectures.
- Runs a blocking Trivy scan for fixable `HIGH` and `CRITICAL`
  vulnerabilities. Fork pull requests run the same scan but do not upload its
  SARIF report to the repository's Security tab, which requires write
  permission.
- Verifies that the final image builds for `linux/amd64`, `linux/arm64/v8`, and
  `linux/arm/v7` without publishing it.
- Runs Hadolint against the `Dockerfile` and ShellCheck against all tracked
  shell scripts.
- Runs the upstream compatibility workflow against Debian Bookworm (full and
  slim) and Bullseye slim base images on AMD64 and ARM64. It uses the default
  `apt-cacher-ng` version available from each base image's repositories.
- Tests Debian Bookworm and Bullseye plus Ubuntu 24.04 and 22.04 clients,
  additional package sources, and cache performance.

The `PR CI Gate` job aggregates these checks into a single status that branch
protection can require.

## Other CI runs

- Pushes to `main`, version tags, and manual `build.yml` runs execute the
  integration and security checks before publishing the multi-architecture
  image to GHCR.
- On the 1st and 15th of each month,
  [`build.yml`](.github/workflows/build.yml) adds comprehensive tests with
  Debian Bookworm, Debian Bullseye, and Ubuntu 22.04 clients, plus load and
  reliability tests, before publishing.
- Every Monday,
  [`upstream-compatibility.yml`](.github/workflows/upstream-compatibility.yml)
  runs independently to detect changes in upstream distributions and package
  repositories.

# Maintenance

## Cache expiry

Using the [Command-line arguments](#command-line-arguments) feature, you can specify the `-e` argument to initiate Apt-Cacher NG's cache expiry maintenance task.

```bash
docker run --name apt-cacher-ng --init -it --rm \
  --publish 3142:3142 \
  --volume ${PWD}/apt-cacher-ng:/var/cache/apt-cacher-ng \
  ghcr.io/oct8l/apt-cacher-ng:latest -e
```

The same can also be achieved on a running instance by visiting the url http://localhost:3142/acng-report.html in the web browser and selecting the **Start Scan and/or Expiration** option.

## Upgrading

To upgrade to newer releases:

  1. Download the updated Docker image:

  ```bash
  docker pull ghcr.io/oct8l/apt-cacher-ng:latest
  ```

  2. Stop the currently running image:

  ```bash
  docker stop apt-cacher-ng
  ```

  3. Remove the stopped container

  ```bash
  docker rm -v apt-cacher-ng
  ```

  4. Start the updated image

  ```bash
  docker run --name apt-cacher-ng --init -d \
    [OPTIONS] \
    ghcr.io/oct8l/apt-cacher-ng:latest
  ```

## Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using Docker version `1.3.0` or higher you can access a running containers shell by starting `bash` using `docker exec`:

```bash
docker exec -it apt-cacher-ng bash
```
