FROM ghcr.io/greyltc-org/archlinux-aur

ADD install-platformio.sh /sbin/install-platformio
RUN install-platformio
RUN printenv
