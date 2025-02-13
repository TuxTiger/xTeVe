# syntax=docker/dockerfile:1

# First stage. Building a binary
# -----------------------------------------------------------------------------

# Base image for builder is debian 11 with golang 1.18+ pre-installed
FROM golang:1.18.1-bullseye AS builder

# Download the source code
RUN git clone https://github.com/dakota/xTeVe.git /src
WORKDIR /src

# Install dependencies
RUN go mod download

# Compile
RUN go build xteve.go

# Second stage. Creating an image
# -----------------------------------------------------------------------------

# Base image is a latest stable debian
FROM debian

ARG BUILD_DATE
ARG VCS_REF
ARG XTEVE_PORT=34400
ARG XTEVE_VERSION
ARG XTEVE_UID=816

LABEL org.label-schema.build-date="{$BUILD_DATE}" \
      org.label-schema.name="xTeVe" \
      org.label-schema.description="Dockerized fork of xTeVe by dakota" \
      org.label-schema.url="https://hub.docker.com/r/dakota/xteve/" \
      org.label-schema.vcs-ref="{$VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/dakota/xTeVe" \
      org.label-schema.vendor="dakota" \
      org.label-schema.version="{$XTEVE_VERSION}" \
      org.label-schema.schema-version="1.0"

ENV XTEVE_BIN=/home/xteve/bin
ENV XTEVE_CONF=/home/xteve/conf
ENV XTEVE_HOME=/home/xteve
ENV XTEVE_TEMP=/tmp/xteve
ENV XTEVE_USER=xteve

# Create the user to run inside the container
RUN adduser --uid $XTEVE_UID $XTEVE_USER

# Add binary to PATH
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$XTEVE_BIN

# Set working directory
WORKDIR $XTEVE_HOME

# Update package lists
RUN apt-get update

# Install CA certificates
RUN apt-get install --yes ca-certificates

# Add VLC and FFMPEG support
RUN apt-get install --yes vlc-bin ffmpeg

# Copy built binary from builder image
COPY --from=builder [ "/src/xteve", "${XTEVE_BIN}/" ]

# Set binary permissions
RUN chmod +rx $XTEVE_BIN/xteve

# Create XML cache directory
RUN mkdir $XTEVE_HOME/cache

# Create working directories for xTeVe
RUN mkdir $XTEVE_CONF
RUN chmod a+rwX $XTEVE_CONF
RUN mkdir $XTEVE_TEMP
RUN chmod a+rwX $XTEVE_TEMP

# Configure container volume mappings
VOLUME $XTEVE_CONF
VOLUME $XTEVE_TEMP

# Ensure the container user has ownership of home dir
RUN chown -R $XTEVE_USER $XTEVE_HOME

# Switch users to the xTeVe container user
USER $XTEVE_USER

# Run the xTeVe executable
ENTRYPOINT ${XTEVE_BIN}/xteve -port=${XTEVE_PORT} -config=${XTEVE_CONF}
