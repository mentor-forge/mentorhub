# S46 – Document runtime `IDP_LOGIN_URI` for journey SPAs

Status: Shipped
Type: Feature
Depends On: S44
Description: Update Developer Edition standards and contributor docs so journey SPAs document the runtime `IDP_LOGIN_URI` contract (container env → client redirect) and retire the spa_utils 0.5.6 loopback-host rewrite workaround (issue F-W08). Run after mentor_spa R147 approval.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./DeveloperEdition/standards/sre_standards.md
- ./DeveloperEdition/standards/spa_standards.md
- ./tasks/SHIPPED.S41.idp_login_uri_magic_hostname.md
- ./tasks/SHIPPED.S43.contributing_hostname_docs.md

**External prerequisites (all must be complete before unblocking):**

- `mentorhub_spa_utils` **0.5.7** published to CodeArtifact (F031 complete).
- `mentorhub_mentee_spa` **L126** approved (CodeArtifact 0.5.7 path validated).
- `mentorhub_mentor_spa` **R147** approved (mentor SPA merged).

## Goals

- `DeveloperEdition/standards/sre_standards.md` — NGINX / container section states that **`IDP_LOGIN_URI`** is injected at **container startup** into a small runtime config script consumed by the SPA (same image, every environment). Clarify resolution order: runtime `IDP_LOGIN_URI` → build-time `VITE_IDP_LOGIN_URI` (dev server) → Developer Edition fallback.
- `DeveloperEdition/standards/spa_standards.md` — Authentication Pattern updated: router guards and logout use `getIdpLoginBaseUrl()` from spa_utils; no per-SPA hostname rewrite logic.
- `CONTRIBUTING.md` — VPN section notes that `mh` sets compose `IDP_LOGIN_URI` and journey SPA **containers** honor it at runtime; `npm run dev` continues to use `.env.development` (`127.0.0.1`) for same-machine development.
- Remove or revise any docs that describe the 0.5.6 `adaptIdpLoginUriToCurrentHost` workaround as the primary fix.

## Testing Expectations

- Markdown lint on touched files.
- Cross-check doc examples against mentee_spa / mentor_spa Dockerfile + nginx startup pattern implemented in L122 / R146.

## Outputs

- `DeveloperEdition/standards/sre_standards.md`
- `DeveloperEdition/standards/spa_standards.md`
- `CONTRIBUTING.md` — only if VPN / IdP sections need a short runtime-config addendum

## Execution Notes

**Summary of changes**
- `spa_standards.md` — Authentication Pattern: `redirectToIdpLogin` / `getIdpLoginBaseUrl`, runtime `__MENTORHUB_RUNTIME__.IDP_LOGIN_URI`, container `runtime-config.js` + Vite load order, resolution order (spa_utils 0.5.7+); no per-SPA hostname rewrite.
- `sre_standards.md` — NGINX env vars: container startup `envsubst` → `/runtime-config.js`, `Cache-Control: no-store`, same-image contract; resolution order; retired loopback rewrite guidance.
- `CONTRIBUTING.md` — VPN section: containers vs `npm run dev` (`VITE_IDP_LOGIN_URI`); link to SPA standards.

**Verification**
- Cross-checked against mentee_spa / mentor_spa Dockerfile CMD + `nginx.conf.template` + `public/runtime-config.js.template` (L122 / R146).
- No remaining references to `adaptIdpLoginUriToCurrentHost` as primary fix in updated standards or CONTRIBUTING.

**Branch:** `F-W08-expose-0.0.0.0`

**Follow-up:** Rename `PENDING.S47` workflow index to `SHIPPED.S47` — F-W08 serial workflow complete.
