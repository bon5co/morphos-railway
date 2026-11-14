# morphos-railway

Wrapper image for the [Morphos](https://github.com/danvergara/morphos) Railway template: the unmodified upstream image `ghcr.io/danvergara/morphos-server:0.6.0` (pinned by digest) behind an nginx HTTP Basic gateway with a generated password (`MORPHOS_PASSWORD`), bound to Railway's injected `PORT`.
