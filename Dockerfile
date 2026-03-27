ARG PHP_VERSION=7.4

FROM php:8.3-cli-bookworm AS phpdocmd-builder

COPY --from=composer:2.2 /usr/bin/composer /usr/local/bin/composer

COPY --chmod=0755 bin/install-builder-deps.sh bin/setup-phpdoc-md.sh /usr/local/bin/
RUN /usr/local/bin/install-builder-deps.sh

RUN /usr/local/bin/setup-phpdoc-md.sh

FROM php:${PHP_VERSION}-cli

COPY --from=phpdocmd-builder /opt/phpdoc-md /opt/phpdoc-md
COPY --chmod=0755 bin/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
