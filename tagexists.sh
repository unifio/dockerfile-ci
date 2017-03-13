#!/usr/bin/env bash

dockerRepo=${DOCKER_REPO:-$1}
dockerRegistry=${DOCKER_REGISTRY:-docker.io}
jsonParser=$(which jq)
tagWanted=${DOCKER_BIN_TAG:-"node-2.0.0"}
#
#  Docker funcs
#
dkrRelativeRepoName() {
  # given $dockerRegistry/repo/path:tag, return the repo/path
  set +o pipefail
  echo ${1-} | sed -e "s|^$dockerRegistry/||" | cut -d: -f1
}

dkrSortVersions() {
  # read stdin, sort by version number descending, and write stdout
  # assumes X.Y.Z version numbers

  # this will sort tags like pr-3001, pr-3002 to the END of the list
  # and tags like 2.1.4 BEFORE 2.1.4-gitsha

  sort -s -t- -k 2,2nr |  sort -t. -s -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr
}

dkrBasicAuth() {
  #
  # read basic auth credentials from `docker login`
  #
  cat "${HOME}"/.docker/config.json | ${jsonParser} -r '.auths["https://index.docker.io/v1/"].auth'
}


dkrRegistryTagsList() {
  # return a list of available tags for the given repository sorted
  # by version number, descending
  #
  # Get tags list from dockerhub using v2 api and an auth.docker token
  local rel_repository
  local TOKEN
  local allTags
  rel_repository=$(dkrRelativeRepoName "${1}")
  [ -z "$rel_repository" ] && return
  TOKEN=$(curl -s -H "Authorization: Basic $(dkrBasicAuth)" \
                  -H 'Accept: application/json' \
                  "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$rel_repository:pull" | ${jsonParser} -r .token)
  allTags=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
          "https://index.docker.io/v2/$rel_repository/tags/list" |
          ${jsonParser} -cS '.tags? | .[]?')
  echo "$allTags"
}


matchingTag=$(dkrRegistryTagsList "$dockerRepo" | grep -o \""${tagWanted}"\" | sed 's/"//g')
if [ "${matchingTag}" ]; then
  echo 1
else
  echo 0
fi
