# TODO - all security checking of downloaded binaries has been removed

FROM alpine:3.7 as build
MAINTAINER "WhistleLabs, Inc. <devops@whistle.com>"

RUN set -exv \
 && apk add --no-cache --update \
        ca-certificates curl unzip zsh \
 && :

WORKDIR /build
ENV PATH=$PATH:/build/bin

COPY install-zipped-bin ./bin/
RUN mkdir -pv terraform-providers

ARG PACKER_VERSION=1.1.0
ARG TERRAFORM_VERSION=0.12.0

# @hashicorp releases
RUN set -exv \
 && export uri_template='https://releases.hashicorp.com/${name}/${ver}/${name}_${ver}_${arch}.zip' \
 # packer & terraform
 && install-zipped-bin ./bin \
    packer:$PACKER_VERSION \
    terraform:$TERRAFORM_VERSION \
 # terraform providers
 && install-zipped-bin ./terraform-providers \
    terraform-provider-archive:1.2.2 \
    terraform-provider-github:2.1.0 \
    terraform-provider-google:2.7.0 \
    terraform-provider-newrelic:1.5.0 \
    terraform-provider-null:2.1.2 \
    terraform-provider-template:2.1.2 \
 && :

# @WhistleLabs github releases
RUN set -exv \
 && export uri_template='https://github.com/WhistleLabs/${name}/releases/download/v${full_ver}/${name}_${ver}_${arch}.zip' \
 # packer plugins
 && install-zipped-bin ./bin \
    packer-post-processor-vagrant-s3:0.0.1-whistle0 \
    packer-provisioner-serverspec:0.0.1-whistle0 \
 # terraform providers
 && install-zipped-bin ./terraform-providers \
    terraform-provider-aws:2.13.0-whistle0-tf012 \
    terraform-provider-cloudamqp:0.0.1-whistle0-tf012 \
    terraform-provider-datadog:1.9.0-whistle0-tf012 \
    terraform-provider-heroku:1.9.0-whistle0-tf012 \
    terraform-provider-logentries:1.0.0-whistle0-tf012 \
    terraform-provider-nrs:0.1.0-whistle1-tf012 \
    terraform-provider-pagerduty:1.2.1-whistle0-tf012 \
    terraform-provider-rabbitmq:1.0.0-whistle0-tf012 \
    terraform-provider-sentry:0.4.0-whistle1-tf012 \
 && :

FROM unifio/covalence:0.8.3
MAINTAINER "WhistleLabs, Inc. <devops@whistle.com>"

RUN set -exv \
 && apk add --no-cache --update \
        ca-certificates curl unzip zsh \
        fzf \
 && :
ENV SHELL=zsh

LABEL packer_version="${PACKER_VERSION}"
LABEL terraform_version="${TERRAFORM_VERSION}"

# Install glibc, PIP, AWS CLI and Misc. Ruby tools
# TODO - postgresql-client is hopefully temporary, see DEVOPS-1844
RUN mkdir -p /usr/local/bin && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" && \
    wget -q "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" && \
    apk update && \
    apk add glibc-2.23-r3.apk && \
    apk add postgresql-client && \
    apk add --no-cache --update curl curl-dev jq python-dev && \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip install awscli && \
    gem install awesome_print thor --no-document && \
    cd /tmp && \
    rm -rf /tmp/build

# Copy required binaries from previous build stages
COPY --from=build /build/bin/packer* /usr/local/bin/
COPY --from=build /build/bin/terraform /usr/local/bin/

# Provider dir needs write permissions by everyone in case additional providers need to be installed at runtime
# TODO Move these to ~/.teraform.d/plugins instead, avoiding all the magic required for this (and the 777)
COPY --from=build /build/terraform-providers/* /usr/local/bin/terraform-providers/linux_amd64/
RUN chmod 777 /usr/local/bin/terraform-providers/linux_amd64

# HACK We should likely just not base from the unifio image period
RUN set -exv \
 && cd /usr/local/bundle/gems \
 && rm -rf covalence-* \
 && git clone -b pr/terraform-012 \
    https://github.com/whistlelabs/covalence.git covalence-0.8.3 \
 && :

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

