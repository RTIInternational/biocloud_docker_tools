#!/bin/bash
set -e

function main() {
    echo "" # see https://github.com/actions/toolkit/issues/168
    cd /github/workspace

    sanitize "${INPUT_USERNAME}" "username"
    sanitize "${INPUT_PASSWORD}" "password"
    sanitize "${INPUT_ORGANIZATION}" "organization"
    sanitize "${INPUT_CHANGED_FILES}" "changed_files"

    # CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r ${GITHUB_SHA}) # dfe37af2c9a8c753fcd6392ea2f5e711a04b38e1
    CHANGED_FILES="${INPUT_CHANGED_FILES}"

    # Can only build 1 Docker image in 1 actions run/commit
    if [[ $(echo $CHANGED_FILES | tr " " "\n" | grep -c "Dockerfile") -gt 1 ]]; then
        echo "Only one changed Dockerfile is allowed per commit."
        exit 1
    fi

    # Only changes to 1 Docker image directory allowed per commit
    BASE_DIR_ARR=()
    for FILE in ${CHANGED_FILES}
    do
        IFS='/'; arrFILE=($FILE); unset IFS;
        BASE_DIR_ARR+=(${arrFILE[0]})
    done
    UNIQUE_DIRS=($(echo "${BASE_DIR_ARR[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    if [[ ${#UNIQUE_DIRS[@]} -gt 1 ]]; then
        echo "Only 1 Docker image directory allowed per commit"
        exit 1
    fi

    CFS_arr=($(echo "$CHANGED_FILES" | tr " " "\n"))
    FIRST_FILE=${CFS_arr[0]}

    IFS='/'; arrFILE=($FIRST_FILE); unset IFS;
    if [[ ${#arrFILE[@]} -eq 3 ]]; then
        REGISTRY_NO_PROTOCOL=${arrFILE[0]}
        SOFTWARE_VERSION=${arrFILE[1]}
        INPUT_WORKDIR=${arrFILE[0]}/${arrFILE[1]}
    fi
    if [[ ${#arrFILE[@]} -eq 2 ]]; then
        REGISTRY_NO_PROTOCOL=${arrFILE[0]}
        SOFTWARE_VERSION="none"
        INPUT_WORKDIR=${arrFILE[0]}
    fi
    if [[ ${#arrFILE[@]} -eq 1 ]]; then
        echo "File is not in a directory."
        exit 0
    fi
    if [[ ${#arrFILE[@]} -eq 0 ]]; then
        echo "No changed files found."
        exit 0
    fi

    # INPUT_REGISTRY="${ORGANIZATION}/${REGISTRY_NO_PROTOCOL}"
    # INPUT_NAME="${INPUT_REGISTRY}"
    INPUT_NAME="${INPUT_ORGANIZATION}/${REGISTRY_NO_PROTOCOL}"

    if uses "${INPUT_WORKDIR}"; then
        changeWorkingDirectory
    fi

    # echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}
    echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin

    SHA_TAG="${SOFTWARE_VERSION}"_$(echo "${GITHUB_SHA}" | cut -c1-7)

    TAGS=("${SHA_TAG}")
    FIRST_TAG=$(echo $TAGS | cut -d ' ' -f1)
    DOCKERNAME="${INPUT_NAME}:${FIRST_TAG}"
    BUILDPARAMS=""
    CONTEXT="."

    # if uses "${INPUT_DOCKERFILE}"; then
    #     useCustomDockerfile
    # fi
    # if uses "${INPUT_BUILDARGS}"; then
    #     addBuildArgs
    # fi
    # if uses "${INPUT_CONTEXT}"; then
    #     CONTEXT="${INPUT_CONTEXT}"
    # fi
    # if usesBoolean "${INPUT_CACHE}"; then
    #     useBuildCache
    # fi
    # if usesBoolean "${INPUT_SNAPSHOT}"; then
    #     useSnapshot
    # fi

    push

    echo "tag=${FIRST_TAG}" >> ${GITHUB_OUTPUT}
    DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${DOCKERNAME})
    echo "digest=${DIGEST}" >> ${GITHUB_OUTPUT}
    docker logout
}

function sanitize() {
    if [ -z "${1}" ]; then
        >&2 echo "Unable to find the ${2}. Did you set with.${2}?"
        exit 1
    fi
}

# function isPartOfTheName() {
#   [ $(echo "${INPUT_NAME}" | sed -e "s/${1}//g") != "${INPUT_NAME}" ]
# }


# function hasCustomTag() {
#   [ $(echo "${INPUT_NAME}" | sed -e "s/://g") != "${INPUT_NAME}" ]
# }

# function isOnMaster() {
#   [ "${BRANCH}" = "master" ]
# }

# function isGitTag() {
#   [ $(echo "${GITHUB_REF}" | sed -e "s/refs\/tags\///g") != "${GITHUB_REF}" ]
# }

# function isPullRequest() {
#   [ $(echo "${GITHUB_REF}" | sed -e "s/refs\/pull\///g") != "${GITHUB_REF}" ]
# }

function changeWorkingDirectory() {
    cd "${INPUT_WORKDIR}"
}

# function useCustomDockerfile() {
#   BUILDPARAMS="${BUILDPARAMS} -f ${INPUT_DOCKERFILE}"
# }

# function addBuildArgs() {
#   for ARG in $(echo "${INPUT_BUILDARGS}" | tr ',' '\n'); do
#     BUILDPARAMS="${BUILDPARAMS} --build-arg ${ARG}"
#     echo "::add-mask::${ARG}"
#   done
# }

# function useBuildCache() {
#   if docker pull ${DOCKERNAME} 2>/dev/null; then
#     BUILDPARAMS="$BUILDPARAMS --cache-from ${DOCKERNAME}"
#   fi
# }

function uses() {
    [ ! -z "${1}" ]
}

# function usesBoolean() {
#   [ ! -z "${1}" ] && [ "${1}" = "true" ]
# }

# function useSnapshot() {
#   local TIMESTAMP=`date +%Y%m%d%H%M%S`
#   local SHORT_SHA=$(echo "${GITHUB_SHA}" | cut -c1-6)
#   local SNAPSHOT_TAG="${TIMESTAMP}${SHORT_SHA}"
#   TAGS="${TAGS} ${SNAPSHOT_TAG}"
#   echo "snapshot-tag=${SNAPSHOT_TAG}" >> ${GITHUB_OUTPUT}
# }

function push() {
    local BUILD_TAGS=""
    for TAG in ${TAGS}
    do
        BUILD_TAGS="${BUILD_TAGS}-t ${INPUT_NAME}:${TAG} "
    done
    # docker build ${INPUT_BUILDOPTIONS} ${BUILDPARAMS} ${BUILD_TAGS} ${CONTEXT}
    docker build  ${BUILDPARAMS} ${BUILD_TAGS} ${CONTEXT}

    for TAG in ${TAGS}
    do
        docker push "${INPUT_NAME}:${TAG}"
    done
}

main
