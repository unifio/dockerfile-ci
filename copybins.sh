#!/usr/bin/env bash
platform=''
tarOpt=''
tarArgs=''
ciScriptDebug=${CI_SCRIPT_DEBUG:-""}
unamestr=$(uname)
tf_version=${TERRAFORM_VERSION_TAG:-""}
pkr_version=${PACKER_VERSION_TAG:-""}
tf_image=${TF_IMAGE:-'unifio/terraform'}
pkr_image=${pkr_image:-'unifio/packer'}
circle_token=${CIRCLE_TOKEN:-""}
binaryToInstall=${1:-""}
if [[ ${binaryToInstall} ]]; then

  # now take care of the terraform files.
  if [[ $tf_version && $tf_image && "${binaryToInstall}" == "terraform" ]]; then
    echo "Running the ${binaryToInstall} container and naming it if it hasn't been already."
    containerName=terraform
    docker run --name "${containerName}" "${tf_image}":"${tf_version}" version 2>/dev/null
    # verify that the container ran and grab its ID
    matchingStarted=$(docker ps -lqa --filter="name=${containerName}${containerSuffix}" \
                --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
    echo "Terraform container ran ${matchingStarted}"
    if [[ $matchingStarted ]];then
      echo "Copying binaries.."
      docker cp ${containerName}:/usr/local/bin/ tf_files
    fi
  fi

  # now take care of the packer files
  if [[ $pkr_version && $pkr_image && "${binaryToInstall}" == "packer" ]]; then
    echo "Running the packer container and naming it if it hasn't been already."
    containerName=packer
    docker run --name "${containerName}" "${pkr_image}":"${pkr_version}" version 2>/dev/null
    # verify that the container ran and grab its ID
    matchingStarted=$(docker ps -lqa --filter="name=${containerName}${containerSuffix}" \
                --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
    echo "packer container ran ${matchingStarted}"
    if [[ $matchingStarted ]];then
      echo "Copying binaries.."
      docker cp ${containerName}:/usr/local/bin/ pkr_files
    fi
  fi
else
  echo "No binary type specified for copy"
  exit 1
fi
