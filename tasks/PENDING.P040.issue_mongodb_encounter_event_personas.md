# P040 – ISSUE handoff: align Encounter, Event, and relationship trails to personas

**Status:** Pending  
**Type:** Feature  
**Depends On:** P030_issue_mongodb_profile_customer_personas  
**Description:** Create a handoff issue for `mentorhub_mongodb_api` so Encounter, Event, Mentee, and related trails reflect the persistent persona relationships (who mentors whom, which Customer sponsors which mentees, compensated vs standard encounters).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md (personas section)
- ./Workshops/README.md
- ./tasks/_PLANNING.md
- ./tasks/P010.persona_audit_findings.md
- ./tasks/ISSUE.mentorhub_mongodb_api.align_persona_profile_customer_test_data.md (from P030)
- Prior encounter rebuild pattern: `../mentorhub_mongodb_api/Tasks/SHIPPED.T109.recreate_encounter_test_data.md` (read-only reference)
- External implementation repo: `mentorhub_mongodb_api` (do **not** edit from this orchestrator)

### Relationship design intent (encode in ISSUE; refine with README)

| Mentee | Customer | Primary mentor(s) | Notes |
| --- | --- | --- | --- |
| Daniel | Persevere | Special Mentor (Persevere-only); Marti only if product allows cross-customer | Special Mentor constraint must be testable |
| Lucky | SuperSoft | Sr. Dev and/or Marti per design | SuperSoft mentee trail |
| Mary (as mentee) | Mary | Marti or Pat (if accepted) | Self-funded apprentice path |
| Money Mentor sessions | Any allowed mentee | Money Mentor | Encounters marked / typed as compensated-only |

Event trails: each active persona should have a believable `Event` breadcrumb history (login, encounter completed, etc. per existing Event enum) so SPA activity views and API event tests are not empty.

## Goals

- Create `tasks/ISSUE.mentorhub_mongodb_api.align_persona_encounter_event_trails.md` with:
  - Dependency on Profile/Customer persona alignment issue (P030)
  - Encounter matrix: mentor_id × mentee_id × customer context; include at least one **Money Mentor compensated** encounter
  - Special Mentor only appears on Persevere mentee encounters
  - Event seed requirements per persona (minimum counts / types)
  - Mentee collection / Journey `profile_id` alignment if those collections remain in seed
  - Note/Rating references updated if they point at dropped profile ids
  - Planning prompt for mongodb_api `_PLANNING.md` to generate PENDING data tasks
- Do not modify seed JSON in this repo

## Testing Expectations

- ISSUE lists concrete mentor↔mentee pairs for every mentee persona in README
- Money Mentor and Special Mentor constraints are testable acceptance bullets
- Markdown self-contained for external planners

## Outputs

- `tasks/ISSUE.mentorhub_mongodb_api.align_persona_encounter_event_trails.md` (create)
- `tasks/PENDING.P040.issue_mongodb_encounter_event_personas.md` (this file — Execution Notes only)

## Execution Notes

(Reserved for the execution agent.)
