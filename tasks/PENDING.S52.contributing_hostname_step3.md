# S52 – Move HOST_NAME setup into Step 3; remove VPN section

Status: Pending
Type: Feature
Depends On: none
Description: F-W09 — Simplify CONTRIBUTING.md: remove the standalone “Local testing over the VPN (Tailscale)” section (added by SHIPPED.S43) and document `~/.mentorhub/HOST_NAME` as part of Step 3 after GITHUB_TOKEN instructions.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./tasks/SHIPPED.S43.contributing_hostname_docs.md
- ./DeveloperEdition/docker-compose.yaml
- ./DeveloperEdition/mh

## Goals

- **Delete** the entire `## Local testing over the VPN (Tailscale)` section from `CONTRIBUTING.md` (lines added by S43).
- Under **Step 3 of 4 — Configure access tokens**, immediately after the `### GITHUB_TOKEN` subsection, add a short **`### HOST_NAME` (optional)** subsection that:
  - Explains `~/.mentorhub/HOST_NAME` holds the developer machine hostname used by `mh` to build `IDP_LOGIN_URI` for journey SPA containers (`http://<HOST_NAME>:8080/login.html`).
  - Gives a simple create command, e.g. `echo 'my-hostname.example' > ~/.mentorhub/HOST_NAME` or the one-liner from S43 using `tailscale status --json | jq …` for developers on Tailscale — keep it brief (3–6 lines of instruction, not a full VPN guide).
  - States the step is **optional**; without the file, localhost-only behavior is unchanged.
  - Notes to set `HOST_NAME` before `mh up` and re-`mh up` after changing it.
- Preserve the CodeArtifact (`make aws-setup`) subsection and Step 4 unchanged except any cross-references that pointed at the removed VPN section — retarget to Step 3 `HOST_NAME` or remove.
- Do **not** duplicate the long security callout from S43 unless one sentence suffices (“Developer Edition binds to `0.0.0.0`; see compose comments / SRE standards”).

## Testing Expectations

- `grep CONTRIBUTING.md` — no heading “Local testing over the VPN (Tailscale)”.
- Step 3 contains both GITHUB_TOKEN and HOST_NAME subsections in order.
- Markdown lint on `CONTRIBUTING.md`.
- All relative links in CONTRIBUTING still resolve.

## Outputs

- `CONTRIBUTING.md` — remove VPN section; add HOST_NAME under Step 3.

## Execution Notes
