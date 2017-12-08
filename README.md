# Unif.io CI Dockerfile
[![CircleCI](https://circleci.com/gh/unifio/dockerfile-ci.svg?style=svg)](https://circleci.com/gh/unifio/dockerfile-ci)

Update the global environment variables from the [.circleci/config.xml](./.circleci/config.xml) file to configure tool versions and Docker image registries.

```
  environment:
    CI_MAJOR_VERSION: 2
    COVALENCE_REGISTRY: 'unifio/covalence'
    COVALENCE_VERSION: 0.7.6
    PACKER_REGISTRY: 'unifio/packer'
    PACKER_VERSION: 1.1.2
    TERRAFORM_REGISTRY: 'unifio/terraform'
    TERRAFORM_VERSION: 0.10.8
```

To build locally with the latest binaries in the CI container first initialize all the binaries:

```
PACKER_VERSION=1.1.2 docker-compose packer
TERRAFORM_VERSION=0.10.8 docker-compose terraform
./copybins.sh
```

Then build:

```
COVALENCE_VERSION=0.7.6 PACKER_VERSION=1.1.2 TERRAFORM_VERSION=0.10.8 docker-compose build
```
