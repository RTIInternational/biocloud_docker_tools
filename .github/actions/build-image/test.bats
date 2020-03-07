#!/usr/bin/env bats

setup(){
  cat /dev/null >| mockCalledWith

  declare -A -p MOCK_RETURNS=(
  ['/usr/local/bin/docker']=""
  ) > mockReturns

  export GITHUB_REF='refs/heads/master'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export ORGANIZATION='my_org'
}

teardown() {
  unset INPUT_TAG_NAMES
  unset INPUT_SNAPSHOT
  unset INPUT_DOCKERFILE
  unset INPUT_REGISTRY
  unset INPUT_CACHE
  unset GITHUB_SHA
  unset INPUT_PULL_REQUESTS
  unset MOCK_ERROR_CONDITION
}

@test "it builds and pushes the Dockerimage with single Dockerfile in commit" {
    export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
    export INPUT_USERNAME=username
    export INPUT_PASSWORD=password

    run /entrypoint.sh

    expectStdOutContains "
    ::set-output name=tag::none_12169e"

    expectMockCalled "/usr/local/bin/docker build -t gwas/generate_gwas_plots:none_12169e .
    /usr/local/bin/docker push gwas/generate_gwas_plots:none_12169e"
}



function expectStdOutContains() {
  local expected=$(echo "${1}" | tr -d '\n')
  local got=$(echo "${output}" | tr -d '\n')
  echo "Expected: |${expected}|
  Got: |${got}|"
  echo "${got}" | grep "${expected}"
}

function expectMockCalled() {
  local expected=$(echo "${1}" | tr -d '\n')
  local got=$(cat mockCalledWith | tr -d '\n')
  echo "Expected: |${expected}|
  Got: |${got}|"
  echo "${got}" | grep "${expected}"
}
