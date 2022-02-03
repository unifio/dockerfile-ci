ARG alpine_version
FROM alpine:${alpine_version}
LABEL maintainer="Unif.io, Inc. <support@unif.io>"

ARG terraform_version
ENV TERRAFORM_VERSION $terraform_version
ENV HASHI_KEY_URL https://rpm.releases.hashicorp.com/gpg

# This is the release of https://github.com/hashicorp/docker-base to pull in order
# to provide HashiCorp-built versions of basic utilities like dumb-init and gosu.
ENV DOCKER_BASE_VERSION=0.0.4

RUN set -ex; \
  apk add --no-cache --update build-base ca-certificates curl gnupg openssl && \
      ruby-dev unzip wget tini su-exec libffi-dev && \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  \
  wget -O - $HASHI_KEY_URL | gpg --import; \
  wget -O - https://keybase.io/hashicorp/pgp_keys.asc | gpg --import; \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip" && \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS" && \
  wget -q "https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig" && \
  gpg --batch --verify docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS && \
  grep docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS | sha256sum -c && \
  unzip docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip && \
  cp bin/gosu /usr/local/bin && \
  \
  wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
  wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
  wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" && \
  gpg --batch --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
  grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c && \
  unzip -d /usr/local/bin terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  \
  wget -q -O /etc/apk/keys/sgerrand.rsa.pub "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" && \
  wget -q "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" && \
  apk add --no-cache --update glibc-2.23-r3.apk && \
  \
  cd / && \
  rm -rf /tmp/build && \
  rm -rf /root/.gnupg

COPY entrypoint.sh /usr/local/bin/

VOLUME ["/data"]
WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["--help"]
