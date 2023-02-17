#!/usr/bin/env bats

setup() {
    export TMP_DATA_PATH=$(mktemp -d)
    mkdir -p "$TMP_DATA_PATH/test"
}

tear() {
    rm -rf "$TMP_DATA_PATH" || true
}

@test "realpath.php returns a directory" {
    RET=$($BATS_TEST_DIRNAME/../bin/realpath.php "$TMP_DATA_PATH/test/../")
    [ -d "$RET" ]
}

@test "realpath.php returns correct realpath" {
    RET1=$($BATS_TEST_DIRNAME/../bin/realpath.php "$TMP_DATA_PATH/test/../")
    RET2=$(realpath "$TMP_DATA_PATH/test/../")
    [ "$RET1" == "$RET2" ]
}