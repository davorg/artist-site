FROM perl:5.40-slim AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libgif-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libtiff-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/artist-site

COPY cpanfile ./
RUN cpanm --notest --installdeps .

FROM perl:5.40-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgif7 \
        libjpeg62-turbo \
        libpng16-16t64 \
        libtiff6 \
        libwebp7 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/perl5/site_perl/ \
    /usr/local/lib/perl5/site_perl/

WORKDIR /opt/artist-site

COPY bin/ ./bin/
COPY lib/ ./lib/
COPY templates/ ./templates/
COPY assets/css/ ./assets/css/

RUN chmod +x /opt/artist-site/bin/build-site

WORKDIR /site

ENTRYPOINT ["/opt/artist-site/bin/build-site"]
CMD ["--site-dir", "/site", "--output-dir", "_site"]
