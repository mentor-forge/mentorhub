# S41 – Route mock IdP login through the Tailscale magic hostname

Status: Pending
Type: Feature
Depends On: S40
Description: Make the Developer Edition mock IdP work when journey SPAs are opened over the Tailscale VPN. Drive `IDP_LOGIN_URI` from `~/.mentorhub/HOST_NAME` via the `mh` CLI, and widen the `welcome-auth.js` `return_to` allowlist so redirects back to a tailnet magic host are accepted (issue F-W08 #40).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./DeveloperEdition/mh
- ./DeveloperEdition/docker-compose.yaml
- ./welcome-auth.js
- ./login.html

## Background (why this is needed)

- The SPAs redirect unauthenticated users to `IDP_LOGIN_URI` (default `http://127.0.0.1:8080/login.html`) with a `return_to` set to the SPA's own origin.
- `welcome-auth.js` `isAllowedReturnTo()` currently only accepts `127.0.0.1` / `localhost` hosts. Over the VPN the SPA origin is `http://<magic-host>:<port>`, so login is blocked with "Invalid return_to URL".
- Two coordinated changes fix this: (1) the login page URL must point at the server's magic host, and (2) the `return_to` allowlist must accept tailnet hosts.

## Goals

- `DeveloperEdition/mh` reads `~/.mentorhub/HOST_NAME` (alongside the existing `~/.mentorhub/*` sourcing) and, when present and `IDP_LOGIN_URI` is not already set, exports:
  - `IDP_LOGIN_URI="http://<HOST_NAME>:8080/login.html"`
  - Falls back to the existing `${IDP_LOGIN_URI:-http://127.0.0.1:8080/login.html}` compose default when `HOST_NAME` is absent (no behavior change for developers who have not opted in).
- `welcome-auth.js` `isAllowedReturnTo()` accepts, in addition to `127.0.0.1` and `localhost`, hosts on the Tailscale MagicDNS domain (hostname ending in `.ts.net`). The `http:`-only protocol check is retained.
- `login.html` requires no change — confirm this and note it in Execution Notes.
- No changes to `mentorhub_spa_utils` (out of repo). The SPA build already consumes `IDP_LOGIN_URI` at container runtime; only the value changes.

## Testing Expectations

- `welcome-auth.js` behavior check for `isAllowedReturnTo`:
  - `http://127.0.0.1:8388/...` → allowed
  - `http://localhost:8388/...` → allowed
  - `http://my-box.tail1234.ts.net:8388/...` → allowed
  - `http://evil.example.com/...` → rejected
  - `https://...` and malformed URLs → rejected
- `DeveloperEdition/mh` still sources cleanly: `mh list-profiles` runs without error with and without `~/.mentorhub/HOST_NAME` present.
- Markdown lint on any docs touched.

## Outputs

- `DeveloperEdition/mh` — add `HOST_NAME` sourcing / `IDP_LOGIN_URI` export.
- `welcome-auth.js` — broaden `isAllowedReturnTo()` allowlist.

## Execution Notes

**Summary of changes**
- `DeveloperEdition/mh`: added a HOST_NAME block alongside the existing `~/.mentorhub/*` sourcing. When `IDP_LOGIN_URI` is unset and `~/.mentorhub/HOST_NAME` exists, it exports `IDP_LOGIN_URI="http://<HOST_NAME>:8080/login.html"`; otherwise the compose default (`http://127.0.0.1:8080/login.html`) applies.
- `welcome-auth.js`: broadened `isAllowedReturnTo()` to also accept hostnames ending in `.ts.net` (Tailscale MagicDNS), keeping the `http:`-only protocol check.
- `login.html`: no change required — it only loads `welcome-auth.js`; the allowlist lives entirely in the script.

**Verification results**
- `isAllowedReturnTo` (real function extracted from `welcome-auth.js`, run under node): all 8 cases pass —
  `127.0.0.1`/`localhost`/`*.ts.net` allowed; `evil.example.com`, the spoof `notreally-ts.net.evil.com`, `https://`, and a malformed URL all rejected.
- `zsh -n DeveloperEdition/mh` → syntax OK.
- Sourcing the real `mh` config block: with `HOST_NAME` present → `IDP_LOGIN_URI=http://curttuff.tailb0d293.ts.net:8080/login.html`; with it absent → unset (compose default used).

**Follow-up tasks**
- `welcome-auth.js` change requires rebuilding the welcome image (`make container`) to take effect locally; the published image updates via CI / `make push`.
