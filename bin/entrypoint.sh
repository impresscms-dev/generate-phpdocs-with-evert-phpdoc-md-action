#!/usr/bin/env bash

set -euo pipefail

OUTPUT_PATH=${1:-}
IGNORED_FILES=${2:-}
PHPDOC_VERSION=${3:-v2.8.5}

if [[ -z "$OUTPUT_PATH" ]]; then
  echo "Input 'output_path' is required." >&2
  exit 1
fi

WORKSPACE_PATH=${GITHUB_WORKSPACE:-/github/workspace}

if [[ ! -d "$WORKSPACE_PATH" ]]; then
  echo "Workspace path does not exist: $WORKSPACE_PATH" >&2
  exit 1
fi

if [[ "$OUTPUT_PATH" = /* ]]; then
  DOCS_PATH=$OUTPUT_PATH
else
  DOCS_PATH="$WORKSPACE_PATH/$OUTPUT_PATH"
fi

TMP_ROOT=$(mktemp -d)
PHPDOC_XML_PATH="$TMP_ROOT/phpdoc-xml"
PHPDOC_PHAR_PATH="$TMP_ROOT/phpDocumentor.phar"
PHPDOC_TAR_GZ_PATH="$TMP_ROOT/phpDocumentor.tgz"
PHPDOC_EXTRACT_PATH="$TMP_ROOT/phpDocumentor"
PHPDOC_MD_PATH=/opt/phpdoc-md
PHPDOC_CACHE_PATH=/opt/phpdocumentor-cache

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$DOCS_PATH"
mkdir -p "$PHPDOC_XML_PATH"
mkdir -p "$PHPDOC_EXTRACT_PATH"

download_file() {
  local url=$1
  local target=$2
  php -r '$url = isset($argv[1]) ? $argv[1] : null; $target = isset($argv[2]) ? $argv[2] : null; if (!$url || !$target) { fwrite(STDERR, "Missing download arguments\n"); exit(1); } $data = @file_get_contents($url); if ($data === false) { exit(1); } if (@file_put_contents($target, $data) === false) { fwrite(STDERR, "Unable to write file: $target\n"); exit(1); }' "$url" "$target"
}

extract_tgz() {
  local archive=$1
  local target=$2
  php -r '$archive = isset($argv[1]) ? $argv[1] : null; $target = isset($argv[2]) ? $argv[2] : null; if (!$archive || !$target) { fwrite(STDERR, "Missing extract arguments\n"); exit(1); } if (!is_dir($target) && !mkdir($target, 0777, true)) { fwrite(STDERR, "Unable to create extract directory\n"); exit(1); } $tarPath = preg_replace("/\\.tgz$/", ".tar", $archive); if ($tarPath === null) { fwrite(STDERR, "Unable to derive tar path\n"); exit(1); } try { $tgz = new PharData($archive); if (!file_exists($tarPath)) { $tgz->decompress(); } $tar = new PharData($tarPath); $tar->extractTo($target, null, true); } catch (Exception $e) { fwrite(STDERR, "Unable to extract phpDocumentor archive: " . $e->getMessage() . "\n"); exit(1); }' "$archive" "$target"
}

PHPDOC_COMMAND=()
PHPDOC_COMMAND_SET=0
if [[ "$PHPDOC_VERSION" == "latest" ]]; then
  PHPDOC_PHAR_URL="https://phpdoc.org/phpDocumentor.phar"
  download_file "$PHPDOC_PHAR_URL" "$PHPDOC_PHAR_PATH"
  PHPDOC_COMMAND=(php "$PHPDOC_PHAR_PATH" run)
  PHPDOC_COMMAND_SET=1
else
  PHPDOC_VERSION_NO_PREFIX=${PHPDOC_VERSION#v}
  CACHED_PHPDOC_TAR_GZ_PATH="$PHPDOC_CACHE_PATH/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.tgz"
  CACHED_PHPDOC_PHAR_PATH="$PHPDOC_CACHE_PATH/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.phar"
  CACHED_PHPDOC_BIN_PATH="$PHPDOC_CACHE_PATH/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}/bin/phpdoc"
  PHPDOC_TAR_GZ_URL="https://github.com/phpDocumentor/phpDocumentor/releases/download/v${PHPDOC_VERSION_NO_PREFIX}/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}.tgz"
  PHPDOC_PHAR_URL="https://github.com/phpDocumentor/phpDocumentor/releases/download/v${PHPDOC_VERSION_NO_PREFIX}/phpDocumentor.phar"

  if ! php -r 'exit(extension_loaded("zlib") ? 0 : 1);'; then
    if [[ -f "$CACHED_PHPDOC_BIN_PATH" ]]; then
      PHPDOC_COMMAND=(php "$CACHED_PHPDOC_BIN_PATH")
      PHPDOC_COMMAND_SET=1
    elif [[ -f "$CACHED_PHPDOC_PHAR_PATH" ]]; then
      cp "$CACHED_PHPDOC_PHAR_PATH" "$PHPDOC_PHAR_PATH"
      PHPDOC_COMMAND=(php "$PHPDOC_PHAR_PATH" run)
      PHPDOC_COMMAND_SET=1
    else
      download_file "$PHPDOC_PHAR_URL" "$PHPDOC_PHAR_PATH"
      PHPDOC_COMMAND=(php "$PHPDOC_PHAR_PATH" run)
      PHPDOC_COMMAND_SET=1
    fi
  fi

  if [[ "$PHPDOC_COMMAND_SET" -eq 0 ]] && [[ -f "$CACHED_PHPDOC_TAR_GZ_PATH" ]]; then
    cp "$CACHED_PHPDOC_TAR_GZ_PATH" "$PHPDOC_TAR_GZ_PATH"
  elif [[ "$PHPDOC_COMMAND_SET" -eq 0 ]] && ! download_file "$PHPDOC_TAR_GZ_URL" "$PHPDOC_TAR_GZ_PATH"; then
    download_file "$PHPDOC_PHAR_URL" "$PHPDOC_PHAR_PATH"
    PHPDOC_COMMAND=(php "$PHPDOC_PHAR_PATH" run)
    PHPDOC_COMMAND_SET=1
  fi

  if [[ "$PHPDOC_COMMAND_SET" -eq 0 ]]; then
    extract_tgz "$PHPDOC_TAR_GZ_PATH" "$PHPDOC_EXTRACT_PATH"
    PHPDOC_BIN_PATH="$PHPDOC_EXTRACT_PATH/phpDocumentor-${PHPDOC_VERSION_NO_PREFIX}/bin/phpdoc"
    if [[ ! -f "$PHPDOC_BIN_PATH" ]]; then
      echo "Unable to find phpDocumentor binary after extraction." >&2
      exit 1
    fi
    PHPDOC_COMMAND=(php "$PHPDOC_BIN_PATH")
    PHPDOC_COMMAND_SET=1
  fi
fi

declare -a PHPDOC_IGNORE_ARGS
PHPDOC_IGNORE_ARGS+=("--ignore=vendor/**")
while IFS= read -r LINE; do
  LINE=${LINE%$'\r'}
  if [[ -n "$LINE" ]]; then
    PHPDOC_IGNORE_ARGS+=("--ignore=$LINE")
  fi
done <<< "$IGNORED_FILES"

"${PHPDOC_COMMAND[@]}" \
  --target="$PHPDOC_XML_PATH" \
  --directory="$WORKSPACE_PATH" \
  --cache-folder="$TMP_ROOT/cache" \
  --template=xml \
  --no-interaction \
  --ansi \
  "${PHPDOC_IGNORE_ARGS[@]}"

if [[ ! -f "$PHPDOC_MD_PATH/bin/phpdocmd" ]]; then
  echo "phpdoc-md binary is missing: $PHPDOC_MD_PATH/bin/phpdocmd" >&2
  exit 1
fi

php "$PHPDOC_MD_PATH/bin/phpdocmd" "$PHPDOC_XML_PATH/structure.xml" "$DOCS_PATH"
