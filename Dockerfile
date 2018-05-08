# TODO - all security checking of downloaded binaries has been removed

FROM alpine:3.5 as packer
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
    wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS" && \
    wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS.sig" && \
    unzip -d /usr/local/bin packer_${PACKER_VERSION}_linux_amd64.zip && \
    cd /tmp && \
    rm -rf /tmp/build

FROM alpine:3.5 as terraform
LABEL maintainer="WhistleLabs, Inc. <devops@whistle.com>"
ENV TERRAFORM_VERSION 0.10.7

RUN apk add --no-cache --update ca-certificates gnupg openssl wget unzip && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" && \
    unzip -d /usr/local/bin terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    cd /tmp && \
    rm -rf /tmp/build

FROM alpine:3.7 as provider
LABEL maintainer="WhistleLabs, Inc. <devops@whistle.com>"

# Loop through the list of providers that we want to include
RUN apk add --no-cache --update ca-certificates gnupg openssl git mercurial wget unzip && \
    mkdir -p /usr/local/bin/terraform-providers && \
    for provider in \
    aws:0.1.4 \
    aws:1.10.0 \
    consul:0.1.0 \
    datadog:0.1.1 \
    github:0.1.1 \
    google:0.1.3 \
    heroku:0.1.0 \
    logentries:0.1.0 \
    newrelic:0.1.1 \
    pagerduty:0.1.2 \
    rabbitmq:0.2.0 \
    template:1.0.0; do \
        prov_name=`echo $provider | cut -d: -f1` && \
        prov_ver=`echo $provider | cut -d: -f2` && \
        echo "Installing provider ${prov_name} version ${prov_ver}" && \
        mkdir -p /tmp/build && \
        cd /tmp/build && \
        wget -q "https://releases.hashicorp.com/terraform-provider-${prov_name}/${prov_ver}/terraform-provider-${prov_name}_${prov_ver}_linux_amd64.zip" && \
        wget -q "https://releases.hashicorp.com/terraform-provider-${prov_name}/${prov_ver}/terraform-provider-${prov_name}_${prov_ver}_SHA256SUMS" && \
        wget -q "https://releases.hashicorp.com/terraform-provider-${prov_name}/${prov_ver}/terraform-provider-${prov_name}_${prov_ver}_SHA256SUMS.sig" && \
        unzip -d /usr/local/bin/terraform-providers terraform-provider-${prov_name}_${prov_ver}_linux_amd64.zip && \
        ls -l /usr/local/bin/terraform-providers && \
        cd /tmp && \
        rm -rf /tmp/build \
    ; done

# Install 3rd party providers - eventually these should come from https://registry.terraform.io/
# See https://github.com/hashicorp/terraform/issues/17154
# and
# https://www.terraform.io/docs/configuration/providers.html#third-party-plugins
# and
# https://github.com/WhistleLabs/terraform-provider-cloudamqp
RUN mkdir -p /aws/.terraform.d/plugins && \
    for provider_url in \
    https://github.com/WhistleLabs/dockerfile-terraform-providers/files/1908683/terraform-provider-cloudamqp.zip; do \
        echo "Installing 3rd party provider from ${provider_url}" && \
        mkdir -p /tmp/build && \
        cd /tmp/build && \
        wget -q "${provider_url}" && \
        unzip -d /aws/.terraform.d/plugins terraform-provider-*.zip && \
        ls -l /aws/.terraform.d/plugins && \
        cd /tmp && \
        rm -rf /tmp/build \
    ; done

FROM unifio/covalence:0.7.6
LABEL maintainer="WhistleLabs, Inc. <devops@whistle.com>"

LABEL packer_version="1.0.0"
LABEL terraform_version="0.10.7"

# Install glibc, PIP, AWS CLI and Misc. Ruby tools
# TODO - postgresql-client is hopefully temporary, see DEVOPS-1844
RUN mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub "https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub" && \
    wget -q "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" && \
    apk update && \
    apk add glibc-2.23-r3.apk && \
    apk add postgresql-client && \
    apk add --no-cache --update curl curl-dev jq python-dev && \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip install awscli && \
    gem install awesome_print consul_loader terraform_landscape thor --no-ri --no-rdoc && \
    cd /tmp && \
    rm -rf /tmp/build

# Copy required binaries from previous build stages
COPY --from=packer /usr/local/bin/packer* /usr/local/bin
COPY --from=terraform /usr/local/bin/terraform* /usr/local/bin
COPY --from=provider /usr/local/bin/terraform-providers/ /usr/local/bin/terraform-providers/linux_amd64
# This assumes that /aws will be the HOME directory
COPY --from=provider /aws/.terraform.d/plugins/ /aws/.terraform.d/plugins

# Provider dir needs write permissions by everyone in case additional providers need to be installed at runtime
RUN chmod 777 /usr/local/bin/terraform-providers/linux_amd64
RUN chmod 777 /aws/.terraform.d/plugins
