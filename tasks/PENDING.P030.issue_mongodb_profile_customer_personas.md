# P030 – ISSUE handoff: align Profile and Customer test data to personas

**Status:** Pending  
**Type:** Feature  
**Depends On:** P020_document_personas_in_readme  
**Description:** Create a copy-paste GitHub / `_PLANNING` handoff issue for `mentorhub_mongodb_api` to audit-confirm and update Profile + Customer seed data so persistent personas in `mentorhub/README.md` are the only long-lived people used in testing.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md (personas section from P020)
- ./Workshops/README.md
- ./tasks/_PLANNING.md
- ./tasks/P010.persona_audit_findings.md
- External implementation repo: `mentorhub_mongodb_api` (do **not** edit that repo from this orchestrator)

## Goals

- Create `tasks/ISSUE.mentorhub_mongodb_api.align_persona_profile_customer_test_data.md` containing:
  - Link to canonical persona table in `mentorhub/README.md`
  - Required Customer documents: Mary, Persevere, ALI, SuperSoft (deterministic `_id`s; preserve existing Persevere/ALI ids when possible)
  - Required Profile documents per persona with `roles`, `customer_id`, `mentor_id`, `full_name`, `email`
  - Explicit **preserve `_id`** map for remapped existing people (mike, marti, daniel, lucky, mary, …) vs new `_id`s for Stacey, Emma, Special Mentor, Money Mentor, Entrepreneur, Dev Lead, Sr. Dev
  - Drop or repurpose obsolete personas (e.g. cat, carol, luther, taylor, sam) per P010/P020 decisions
  - Configurator reconfigure expectations and downstream collections that reference Profile/Customer ids
  - Planning prompt block suitable for pasting into `mentorhub_mongodb_api` `Tasks/_PLANNING.md` workflow

## Testing Expectations

- ISSUE markdown is self-contained enough for a mongodb_api planner to create PENDING Tasks without reading chat history
- No `configurator/test_data` files modified in **this** repo

## Outputs

- `tasks/ISSUE.mentorhub_mongodb_api.align_persona_profile_customer_test_data.md` (create)
- `tasks/PENDING.P030.issue_mongodb_profile_customer_personas.md` (this file — Execution Notes only)

## Execution Notes

(Reserved for the execution agent.)
