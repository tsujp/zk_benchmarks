# -*- mode: dockerfile-ts -*-

# Defaults for arguments. All other occurances of these are to ensure they
# continue propagating through build stages.
ARG VERSION=42
ARG USERNAME=benchy

ARG SUITE_NAME
ARG VARIANT_NAME
ARG BENCHY_TARGET="$SUITE_NAME-$VARIANT_NAME"

# ******************************************************************************
FROM localhost/benchy/fedora-baseline:$VERSION as benchy-$BENCHY_TARGET-fedora:$VERSION
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

COPY stwo_benchmarks scenarios
RUN sudo chown -R "$USERNAME":"$USERNAME" "$HOME"

RUN ./benchmark bootstrap

CMD ["/bin/bash", "-l", "-c", "./benchmark benchmark"]

# ls -lan
# ls -la@
# podman top -l capeff
# podman top -l user uid huser group hgroups
