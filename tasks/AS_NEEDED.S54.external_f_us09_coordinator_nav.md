# S54 – External: remove Coordinator from universal nav (F-US09)

Status: Run as needed
Type: Feature
Depends On: none
Description: F-W09 cross-repo note — Removing Coordinator from the **spa_utils universal nav** is implemented in `mentorhub_spa_utils`, not orchestrated from this repo. Run manually or via spa_utils task automation when F-US09 is active.

## Context

- ../mentorhub_spa_utils/README.md
- ./Workshops/customer_journey_issues.md (F-W09, F-US09 reference)
- ./Workshops/customer_journey_issues_adjustments.md (universal nav, coordinator removal)
- [F-US09 mentorhub_spa_utils#26](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)

## Goals

- Confirm `mentorhub_spa_utils` universal nav / cross-repo link table no longer lists Coordinator SPA or API.
- Replace with Admin, Discovery, Customer, Mentor, Mentee entries per F-US09 when those domains are registered.
- No file changes in **mentorhub** unless a one-line CONTRIBUTING or standards cross-link to F-US09 is needed (prefer zero mentorhub diff).

## Testing Expectations

- Review merged F-US09 PR in `mentorhub_spa_utils` — grep nav config for `coordinator`.
- Customer SPA smoke after spa_utils bump — universal nav renders without Coordinator link.

## Outputs

- None in mentorhub (execution agent works in `mentorhub_spa_utils` only).
- Optional: link from `DeveloperEdition/standards/spa_standards.md` to F-US09 if gap found during review — only if explicitly needed.

## Execution Notes

**Orchestration boundary:** `_ORCHESTRATE.md` does not run tasks in sibling repos. A human or spa_utils planning agent owns F-US09 implementation. Unblock Customer/Discovery SPAs after F-W18 + F-US09 both land.
