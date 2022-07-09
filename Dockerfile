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
#set -o pipefail  # often causes death

#curl --quiet --follow https://raw.githubusercontent.com/greyltc/docker-archlinux/master/get-new-mirrors.sh > /bin/get-new-mirrors
#chmod +x /bin/get-new-mirrors
#get-new-mirrors
pacman --sync --refresh --needed --noconfirm avrdude dfu-util python-intelhex  # NOTE: this probably needs --sysupgrade
yes|pacman --upgrade --needed --noconfirm --noprogressbar /mnt/foreigns/*
yes|pacman --sync --clean --clean
EOF

# images from this step are currently published by CI as ghcr.io/greyltc-org/firmware-builder
FROM mkimg-stage AS mkfwb-stage
RUN <<EOF
#!/usr/bin/env bash
set -e
#set -o pipefail  # often causes death

#pio platform install atmelavr --with-package framework-arduino-avr --with-package framework-arduino-avr-minicore
#pio platform install ststm32 --with-package framework-arduino-mbed

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
#pio lib --storage-dir ${BOARD} install "arduino-libraries/Ethernet@^2.0.1"  # Arduino's Ethernet library
#pio lib --storage-dir ${BOARD} install "adafruit/Adafruit ADS1X15@^2.4.0"  # ADC library
#pio lib --storage-dir ${BOARD} install "adafruit/Adafruit BusIO@^1.11.1"  # abstracts away UART, I2C and SPI interfacing
#pio run --project-dir ${BOARD} || echo "${BOARD} ready"  # download&prepare platformio/tool-scons, generates expected errors but can't figure out how to get it otherwise
#pio run --project-dir ${BOARD} --target upload || echo "${BOARD} upload ready"  # download&prepare platformio/tool-avrdude, generates expected errors but can't figure out how to get it otherwise

BOARD=ATmega328PB
mkdir -p ${BOARD}
platformio init --board ${BOARD} --project-dir ${BOARD} --project-option "lib_extra_dirs = \$PROJECT_CORE_DIR/packages/framework-arduino-avr/libraries"
pio pkg install --project-dir ${BOARD} --platform "atmelavr"
pio pkg install --project-dir ${BOARD} --tool "platformio/framework-arduino-avr-minicore"
pio pkg install --project-dir ${BOARD} --tool "platformio/framework-arduino-avr"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-scons"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-avrdude"
#  --project-options only needed until my wire mods are in MCUdude/MiniCore. see https://github.com/MCUdude/MiniCore/issues/178
#platformio init --board ${BOARD} --project-dir ${BOARD} --project-option "lib_deps = framework-arduino-avr/Wire" --project-option "lib_extra_dirs = \$PROJECT_CORE_DIR/packages/framework-arduino-avr/libraries"
#pio run --project-dir ${BOARD} || echo "${BOARD} ready"  # download&prepare platformio/tool-scons, generates expected errors but can't figure out how to get it otherwise
#pio run --project-dir ${BOARD} --target upload || echo "${BOARD} upload ready"  # download&prepare platformio/tool-avrdude, generates expected errors but can't figure out how to get it otherwise

BOARD=portenta_h7_m7
mkdir -p ${BOARD}
platformio init --board ${BOARD} --project-dir ${BOARD}
pio pkg install --project-dir ${BOARD} --platform "ststm32"
pio pkg install --project-dir ${BOARD} --tool "platformio/framework-arduino-mbed"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-dfuutil"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-openocd"
pio pkg install --project-dir ${BOARD} --tool "platformio/tool-stm32duino"
#pio run --project-dir ${BOARD} || echo "${BOARD} ready"  # download&prepare platformio/tool-dfuutil, generates expected errors but can't figure out how to get it otherwise
#pio run --project-dir ${BOARD} --target upload || echo "${BOARD} upload ready"  # download&prepare platformio/tool-openocd, platformio/tool-stm32duino, generates expected errors but can't figure out how to get it otherwise

yes | pio system prune
EOF
