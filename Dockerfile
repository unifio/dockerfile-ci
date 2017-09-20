FROM unifio/covalence:latest
MAINTAINER "WhistleLabs, Inc. <devops@whistle.com>"

LABEL packer_version="1.0.0"
LABEL terraform_version="0.10.6"

RUN mkdir -p /tmp/build && \
    cd /tmp/build && \

    # Install glibc
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub "https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub" && \
    wget -q "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" && \
    apk add glibc-2.23-r3.apk && \

    # Install PIP
    apk add --no-cache --update curl curl-dev jq python-dev && \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \

    # Install AWS CLI
    pip install awscli && \

    # Install Misc. Ruby tools
    gem install awesome_print consul_loader thor --no-ri --no-rdoc && \

    # Cleanup
    cd /tmp && \
    rm -rf /tmp/build

COPY pkr_files/packer* /usr/local/bin/
COPY tf_files/terraform* /usr/local/bin/
COPY other_bins/* /usr/local/bin/
