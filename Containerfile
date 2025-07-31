# -*- mode: dockerfile-ts -*-

ARG VERSION=42
FROM fedora:$VERSION AS fedora-baseline:$VERSION

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
	\
	&& dnf clean all

ARG VERSION=42
FROM fedora-baseline:$VERSION

# Install Zig.
RUN curl -LO https://ziglang.org/download/0.14.1/zig-x86_64-linux-0.14.1.tar.xz; \
    tar xf zig-x86_64-linux-0.14.1.tar.xz; \
    mv zig-x86_64-linux-0.14.1/{zig,doc,lib} /usr/local/bin/; \
    zig --version

# Install Noir.
RUN curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash; \
    source ~/.bashrc; \
    noirup

# Install Barretenberg.
RUN curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash; \
    source ~/.bashrc; \
    bbup

# Unless specified will inherit value as set at top of file.
ARG VERSION

ARG PROJECT_NAME=zk_benchmarks

LABEL sh.jam.name="$PROJECT_NAME" \
	  sh.jam.summary="Image with $PROJECT_NAME project dependencies" \
	  sh.jam.box="true"

ENV JAM_PROJECT="$PROJECT_NAME"

# -------------------------------------------- Namespace mapping.
# Without the following magic adduser namespace mapping will break horribly. If you do NOT want to use it one alternative is that the Containerfile must specify no USER at all, and when calling `run` on podman-machine as user `core` `--userns keep-id:uid=501` must be passed.

# UID for this account must match macOS UID that is running podman-machine (vm) as by default Podman will set up namespace mapping to said UID which is also (from macOS) default: 501.
ARG USERNAME=jammy
RUN adduser \
	--groups wheel \
	--home-dir /home/"$USERNAME" \
	--password '' \
	--shell /bin/bash \
	--user-group \
	"$USERNAME"
# -------------------------------------------- /

USER $USERNAME

# CMD ["/bin/bash", "-l"]

# ls -lan
# ls -la@
# podman top -l capeff
# podman top -l user uid huser group hgroups
