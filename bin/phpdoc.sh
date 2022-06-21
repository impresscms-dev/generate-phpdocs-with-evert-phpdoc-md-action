#!/usr/bin/env bash

IGNORED_FILES=$1
PHPDOC_TAG=$2

GENERATOR_DOCKER_APP_ARGS="--target=/result --directory=/data --cache-folder=/tmp -v --template=xml --ansi --no-interaction --ignore=\"vendor/**\""
if [ "$IGNORED_FILES" != "" ]; then
  while read -r line
  do
    GENERATOR_DOCKER_APP_ARGS="$GENERATOR_DOCKER_APP_ARGS --ignore=\"$line\""
  done <<< "$IGNORED_FILES"
fi;

docker run \
  --rm \
  -v ${PWD}:/data \
  -v ${GENERATOR_TMP_FILES_PATH}:/result \
  phpdoc/phpdoc:$PHPDOC_TAG \
  $GENERATOR_DOCKER_APP_ARGS