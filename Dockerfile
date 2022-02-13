# syntax=docker/dockerfile:1.3
FROM ghcr.io/greyltc-org/archlinux-aur as build-stage
RUN <<EOF
#!/usr/bin/env bash
#get-new-mirrors
pacman --sync --refresh
aur-install platformio
EOF

FROM scratch AS pkg-export-stage
COPY --from=build-stage /var/cache/foreign-pkg/* /

FROM archlinux/archlinux:base AS mkimg-stage
RUN --mount=type=bind,target=/mnt/foreigns,source=/var/cache/foreign-pkg,from=build-stage <<EOF
#!/usr/bin/env bash
#curl --quiet --follow https://raw.githubusercontent.com/greyltc/docker-archlinux/master/get-new-mirrors.sh > /bin/get-new-mirrors
#chmod +x /bin/get-new-mirrors
#get-new-mirrors
pacman --sync --refresh
yes|pacman --upgrade --needed --noconfirm --noprogressbar /mnt/foreigns/*
yes|pacman --sync --clean --clean
EOF
