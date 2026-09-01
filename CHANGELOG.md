# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

## [1.0.0] - 2026-09-01

First semver release. Brings this template to the fleet standard established
in [keycloak-traefik-letsencrypt-docker-compose](https://github.com/heyvaldemar/keycloak-traefik-letsencrypt-docker-compose)
v1.2.0.

### Changed (BREAKING for existing deployments)

- **Bitbucket 8.13 (EOL) → 10.4.2**, moving from the deprecated
  `atlassian/bitbucket-server` image name to `atlassian/bitbucket`.
  ❗ Atlassian supports one platform upgrade at a time: existing 8.13
  deployments step 8.13 → 9.6 (LTS) → 10.4 via `BITBUCKET_IMAGE_TAG`
  overrides — see the release notes.
- **Traefik 3.2 → 3.7** (3.2's Docker client cannot talk to Docker
  Engine 29); PostgreSQL 15 → 17 (Bitbucket 10.x
  supports PostgreSQL 16-18; 15 is rejected as unsupported). All pins
  in the compose `x-images` block.

### Fixed

- **The container healthcheck could never pass on a proxied setup**: with
  `SERVER_SECURE`/`SERVER_SCHEME` configured, Bitbucket redirects
  plain-HTTP checks to the public hostname, which does not resolve inside
  the container. A permanently unhealthy container is removed from
  Traefik load balancing (every request 404s). The healthcheck now
  probes the Tomcat port instead of speaking HTTP.
- Backup-loop variables are `$$`-escaped so the container shell resolves
  them at runtime; shellcheck findings in both restore scripts.

### Security

- **Credentials untracked from git.** The tracked `.env` carried a
  generated-looking database password — rotate it if reused.

### Added

- **Deployment Verification workflow**: shellcheck + actionlint; Trivy
  scans of all three pinned images; weekly `check-pin-freshness`; and a
  deploy-and-test job that boots the stack and requires Bitbucket's
  `/status` endpoint to answer through Traefik.

[Unreleased]: https://github.com/heyvaldemar/bitbucket-traefik-letsencrypt-docker-compose/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/heyvaldemar/bitbucket-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
