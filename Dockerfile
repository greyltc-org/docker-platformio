FROM ghcr.io/greyltc-org/archlinux-aur as build-stage
ADD install-platformio.sh /sbin/install-platformio
RUN install-platformio

FROM scratch AS pkg-export-stage
COPY --from=build-stage /home/custompkgs /

FROM build-stage as cleanup-stage
RUN rm /home/custompkgs/*
