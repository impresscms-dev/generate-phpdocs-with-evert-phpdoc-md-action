#!/usr/bin/env bats

setup_file() {
    export TMP_DATA_PATH=$(mktemp -d)
    export GENERATOR_DOCS_PATH=$TMP_DATA_PATH/docs
    export GENERATOR_TMP_FILES_PATH=$TMP_DATA_PATH/files
}

tear_file() {
    rm -rf "$TMP_DATA_PATH" || true
}

@test "GENERATOR_DOCS_PATH exists" {
    "$BATS_TEST_DIRNAME/../bin/create-paths.sh"
    [ -d "$GENERATOR_DOCS_PATH" ];
}

@test "GENERATOR_TMP_FILES_PATH exists" {
    "$BATS_TEST_DIRNAME/../bin/create-paths.sh"
    [ -d "$GENERATOR_TMP_FILES_PATH" ];
}