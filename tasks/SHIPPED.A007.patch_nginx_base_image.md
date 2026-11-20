# A007 — Patch the Nginx base image built by CI

**Status**: Shipped
**Type**: Defect
**Depends On**: A005
**Issue**: https://github.com/mentor-forge/mentorhub/issues/81
**Description**: Replace the floating Nginx runtime base with the latest patched stable Alpine image, refresh builds, and prove the packaged welcome/login edge still meets its deployment contract.

## Context

- `../mentorhub/DeveloperEdition/standards/*.md`
- `../mentorhub_api_utils/README.md`
- `../mentorhub_spa_utils/README.md`
- `README.md`
- `CONTRIBUTING.md`
- `Workshops/README.md`
- `tasks/_PLANNING.md`
- `tasks/_ORCHESTRATE.md`
- `tasks/SHIPPED.A005.welcome_ci_migration.md` (resolve by task ID after lifecycle renaming)
- `Dockerfile`
- `.github/workflows/docker-push.yml`
- `Makefile`
- `nginx.conf`
- `DeveloperEdition/docker-compose.yaml`
- `tests/welcome-auth.test.js`
- [Official Nginx releases](https://nginx.org/en/download.html)
- [Official Nginx security advisories](https://nginx.org/en/security_advisories.html)
- [Official Docker image definitions](https://github.com/nginx/docker-nginx)

Execution follows A005, so its migrated Welcome workflow is authoritative. Preserve the GitHub-hosted dependency migration and cloud-agnostic local runtime. Do not restore AWS CLI, OIDC, CodeArtifact endpoints, or CodeArtifact secrets. No production provider choice or AWS teardown is required for this security update.

The pre-migration Dockerfile uses `FROM nginx:stable-alpine`. The publishing workflow builds `linux/amd64,linux/arm64` on pushes to `main` and publishes `ghcr.io/mentor-forge/mentorhub:latest`. A floating tag does not identify the binary in an existing published image.

This task extends the existing AWS-exit branch after A005. Paths are anchored to the mentorhub repository root.

## Goals

- At execution time, select the newest patched **stable** upstream Nginx release with an available official Alpine image supporting both target architectures. Record release/advisory URLs, retrieval date, version, image tag, and multi-platform index digest in Execution Notes. Do not copy an old version number from conversation history or silently switch to mainline.
- Identify applicable Nginx advisories using the actual image version, enabled modules (`nginx -V`), and effective configuration. The reported CVE was not supplied; distinguish confirmed affected findings from configuration-dependent or unrelated findings.
- Pin the Dockerfile runtime base to the verified explicit version tag plus multi-platform index digest, keeping Alpine and existing runtime startup behavior. Use the index digest rather than a single-architecture manifest digest.
- In `.github/workflows/docker-push.yml`, set `pull: true` on the existing build action. Keep publishing restricted to `push` on `main`, both target platforms, current registry tags, cache settings, and the migrated GitHub package authentication.
- Add `--pull` to the existing local Makefile container build so local packaging follows the refreshed-base policy. Preserve existing make targets and all other build behavior.
- Verify the final application image's actual Nginx binary and configuration, rather than relying on a base tag or a successful Vite build. Record image IDs/digests and scan evidence per architecture.
- Document the chosen Nginx pin and the short verification/update procedure in README without duplicating the digest outside the Dockerfile.
- Preserve immutable promotion: build once and promote the same application digest through test, staging, and production. Post-merge CI must publish a fresh image; record its digest and verify its version before marking the security issue resolved. Do not manually publish or deploy during this task's pre-merge work.

### Craftsmanship Expectations

- Keep changes limited to Nginx base selection and fresh-base build behavior. Reuse the current build paths and existing deployment tests.
- Preserve welcome/login token bootstrap, shared-origin journey routing, Docker DNS resolution, and full prefixed upstream request paths.
- Do not change application dependency versions, authentication, API contracts, shared utility repositories, or infrastructure as part of this update.
- If a required patched multi-platform image, registry access, GitHub package credentials, Docker runtime, or backing service is unavailable, record the exact blocker and mark the task Blocked. Do not claim verification or weaken tests to pass.

## Testing Expectations

- Validate the YAML and diff: the base uses the verified pin; CI requests a pull, keeps both architectures, and retains its main-only publishing trigger. Use available existing lint tooling; do not introduce a dependency solely for this check.
- Run `make test` (existing `tests/welcome-auth.test.js`) and `make container`.
- **Packaging verification**: start the Developer Edition stack with the newly built local welcome image, not a stale registry image. Validate `nginx -t` inside the running welcome container and run HTTP checks for `/`, `/login.html`, `/welcome-auth.js`, and all five journey prefixes through `:8080`. Confirm journey trailing-slash redirects retain the public host/port and API requests reach the expected upstream rather than welcome HTML. Existing journey services are runtime prerequisites, not repositories to edit.
- Build the final application image for **both** amd64 and arm64 using the existing build/auth conventions (Buildx local exports or separate local platform tags; no registry push). Run `nginx -v` and `nginx -V` against each built image, with explicit platform selection/emulation where needed, and compare with the selected patched version.
- Scan each final application image using an available container scanner with current advisory data. Record scanner/database versions, target image identity, applicable Nginx findings and disposition, and remaining unrelated findings. Scanner unavailability or missing architecture validation is a blocker, not a passing result.
- Record commands, results, image identities, and advisory decisions in Execution Notes. Publishing only occurs after human review and merge under existing CI. Leave a clearly identified post-merge check for the published multi-platform image's digest and binary versions; the issue remains open until that check succeeds.

## Outputs

Implementation may change only:
- `Dockerfile` — explicit patched stable Alpine tag and multi-platform digest.
- `.github/workflows/docker-push.yml` — fresh-base pull setting.
- `Makefile` — fresh-base local build option.
- `README.md` — short Nginx update/verification procedure.
- `tasks/PENDING.A007.patch_nginx_base_image.md` — execution evidence and lifecycle update; rename to `tasks/SHIPPED.A007.patch_nginx_base_image.md` only after required pre-merge validation and commit, or the corresponding `BLOCKED.` filename if prerequisites fail.

Existing test files to execute unchanged:
- `tests/welcome-auth.test.js`

All other files remain outside this task's output scope. If verification reveals a required config or test correction, record it for replanning rather than silently expanding outputs.

## Execution Notes

- On November 20, 2026, [Nginx upstream releases](https://nginx.org/en/download.html) identified 1.30.7 as stable. `docker buildx imagetools inspect nginx:1.30.7-alpine` verified the [official Alpine image](https://hub.docker.com/_/nginx) and its OCI index, with AMD64 and ARM64/v8 manifests. The index pin is recorded in the Dockerfile.
- [Upstream advisories](https://nginx.org/en/security_advisories.html) confirm 1.30.7 includes the resolver fix for CVE-2026-123634. The packaged effective configuration uses the Docker resolver, so the resolver advisory is relevant to this edge. Both binaries include HTTP/2, HTTP/3, TLS, mail and stream modules, but the effective edge config listens on plain HTTP/1.x and has none of those listeners or alias rules enabled. The upstream PROXY protocol finding lists a mainline-only affected range. The reported advisory and preexisting published runtime version were not supplied, so the prior published image's exposure is unverified.
- `make test` and `make container` passed. `docker buildx build --pull --platform linux/amd64 --load` produced the AMD64 image. Explicitly selected binaries both reported `nginx/1.30.7` with `nginx -v` and `nginx -V`. ARM64 ran natively. AMD64 ran through Ubuntu's standalone QEMU 8.2.2 userspace executable with no host binfmt changes.
- Final local application image IDs: ARM64 `sha256:dbceb7f9aa2f4f2d0c37205b9c242408582a36c4600cb17b1883b771ccc94060`; AMD64 `sha256:2858cbf079e14ec1993561e3e81a0431920aa0e13a20a5ba69df6b683a60dabf`.
- The existing Developer Edition stack occupied port 8080. A temporary Compose Welcome container used the ARM64 local image with pulling disabled on the existing journey network. A loopback connection override used an alternate physical port with the public `localhost:8080` origin and Host header. `nginx -t` passed and `nginx -T` confirmed the effective config. Landing, login, and script returned 200. All five unslashed journey prefixes redirected to the matching slash path while retaining the public host and port, and all five slash paths returned distinct journey HTML. Four journey `/api/config` routes and Discovery `/api/cards` returned the same 401 JSON as direct journey upstreams. The temporary Welcome container was removed after validation.
- Trivy 0.76.2 scanned both application image archives (`trivy image --input … --scanners vuln`) against schema 2 with database updated November 20, 2026 at 13:11 UTC. Neither image reported Nginx findings. Each reported the same 11 Alpine 3.24.4 package findings: five OpenSSL advisories (CVE-2026-107496, CVE-2026-88822, CVE-2026-88823, CVE-2026-95691, CVE-2026-95692) in both libcrypto3 and libssl3, and CVE-2026-4738 in zlib. These are separate base-image dependency findings. Track the updated official base or a separately reviewed dependency change.
- After merge, record the fresh GHCR OCI index and inspect the actual packaged Nginx version on each platform. Keep the issue open until then and promote the same verified application digest.
