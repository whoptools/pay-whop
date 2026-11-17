# Shared Hetzner deployment

The playground runs at https://pay.whoptools.com on the existing Corsego server
(`188.245.75.73`), alongside the Webflow integration. Each app has its own container
and hostname behind Kamal Proxy. The playground uses a dedicated PostgreSQL 17 container on the same host. It
started with a fresh sandbox database on November 17, 2026; Neon data was not
imported. The old Neon database remains intact as a fallback.

## Layout

- Releases: `/opt/pay-whop/releases/<commit>`
- Active release: `/opt/pay-whop/current`
- Runtime environment: `/opt/pay-whop/shared/runtime.env` (root-owned, mode 0600)
- Container: `pay-whop-app`, private port 3001, external Docker network `kamal`
- App limits: 512 MB RAM and half a CPU; bounded Docker logs; automatic restart
- Database: `pay-whop-db`, volume `pay-whop_postgres_data`, 256 MB RAM
- Private database network: `pay-whop-database`; no published database port
- Database definition: `/opt/pay-whop/shared/postgres.yaml` from `deploy/postgres.yaml`

Keep `SECRET_KEY_BASE`, `DATABASE_URL` and the sandbox Whop settings stable. Never
commit runtime secrets or include them in the Docker build context. The app
refuses to boot with a live Whop environment.

## Database and backups

The database is managed separately from application releases:

```sh
docker compose -f /opt/pay-whop/shared/postgres.yaml up -d --wait db
```

The database password lives in `/opt/pay-whop/shared/postgres-password` (mode
0600). The app connects through the private Docker network using its protected
`DATABASE_URL`. Do not publish PostgreSQL ports or reuse the Corsego database.
Never delete `pay-whop_postgres_data` during an application deployment.

The `pay-whop-database-backup.timer` runs daily. Its operator-installed script,
`deploy/backup-postgres.sh`, writes custom-format dumps to
`/opt/pay-whop/shared/backups`, checks their archive index and retains 14 days.
Run `/usr/local/sbin/pay-whop-database-backup` for an on-demand dump. These backups
remain on the server; off-server backup storage is a separate recovery task.

The initial database reset also rotated `SECRET_KEY_BASE`, invalidating old
browser sessions before numeric IDs could be reused. Keep the new secret stable
for subsequent deployments. The sandbox seller mapping was restored from its
verified Whop child account; old users, payments and subscriptions were not
imported. Whop's own sandbox records remain at Whop.

## Automatic deployments

Pushes to `main` run the complete CI matrix. Only a successful matrix starts the
Hetzner deployment job. Pull requests never receive the deployment key. Deploys
are serialized, and a superseded commit is skipped before build and activation.

GitHub secrets `HETZNER_DEPLOY_KEY` and `HETZNER_KNOWN_HOSTS` hold a dedicated SSH
key and the pinned server host key. The Unix account `pay-whop-deploy` has a forced
SSH command and no forwarding or interactive shell access through that key.
Its only sudo command is `/usr/local/sbin/pay-whop-deploy`, installed from
`deploy/hetzner.sh`. That root-owned script accepts only `deploy <commit SHA>` and
fetches that exact revision from `whoptools/pay-whop` after checking it is current
`main`. Application credentials remain on the server.

The server builds with its dedicated resource-limited `pay-whop-builder`, stops
the builder, then replaces the app container. It checks container health and
HTTPS before advancing `current`. Activation failure restores the previous app
image. The shared proxy, Webflow app and database are not restarted. This is a
single-container deployment, so replacement can briefly interrupt requests.

Monitor the **Deploy to Hetzner** job in the repository's CI workflow. To retry a
failed deployment, rerun the failed GitHub Actions jobs. A newer main revision
will supersede an older retry. Keep releases and images needed for rollback.

## Operator access

For a manual deployment of the current, CI-verified main commit:

```sh
ssh root@188.245.75.73 "/usr/local/sbin/pay-whop-deploy 'deploy <40-character SHA>'"
```

Changes to the deployment script itself require an operator to install the
reviewed `deploy/hetzner.sh` at `/usr/local/sbin/pay-whop-deploy` (root-owned, mode
0755). The restricted CI account cannot replace that script or rotate its key.
The build context excludes private environment files, Git history and temporary
files. The app start command applies migrations and starts Puma with embedded
GoodJob; it refuses to boot with a live Whop environment.

## Webhooks and rollback

Whop delivers to `https://pay.whoptools.com/pay/whop/webhooks`. Preserve the existing
endpoint's event list, dated API version, signing secret and child-event setting
when moving its URL.

The old Render service is retained suspended for rollback. To roll back the
hosting move, resume it, restore Cloudflare's `pay` CNAME to
`pay-whop.onrender.com`, and restore that endpoint's previous webhook URL.
Render retains its former Neon configuration and cannot reach the new private
Docker database. Resuming it would show the pre-reset demo data, not the current
database. `/opt/pay-whop/shared/runtime.neon.env` retains the original protected
configuration for that fallback. Do not silently swap databases as part of an
application rollback.

Application rollback does not reverse database migrations. A release requiring
irreversible migrations needs its own backup and rollback plan. Render remains
suspended and is no longer the deployment destination.
