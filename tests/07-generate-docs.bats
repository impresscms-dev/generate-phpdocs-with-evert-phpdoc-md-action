#!/usr/bin/env bats

setup_file() {
    export COMPOSER_GLOBAL_JSON_PATH=$(composer config data-dir)/composer.json
    export BACKUP_PATH=$(mktemp -d)
    export BACKUP_COMPOSER=$BACKUP_PATH/composer.json
    export TMP_TEST_PATH=$(mktemp -d)
    export GENERATOR_TMP_FILES_PATH=$(mktemp -d)
    export GENERATOR_DOCS_PATH=$(mktemp -d)
    export IGNORED_FILES=""
    export PHPDOC_TAG=latest

    if [ -f "$COMPOSER_GLOBAL_JSON_PATH" ]; then
        cp "$COMPOSER_GLOBAL_JSON_PATH" "$BACKUP_COMPOSER"
    fi;

    pushd $TMP_TEST_PATH
        "$BATS_TEST_DIRNAME/../bin/phpdoc.sh" "$IGNORED_FILES" "$PHPDOC_TAG"
    popd

    $BATS_TEST_DIRNAME/../bin/add-composer-packages.sh
}

tear_file() {
    rm -rf "$COMPOSER_GLOBAL_JSON_PATH"

    if [ -f "$BACKUP_COMPOSER" ]; then
        cp "$BACKUP_COMPOSER" "$COMPOSER_GLOBAL_JSON_PATH"
    fi;

    rm -rf "$BACKUP_PATH" || true

    composer global install -q || true

    rm -rf "$TMP_TEST_PATH" || true
    rm -rf "$GENERATOR_TMP_FILES_PATH" || true
    rm -rf "$GENERATOR_DOCS_PATH" || true
}

@test "Runs correctly" {
    $BATS_TEST_DIRNAME/../bin/generate-docs.sh
}