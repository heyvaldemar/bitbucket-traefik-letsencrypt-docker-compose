# Bitbucket + Traefik + Let's Encrypt — Docker Compose

[![Deployment Verification](https://github.com/heyvaldemar/bitbucket-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml/badge.svg?branch=main)](https://github.com/heyvaldemar/bitbucket-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository deploys **Bitbucket Data Center** (single node) behind **Traefik** with automatic **Let's Encrypt TLS**, backed by **PostgreSQL 17**, with scheduled **backups** (database + home directory) and companion **restore scripts**.

📙 Full narrative installation guide on the blog: [heyvaldemar.com/install-bitbucket-using-docker-compose/](https://www.heyvaldemar.com/install-bitbucket-using-docker-compose/).

## Getting started

```bash
# 1. Clone
git clone https://github.com/heyvaldemar/bitbucket-traefik-letsencrypt-docker-compose
cd bitbucket-traefik-letsencrypt-docker-compose

# 2. Create the two Docker networks the stack expects
docker network create traefik-network
docker network create bitbucket-network

# 3. Copy the environment template and fill in required values
cp .env.example .env
$EDITOR .env
# ^ Required: BITBUCKET_DB_PASSWORD, BITBUCKET_HOSTNAME, BITBUCKET_URL,
#   TRAEFIK_HOSTNAME, TRAEFIK_ACME_EMAIL, TRAEFIK_BASIC_AUTH.

# 4. Deploy
docker compose -f bitbucket-traefik-letsencrypt-docker-compose.yml -p bitbucket up -d
```

First start takes a few minutes (JVM warm-up plus database initialization). `https://${BITBUCKET_HOSTNAME}` then serves the setup wizard — license, admin account, and instance name are entered there.

### What success looks like

```bash
docker compose -f bitbucket-traefik-letsencrypt-docker-compose.yml -p bitbucket ps
curl -fsk "https://${BITBUCKET_HOSTNAME}/status"   # {"state":"FIRST_RUN"} before setup, RUNNING after
```

### Common first-deploy issues

- **404 through the proxy while Bitbucket logs look fine.** The container is still starting — Traefik routes only to healthy containers; `docker ps` shows the health state.
- **Cert issuance fails.** DNS hasn't propagated or port 80 isn't reachable from the internet.
- **`docker compose up` fails with `set in .env`.** A required variable is empty; the error names it.
- **Networks not found.** Step 2 was skipped.

## Supply chain trust

Three images — [`traefik`](https://hub.docker.com/_/traefik), [`atlassian/bitbucket`](https://hub.docker.com/r/atlassian/bitbucket), [`postgres`](https://hub.docker.com/_/postgres) — pinned to `tag@sha256:<digest>` as interpolation defaults in the compose `x-images` block. `git pull` alone delivers the tested combination; an `*_IMAGE_TAG` variable in `.env` overrides deliberately.

The weekly `check-pin-freshness` CI job re-resolves each pin against its registry and compares the pinned Bitbucket and Traefik versions against the latest upstream releases. GitHub Actions are pinned by commit SHA; Dependabot keeps those fresh.

## Production checklist

- [ ] **Strong database password** — 24+ random characters; regenerate the Traefik dashboard hash.
- [ ] **Size the JVM for real load** — the defaults (1G/4G) suit evaluation; Atlassian's sizing guide has the numbers.
- [ ] **Host-mount the backup volumes** for disaster recovery — the home directory holds the repositories.
- [ ] **Upgrade one platform version at a time** — and back up before each step.
- [ ] **Verify Let's Encrypt cert issuance** in the Traefik logs on first start.

## Backups and restore

The `backups` container runs a `pg_dump | gzip` + `tar.gz`-of-home → prune → sleep loop (defaults: 30-minute warm-up, 24-hour interval, 7-day retention). Restore with the interactive scripts (`chmod +x *.sh` once): `./bitbucket-restore-database.sh`, then `./bitbucket-restore-application-data.sh`. Repositories live in the home directory, so database and home must be restored as a matching pair.

## Testing

The [Deployment Verification](https://github.com/heyvaldemar/bitbucket-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml?query=branch%3Amain) workflow runs on every push, pull request, and every Monday at 06:00 UTC: shellcheck + actionlint, Trivy scans of all three pinned images, the weekly freshness check, and a deploy-and-test job that boots the stack with ephemeral credentials and requires Bitbucket's `/status` endpoint to answer through Traefik.

## Security Notes

- Credentials are read from `.env` at deploy time; `.env` is gitignored and compose fails fast on missing required variables.
- **Pre-rotation advisory.** Releases before v1.0.0 (2026-09-01) shipped a tracked `.env` with a generated-looking database password. Rotate it if your deployment reused it.
- PostgreSQL listens only on the internal network.

---

## About the maintainer

<div align="center">

**Maintained by [Vladimir Mikhalev](https://github.com/heyvaldemar)** — Docker Captain · IBM Champion · AWS Community Builder

[YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1) · [Blog](https://heyvaldemar.com) · [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)

</div>
