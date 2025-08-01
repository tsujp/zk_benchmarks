# -*- mode: dockerfile-ts -*-

# Defaults for arguments. All other occurances of these are to ensure they
# continue propagating through build stages.
ARG VERSION=42
ARG USERNAME=benchy

ARG SUITE_NAME
ARG VARIANT_NAME
ARG BENCHY_TARGET="$SUITE_NAME-$VARIANT_NAME"

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

# ******************************************************************************
FROM fedora-baseline:$VERSION as benchy-$BENCHY_TARGET-fedora:$VERSION
# ARG VERSION
ARG USERNAME
ARG SUITE_NAME
ARG VARIANT_NAME
ARG BENCHY_TARGET

LABEL sh.benchy.suite="$SUITE_NAME" \
      sh.benchy.variant="$VARIANT_NAME" \
	  sh.benchy.summary="Benchy image for $BENCHY_TARGET scenarios"

ENV BENCHY_TARGET="$BENCHY_TARGET"

USER $USERNAME
WORKDIR /home/$USERNAME

COPY benchy_imaged.sh .benchy_imaged.sh
COPY "$VARIANT_NAME.sh" benchmark
# TODO: Perhaps later we have a "bin" staged folder so we can COPY binaries/* bin/
COPY poop bin/install-poop

# Fix ownership.
RUN sudo chown -R "$USERNAME":"$USERNAME" "$HOME"
RUN ./bin/install-poop

# ******************************************************************************
FROM benchy-$BENCHY_TARGET-fedora:$VERSION
ARG USERNAME
ARG BENCHY_TARGET

USER $USERNAME
WORKDIR /home/$USERNAME

RUN ./benchmark bootstrap

CMD ["./benchmark", "benchmark"]

# ls -lan
# ls -la@
# podman top -l capeff
# podman top -l user uid huser group hgroups
