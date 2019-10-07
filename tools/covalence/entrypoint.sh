#!/bin/sh

## Defaulting to root user (UID 0) to maintain backwards compatibility
USER_ID=${LOCAL_USER_ID:-0}

function installProviders()
{
  local tfHomeDir providerDir
  tfHomeDir="${1}"
  providerDir="${2}"
  if [ -d "$providerDir" ]; then
    [ "$DEBUG" == true ] && echo "Copying third party plugins from .terraform.d/plugins to ${tfHomeDir}/.terraform.d/plugins"
    mkdir -p "${tfHomeDir}"/.terraform.d/plugins && \
    cp -p "${providerDir}"/terraform-* "${tfHomeDir}"/.terraform.d/plugins/ && \
    chmod -R a+rx "${tfHomeDir}"/.terraform.d
  else
    echo "$providerDir does not exist. No thirdparty providers installed."
  fi
}
if [ "$TEST_MODE" == true ]; then
  echo "Holding the container process for testing"
  sleep 60
fi
if [ "$DEBUG" == true ] ; then
  echo "Starting with UID: $USER_ID"
fi
if [ "$USER_ID" -ne "0" ]; then
  adduser -s /bin/sh -D -u $USER_ID user
  export HOME=/home/user
  [ ! -z "$TF_TP_PROVIDER_DIR" ] && installProviders /home/user "${TF_TP_PROVIDER_DIR}"
  exec /usr/local/bin/dumb-init /usr/local/bin/gosu user "$@"
else
[ ! -z "$TF_TP_PROVIDER_DIR" ] && installProviders "${HOME}" "${TF_TP_PROVIDER_DIR}"
  exec /usr/local/bin/dumb-init "$@"
fi
