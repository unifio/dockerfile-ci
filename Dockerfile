FROM unifio/covalence:latest
MAINTAINER "Unif.io, Inc. <support@unif.io>"

RUN gem install awesome_print consul_loader thor --no-ri --no-rdoc

COPY pkr_files/packer* /usr/local/bin/
COPY tf_files/terraform* /usr/local/bin/
