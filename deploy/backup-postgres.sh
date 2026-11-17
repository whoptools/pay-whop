#!/usr/bin/env bash
set -euo pipefail
umask 077
base=/opt/pay-whop/shared/backups
install -d -m 700 "$base"
file="$base/pay-whop-$(date -u +%Y%m%dT%H%M%S)-$$.dump"
trap 'rm -f "$file.partial"' EXIT
docker exec pay-whop-db pg_dump -U pay_whop -d pay_whop --format=custom > "$file.partial"
docker exec -i pay-whop-db pg_restore --list < "$file.partial" >/dev/null
mv "$file.partial" "$file"
find "$base" -name 'pay-whop-*.dump' -mtime +14 -delete
printf 'Created PostgreSQL backup: %s\n' "$file"
