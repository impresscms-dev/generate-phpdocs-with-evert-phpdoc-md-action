#!/usr/bin/env bats

@test "composer.json exists" {
    [ -f "$BATS_TEST_DIRNAME/../composer.json" ]
}

@test "get-composer-dependencies.php runs (without args)" {
    $BATS_TEST_DIRNAME/../bin/get-composer-dependencies.php
}

@test "get-composer-dependencies.php returns output (without args)" {
    RET=$($BATS_TEST_DIRNAME/../bin/get-composer-dependencies.php)
    [ ! -z "$RET" ]
}

@test "get-composer-dependencies.php runs (with versions)" {
    $BATS_TEST_DIRNAME/../bin/get-composer-dependencies.php 1
}

@test "get-composer-dependencies.php returns output (with versions)" {
    RET=$($BATS_TEST_DIRNAME/../bin/get-composer-dependencies.php 1)
    [ ! -z "$RET" ]
}

@test "get-composer-dependencies.php runs (without versions)" {
    $BATS_TEST_DIRNAME/../bin/get-composer-dependencies.php 0
}

@test "get-composer-dependencies.php returns output (without versions)" {
    RET=$($BATS_TEST_DIRNAME/../bin/get-composer-dependencies.php 0)
    [ ! -z "$RET" ]
}