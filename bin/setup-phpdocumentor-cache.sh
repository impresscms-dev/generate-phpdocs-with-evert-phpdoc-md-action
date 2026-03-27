#!/usr/bin/env bash

set -euo pipefail

TARGET_DIR=${1:-/opt/phpdocumentor-cache}
PHPDOC_VERSION=${2:-v2.8.5}
PHPDOC_VERSION_NO_PREFIX=${PHPDOC_VERSION#v}
PHPDOC_TAR_GZ_URL="https://github.com/phpDocumentor/phpDocumentor/releases/download/v${PHPDOC_VERSION_NO_PREFIX}/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.tgz"
PHPDOC_PHAR_URL="https://github.com/phpDocumentor/phpDocumentor/releases/download/v${PHPDOC_VERSION_NO_PREFIX}/phpDocumentor.phar"
TARGET_FILE="${TARGET_DIR}/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.tgz"
PHAR_TARGET_FILE="${TARGET_DIR}/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.phar"

mkdir -p "$TARGET_DIR"

php -r '$url = isset($argv[1]) ? $argv[1] : null; $target = isset($argv[2]) ? $argv[2] : null; if (!$url || !$target) { fwrite(STDERR, "Missing download arguments\n"); exit(1); } $data = @file_get_contents($url); if ($data === false) { fwrite(STDERR, "Unable to download file: $url\n"); exit(1); } if (@file_put_contents($target, $data) === false) { fwrite(STDERR, "Unable to write file: $target\n"); exit(1); }' "$PHPDOC_TAR_GZ_URL" "$TARGET_FILE"
php -r '$url = isset($argv[1]) ? $argv[1] : null; $target = isset($argv[2]) ? $argv[2] : null; if (!$url || !$target) { fwrite(STDERR, "Missing download arguments\n"); exit(1); } $data = @file_get_contents($url); if ($data === false) { fwrite(STDERR, "Unable to download file: $url\n"); exit(1); } if (@file_put_contents($target, $data) === false) { fwrite(STDERR, "Unable to write file: $target\n"); exit(1); }' "$PHPDOC_PHAR_URL" "$PHAR_TARGET_FILE"
