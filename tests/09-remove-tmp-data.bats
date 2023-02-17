setup() {
    export GENERATOR_TMP_FILES_PATH=$(mktemp -d)
}

tear() {
    rm -rf "$GENERATOR_TMP_FILES_PATH" || true
}

@test "GENERATOR_TMP_FILES_PATH not exists" {
    "$BATS_TEST_DIRNAME/../bin/remove-tmp-data.sh"

    [ ! -d "$GENERATOR_TMP_FILES_PATH" ];
}