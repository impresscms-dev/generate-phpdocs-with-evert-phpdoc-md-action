#!/bin/sh

set -eu

if php -r 'exit(extension_loaded("zlib") ? 0 : 1);'; then
  exit 0
fi

if php -d extension=zlib.so -r 'exit(function_exists("gzcompress") ? 0 : 1);'; then
  echo "extension=zlib.so" > /usr/local/etc/php/conf.d/zz-zlib.ini
  exit 0
fi

if ! command -v apt-get >/dev/null 2>&1 || ! command -v docker-php-ext-install >/dev/null 2>&1; then
  echo "Unable to install zlib extension automatically." >&2
  exit 1
fi

apt-get update
if [ -n "${PHPIZE_DEPS:-}" ]; then
  apt-get install -y --no-install-recommends $PHPIZE_DEPS zlib1g-dev
else
  apt-get install -y --no-install-recommends zlib1g-dev
fi
docker-php-ext-install zlib
rm -rf /var/lib/apt/lists/*

php -r 'if (!function_exists("gzcompress")) { fwrite(STDERR, "zlib extension is required but unavailable.\n"); exit(1); }'
