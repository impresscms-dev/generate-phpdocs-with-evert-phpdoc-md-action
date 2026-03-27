ARG PHP_VERSION=7.4
ARG PHPDOC_VERSION=v2.8.5

FROM php:8.3-cli-bookworm AS phpdocmd-builder
ARG PHPDOC_VERSION

COPY --from=composer:2.2 /usr/bin/composer /usr/local/bin/composer

COPY --chmod=0755 bin/install-builder-deps.sh bin/setup-phpdoc-md.sh bin/setup-phpdocumentor-cache.sh /usr/local/bin/
RUN /usr/local/bin/install-builder-deps.sh

RUN /usr/local/bin/setup-phpdoc-md.sh
RUN /usr/local/bin/setup-phpdocumentor-cache.sh /opt/phpdocumentor-cache "$PHPDOC_VERSION"

FROM php:${PHP_VERSION}-cli

COPY --chmod=0755 bin/install-runtime-zlib.sh /usr/local/bin/install-runtime-zlib.sh
RUN /usr/local/bin/install-runtime-zlib.sh \
    && rm -f /usr/local/bin/install-runtime-zlib.sh

COPY --from=phpdocmd-builder /opt/phpdoc-md /opt/phpdoc-md
COPY --from=phpdocmd-builder /opt/phpdocumentor-cache /opt/phpdocumentor-cache
COPY --chmod=0755 bin/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
