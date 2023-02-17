#!/usr/bin/env bats

setup() {
     export TMP_TEST_PATH=$(mktemp -d)
     export GENERATOR_TMP_FILES_PATH=$(mktemp -d)
     export IGNORED_FILES=""
     export PHPDOC_TAG=latest

     pushd $TMP_TEST_PATH
         git clone --quiet https://github.com/imponeer/toarray-interface.git .
         git config --local advice.detachedHead false
         git checkout 1.0.0
     popd
}

tear() {
    rm -rf "$TMP_TEST_PATH" || true
    rm -rf "$GENERATOR_TMP_FILES_PATH" || true
}

@test "docker is available" {
    command -v docker
}

@test "runs correctly" {
    EXIT_CODE=0
    pushd $TMP_TEST_PATH
        "$BATS_TEST_DIRNAME/../bin/phpdoc.sh" "$IGNORED_FILES" "$PHPDOC_TAG"
        EXIT_CODE=$?
    popd

    [ "$EXIT_CODE" == "0" ]
}

@test "produce some results" {
    pushd $TMP_TEST_PATH
        "$BATS_TEST_DIRNAME/../bin/phpdoc.sh" "$IGNORED_FILES" "$PHPDOC_TAG"
    popd

    [ -s "$GENERATOR_TMP_FILES_PATH" ]
}