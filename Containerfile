ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="42"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-nvidia"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"

FROM scratch AS ctx
COPY build_files /build_files

## Avios Professional Desktop image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG AKMODS_FLAVOR="coreos-stable"
ARG BASE_IMAGE_NAME="silverblue"
ARG FEDORA_MAJOR_VERSION="42"
ARG IMAGE_NAME="avios"
ARG IMAGE_VENDOR="RickyvdBerg"
ARG KERNEL="6.12.7-200.fc42.x86_64"
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""

# Build, cleanup, commit.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/build.sh && \
    ostree container commit
