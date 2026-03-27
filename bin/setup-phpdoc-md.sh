#!/usr/bin/env bash

set -euo pipefail

TARGET_DIR=${1:-/opt/phpdoc-md}
COMPOSER_HOME_DIR=${2:-/tmp/composer}

GIT_SSH_OPTIONS="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"

if ! GIT_SSH_COMMAND="$GIT_SSH_OPTIONS" git clone --depth 1 git@github.com:evert/phpdoc-md.git "$TARGET_DIR"; then
  git clone --depth 1 https://github.com/evert/phpdoc-md.git "$TARGET_DIR"
fi

php -r '$composer = json_decode(file_get_contents($argv[1]), true); unset($composer["require-dev"]); file_put_contents($argv[1], json_encode($composer, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL);' "$TARGET_DIR/composer.json"

COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_HOME="$COMPOSER_HOME_DIR" composer config --global platform.php 5.5.0
COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_HOME="$COMPOSER_HOME_DIR" composer install \
  --working-dir="$TARGET_DIR" \
  --no-dev \
  --no-plugins \
  --no-scripts \
  --no-interaction \
  --no-progress \
  --prefer-dist

rm -rf "$COMPOSER_HOME_DIR"
