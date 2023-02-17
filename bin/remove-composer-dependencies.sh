#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# shellcheck disable=SC2046
composer global remove $("$SCRIPT_DIR"/get-composer-dependencies.php 0)