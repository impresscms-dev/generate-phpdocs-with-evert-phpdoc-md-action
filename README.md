[![License](https://img.shields.io/github/license/impresscms-dev/generate-phpdocs-with-evert-phpdoc-md-action.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/release/impresscms-dev/generate-phpdocs-with-evert-phpdoc-md-action.svg)](https://github.com/impresscms-dev/generate-php-project-classes-list-file-action/releases)

# Generate PHP docs with evert/phpdoc-md

GitHub action to generate PHP project documentation in [MarkDown](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) format. Based on [clean/phpdoc-md](https://github.com/clean/phpdoc-md) library.

## Usage

To use this action in your project, create workflow in your project similar to this code (Note: some parts and arguments needs to be altered):
```yaml
name: Generate documentation

on:
  push:

jobs:
  get_php_classes_list:
    runs-on: ubuntu-latest
    steps:
      - name: Checkouting project code...
        uses: actions/checkout@v2
        
      - name: Install PHP
        uses: shivammathur/setup-php@master
        with:
          php-version: 8.1
          extensions: curl, gd, pdo_mysql, json, mbstring, pcre, session
          ini-values: post_max_size=256M
          coverage: none
          tools: composer:v2
          
      - name: Install Composer dependencies (with dev)
        run: composer install --no-progress --no-suggest --prefer-dist --optimize-autoloader       
          
      - name: Generating documentation...
        uses: impresscms-dev/generate-phpdocs-with-evert-phpdoc-md-action@v0.1
        with:
          output_path: ./docs/
          ignored_files: |
            test/
            extras/
          
      - uses: actions/upload-artifact@v3
        with:
          name: my-artifact
          path: ./docs/
```

## Arguments 

This action supports such arguments (used in `with` keyword):
| Argument    | Required | Default value        | Description                       |
|-------------|----------|----------------------|-----------------------------------|
| ignored_files | No      |                      | Defines files that can be ignored (supports glob rules; each line means one rule) |
| phpdocumentor_version | No | latest | What [PHP Documentator](https://www.phpdoc.org) version to use? (version = docker image tag) |
| output_path | Yes | | Path where to write generated documentation |

## How to contribute? 

If you want to add some functionality or fix bugs, you can fork, change and create pull request. If you not sure how this works, try [interactive GitHub tutorial](https://try.github.io).

If you found any bug or have some questions, use [issues tab](https://github.com/impresscms-dev/generate-phpdocs-with-evert-phpdoc-md-action/issues) and write there your questions.
