#
# Paperless Regex Extractor - Docker Image
# https://github.com/serefkoca46/paperless-regex-extractor
#
# Bu Dockerfile, Paperless-ngx base image'ına regex extraction
# özelliğini ekler.
#
# Kullanım:
#   docker build -t paperless-regex-extractor .
#   docker run -d paperless-regex-extractor
#

# Base image - Paperless-ngx
ARG PAPERLESS_VERSION=latest
FROM ghcr.io/paperless-ngx/paperless-ngx:${PAPERLESS_VERSION}

# Metadata
LABEL maintainer="Paperless Regex Extractor"
LABEL description="Paperless-ngx with Automatic Regex Extraction"
LABEL version="1.0.0"

# Çalışma dizini
WORKDIR /usr/src/paperless

# Regex Extractor dosyalarını kopyala
COPY src/migrations/0001_add_extraction_fields.py ./src/documents/migrations/
COPY src/signals/extraction_handler.py ./src/documents/signals/
COPY src/templates/default_templates.json ./data/regex_templates/

# Signal handler'ı aktifleştir
RUN echo "" >> ./src/documents/signals/__init__.py && \
    echo "# Paperless Regex Extractor" >> ./src/documents/signals/__init__.py && \
    echo "from .extraction_handler import auto_extract_custom_fields" >> ./src/documents/signals/__init__.py

# Templates dizini oluştur
RUN mkdir -p ./data/regex_templates

# Permissions
RUN chown -R paperless:paperless ./src/documents/signals/ && \
    chown -R paperless:paperless ./data/regex_templates/

# Default command (parent'tan miras)
# Migration otomatik çalışacak
