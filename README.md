[![CI](https://github.com/greyltc-org/docker-platformio/actions/workflows/build.yml/badge.svg)](https://github.com/greyltc-org/docker-platformio/actions/workflows/build.yml)
# docker-platformio
Arch Linux based docker container with platformio

# Usage
## Basic
```bash
docker run --name pio-ver --pull=always ghcr.io/greyltc-org/platformio platformio --version
```
## Interactive
```
docker run --name pio-check --pull=always --interactive --tty ghcr.io/greyltc-org/platformio bash
```
