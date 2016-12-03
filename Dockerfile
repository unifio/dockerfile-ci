FROM unifio/covalence:latest
MAINTAINER "Unif.io, Inc. <support@unif.io>"

COPY pkr_files/packer* /usr/local/bin/
COPY tf_files/terraform* /usr/local/bin/
