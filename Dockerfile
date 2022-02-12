# syntax=docker/dockerfile:1.3
FROM ghcr.io/greyltc-org/archlinux-aur as build-stage
ADD install-platformio.sh /sbin/install-platformio
RUN install-platformio
RUN ls /var/cache/makepkg/pkg
RUN ls /var/cache/foreign-pkg

FROM scratch AS pkg-export-stage
COPY --from=build-stage /var/cache/foreign-pkg/* /

FROM archlinux/archlinux:base AS mkimg-stage
#ADD https://raw.githubusercontent.com/greyltc/docker-archlinux/master/get-new-mirrors.sh /usr/bin/get-new-mirrors
#RUN chmod +x /usr/bin/get-new-mirrors
#RUN get-new-mirrors
RUN pacman --sync --refresh
RUN --mount=type=bind,target=/mnt,source=/var/cache/foreign-pkg,from=build-stage yes|pacman --upgrade --needed --noconfirm --noprogressbar /mnt/*
RUN pacman --sync --clean --clean
