FROM ruby:2.4-alpine
LABEL maintainer="Unif.io, Inc. <support@unif.io>"

# This is the release of https://github.com/hashicorp/docker-base to pull in order
# to provide HashiCorp-built versions of basic utilities like dumb-init and gosu.
ENV DOCKER_BASE_VERSION=0.0.4

ARG covalence_version

ENV COVALENCE_VERSION $covalence_version
ENV HASHI_KEY_URL https://keybase.io/hashicorp/key.asc

RUN set -ex; \
  \
  fetchDeps=' \
    build-base \
    ca-certificates \
    device-mapper \
    gnupg \
    git \
    iptables \
    lxc \
    mercurial \
    openssl \
    unzip \
    wget \
  '; \
  apk add --no-cache --update $fetchDeps && \
  \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  \
  mkdir -p /usr/local/external_bins && \

  # Docker base goodies
  wget -O - $HASHI_KEY_URL | gpg --import; \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip" && \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS" && \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig" && \
  gpg --batch --verify docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS && \
  grep docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS | sha256sum -c && \
  unzip docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip && \
  cp bin/gosu /usr/local/bin && \
  cp bin/dumb-init /usr/local/bin && \

  # Covalence
  gem install covalence -v $COVALENCE_VERSION --no-document  && \
  gem install dotenv serverspec --no-document  && \
  gem install rspec ci_reporter_rspec --no-document  && \

  # Cleanup
  cd /tmp && \
  rm -rf /tmp/build && \
  rm -rf /root/.gnupg

COPY entrypoint.sh /usr/local/bin/

VOLUME ["/data"]
WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "--"]
CMD ["rake"]
