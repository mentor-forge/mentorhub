# S56 – Welcome portal: org H1, featured Discovery, collapsed sections, MailPit

Status: Shipped
Type: Feature
Depends On: none
Description: Update `index.html` so the H1 links to the mentor-forge GitHub org, Discovery sits on its own line under the welcome subtitle, all collapsible sections start closed, and the mail UI label is MailPit.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./index.html
- ./tasks/SHIPPED.L025.welcome_portal_applications.md
- ./tasks/SHIPPED.S50.welcome_portal_remove_coordinator.md

Current markup (do not assume docs over the file):

- H1: `<a href="https://github.com/mentor-forge/mentorhub" id="repo-link" …>Mentor Hub</a>`
- Subtitle: `Welcome to the Development Environment`
- Discovery is the first Applications `cell-link` (`id="discovery-app-link"`)
- Applications and Tools start expanded (`aria-expanded="true"`; content not `hidden`)
- API Explorer already starts collapsed (`aria-expanded="false"`; content `hidden`)
- Tools mail link: `id="mailpit-link"` visible text `Mailpit` (href still set in JS to `:8025/`)

## Goals

- Change the H1 `repo-link` href to `https://github.com/mentor-forge` (org landing, not the `mentorhub` repo). Keep `target="_blank"` and `rel="noopener noreferrer"`. Visible H1 text stays **Mentor Hub**.
- Move Discovery out of the Applications section. Place it as its own line immediately below the subtitle `Welcome to the Development Environment` and above the Applications / Tools / API Explorer list.
  - Keep `id="discovery-app-link"` so existing JS still sets `http://${hostname}:8080/discovery/`.
  - Keep `cell-link` styling (and `target`/`rel`) so it remains a primary action, not a heading.
  - Keep the current visible label **Discovery (default landing)** unless a shorter **Discovery** label is needed for the featured row — prefer keeping the existing label.
  - Applications then lists Customer, Admin, Mentor, Mentee only (no Discovery duplicate).
- Start **all** collapsible sections closed on load: Applications, Tools, and API Explorer.
  - Each `.section-toggle`: `aria-expanded="false"`.
  - Each `.section-content`: `hidden`.
  - Do not change the existing click-to-toggle script unless it is required for the default-collapsed markup.
- Tools mail link visible text: **MailPit** (replace MailHog or Mailpit). Keep `id="mailpit-link"` and the JS href `http://${hostname}:8025/`. Do not retarget the link to a MailHog URL.

## Testing Expectations

- Static review of `index.html`:
  - `repo-link` href is exactly `https://github.com/mentor-forge`.
  - `discovery-app-link` appears after the subtitle and is not inside `#app-links`.
  - `#app-links` has no Discovery anchor.
  - Every `.section-toggle` has `aria-expanded="false"` and every `.section-content` has `hidden`.
  - Visible Tools label is `MailPit`; `getElementById('mailpit-link')` still assigns `:8025/`.
  - Remaining app/tool/API `getElementById` assignments still match element IDs (no missing IDs).
- Grep `index.html` — no `MailHog` / `Mailhog` / `mentorhub` in the H1 href.
- HTML lint if tooling is available. Browser smoke of the welcome page is optional if the stack is up; syntax and ID wiring are required.

## Outputs

- `index.html` — H1 org URL; featured Discovery row; all sections collapsed by default; MailPit label.

## Execution Notes

- Updated the real `index.html` markup: changed the H1 link to the mentor-forge organization, featured the existing Discovery link below the subtitle, removed Discovery from Applications, collapsed all three sections by default, and corrected the visible mail UI label to `MailPit`.
- Static grep review confirmed the exact organization URL, Discovery placement and retained JS wiring, three `aria-expanded="false"` toggles, three hidden section contents, the `MailPit` label, and the existing `:8025/` assignment. No old mentorhub H1 href or `MailHog` / `Mailhog` / `Mailpit` label remains.
- Ran a Python standard-library HTML parser check: all 3 toggles start collapsed, all 3 section contents are hidden, all 18 `getElementById(...).href` assignments resolve to existing element IDs, Discovery is outside `#app-links`, and MailPit remains wired to port 8025.
- Follow-ups: none. Browser smoke was not run because it is optional and no running stack was required for this static markup change.
