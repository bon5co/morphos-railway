#!/bin/sh
# Morphos on Railway: password gateway on the injected PORT in front of the unmodified app on 127.0.0.1:3000.
set -eu

die() { echo "morphos-railway: $*" >&2; exit 1; }

: "${MORPHOS_PASSWORD:?MORPHOS_PASSWORD is empty - the converter would be open to anyone}"
[ "${#MORPHOS_PASSWORD}" -ge 16 ] || die "MORPHOS_PASSWORD must be at least 16 characters"
case "$MORPHOS_PASSWORD" in
  *[!A-Za-z0-9]*) die "MORPHOS_PASSWORD must be letters and digits only" ;;
esac

PORT="${PORT:-8080}"
CRED="$(printf 'admin:%s' "$MORPHOS_PASSWORD" | base64 | tr -d '\n')"
sed -e "s|__PORT__|$PORT|g" -e "s|__CRED__|$CRED|g" /etc/nginx-railway.conf.template > /tmp/nginx.conf
mkdir -p /tmp/nginx-body /tmp/nginx-proxy /tmp/nginx-fastcgi /tmp/nginx-uwsgi /tmp/nginx-scgi
nginx -e /dev/stderr -t -c /tmp/nginx.conf || die "nginx config rejected"

# the app: upload scratch space under /tmp (its default); MORPHOS_PORT moves it off the injected PORT
mkdir -p /tmp/morphos
MORPHOS_PORT=3000 MORPHOS_UPLOAD_PATH=/tmp/morphos /bin/morphos &
APP=$!
nginx -e /dev/stderr -c /tmp/nginx.conf -g 'daemon off;' &
GW=$!
echo "morphos-railway: gateway on :$PORT (pid $GW), app on :3000 (pid $APP)"

trap 'kill $APP $GW 2>/dev/null; exit 0' TERM INT
# exit when either process dies so Railway's restart policy brings both back
while kill -0 "$APP" 2>/dev/null && kill -0 "$GW" 2>/dev/null; do sleep 2; done
echo "morphos-railway: a process exited, stopping" >&2
kill $APP $GW 2>/dev/null || true
exit 1
