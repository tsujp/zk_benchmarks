# -*- mode: dockerfile-ts -*-

# Defaults for arguments. All other occurances of these are to ensure they
# continue propagating through build stages.
ARG VERSION=42
ARG USERNAME=benchy

# ******************************************************************************
FROM fedora:$VERSION AS fedora-baseline:$VERSION
ARG USERNAME

# Base dependencies.
RUN dnf update -y && dnf install -y \
	git \
	ripgrep \
	rsync \
	htop \
	curl \
	minisign \
	man \
	which \
	lsof \
	acl \
	diffutils \
	just \
    jq \
    bash \
    bsdtar \
    bc \
    helix \
	\
	&& dnf clean all

# -------------------------------------------- Namespace mapping.
# Without the following magic adduser namespace mapping will break horribly. If
#   you do NOT want to use it one alternative is that the Containerfile must
#   specify no USER at all, and when calling `run` on podman-machine as user
#  `core` `--userns keep-id:uid=XXXX` must be passed.

# For macOS the default UID is 501. If that user is the one running the
#   podman-machine (vm) then Podman will by default set up namespace mapping to
#   said UID.
# -------------------------------------------- /

# TODO: Can do this conditionally depending on whether macOS is the host, or just build a macOS version. Since bb doesn't come (precompiled) for darwin aarch64 we don't bother _for now_. Have removed macOS required arg: 	--uid 501 \
RUN adduser \
	--groups wheel \
	--home-dir /home/"$USERNAME" \
	--password '' \
	--shell /bin/bash \
	--user-group \
	"$USERNAME"

RUN mkdir -p /home/"$USERNAME"/bin
