#!/usr/bin/env bash
platform=''
tarOpt=''
tarArgs=''
ciScriptDebug=${CI_SCRIPT_DEBUG:-""}
unamestr=$(uname)
tf_version=${TERRAFORM_VERSION_TAG:-""}
tf_provider_version=${TERRAFORM_PROVIDER_VERSION_TAG:-""}
pkr_version=${PACKER_VERSION_TAG:-""}
tf_image=${TF_IMAGE:-'unifio/terraform'}
tf_provider_image=${TF_PROVIDER_IMAGE:-'whistle/terraform-providers'}
pkr_image=${pkr_image:-'unifio/packer'}
artifact_tool=${ARTIFACT_TOOL:-'WhistleLabs/promote-atlas-artifact'}
artifact_tool_version=${ARTIFACT_TOOL_VERSION:-'latest'}
circle_token=${CIRCLE_TOKEN:-""}
binaryToInstall=${1:-""}
if [[ ${binaryToInstall} ]]; then

  if [[ "$unamestr" == 'Linux' ]]; then
    platform='linux'
    tarOpt=''
    tarArgs="--wildcards --exclude=*zipinfo*"
  elif [[ "$unamestr" == 'Darwin' || "$unamestr" == 'FreeBSD' ]]; then
    platform='freebsd'
    tarOpt=''
    tarArgs=''
  fi
  if [[ $ciScriptDebug ]];then
    theArgs="-v $theArgs"
  fi

  read -r -d '' fileList << EOM
  ${tarOpt} /usr/bin/unzip        \
  ${tarOpt} /usr/include/node     \
  ${tarOpt} /usr/lib/node_modules \
  ${tarOpt} /usr/share/doc        \
  ${tarOpt} /usr/share/systemtap  \
  ${tarOpt} /usr/bin/node         \
  ${tarOpt} /usr/bin/npm          \
  ${tarOpt} /usr/bin/zip
EOM
  # Set Default values or check for environment variable override
  destDir=${CI_DEST_DIR:-"node_files"}
  containerName=${CI_CONTAINER_NAME:-"whistle-ci"}
  imageName=${CI_NODE_IMAGE_NAME:-"whistle/ci:node-7.5.0"}
  containerSuffix=${CI_CONTAINER_SUFFIX:-""}
  binaryFile=${CI_BINARY_FILE:-"node"}

  # If the node container
  if [[ "${binaryToInstall}" == "${binaryFile}" ]];then
    containerName="whistle-ci_${binaryFile}"
    # Run the node container, name it, and get binary version number.
    docker run --entrypoint "${binaryFile}" --name "${containerName}${containerSuffix}" \
            "${imageName}" --version 2>/dev/null
    # now verify that the container ran and echo its ID for reference
    matchingStarted=$(docker ps -lqa --filter="name=${containerName}${containerSuffix}" \
                  --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
    echo "Last container ran matching ${matchingStarted}"

    if [[ $matchingStarted ]]; then
      mkdir -p "${destDir}"
      docker cp "${containerName}${containerSuffix}":/ - | (cd "${destDir}" && tar -xp $tarArgs $fileList)
      tar czvf ./"${destDir}".tar.gz -C "${destDir}"/ usr/
      if tar tvzf ./"${destDir}".tar.gz | grep -q "\/bin\/${binaryFile}\$"; then
        echo "$binaryFile found in tarball ready for copy to container"
      else
        exit 1
      fi
    fi
  fi

  # now take care of the terraform files.
  if [[ $tf_version && $tf_image && "${binaryToInstall}" == "terraform" ]]; then
    echo "Running the ${binaryToInstall} container and naming it if it hasn't been already."
    containerName=terraform
    docker run --name "${containerName}" "${tf_image}":"${tf_version}" version 2>/dev/null
    # veirfy that the container ran and grab its ID
    matchingStarted=$(docker ps -lqa --filter="name=${containerName}${containerSuffix}" \
                --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
    echo "Terraform container ran ${matchingStarted}"
    if [[ $matchingStarted ]];then
      echo "Copying binaries.."
      docker cp ${containerName}:/usr/local/bin/ tf_files
    fi
  fi

  # now take care of the terraform provider files.
  if [[ $tf_provider_version && $tf_provider_image && "${binaryToInstall}" == "terraform-providers" ]]; then
    echo "Running the ${binaryToInstall} container and naming it if it hasn't been already."
    containerName=terraform-providers
    docker run --name "${containerName}" "${tf_provider_image}":"${tf_provider_version}" version 2>/dev/null
    # veirfy that the container ran and grab its ID
    matchingStarted=$(docker ps -lqa --filter="name=${containerName}${containerSuffix}" \
                --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
    echo "Terraform provider container ran ${matchingStarted}"
    if [[ $matchingStarted ]];then
      echo "Copying binaries.."
      docker cp ${containerName}:/usr/local/bin/terraform-providers/ tf_provider_files
    fi
  fi
  # now take care of the packer files
  if [[ $pkr_version && $pkr_image && "${binaryToInstall}" == "packer" ]]; then
    echo "Running the packer container and naming it if it hasn't been already."
    containerName=packer
    docker run --name "${containerName}" "${pkr_image}":"${pkr_version}" version 2>/dev/null
    # veirfy that the container ran and grab its ID
    matchingStarted=$(docker ps -lqa --filter="name=${containerName}${containerSuffix}" \
                --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
    echo "packer container ran ${matchingStarted}"
    if [[ $matchingStarted ]];then
      echo "Copying binaries.."
      docker cp ${containerName}:/usr/local/bin/ pkr_files
    fi
  fi

  # Include the promote artifact tool into container
  if [[ "${binaryToInstall}" == "promote-atlas-artifact" ]]; then
    [[ ! -d other_bins ]] && mkdir other_bins
    if [[ -n "$circle_token" ]]; then
        curl https://circleci.com/api/v1.1/project/github/${artifact_tool}/${artifact_tool_version}/artifacts?circle-token=$circle_token 2> /dev/null | grep -o 'https://[^"]*' | \
        while read bin; do
            bin_name=`basename $bin`
            echo "Downloading ${bin_name}"
            curl ${bin}?circle-token=$circle_token 2> /dev/null > other_bins/${bin_name}
            chmod 755 other_bins/${bin_name}
        done
    fi
  fi
else
  echo "No binary type specified for copy"
  exit 1
fi
