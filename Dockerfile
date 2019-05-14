# TODO - all security checking of downloaded binaries has been removed

FROM alpine:3.7 as packer
LABEL maintainer="WhistleLabs, Inc. <devops@whistle.com>"
ENV PACKER_VERSION 1.1.0

RUN apk add --no-cache --update ca-certificates gnupg openssl wget unzip && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget -q "https://circle-artifacts.com/gh/unifio/packer-post-processor-vagrant-s3/22/artifacts/0/home/ubuntu/.go_workspace/bin/packer-post-processor-vagrant-s3" && \
    wget -q "https://circle-artifacts.com/gh/unifio/packer-provisioner-serverspec/26/artifacts/0/home/ubuntu/.go_workspace/bin/packer-provisioner-serverspec" && \
    chmod +x packer-post-processor-vagrant-s3 packer-provisioner-serverspec && \
    mv packer-post-processor-vagrant-s3 packer-provisioner-serverspec /usr/local/bin && \
    wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" && \
    unzip -d /usr/local/bin packer_${PACKER_VERSION}_linux_amd64.zip && \
    cd /tmp && \
    rm -rf /tmp/build

FROM alpine:3.7 as terraform
LABEL maintainer="WhistleLabs, Inc. <devops@whistle.com>"
ENV TERRAFORM_VERSION 0.12.0-beta2

RUN apk add --no-cache --update ca-certificates gnupg openssl wget unzip && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip -d /usr/local/bin terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    cd /tmp && \
    rm -rf /tmp/build

FROM alpine:3.7 as terraform_providers
LABEL maintainer="WhistleLabs, Inc. <devops@whistle.com>"

RUN apk add --no-cache --update ca-certificates gnupg openssl unzip bash curl

WORKDIR /tmp/build
COPY install-tf-provider /usr/local/bin/

# Loop through the list of providers that we want to include
RUN set -exv \
 && install-tf-provider \
        archive:1.2.2 \
        aws:2.10.0 \
        github:2.0.0 \
        google:2.5.1 \
        newrelic:1.5.0 \
        null:2.1.2 \
        template:2.1.2 \
 && :

# Install 3rd party providers forked from open source - eventually these should come from https://registry.terraform.io/
# See https://github.com/hashicorp/terraform/issues/17154
# and
# https://www.terraform.io/docs/configuration/providers.html#third-party-plugins

# Loop through the list of providers that we want to include
RUN set -exv \
 && export uri_template='https://github.com/WhistleLabs/terraform-provider-${name}/releases/download/v${full_ver}/terraform-provider-${name}_${ver}_${arch}.zip' \
 && install-tf-provider \
    atlas:0.1.0-whistle0-tf012 \
    cloudamqp:0.0.1-whistle0-tf012 \
    datadog:1.9.0-whistle0-tf012 \
    heroku:1.9.0-whistle0-tf012 \
    logentries:1.0.0-whistle0-tf012 \
    nrs:0.1.0-whistle0-tf012 \
    pagerduty:1.2.1-whistle0-tf012 \
    rabbitmq:1.0.0-whistle0-tf012 \
    sentry:0.4.0-whistle0-tf012 \
 && :

FROM unifio/covalence:0.8.3
LABEL maintainer="WhistleLabs, Inc. <devops@whistle.com>"

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
COPY --from=packer /usr/local/bin/packer* /usr/local/bin/
COPY --from=terraform /usr/local/bin/terraform* /usr/local/bin
COPY --from=terraform_providers /usr/local/bin/terraform-providers/ /usr/local/bin/terraform-providers/linux_amd64

# Provider dir needs write permissions by everyone in case additional providers need to be installed at runtime
RUN chmod 777 /usr/local/bin/terraform-providers/linux_amd64

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

