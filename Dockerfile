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

COPY bin/setup-phpdoc-md.sh /usr/local/bin/setup-phpdoc-md.sh
RUN chmod +x /usr/local/bin/setup-phpdoc-md.sh \
    && /usr/local/bin/setup-phpdoc-md.sh

FROM php:${PHP_VERSION}-cli

COPY --from=phpdocmd-builder /opt/phpdoc-md /opt/phpdoc-md
COPY bin/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
