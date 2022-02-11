FROM ghcr.io/greyltc-org/archlinux-aur

# optinally set, internal place to copy built packages to
ARG PKG_OUT
ENV PKG_OUT=$PKG_OUT

ADD install-platformio.sh /sbin/install-platformio
RUN install-platformio
RUN printenv
