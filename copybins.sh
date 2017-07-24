#!/usr/bin/env bash
platform=''
tarOpt=''
tarArgs=''
ciScriptDebug=${CI_SCRIPT_DEBUG:-""}
unamestr=$(uname)
tf_version=${TERRAFORM_VERSION_TAG:-""}
pkr_version=${PACKER_VERSION_TAG:-""}
tf_image=${TF_IMAGE:-'unifio/terraform'}
pkr_image=${PKR_IMAGE:-'unifio/packer'}
artifact_tool=${ARTIFACT_TOOL:-'unifio/promote-atlas-artifact'}
artifact_tool_version=${ARTIFACT_TOOL_VERSION:-'latest'}
circle_token=${CIRCLE_TOKEN:-""}

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
containerName=${CI_CONTAINER_NAME:-"unifio-ci"}
imageName=${CI_NODE_IMAGE_NAME:-"unifio/ci:node-2.0.0"}
containerSuffix=${CI_CONTAINER_SUFFIX:-""}
binaryFile=${CI_BINARY_FILE:-"node"}
# Run the container, name it, and get binary version number.
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
  fi
fi

# now take care of the terraform files.
if [[ $tf_version && $tf_image ]]; then
  echo "Running the terraform container and naming it if it hasn't been already."
  docker run --name terraform "${tf_image}":"${tf_version}" version 2>/dev/null
  # veirfy that the container ran and grab its ID
  matchingStarted=$(docker ps -lqa --filter="name=terraform${containerSuffix}" \
              --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
  echo "Terraform container ran ${matchingStarted}"
  if [[ $matchingStarted ]];then
    echo "Copying binaries.."
    docker cp terraform:/usr/local/bin/ tf_files
  fi
fi
# now take care of the packer files
if [[ $pkr_version && $pkr_image ]]; then
  echo "Running the packer container and naming it if it hasn't been already."
  docker run --name packer "${pkr_image}":"${pkr_version}" version 2>/dev/null
  # veirfy that the container ran and grab its ID
  matchingStarted=$(docker ps -lqa --filter="name=packer${containerSuffix}" \
              --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
  echo "packer container ran ${matchingStarted}"
  if [[ $matchingStarted ]];then
    echo "Copying binaries.."
    docker cp packer:/usr/local/bin/ pkr_files
  fi
fi

# Include the promote artifact tool into container
if [[ -z "$circle_token" ]]; then
    curl https://circleci.com/api/v1.1/project/github/${artifact_tool}/${artifact_tool_version}/artifacts?circle-token=$circle_token | grep -o 'https://[^"]*' | \
    while read bin; do
        bin_name=`basename $bin`
        curl ${bin}?circle-token=$circle_token > /usr/local/bin/${bin_name}
        chmod 755 /usr/local/bin/${bin_name}
    done
fi
