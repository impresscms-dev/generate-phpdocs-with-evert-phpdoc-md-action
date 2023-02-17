#!/usr/bin/env php
<?php

if (!isset($argv[1])) {
    echo 'ERROR: first argument is missing';
    exit(1);
}

echo realpath($argv[1]);