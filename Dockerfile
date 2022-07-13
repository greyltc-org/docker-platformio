# syntax=docker.io/docker/dockerfile:1.4.2
FROM ghcr.io/greyltc-org/archlinux-aur as build-stage
RUN <<EOF
#!/usr/bin/env bash
set -e
set -o pipefail

get-new-mirrors
aur-install platformio
EOF

FROM scratch AS pkg-export-stage
COPY --from=build-stage /var/cache/foreign-pkg/* /

# images from this step are currently published by CI as ghcr.io/greyltc-org/platformio
FROM archlinux/archlinux:base AS mkimg-stage
RUN --mount=type=bind,target=/mnt/foreigns,source=/var/cache/foreign-pkg,from=build-stage <<EOF
#!/usr/bin/env bash
set -e
set -o pipefail

pacman --sync --refresh --sysupgrade --noconfirm --needed avrdude dfu-util python-intelhex patch
(yes || true) | pacman --upgrade --needed --noconfirm --noprogressbar /mnt/foreigns/*
(yes || true) | pacman --sync --clean --clean
EOF

# images from this step are currently published by CI as ghcr.io/greyltc-org/firmware-builder
FROM mkimg-stage AS mkfwb-stage
RUN <<EOF
#!/usr/bin/env bash
set -e
set -o pipefail

BOARD=megaatmega2560
mkdir -p ${BOARD}
platformio init --board ${BOARD} --project-dir ${BOARD}
pio pkg install --project-dir ${BOARD} --platform "atmelavr"
pio pkg install --project-dir ${BOARD} --tool "platformio/framework-arduino-avr"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-scons"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-avrdude"
pio pkg install --project-dir ${BOARD} --library "arduino-libraries/Ethernet"  # Arduino's Ethernet library
pio pkg install --project-dir ${BOARD} --library "adafruit/Adafruit ADS1X15"   # ADC library
pio pkg install --project-dir ${BOARD} --library "adafruit/Adafruit BusIO"  # abstracts away UART, I2C and SPI interfacing
# patch the core-avr Wire library to remember last slave address
curl --silent https://github.com/arduino/ArduinoCore-avr/compare/1.8.5...greyltc:ArduinoCore-avr:remember-slave-address.patch | patch -d "/root/.platformio/packages/framework-arduino-avr" -p1

BOARD=ATmega328PB
mkdir -p ${BOARD}
platformio init --board ${BOARD} --project-dir ${BOARD} --project-option "lib_extra_dirs = \$PROJECT_CORE_DIR/packages/framework-arduino-avr/libraries"
pio pkg install --project-dir ${BOARD} --platform "atmelavr"
pio pkg install --project-dir ${BOARD} --tool "platformio/framework-arduino-avr-minicore"
pio pkg install --project-dir ${BOARD} --tool "platformio/framework-arduino-avr"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-scons"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-avrdude"

BOARD=portenta_h7_m7
mkdir -p ${BOARD}
platformio init --board ${BOARD} --project-dir ${BOARD}
pio pkg install --project-dir ${BOARD} --platform "ststm32"
pio pkg install --project-dir ${BOARD} --tool "platformio/framework-arduino-mbed"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-dfuutil"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-openocd"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-stm32duino"

(yes || true) | pio system prune
EOF
