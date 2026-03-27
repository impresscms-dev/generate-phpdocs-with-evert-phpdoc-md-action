#!/usr/bin/env bash

set -euo pipefail

TARGET_DIR=${1:-/opt/phpdocumentor-cache}
PHPDOC_VERSION=${2:-v2.8.5}
PHPDOC_VERSION_NO_PREFIX=${PHPDOC_VERSION#v}
PHPDOC_TAR_GZ_URL="https://github.com/phpDocumentor/phpDocumentor/releases/download/v${PHPDOC_VERSION_NO_PREFIX}/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.tgz"
PHPDOC_PHAR_URL="https://github.com/phpDocumentor/phpDocumentor/releases/download/v${PHPDOC_VERSION_NO_PREFIX}/phpDocumentor.phar"
TARGET_FILE="${TARGET_DIR}/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.tgz"
PHAR_TARGET_FILE="${TARGET_DIR}/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.phar"
EXTRACTED_ROOT="${TARGET_DIR}/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}"
XML_WRITER_PATH="${EXTRACTED_ROOT}/src/phpDocumentor/Plugin/Core/Transformer/Writer/Xml.php"

mkdir -p "$TARGET_DIR"

php -r '$url = isset($argv[1]) ? $argv[1] : null; $target = isset($argv[2]) ? $argv[2] : null; if (!$url || !$target) { fwrite(STDERR, "Missing download arguments\n"); exit(1); } $data = @file_get_contents($url); if ($data === false) { fwrite(STDERR, "Unable to download file: $url\n"); exit(1); } if (@file_put_contents($target, $data) === false) { fwrite(STDERR, "Unable to write file: $target\n"); exit(1); }' "$PHPDOC_TAR_GZ_URL" "$TARGET_FILE"
php -r '$url = isset($argv[1]) ? $argv[1] : null; $target = isset($argv[2]) ? $argv[2] : null; if (!$url || !$target) { fwrite(STDERR, "Missing download arguments\n"); exit(1); } $data = @file_get_contents($url); if ($data === false) { fwrite(STDERR, "Unable to download file: $url\n"); exit(1); } if (@file_put_contents($target, $data) === false) { fwrite(STDERR, "Unable to write file: $target\n"); exit(1); }' "$PHPDOC_PHAR_URL" "$PHAR_TARGET_FILE"

rm -rf "$EXTRACTED_ROOT"
php -r '$archive = isset($argv[1]) ? $argv[1] : null; $target = isset($argv[2]) ? $argv[2] : null; if (!$archive || !$target) { fwrite(STDERR, "Missing extract arguments\n"); exit(1); } if (!is_dir(dirname($target)) && !mkdir(dirname($target), 0777, true)) { fwrite(STDERR, "Unable to create target parent directory\n"); exit(1); } $root = dirname($target); $tarPath = preg_replace("/\\.tgz$/", ".tar", $archive); if ($tarPath === null) { fwrite(STDERR, "Unable to derive tar path\n"); exit(1); } try { if (!file_exists($tarPath)) { $tgz = new PharData($archive); $tgz->decompress(); } $tar = new PharData($tarPath); $tar->extractTo($root, null, true); } catch (Exception $e) { fwrite(STDERR, "Unable to extract phpDocumentor archive: " . $e->getMessage() . "\n"); exit(1); }' "$TARGET_FILE" "$EXTRACTED_ROOT"

php -r '$path = isset($argv[1]) ? $argv[1] : null; if (!$path || !file_exists($path)) { fwrite(STDERR, "Xml writer file not found: " . ($path ?: "null") . "\n"); exit(1); } $content = file_get_contents($path); if ($content === false) { fwrite(STDERR, "Unable to read xml writer file\n"); exit(1); } $needle = '\''base64_encode(gzcompress($file->getSource()))'\''; $replacement = '\''(function_exists("gzcompress") ? base64_encode(gzcompress($file->getSource())) : "")'\''; $updated = str_replace($needle, $replacement, $content, $count); if ($count < 1) { fwrite(STDERR, "Unable to patch xml writer for missing zlib support\n"); exit(1); } if (file_put_contents($path, $updated) === false) { fwrite(STDERR, "Unable to write patched xml writer file\n"); exit(1); }' "$XML_WRITER_PATH"
