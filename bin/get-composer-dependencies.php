#!/usr/bin/env php
<?php

$withVersions = !isset($argv[1]) || ((int)$argv[1] > 0);

$contents = file_get_contents(dirname(__DIR__) . DIRECTORY_SEPARATOR . 'composer.json');
$composer = json_decode($contents, true);

$packages = [];
foreach ($composer['require'] as $package => $version) {
    if ($withVersions) {
        $packages[] =  $package . "=" . $version;
    } else {
        $packages[] =  $package;
    }
}

echo implode(" ", $packages);