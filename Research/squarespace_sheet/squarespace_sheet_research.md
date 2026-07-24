# Squarespace → Google Sheet → POST Profile Research Summary

**Do This First:** **R2** — see `Workshops/customer_journey_issues.md`.

**Primary onboarding path (Mike):** Squarespace registration form → Google Sheet → Sheet-bound script → Customer API **special POST Profile** → AWS Cognito Admin create user with custom claims.

**Not this document:**
- **AWS Cognito** (IdP) — `Research/aws_cognito/aws_cognito_research.md` (R1)
- **Cognito Forms** (optional alternate form tooling) — `Research/cognito_forms/cognito_forms_research.md`

**Team touch points:**

| Person | Area | Repo |
| --- | --- | --- |
| **Mary** | Registration handoff research (this file) | `mentorhub/Research` |
| **Lucky** | Customer API (special `POST Profile`) | `mentorhub_customer_api` |
| **Daniel** | Customer SPA (login only — no signup form) | `mentorhub_customer_spa` |

**Schema rule (Mike):** Do **not** change MongoDB dictionaries/schemas until form fields, Sheet columns, and POST payloads are locked; then create tickets (F-D21 / F-CA05).

---

## Decisions (MentorHub onboarding)

| Decision | Detail |
| --- | --- |
| **Primary path** | Squarespace form → Google Sheet → script → special `POST Profile` |
| **Public registration off SPA** | New customers register on the public Squarespace site, not via Customer SPA or Cognito Hosted UI self-signup |
| **Why not Hosted UI self-signup alone** | APIs require JWT custom claims (`profile_id`, `customer_id`, `mentor_id`, `roles`). Hosted UI self-onboarding does not set those MentorHub claims |
| **Provision via Admin path** | After successful POST Profile, Customer API creates Profile (+ Customer as designed) and creates the IdP user via **AWS Cognito Admin API** with custom claims (R1) |
| **SPA auth already done** | Customer SPA IdP redirect / JWT guards are sufficient; no Squarespace/registration/login/signup screens in the SPA |
| **Optional alternate** | Cognito Forms JSON webhook → same `POST Profile` — document separately; do not block R2 on Forms |
| **Do not change schemas yet** | Lock fields + Sheet columns + payload first |

---

## Workflow (to verify)

```text
Prospect
  → opens public Squarespace registration form
  → submits registration (full name, company, email, … TBD — lock below)

Squarespace
  → writes a new row to a connected Google Sheet

Google Sheet + script
  → on new row (or timed trigger): build JSON body from columns
  → POST to Customer API special POST Profile
  → authenticate with service credential (not end-user JWT)
  → mark row success / failure for ops visibility

Customer API (Lucky)
  → authenticate service caller
  → create Profile (+ Customer org as designed)
  → AWS Cognito AdminCreateUser with custom claims:
        profile_id, customer_id, mentor_id, roles (e.g. ["customer"])
  → idempotent on email and/or Sheet row key

Customer (later)
  → opens Customer SPA → existing auth → AWS Cognito login
  → JWT carries required claims → Customer API accepts calls
```

---

## Candidate registration fields

Workshop / journey alignment (confirm on the real Squarespace form):

| Form field (candidate) | Likely destination | Notes |
| --- | --- | --- |
| Full name / name | Profile `full_name` | Display name |
| Email | Profile `email`; Cognito username/email | Primary idempotency candidate |
| Username (if collected) | Profile `name` (IdP username) | Workshop mentioned username — confirm if still required |
| Company / org name | Customer `name` | Org display |
| Company description (optional) | Customer `description` | TBD |
| Phone / other | TBD | Only if form collects it |

**Current Profile (from journey / dictionary notes):** `_id`, `name` (IdP username), `status`, `description`, `full_name`, `email`, `email_verified`, `mentor_id`, `goals`, `interests`, `experience[]`, `created`, `saved`, `customer_id`, `roles`.

**Current Customer:** `_id`, `name`, `description`, `created`, `saved`, `status` — no `subscriptions[]` yet (billing is later research).

Add only missing attributes after this form list is locked + R1 Admin attributes are known.

---

## Google Sheet columns (proposed)

Lock column names with ops before F-CA05. Proposed starter set:

| Column | Purpose |
| --- | --- |
| `submitted_at` | When Squarespace wrote the row |
| `full_name` | Profile |
| `email` | Profile + idempotency |
| `username` | Profile `name` if collected |
| `company_name` | Customer `name` |
| `company_description` | Customer `description` (optional) |
| `sheet_row_id` | Stable key (row number or UUID script assigns) |
| `provision_status` | `pending` / `success` / `failed` |
| `provision_http_status` | Last API response code |
| `provision_error` | Error body / message for ops |
| `profile_id` | Filled on success (optional ops aid) |
| `processed_at` | When script last attempted POST |

---

## Inbound: special POST Profile (script → Customer API)

| Concern | Research need | Status |
| --- | --- | --- |
| **Auth** | How the script proves itself (Bearer service token, shared secret header, API key, m2m) | **TBD — confirm with Mike / Lucky** |
| **Payload** | Exact JSON mapped from Sheet columns | **Draft below — confirm** |
| **Idempotency** | Key on `email` and/or `sheet_row_id` so retries do not double-create Profile or Cognito users | **TBD — prefer both** |
| **Success / error** | Codes the script uses to set `provision_status` (avoid silent retries that duplicate) | **TBD** |
| **AWS Cognito** | Admin create attributes + custom claims | **R1** — `Research/aws_cognito/` |

### Draft request body (not final)

```json
{
  "full_name": "Jane Customer",
  "email": "jane@example.com",
  "name": "jane.customer",
  "company_name": "Acme Mentoring Co",
  "company_description": "Optional",
  "sheet_row_id": "row-42",
  "idempotency_key": "jane@example.com"
}
```

Field names and whether `company_*` create a new Customer in the same call are **Lucky / Mike** design choices for F-CA05.

### Draft auth shape (not final)

```http
POST /…/profiles  (exact path TBD in F-CA05)
Authorization: Bearer <service-token>
Content-Type: application/json
Idempotency-Key: <email-or-sheet_row_id>
```

Do **not** use an end-user Cognito JWT for the Sheet script.

---

## Script behavior (proposed)

1. Trigger on new Sheet row (or poll `provision_status = pending`).
2. Skip rows already `success`.
3. Build JSON from columns; POST with service auth.
4. On **2xx**: set `provision_status=success`, store `profile_id` if returned, `processed_at`.
5. On **4xx** (client error, e.g. validation): set `failed`; do **not** blind-retry without ops fix.
6. On **5xx / network**: leave `pending` or `failed` with retry policy that respects idempotency.
7. Never create Cognito users from the script directly — only via Customer API.

---

## Failure handling / ops

| Situation | Handling |
| --- | --- |
| Duplicate submit (same email) | API returns success or conflict; no second Profile/Cognito user |
| Bad/missing fields | 4xx → row `failed` + message in `provision_error` |
| API down | Retry with backoff; idempotent POST |
| Auth misconfigured | 401/403 → stop automatic retries; alert ops |
| Partial success (Profile yes, Cognito no) | API responsibility — script treats non-2xx as failed unless API documents otherwise |

---

## Anti-patterns

| Anti-pattern | Why it’s wrong | Prefer |
| --- | --- | --- |
| **Hosted UI self-signup for MentorHub claims** | Custom claims won’t be set | Squarespace → Sheet → POST Profile → AdminCreateUser |
| **Registration UI in Customer SPA** | Duplicates public form; login redirect exists | Public Squarespace + SPA login only |
| **Trust script POST without service auth** | Anyone could create profiles | Authenticate special POST Profile |
| **Non-idempotent create on retry** | Duplicate Profiles / Cognito users | Idempotent on email / sheet_row_id |
| **Script calling Cognito Admin directly** | Bypasses Profile/Customer consistency | Only Customer API provisions IdP |
| **Change Profile schema before locking form fields** | Rework | Capture real form + Sheet columns first |
| **Confusing Cognito Forms with this path** | Wrong primary tooling | Squarespace is primary; Forms is optional |

---

## Gaps (open research checklist)

1. **Capture real Squarespace form fields** (screenshot or field list from the live form).
2. **Confirm Squarespace → Google Sheet** wiring (native form storage / Zapier / other) used by Mentor Forge.
3. **Lock Sheet column names** and who owns the Sheet.
4. **Choose script runtime** (Apps Script bound to Sheet vs Cloud Function vs other).
5. **Lock special POST Profile** path, auth, payload, idempotency, error codes with Lucky/Mike.
6. **Complete R1** (AWS Cognito Admin + custom claims) so Profile fields are complete.
7. **PII / retention** — Sheet holds registration PII; retention and access rules TBD (GDPR later is API redact of Profile, not a Sheet feature).
8. **Whether Cognito Forms** remains a documented alternate only or is dropped for MVP.

---

## Related tickets (after R2 locked)

| Ticket | Role |
| --- | --- |
| **F-D21** | Extend Customer / confirm Profile for Sheet registration fields |
| **F-CA05** | Special POST Profile — Sheet script + AWS Cognito custom claims |
| **F-CS03** | Post-auth landing only — no registration UI |

---

## References

- Journey / R2 definition: `Workshops/customer_journey_issues.md` (Do This First R2; Experience E1)
- Optional form alternate: `Research/cognito_forms/cognito_forms_research.md`
- IdP / Admin claims (R1): `Research/aws_cognito/aws_cognito_research.md`
- Follow-up index: `Workshops/customer_workshop_followup_issues.md`
