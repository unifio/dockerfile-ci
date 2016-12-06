FROM unifio/covalence:latest
MAINTAINER "Unif.io, Inc. <support@unif.io>"

RUN mkdir -p /tmp/build && \
    cd /tmp/build && \

    # Install PIP
    apk add --no-cache --update curl python-dev && \
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
