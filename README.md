# Unif.io CI Dockerfile
[![CircleCI](https://circleci.com/gh/unifio/dockerfile-ci.svg?style=svg)](https://circleci.com/gh/unifio/dockerfile-ci)

To build with the latest packer/terraform/node binaries in the CI container first initialize all the binaries:

```
PACKER_VERSION_TAG=latest TERRAFORM_VERSION_TAG=latest CI_DEST_DIR=node_files CI_CONTAINER_NAME=unifio-ci CI_NODE_IMAGE_NAME='unifio/ci:node-2.0.0' CI_SCRIPT_DEBUG=1 TF_IMAGE='unifio/terraform' PKR_IMAGE='unifio/packer' ./copybins.sh
```

Then build:

```
docker build -t unifio/ci .
```

Then test container has all the latest binaries.

```
docker run --entrypoint /bin/sh unifio/ci -c "gem list | grep covalence"
docker run --entrypoint /bin/sh unifio/ci -c "aws --version"
docker run -e CHECKPOINT_DISABLE=1 --entrypoint /bin/sh unifio/ci -c "packer version"
docker run -e CHECKPOINT_DISABLE=1 --entrypoint /bin/sh unifio/ci -c "terraform version"
docker run --entrypoint /bin/sh unifio/ci -c "node --version"
docker run --entrypoint /bin/sh unifio/ci -c "npm --version"
```
