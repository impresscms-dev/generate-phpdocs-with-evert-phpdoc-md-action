#!/usr/bin/env bash

mkdir -p "$GENERATOR_DOCS_PATH" || true

rm -rf "$GENERATOR_TMP_FILES_PATH" || true
mkdir -p "$GENERATOR_TMP_FILES_PATH"