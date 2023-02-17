#!/usr/bin/env bash

set -e

composer global exec phpdocmd "$GENERATOR_TMP_FILES_PATH/structure.xml" "$GENERATOR_DOCS_PATH"