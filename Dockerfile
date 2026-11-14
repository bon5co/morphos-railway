# Morphos for Railway.
#
# Morphos (github.com/danvergara/morphos, MIT) is a self-hosted file converter: images, PDF, Office documents, e-books, audio and
# video, behind a web form and a REST API (POST /api/v1/upload, GET /api/v1/formats). The upstream repository was archived in
# 2024-11 with v0.6.0 as its last release, and the image is unchanged here. This wrapper adds what a public Railway deploy
# driven by an agent needs.
#
# 1. Upstream has no authentication at all. A bare public domain is an open file-conversion service (LibreOffice, ffmpeg and
#    calibre run server-side on whatever is uploaded) on the deployer's bill. An nginx gateway on Railway's port requires HTTP
#    Basic auth on every path except /health, with a password generated per deploy (MORPHOS_PASSWORD). The entrypoint refuses
#    to start without one.
# 2. Morphos listens on MORPHOS_PORT (set to 3000 by the entrypoint) on every interface; the gateway owns the injected PORT.
# 3. Conversions work in /tmp and the response carries the result, so the app is stateless and there is no volume.
#
# Newest upstream release is v0.6.0 (2024-09-21), checked 2026-11-14; the GHCR tag 0.6.0 is the same image as latest.
# upstream: danvergara/morphos
FROM ghcr.io/danvergara/morphos-server:0.6.0@sha256:3d6f64ef386cbb6a7c5d55526e1a69da2d3661a1996d757897e92bf4369088f5

USER root
RUN apt-get update \
   && apt-get install -y --no-install-recommends nginx-light curl ca-certificates \
   && apt-get autoremove -y \
   && rm -rf /var/lib/apt/lists/*
COPY nginx.conf.template /etc/nginx-railway.conf.template
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh
USER morphos

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
