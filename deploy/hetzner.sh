#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} != deploy\ * ]] || [[ ! ${1#deploy } =~ ^[0-9a-f]{40}$ ]]; then
  echo 'Expected: deploy <40-character commit SHA>' >&2
  exit 64
fi
revision=${1#deploy }
base=/opt/pay-whop
repository=https://github.com/whoptools/pay-whop.git
exec 9>"$base/shared/deploy.lock"
flock -w 900 9

latest=$(git ls-remote "$repository" refs/heads/main | cut -f1)
if [[ $revision != "$latest" ]]; then
  echo 'Skipping a superseded main revision.'
  exit 0
fi

release="$base/releases/$revision"
previous=$(readlink -f "$base/current")
activated=false
replacing=false
activate() {
  local directory=$1
  docker compose --project-name pay-whop --env-file "$directory/.env" -f "$directory/compose.yaml" up -d --no-build --wait --wait-timeout 120 app
  docker exec kamal-proxy kamal-proxy deploy whoptools-pay \
    --target pay-whop-app:3001 --host pay.whoptools.com --tls --health-check-path /up
}
cleanup() {
  local result=$?
  trap - EXIT
  docker buildx stop pay-whop-builder >/dev/null 2>&1 || true
  if [[ $result != 0 && $replacing == true && $activated == false ]]; then
    echo 'Restoring the previous application release.' >&2
    activate "$previous" || echo 'ROLLBACK FAILED: operator intervention required.' >&2
  fi
  exit "$result"
}
trap cleanup EXIT

install -d "$release"
curl --fail --silent --show-error --location --retry 3 \
  "https://codeload.github.com/whoptools/pay-whop/tar.gz/$revision" \
  | tar -xz --strip-components=1 -C "$release"
cp "$release/deploy/compose.yaml" "$release/compose.yaml"
printf 'APP_IMAGE_TAG=%s\n' "$revision" > "$release/.env"

docker buildx build --builder pay-whop-builder --load \
  -t "pay-whop:$revision" -f "$release/deploy/Dockerfile" "$release"
docker buildx stop pay-whop-builder

# A newer push can arrive while this image builds.
latest=$(git ls-remote "$repository" refs/heads/main | cut -f1)
if [[ $revision != "$latest" ]]; then
  echo 'Skipping activation of a superseded main revision.'
  exit 0
fi
replacing=true
activate "$release"
curl --fail --silent --show-error --retry 5 --retry-all-errors --retry-delay 2 \
  --resolve pay.whoptools.com:443:127.0.0.1 https://pay.whoptools.com/up >/dev/null
ln -sfn "$release" "$base/current"
activated=true
printf 'Deployed %s to https://pay.whoptools.com/\n' "$revision"
