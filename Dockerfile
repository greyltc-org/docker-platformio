# syntax=docker/dockerfile:1.3.1-labs
FROM ghcr.io/greyltc-org/archlinux-aur as build-stage
RUN <<EOF
#!/usr/bin/env bash
set -e
get-new-mirrors
aur-install platformio
EOF

FROM scratch AS pkg-export-stage
COPY --from=build-stage /var/cache/foreign-pkg/* /

FROM archlinux/archlinux:base AS mkimg-stage
RUN --mount=type=bind,target=/mnt/foreigns,source=/var/cache/foreign-pkg,from=build-stage <<EOF
#!/usr/bin/env bash
set -e
#curl --quiet --follow https://raw.githubusercontent.com/greyltc/docker-archlinux/master/get-new-mirrors.sh > /bin/get-new-mirrors
#chmod +x /bin/get-new-mirrors
#get-new-mirrors
pacman --sync --refresh
yes|pacman --upgrade --needed --noconfirm --noprogressbar /mnt/foreigns/*
yes|pacman --sync --clean --clean
EOF

FROM mkimg-stage AS mkfwb-stage
RUN <<EOF
#!/usr/bin/env bash
set -e

pio platform install atmelavr --with-package framework-arduino-avr --with-package framework-arduino-avr-minicore --with-package framework-arduino-mbed
pio platform install ststm32 --with-package framework-arduino-mbed

BOARD=megaatmega2560
mkdir -p ${BOARD}
platformio init --board ${BOARD} --project-dir ${BOARD}
pio lib --project-dir ${BOARD} install "arduino-libraries/Ethernet@^2.0.0"  # Arduino's Ethernet library
pio run --project-dir ${BOARD} || echo "${BOARD} ready"  # download&prepare platformio/tool-scons, generates expected errors but can't figure out how to get it otherwise
pio run --project-dir ${BOARD} --target upload || echo "${BOARD} upload ready"  # download&prepare platformio/tool-avrdude, generates expected errors but can't figure out how to get it otherwise

BOARD=ATmega328PB
mkdir -p ${BOARD}
#  --project-options only needed until my wire mods are in MCUdude/MiniCore. see https://github.com/MCUdude/MiniCore/issues/178
platformio init --board ${BOARD} --project-dir ${BOARD} --project-option "lib_deps = framework-arduino-avr/Wire" --project-option "lib_extra_dirs = \$PROJECT_CORE_DIR/packages/framework-arduino-avr/libraries"
pio run --project-dir ${BOARD} || echo "${BOARD} ready"  # download&prepare platformio/tool-scons, generates expected errors but can't figure out how to get it otherwise
pio run --project-dir ${BOARD} --target upload || echo "${BOARD} upload ready"  # download&prepare platformio/tool-avrdude, generates expected errors but can't figure out how to get it otherwise

BOARD=portenta_h7_m7
mkdir -p ${BOARD}
platformio init --board ${BOARD} --project-dir ${BOARD}
pio run --project-dir ${BOARD} || echo "${BOARD} ready"  # download&prepare platformio/tool-dfuutil, generates expected errors but can't figure out how to get it otherwise
pio run --project-dir ${BOARD} --target upload || echo "${BOARD} upload ready"  # download&prepare platformio/tool-openocd, platformio/tool-stm32duino, generates expected errors but can't figure out how to get it otherwise

yes | pio system prune
EOF
