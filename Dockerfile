FROM ghcr.io/greyltc-org/archlinux-aur

ADD install-platformio.sh /sbin/install-platformio
RUN --mount=type=bind,source=.,target=/mnt/out,rw install-platformio
