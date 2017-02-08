#!/usr/bin/env bash
platform=''
tarOpt=''
tarArgs=''
unamestr=$(uname)
ciScriptDebug=${CI_SCRIPT_DEBUG:-""}
#unamestr="Linux"
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
${tarOpt} /usr/bin/zip
EOM
# Set Default values or check for environment variable override
destDir=${CI_DEST_DIR:-"node_files"}
containerName=${CI_CONTAINER_NAME:-"unifio-ci"}
imageName=${CI_IMAGE_NAME:-"unifio/ci:node-2.0.0"}
containerSuffix=${CI_CONTAINER_SUFFIX:-""}
binaryFile=${CI_BINARY_FILE:-"node"}
# Run the container, name it, and get binary version number.
docker run --entrypoint "${binaryFile}" --name "${containerName}" \
        "${imageName}" --version 2>/dev/null
# now verify that the container ran and echo its ID for reference
matchingStarted=$(docker ps -lqa --filter="name=${containerName}" \
              --format="{{.Names}},{{.ID}},{{.Image}},{{.Command}}")
echo "Last container ran matching ${matchingStarted}"

if [[ $matchingStarted ]]; then
  docker cp "${containerName}":/ - | (cd "${destDir}" && tar -xp $tarArgs $fileList)
  tar czvf ./"${destDir}".tar.gz -C "${destDir}"/ usr/
  if tar tvzf ./"${destDir}".tar.gz | grep -q "\/bin\/${binaryFile}\$"; then
    echo "$binaryFile found in tarball ready for copy to container"
  fi
fi
