ARG PHP_VERSION=7.4

FROM php:8.3-cli-bookworm AS phpdocmd-builder

COPY --from=composer:2.2 /usr/bin/composer /usr/local/bin/composer

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        openssh-client \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5" \
        git clone --depth 1 git@github.com:evert/phpdoc-md.git /opt/phpdoc-md \
    || git clone --depth 1 https://github.com/evert/phpdoc-md.git /opt/phpdoc-md \
    && php -r '$composer = json_decode(file_get_contents("/opt/phpdoc-md/composer.json"), true); unset($composer["require-dev"]); file_put_contents("/opt/phpdoc-md/composer.json", json_encode($composer, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL);' \
    && COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_HOME=/tmp/composer composer config --global platform.php 5.5.0 \
    && COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_HOME=/tmp/composer composer install \
        --working-dir=/opt/phpdoc-md \
        --no-dev \
        --no-plugins \
        --no-scripts \
        --no-interaction \
        --no-progress \
        --prefer-dist \
    && rm -rf /tmp/composer

FROM php:${PHP_VERSION}-cli

COPY --from=phpdocmd-builder /opt/phpdoc-md /opt/phpdoc-md
COPY bin/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
