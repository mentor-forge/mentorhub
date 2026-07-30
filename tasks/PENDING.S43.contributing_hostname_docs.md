# S43 – Document HOST_NAME / VPN access in CONTRIBUTING

Status: Pending
Type: Feature
Depends On: S41
Description: Document how developers configure `~/.mentorhub/HOST_NAME` with their Tailscale MagicDNS hostname so their local stack (now bound to `0.0.0.0`) is reachable and the mock IdP login works over the VPN. Include the security posture of the new bindings and a broadcast note for the existing team (issue F-W08 #40).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md

## Goals

- `CONTRIBUTING.md` gains a short "VPN / remote access" subsection under the token-configuration / Developer Workflow area that:
  - Explains that Developer Edition services now bind to `0.0.0.0` and are reachable by teammates on the Tailscale tailnet.
  - Instructs the developer to create `~/.mentorhub/HOST_NAME` containing their Tailscale MagicDNS name (e.g. `my-box.tailXXXX.ts.net`), used by `mh` to set `IDP_LOGIN_URI`.
  - Notes this is a **manual, opt-in** step; without it, behavior is unchanged (localhost only).
  - States the security posture: `0.0.0.0` bindings (including unauthenticated MongoDB on `27017`) rely entirely on Tailscale ACLs; this is Developer-Edition-only and must never be used outside local/tailnet development.
- A "broadcast" call-out reminds existing developers to re-run `make update` and add `~/.mentorhub/HOST_NAME` when next refreshing their local instance.

## Testing Expectations

- Markdown lint on `CONTRIBUTING.md`.
- All added links resolve (relative links to standards/compose where referenced).

## Outputs

- `CONTRIBUTING.md` — add the VPN / `HOST_NAME` configuration subsection and broadcast note.

## Execution Notes

_(reserved for the execution agent: plan, commands run, test results, follow-ups)_
