[![License](https://img.shields.io/github/license/impresscms-dev/generate-phpdocs-with-evert-phpdoc-md-action.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/release/impresscms-dev/generate-phpdocs-with-evert-phpdoc-md-action.svg)](https://github.com/impresscms-dev/generate-php-project-classes-list-file-action/releases)

# Generate PHP docs with evert/phpdoc-md

GitHub action to generate PHP project documentation in [MarkDown](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) format. Based on [evert/phpdoc-md](https://github.com/evert/phpdoc-md) library.

This action is container-based and runs on official PHP Docker images. It does not require setting up PHP or Composer on the runner.

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

      - name: Generating documentation...
        uses: impresscms-dev/generate-phpdocs-with-evert-phpdoc-md-action@v1.0.0
        with:
          php_version: '7.4'
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
| php_version | No | 7.4 | PHP version to run (accepted range: `5.4` to `7.4`, inclusive) |
| ignored_files | No      |                      | Defines files that can be ignored (supports glob rules; each line means one rule) |
| phpdocumentor_version | No | v2.8.5 | What [phpDocumentor](https://www.phpdoc.org) version to use (latest or release tag like `v2.8.5`) |
| output_path | Yes | | Path where to write generated documentation |

## Notes

- Docker build clones `git@github.com:evert/phpdoc-md.git` directly and falls back to HTTPS clone when SSH credentials are not available.
- phpDocumentor release artifacts are downloaded during action runtime and are not stored in this repository.
- Dockerfile supports selecting PHP by version: `docker build --build-arg PHP_VERSION=7.4 .`
- `php_version` input must match the container runtime version (this image version is controlled by `PHP_VERSION` build arg).
- Tests are JavaScript integration tests based on [testcontainers-node](https://github.com/testcontainers/testcontainers-node).

## How to contribute? 

If you want to add some functionality or fix bugs, you can fork, change and create pull request. If you not sure how this works, try [interactive GitHub tutorial](https://skills.github.com).

If you found any bug or have some questions, use [issues tab](https://github.com/impresscms-dev/generate-phpdocs-with-evert-phpdoc-md-action/issues) and write there your questions.
