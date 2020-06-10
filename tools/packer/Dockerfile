ARG alpine_version
# Golang Build stage for vagrants3 plugin
FROM golang:alpine AS golang-build
RUN apk --no-cache add build-base git mercurial gcc && \
GO111MODULE=on go get github.com/lmars/packer-post-processor-vagrant-s3 && \
file /go/bin/packer-post-processor-vagrant-s3

FROM alpine:${alpine_version}
LABEL maintainer="Unif.io, Inc. <support@unif.io>"

ARG packer_version
ENV PACKER_VERSION $packer_version
ENV HASHI_KEY_URL https://keybase.io/hashicorp/key.asc

# This is the release of https://github.com/hashicorp/docker-base to pull in order
# to provide HashiCorp-built versions of basic utilities like dumb-init and gosu.
ENV DOCKER_BASE_VERSION=0.0.4

RUN set -ex; \
  \
  fetchDeps=' \
    ca-certificates \
    gnupg \
    git \
    openssl \
    unzip \
    wget \
  '; \
  apk add --no-cache --update $fetchDeps && \
  \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  \
  wget -O - $HASHI_KEY_URL | gpg --import; \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip" && \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS" && \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig" && \
  gpg --batch --verify docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS && \
  grep docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS | sha256sum -c && \
  unzip docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip && \
  cp bin/gosu /usr/local/bin && \
  \
  wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" && \
  wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS" && \
  wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS.sig" && \
  gpg --batch --verify packer_${PACKER_VERSION}_SHA256SUMS.sig packer_${PACKER_VERSION}_SHA256SUMS && \
  grep packer_${PACKER_VERSION}_linux_amd64.zip packer_${PACKER_VERSION}_SHA256SUMS | sha256sum -c && \
  unzip -d /usr/local/bin packer_${PACKER_VERSION}_linux_amd64.zip && \
  \
  wget -q -O /etc/apk/keys/sgerrand.rsa.pub "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" && \
  wget -q "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" && \
  apk add --no-cache --update glibc-2.23-r3.apk && \
  \
  cd / && \
  rm -rf /tmp/build && \
  rm -rf /root/.gnupg

RUN set -ex; \
  \
  fetchDeps=' \
    build-base \
    ruby-dev \
    ruby \
    ruby-etc \
  '; \
  apk add --no-cache --update $fetchDeps && \
  \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  \
  wget -q "https://github.com/unifio/packer-provisioner-serverspec/releases/download/v0.2.0/packer-provisioner-serverspec_0.2.0_linux_amd64.tar.gz" && \
  \
  tar xvfz packer-provisioner-serverspec_0.2.0_linux_amd64.tar.gz && \
  chmod +x packer-provisioner-serverspec && \
  mv packer-provisioner-serverspec /usr/local/bin && \
  gem install io-console bundler rake rspec serverspec --no-document  && \
  \
  cd / && \
  rm -rf /tmp/build

ENV DOCKER_VERSION 1.9.1
ENV DOCKER_SHA256 6a095ccfd095b1283420563bd315263fa40015f1cee265de023efef144c7e52d

RUN set -ex; \
  \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  \
  wget -q -O docker.tgz "https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" && \
  echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - && \
  tar -C / -xzvf docker.tgz && \
  \
  cd / && \
  rm -rf /tmp/build && \
  docker -v
COPY --from=golang-build /go/bin/packer-post-processor-vagrant-s3 /usr/local/bin
COPY entrypoint.sh /usr/local/bin/

VOLUME ["/data"]
WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["--help"]
