#!/usr/bin/env bats

setup_file() {
    export COMPOSER_GLOBAL_JSON_PATH=$(composer config data-dir)/composer.json
    export BACKUP_PATH=$(mktemp -d)
    export BACKUP_COMPOSER=$BACKUP_PATH/composer.json

    if [ -f "$COMPOSER_GLOBAL_JSON_PATH" ]; then
        cp "$COMPOSER_GLOBAL_JSON_PATH" "$BACKUP_COMPOSER"
    fi;

    $BATS_TEST_DIRNAME/../bin/add-composer-packages.sh
}

tear_file() {
    rm -rf "$COMPOSER_GLOBAL_JSON_PATH"

    if [ -f "$BACKUP_COMPOSER" ]; then
        cp "$BACKUP_COMPOSER" "$COMPOSER_GLOBAL_JSON_PATH"
    fi;

    rm -rf "$BACKUP_PATH" || true

    composer global install -q || true
}

@test "Runs correctly" {
     $BATS_TEST_DIRNAME/../bin/remove-composer-dependencies.sh
}