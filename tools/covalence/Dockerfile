ARG alpine_version
ARG ruby_version
FROM ruby:${ruby_version}-alpine${alpine_version}
LABEL maintainer="Unif.io, Inc. <support@unif.io>"
ARG covalence_version
ARG sops_version
ARG prefixout_version

# This is the release of https://github.com/hashicorp/docker-base to pull in order
# to provide HashiCorp-built versions of basic utilities like dumb-init and gosu.
ENV DOCKER_BASE_VERSION=0.0.4

ARG covalence_version

ENV COVALENCE_VERSION $covalence_version
ENV HASHI_KEY_URL https://keybase.io/hashicorp/key.asc
ENV SOPS_VERSION $sops_version
ENV PREFIXOUT_VERSION $prefixout_version
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
  # Sops
  wget -O /tmp/build/sops "https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux"; \
  chmod +x sops;\
  # prefixout used in covaelnce for logging output of commands delivered
  wget -qO /tmp/prefixout_0.1.0_linux_amd64.zip "https://github.com/unifio/prefixout/releases/download/v0.1.0/prefixout_0.1.0_linux_amd64.zip" && \
  unzip -d /tmp/build /tmp/prefixout_0.1.0_linux_amd64.zip && \
  chmod +x /tmp/build/prefixout && \
  cp bin/gosu /usr/local/bin && \
  cp bin/dumb-init /usr/local/bin && \
  cp /tmp/build/sops /usr/local/bin/ && \
  cp /tmp/build/prefixout /usr/local/bin/ && \
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
