# Unif.io CI Dockerfile
[![CircleCI](https://circleci.com/gh/unifio/dockerfile-ci.svg?style=svg)](https://circleci.com/gh/unifio/dockerfile-ci)

Update the global environment variables from the [.circleci/config.xml](./.circleci/config.xml) file to configure tool versions and Docker image registries.

```
  environment:
      ALPINE_VERSION: '3.10'
      CI_REGISTRY: 'unifio/ci'
      CI_MAJOR_VERSION: '4'
      COVALENCE_REGISTRY: 'unifio/covalence'
      COVALENCE_VERSION: '0.9.9'
      DUMBINIT_VERSION: '1.2.2'
      GOSU_VERSION: '1.12'
      NODE_VERSION: '10.16.1'
      PACKER_REGISTRY: 'unifio/packer'
      PACKER_VERSION: '1.6.3'
      RUBY_VERSION: '2.5.5'
      SOPS_VERSION: '3.6.0'
      TERRAFORM_REGISTRY: 'unifio/terraform'
      TERRAFORM_VERSION: '0.12.29'
```

To build locally with the latest binaries in the CI container first initialize all the binaries:

```
PACKER_VERSION=1.6.3  docker-compose build packer
TERRAFORM_VERSION=0.10.8 docker-compose build terraform
./copybins.sh
```
Then build:

```
COVALENCE_VERSION=0.9.9 PACKER_VERSION=1.6.3 TERRAFORM_VERSION=0.12.29 docker-compose build
```
