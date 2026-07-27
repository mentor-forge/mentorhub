# P010 – Audit existing persona and related test data

**Status:** Pending  
**Type:** Feature  
**Depends On:** none  
**Description:** Audit current Profile, Customer, Encounter, Event, Mentee, and local IdP (`welcome-auth.js`) seed data against the target persistent user-persona set; publish a gap report that later tasks use to propose aligned updates.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./CONTRIBUTING.md
- ./Workshops/README.md
- ./tasks/_ORCHESTRATE.md
- ./tasks/_PLANNING.md
- ./welcome-auth.js
- ./login.html
- Target persona table (design intent — not yet canonical in README):

| Persona | Roles | Explanation | Customer |
| --- | --- | --- | --- |
| Mary the Super Mentee | Customer, Coordinator, Mentee | Self Funded Apprentice | Mary |
| Stacey the CEO | Customer | Big Time CEO, may check on Mentees, super busy | Persevere |
| Emma the Coordinator | Coordinator | Matches mentees with mentors | Persevere |
| Daniel | Mentee | Mentee from Persevere | Persevere |
| Marti the Mentor | Mentor | Mentor for the Agile Learning Institute | ALI |
| Mike the Admin | Customer, Coordinator, Mentor, Mentee, Admin | SRE | ALI |
| Special Mentor | Mentor | Mentor for only Persevere mentees | ALI |
| Money Mentor | Mentor | Only Compensated Encounters | Any |
| Entrepreneur | Customer | Startup CEO for SuperSoft | SuperSoft |
| Dev Lead | Coordinator | Just watches mentees for the Customer | SuperSoft |
| Sr. Dev | Coordinator, Mentor | Matches and Mentors | SuperSoft |
| Lucky | Mentee | Mentee from SuperSoft | SuperSoft |

**Suggested additional personas (missing use cases — confirm in P020):**

| Persona | Roles | Explanation | Customer | Why |
| --- | --- | --- | --- | --- |
| Sam the Platform Admin | Admin | Pure admin / SRE without journey roles | ALI (or none) | Isolates admin-only RBAC from Mike’s multi-role superuser |
| Pat the Sponsoring Mentor | Customer, Mentor | Customer who also mentors | Mary or SuperSoft | Covers customer+mentor without full Mike combo |
| Riley Dual Path | Mentor, Mentee | Learns while mentoring | Persevere or ALI | Preserves mentor+mentee path tests (current Taylor-like) |

### External read-only audit sources (do not edit from this repo’s orchestrator)

Fetch definitive schemas from the running configurator when available (`tasks/_PLANNING.md`):

```bash
curl -X GET "http://localhost:8383/api/configurations/json_schema/Profile.yaml/latest/" -H "accept: application/json"
curl -X GET "http://localhost:8383/api/configurations/json_schema/Customer.yaml/latest/" -H "accept: application/json"
curl -X GET "http://localhost:8383/api/configurations/json_schema/Encounter.yaml/latest/" -H "accept: application/json"
curl -X GET "http://localhost:8383/api/configurations/json_schema/Event.yaml/latest/" -H "accept: application/json"
```

Inspect sibling seed files only as **read-only** context for the gap report (implementation belongs in `mentorhub_mongodb_api` via P030/P040 ISSUE handoffs):

- `../mentorhub_mongodb_api/configurator/test_data/Profile.0.1.0.0.json`
- `../mentorhub_mongodb_api/configurator/test_data/Customer.0.1.0.0.json`
- `../mentorhub_mongodb_api/configurator/test_data/Encounter.0.1.0.0.json`
- `../mentorhub_mongodb_api/configurator/test_data/Event.0.1.0.0.json`
- `../mentorhub_mongodb_api/configurator/test_data/Mentee.0.1.0.0.json` (if present)
- Prior persona prune: `../mentorhub_mongodb_api/Tasks/SHIPPED.T204.update_profile_test_data.md`

If the configurator is down, set **Status** to `Blocked` and stop — do not treat YAML dictionaries as write source of truth.

## Goals

- Produce a written **persona audit gap report** in `tasks/P010.persona_audit_findings.md` covering:
  - Current Profile `name` / `full_name` / `roles` / `customer_id` / `mentor_id` vs target personas
  - Current Customer orgs vs required **Mary**, **Persevere**, **ALI**, **SuperSoft** (and Any)
  - Whether Encounters, Events, and Mentee docs still resolve to retained profile ids
  - Drift between `welcome-auth.js` `PROFILES` and Profile seed data
  - Recommended keep / rename / add / remove per persona
  - Confirmation or rejection of suggested extra personas (Sam / Pat / Riley)
- List breaking risks for Journey, Encounter, Note, Rating, E2E JWT helpers if `_id` values change
- Prefer **preserving stable Profile `_id` values** where a persona maps to an existing person (e.g. mike, marti, daniel, lucky, mary)

## Testing Expectations

- Markdown lint / structural review of `tasks/P010.persona_audit_findings.md` (tables render; every target persona appears once)
- Cross-check that every `welcome-auth.js` `PROFILES` key is mentioned as keep, remap, or drop
- No code or seed files modified in this task

## Outputs

- `tasks/P010.persona_audit_findings.md` (create)
- `tasks/PENDING.P010.audit_existing_persona_test_data.md` (this file — Execution Notes only)

## Execution Notes

(Reserved for the execution agent.)
