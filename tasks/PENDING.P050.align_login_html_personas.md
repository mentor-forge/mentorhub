# P050 – Align local login (`login.html` / `welcome-auth.js`) with persistent personas

**Status:** Pending  
**Type:** Feature  
**Depends On:** P020_document_personas_in_readme  
**Description:** Update the MentorHub local IdP login page and `welcome-auth.js` profile catalog so the login selector matches the canonical personas documented in `README.md` (labels, roles, profile_id, customer_id, mentor_id). Includes a planning prompt suitable for a GitHub issue if work is filed separately.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md (personas section from P020)
- ./CONTRIBUTING.md
- ./Workshops/README.md
- ./tasks/_PLANNING.md
- ./login.html
- ./welcome-auth.js
- ./tasks/P010.persona_audit_findings.md
- External: Profile `_id` / `customer_id` values must match mongodb seed after P030 lands — if seed ids are not finalized, set **Status** to `Blocked` on missing id map rather than inventing conflicting oids

### Planning prompt (for GitHub issue / PR description — use if filing separately)

```text
Title: Align mentorhub login.html / welcome-auth.js with persistent test personas

## Summary
Update the local Dev IdP login experience so the Profile dropdown and minted JWTs match the canonical User personas table in mentorhub/README.md (testing & design).

## Background
- Personas are the persistent people used across Profile/Customer seed data, Encounters, Events, and SPA/API E2E.
- Today welcome-auth.js still lists legacy people (e.g. cat, carol, luther, taylor, sam) and role/customer_id values that drift from the target matrix (Mary/Persevere/ALI/SuperSoft).

## Requirements
1. welcome-auth.js `PROFILES` entries: one key per accepted README persona; label = persona display name.
2. JWT claims per persona: sub/name, profile_id, roles[], customer_id, mentor_id — exactly aligned to mongodb Profile seed (preserve stable _ids where README says keep).
3. login.html: selector remains data-automation-id friendly; options show persona label + short role hint if helpful; no dead options for dropped people.
4. Remove or stop listing obsolete personas not in README.
5. Document in PR which Profile _ids / Customer _ids were used (table).

## Depends on
- README personas section shipped (mentorhub tasks P020)
- mentorhub_mongodb_api Profile/Customer seed aligned (issue from tasks P030) — or Blocked until id map exists

## Test plan
- [ ] Open login.html locally; every README persona appears once
- [ ] Login as each persona; decode JWT; roles/customer_id/profile_id match README + seed
- [ ] Smoke: mentee/mentor/customer/admin personas can hit their SPA return_to smoke paths
- [ ] No console errors; automation ids preserved
```

## Goals

- `welcome-auth.js` `PROFILES` matches README persona catalog (keys, labels, roles, ids)
- `login.html` continues to populate from `PROFILES` (adjust copy/labels only if needed for clarity)
- Dropped personas removed from the dropdown
- Execution Notes record the final id map table
- If mongodb P030 ids are unavailable, mark Blocked and paste the planning prompt into a GitHub issue instead of shipping mismatched claims

## Testing Expectations

- Manual: load `login.html`, confirm option list ≡ README personas
- For at least Mike, Mary, Daniel, Marti, Lucky, Stacey (or Entrepreneur): mint token via UI and confirm claim fields
- Markdown/issue prompt in this task remains accurate after implementation (update prompt if labels change)

## Outputs

- `./welcome-auth.js` (update)
- `./login.html` (update only if needed for labels/accessibility/automation)
- `tasks/PENDING.P050.align_login_html_personas.md` (this file — Execution Notes; keep planning prompt in sync)

## Execution Notes

(Reserved for the execution agent.)
