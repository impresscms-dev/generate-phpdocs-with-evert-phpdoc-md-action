#!/usr/bin/env bats

setup() {
     export TMP_TEST_PATH_1=$(mktemp -d)
     export TMP_TEST_PATH_2=$(mktemp -d)
}

tear() {
    rm -rf "$TMP_TEST_PATH_1" || true
    rm -rf "$TMP_TEST_PATH_2" || true
}

@test "GENERATOR_TMP_FILES_PATH var exists" {
    eval $("$BATS_TEST_DIRNAME/../bin/generate-env.sh" "$TMP_TEST_PATH_1" "$TMP_TEST_PATH_2")
    [ ! -z "$GENERATOR_TMP_FILES_PATH" ];
}

@test "GENERATOR_DOCS_PATH var exists" {
    eval $("$BATS_TEST_DIRNAME/../bin/generate-env.sh" "$TMP_TEST_PATH_1" "$TMP_TEST_PATH_2")
    [ ! -z "$GENERATOR_DOCS_PATH" ];
}

@test "ACTION_BIN_PATH var exists" {
    eval $("$BATS_TEST_DIRNAME/../bin/generate-env.sh" "$TMP_TEST_PATH_1" "$TMP_TEST_PATH_2")
    [ ! -z "$ACTION_BIN_PATH" ];
}

@test "ACTION_BIN_PATH is correct" {
    eval $("$BATS_TEST_DIRNAME/../bin/generate-env.sh" "$TMP_TEST_PATH_1" "$TMP_TEST_PATH_2")
    NORMALIZED_PATH_1=$(realpath "$ACTION_BIN_PATH")
    NORMALIZED_PATH_2=$(realpath "$BATS_TEST_DIRNAME/../bin")

    [ "$NORMALIZED_PATH_1" == "$NORMALIZED_PATH_2" ];
}