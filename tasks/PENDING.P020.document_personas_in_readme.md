# P020 – Document persistent user personas in README

**Status:** Pending  
**Type:** Feature  
**Depends On:** P010_audit_existing_persona_test_data  
**Description:** Add a clear, durable **User personas (testing & design)** section to `./README.md` so Profile/Customer seed data, local login, Encounters, and Events all share one canonical persona catalog.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./CONTRIBUTING.md
- ./Workshops/README.md
- ./tasks/_ORCHESTRATE.md
- ./tasks/_PLANNING.md
- ./tasks/P010.persona_audit_findings.md (from P010)
- ./welcome-auth.js (reference only — updated in P050)
- `user_roles` enum expectation: mentor / mentee / customer / coordinator / admin

### Canonical persona set (starting point — refine with P010 findings)

| Persona | IdP / Profile `name` (proposed) | Roles | Explanation | Customer org |
| --- | --- | --- | --- | --- |
| Mary the Super Mentee | `mary` | customer, coordinator, mentee | Self Funded Apprentice | Mary |
| Stacey the CEO | `stacey` | customer | Big Time CEO; may check on mentees; super busy | Persevere |
| Emma the Coordinator | `emma` | coordinator | Matches mentees with mentors | Persevere |
| Daniel | `daniel` | mentee | Mentee from Persevere | Persevere |
| Marti the Mentor | `marti` | mentor | Mentor for the Agile Learning Institute | ALI |
| Mike the Admin | `mike` | customer, coordinator, mentor, mentee, admin | SRE | ALI |
| Special Mentor | `special` (or agreed short name) | mentor | Mentor for only Persevere mentees | ALI |
| Money Mentor | `money` | mentor | Only Compensated Encounters | Any |
| Entrepreneur | `entrepreneur` (or short name) | customer | Startup CEO for SuperSoft | SuperSoft |
| Dev Lead | `devlead` | coordinator | Just watches mentees for the Customer | SuperSoft |
| Sr. Dev | `srdev` | coordinator, mentor | Matches and Mentors | SuperSoft |
| Lucky | `lucky` | mentee | Mentee from SuperSoft | SuperSoft |

### Suggested personas for missing use cases (include in README as optional / recommended)

| Persona | Roles | Explanation | Customer | Gap covered |
| --- | --- | --- | --- | --- |
| Sam the Platform Admin | admin | Admin-only RBAC / SRE without journey roles | ALI or none | Pure admin vs Mike multi-role |
| Pat the Sponsoring Mentor | customer, mentor | Pays and mentors | Mary or SuperSoft | customer+mentor without full admin set |
| Riley Dual Path | mentor, mentee | Mentors while on a learning path | Persevere or ALI | mentor+mentee dual (legacy Taylor) |

Document in README that **role combinations above are the persistent testing matrix**; new seed people should extend this table rather than invent one-off names.

## Goals

- README contains a dedicated **User personas (testing & design)** section with:
  - Persona table (name, roles, explanation, Customer org)
  - Required Customer orgs: **Mary**, **Persevere**, **ALI**, **SuperSoft** (+ notes for Money Mentor “Any”)
  - Mapping rules: Profile `name` ↔ login selector ↔ JWT `sub` / `profile_id` / `customer_id` / `roles` / `mentor_id`
  - Relationship rules for test design (who mentors whom; which mentees belong to which Customer)
  - Pointer that MongoDB seed updates are owned by `mentorhub_mongodb_api` (P030/P040)
  - Pointer that local login UI is `login.html` / `welcome-auth.js` (P050)
- Incorporate P010 keep/rename/add decisions and accept or reject Sam/Pat/Riley with a one-line rationale each
- Do not change seed JSON or `welcome-auth.js` in this task

## Testing Expectations

- README markdown tables render; every accepted persona listed once
- Roles listed use only valid `user_roles` values
- Links/paths to P030/P040/P050 task or ISSUE files are correct relative to repo root

## Outputs

- `./README.md` (update — add personas section; do not remove unrelated Quick Start / Contributing content)
- `tasks/PENDING.P020.document_personas_in_readme.md` (this file — Execution Notes only)

## Execution Notes

(Reserved for the execution agent.)
