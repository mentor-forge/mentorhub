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

## Field map: candidate form → Profile / Customer (R2 step 2)

**Sources (do not change schemas yet):**
- Profile: `mentorhub_mongodb_api/configurator/dictionaries/Profile.0.1.0.yaml`
- Customer: `mentorhub_mongodb_api/configurator/dictionaries/Customer.0.1.0.yaml`
- Workshop candidates: username, company name, email (+ journey: full name / org)

Dictionary note: Profile and Customer properties are all `required: false` in YAML; provisioning still needs a practical required set for the form/API (Mike/Lucky).

### Candidate form fields → existing attributes

| Candidate Squarespace field | Maps to | Dictionary type / meaning | Fit? |
| --- | --- | --- | --- |
| Full name / display name | Profile `full_name` | `sentence` — “Display name from intake (distinct from IdP username)” | **Yes — direct** |
| Email | Profile `email` | `email` | **Yes — direct**; also primary idempotency key |
| Username (IdP login name) | Profile `name` | `word` — “The IDP Username used in JWT Claims” | **Yes — if form collects it**; else API may derive from email local-part (Mike decision) |
| Company / org name | Customer `name` | `sentence` — searchable org name | **Yes — direct** |
| Company description (optional) | Customer `description` | `sentence` | **Yes — optional**; may omit from MVP form |
| Phone | — | No Profile or Customer phone property | **Gap** — drop from form, or new schema attribute later (do not add until Mike agrees) |
| Profile “about” / bio | Profile `description` | `sentence` — user comment on profile | **Unlikely on registration**; usually post-login |
| Work history | Profile `experience[]` | nested company / titles / dates | **Not registration**; later SPA/profile edit |
| Goals / interests | Profile `goals`, `interests` | array / enum_array | **Not registration** |

### Profile attributes — not from the form (API / IdP sets)

| Attribute | Set by | Registration notes |
| --- | --- | --- |
| `_id` | API on create | Returned to script / Sheet optional column |
| `status` | API default (e.g. `active`) | Confirm enum `profile_status` value at create |
| `email_verified` | API / Cognito | Likely `false` until Cognito verifies; confirm R1 |
| `customer_id` | API after Customer create/link | Required for sponsorship; JWT claim later |
| `roles` | API | Expect `["customer"]` (enum `user_roles`); confirm Mike |
| `mentor_id` | API or empty | Usually unset for new customer registrant |
| `created` / `saved` | API breadcrumbs | Not from form |
| `goals` / `interests` / `experience` | Not at registration | Leave empty / omit |

### Customer attributes — not from the form (API sets)

| Attribute | Set by | Registration notes |
| --- | --- | --- |
| `_id` | API on create | Linked onto Profile as `customer_id` |
| `status` | API default (e.g. `active`) | Enum `default_status` |
| `created` / `saved` | API breadcrumbs | Not from form |
| `subscriptions[]` | — | **Not in Customer.0.1.0** yet — billing research (R3–R5); not a form field |
| `stripe_customer_id` | — | **Not in dictionary** — future billing; not a form field |

### Gaps / decisions for Mike

| # | Question | Why it matters |
| --- | --- | --- |
| G1 | Confirm **required** Squarespace fields: at least `full_name`, `email`, `company_name`? Is **username** required or derived? | Locks Sheet columns + POST body |
| G2 | If username is omitted, how does API set Profile `name` (email local-part vs email vs other)? | IdP username + JWT |
| G3 | Does one registration always **create a new Customer**, or can it attach to an existing Customer? | F-CA05 create vs link |
| G4 | Default Profile `roles` = `["customer"]` only? | Claims + RBAC |
| G5 | Default `email_verified` at create? | Cognito Admin + Profile consistency (R1) |
| G6 | Collect **phone** or any field with **no** dictionary home? | Avoid schema creep; drop or ticket later |
| G7 | Collect Customer `description` on the form? | Optional column vs leave blank |
| G8 | Any form field needed for Cognito Admin beyond email / name / full_name? | Depends on R1; do not invent Profile fields for Cognito-only attrs |

**Verdict for schema tickets:** For the candidate form set above, **Profile and Customer already have homes** for name/email/username/company. **No dictionary change is required** for those mappings alone. Gaps are product rules (G1–G8), not missing columns — unless Mike adds phone or other new intake fields.

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

## Handoff mechanics — Squarespace → Sheet → script

**Purpose:** Describe how the registration row gets from the public site into MentorHub, what the automation does, and how retries / failure rows work. Confirm against the live Mentor Forge Squarespace form + Sheet (gap: which Google account owns the Sheet).

### How Squarespace → Google Sheet typically works

1. **Form block on the public site** — Prospect submits the Squarespace Form (Storage tab configured).
2. **Storage options** — Squarespace does not keep a durable in-form inbox by itself; connect at least one storage:
   - **Email** — notification to an inbox (optional; good as a human alert).
   - **Google Drive** — native integration that **creates/appends a Google Spreadsheet** with one row per submission ([Squarespace form storage pattern](https://www.chasinghoneyconsulting.com/blog/squarespace-built-in-forms-guide)).
3. **Connect Google Drive once per form** — In the form editor → Storage → Google Drive → connect a Google account → name the new spreadsheet. Squarespace writes form field values into columns it creates (labels → headers).
4. **Important platform limits (ops):**
   - Reconnecting Google Drive typically **creates a new Sheet**; you generally **cannot** point the form at an arbitrary existing spreadsheet ([reconnect notes](https://www.usingmyhead.com/using-my-head/how-to-safely-disconnect-and-reconnect-google-sheets-to-squarespace)).
   - After a reconnect, the **script must be attached to (or retargeted at) the new Sheet**, or provisioning stops while rows still land somewhere ops is not watching.
   - Prefer **email + Google Drive** together so a Drive outage does not lose visibility of submissions.
5. **Column reality** — First row headers come from Squarespace field labels. Ops/script may add **extra columns** on the right (`provision_status`, `sheet_row_id`, etc.) that Squarespace never overwrites. Do not rename Squarespace-owned headers without updating the script mapper.
6. **Alternates (not primary for R2)** — Zapier/Make into an existing Sheet, or Cognito Forms webhook (see `Research/cognito_forms/`). Use only if native Drive storage is insufficient.

```text
Squarespace Form submit
  → (optional) email notification
  → Google Drive storage appends 1 row to connected Sheet
  → Sheet script (trigger) reads row → POST Customer API
  → script writes provision_* columns on that row
```

### What the script does

**Runtime (proposed):** Google Apps Script bound to the registration spreadsheet (simplest ops story). Alternatives: Cloud Function on Sheet change, or Zapier “new row → HTTP” — same contract either way.

**Triggers (pick one, document it):**

| Trigger | Behavior | Tradeoff |
| --- | --- | --- |
| **On edit / on change** | Fires when Squarespace adds a row | Fast; must ignore edits to `provision_*` columns to avoid loops |
| **Time-driven (e.g. every 1–5 min)** | Scans rows where `provision_status` is empty or `pending` | Simpler; small delay; good for retries |
| **Manual “Process pending”** | Ops menu item | Backup when automation is paused |

**Per eligible row — happy path:**

1. Skip if `provision_status` is `success` (or `failed` unless ops reset to `pending`).
2. Ensure `sheet_row_id` is set (row number or UUID); write it if missing.
3. Map Sheet cells → JSON body (`full_name`, `email`, `name`, `company_name`, …) per API contract.
4. `UrlFetchApp.fetch` (or equivalent) `POST` with:
   - `Authorization: Bearer <service-token>` (Script Property / Secret — never a cell value)
   - `Idempotency-Key: <lowercased email>`
   - `Content-Type: application/json`
5. Parse response:
   - **2xx** → write `provision_status=success`, `provision_http_status`, `profile_id` / `customer_id` if returned, `processed_at`, clear or keep last `provision_error`.
   - **4xx** → write `failed` + status + error body; **do not** auto-retry.
   - **5xx / timeout** → write `pending` (or `failed` after max attempts) + status + error; allow retry.

**Secrets:** Store the service token in Apps Script **Script Properties** (or Secret Manager for non-Apps runtimes). Never commit tokens to the Sheet or to git.

**Idempotency:** Always resend the **same** `Idempotency-Key` for the same email/row so API retries do not double-create Profile / Cognito users.

### Retries

| Case | Retry? | How |
| --- | --- | --- |
| **5xx, 502, 503, 504, network timeout** | **Yes** | Backoff (e.g. next time-driven pass); same body + same `Idempotency-Key`; bump attempt count in optional `provision_attempts` column |
| **400 validation** | **No** | Leave `failed`; ops fixes cells (email typo, missing company) then sets `provision_status=pending` |
| **401 / 403** | **No** (auto) | Leave `failed`; fix script secret / API allowlist; then reset rows to `pending` |
| **409 conflict** | Per API contract | If body returns existing `profile_id` → treat as **success**; else `failed` + ops |
| **Already `success`** | **No** | Skip forever unless ops intentionally clears status for a controlled replay (rare) |

**Suggested caps:** e.g. max **5** automatic attempts, then `failed` with `provision_error=max_retries` so the row does not retry forever.

**Partial API failure:** If the API returns non-2xx, the row stays non-success. The script never marks `success` without 2xx — even if a Profile might exist server-side; idempotent replay on the next pending pass should converge.

### Failure rows (ops playbook)

| `provision_status` | Meaning | Ops action |
| --- | --- | --- |
| *(empty)* / `pending` | Not yet succeeded; eligible for script | Wait for next run, or run manual process |
| `success` | Provisioned (or idempotent replay) | Done; optional verify login with that email |
| `failed` | Client/config error or exhausted retries | Read `provision_http_status` + `provision_error`; fix data or secrets; set back to `pending` to retry |

**Filter view:** Ops should keep a Sheet filter or separate tab view: `provision_status = failed` (and optionally `pending` older than N minutes).

**Do not:**

- Delete failure rows until the root cause is understood (loses audit trail).
- Manually create Cognito users to “fix” a failed row — that bypasses Profile/`customer_id` claims.
- Edit `profile_id` by hand unless Lucky documents a repair procedure.

**Reconnect / new Sheet event:** When Squarespace creates a **new** spreadsheet after Google Drive reconnect, copy the script (or re-bind), re-add `provision_*` columns, re-set Script Properties, and smoke-test one submission before advertising registration.

### Mechanics checklist (confirm on live site)

1. Which Squarespace page/form is the registration form?
2. Which Google account owns the connected Drive Sheet?
3. Apps Script vs Zapier vs other for the POST?
4. Trigger type (on change vs time-driven)?
5. Who watches `failed` rows day-to-day?

---

## API contract (draft) — special POST Profile

**Status:** Research draft for R2 / F-CA05. Exact path and service-auth mechanism are **Lucky/Mike** to lock. Aligns with existing Customer API style: `Authorization: Bearer …`, JSON errors as `{"error": "<message>"}` (`api_utils` route wrapper).

**Caller:** Google Sheet script only (service credential). **Not** an end-user Cognito JWT from the Customer SPA.

### Request

```http
POST /api/profile/register
Host: <customer-api-host>
Authorization: Bearer <service-token>
Content-Type: application/json
Idempotency-Key: <idempotency-key>
```

| Part | Draft value | Notes |
| --- | --- | --- |
| **Method / path** | `POST /api/profile/register` | Path is illustrative; final route name is F-CA05. Prefer a **special** path so it is not confused with generic Profile CRUD |
| **Authorization** | `Bearer <service-token>` | Same header shape as other APIs; token is a **service** secret (or future M2M), **not** a user IdP access token. Missing/invalid → **401** |
| **Content-Type** | `application/json` | Required |
| **Idempotency-Key** | See below | Required for safe retries |

Optional alternate if Bearer service JWT is not ready: `X-Registration-Secret: <shared-secret>` **in addition to or instead of** Bearer — pick one scheme and document it; do not leave both ambiguous in production.

### Idempotency key

| Rule | Draft |
| --- | --- |
| **Header** | `Idempotency-Key: <value>` |
| **Recommended value** | Lowercased trimmed `email` (stable across Sheet retries) |
| **Also accept / store** | `sheet_row_id` in body so ops can correlate; API may treat `(email)` or `(email + sheet_row_id)` as the dedupe key — **Mike/Lucky choose one** |
| **Behavior** | Same key + same logical registration → **same outcome**, no second Profile / Customer / Cognito user |
| **Replay response** | Prefer **200** with the existing resource ids (script treats as success). Avoid **409** unless product wants “already exists” as a distinct ops signal — if **409**, script still marks row `success` when body includes existing `profile_id` |

Do **not** put a second copy of the key only in the body without the header; header is what the script retries with.

### JSON body (request)

```json
{
  "full_name": "Jane Customer",
  "email": "jane@example.com",
  "name": "jane.customer",
  "company_name": "Acme Mentoring Co",
  "company_description": "Optional org blurb",
  "sheet_row_id": "row-42"
}
```

| Field | Required (draft) | Maps to | Notes |
| --- | --- | --- | --- |
| `full_name` | **Yes** | Profile `full_name` | Display name |
| `email` | **Yes** | Profile `email` | Normalize lowercase; idempotency basis |
| `name` | No* | Profile `name` (IdP username) | *Required if Mike keeps username on form; else API derives (see field map G2) |
| `company_name` | **Yes** | Customer `name` | Creates or links Customer per G3 |
| `company_description` | No | Customer `description` | Omit or empty string OK |
| `sheet_row_id` | **Yes** | Ops correlation only | Not a Profile property; store for logs / support |

**Not in body (API sets):** `profile_id` / `_id`, `customer_id`, `roles`, `email_verified`, `status`, `mentor_id`, breadcrumbs, Cognito claims.

### JSON body (success response)

**201 Created** — first successful provision:

```json
{
  "profile_id": "A00000000000000000000099",
  "customer_id": "D00000000000000000000099",
  "email": "jane@example.com",
  "idempotency_key": "jane@example.com",
  "created": true
}
```

**200 OK** — idempotent replay (already provisioned for this key):

```json
{
  "profile_id": "A00000000000000000000099",
  "customer_id": "D00000000000000000000099",
  "email": "jane@example.com",
  "idempotency_key": "jane@example.com",
  "created": false
}
```

Script: any **2xx** with `profile_id` → Sheet `provision_status=success`.

### Error response shape

Match existing APIs:

```json
{ "error": "Human-readable message" }
```

### Status codes the Sheet script should expect

| HTTP | When | Script action | `provision_status` |
| --- | --- | --- | --- |
| **201** | New Profile (+ Customer) + Cognito Admin create succeeded | Save `profile_id` / `customer_id`; done | `success` |
| **200** | Idempotent replay; resources already exist | Save ids from body; done | `success` |
| **400** | Validation (missing `email`, bad JSON, unknown fields if strict) | Do **not** auto-retry; fix Sheet row | `failed` |
| **401** | Missing/invalid `Authorization` (or registration secret) | Stop retries; alert ops (secret/config) | `failed` |
| **403** | Authenticated but not allowed to call register | Stop retries; alert ops | `failed` |
| **409** | Optional: duplicate email with **different** payload / conflict policy | If body has existing ids → treat as success; else `failed` + ops | `success` or `failed` |
| **404** | Should not happen for register; misconfigured path | Stop; fix script URL | `failed` |
| **500** | Server / Cognito / DB failure mid-provision | Retry with backoff + same `Idempotency-Key` | leave `pending` (or `failed` after max attempts) |
| **502 / 503 / 504** | Upstream / gateway unavailable | Retry with backoff + same key | leave `pending` |
| *(network timeout)* | No HTTP status | Retry with backoff + same key | leave `pending` |

**Partial failure:** If Profile is written but Cognito Admin fails, API should return **5xx** (not 2xx) until both succeed or a documented compensating path exists — script must not mark `success` without a 2xx.

### Script expectations (summary)

1. Always send `Authorization` + `Content-Type` + `Idempotency-Key`.
2. On **2xx** → `success` + store ids.
3. On **400 / 401 / 403 / 404** → `failed`; no blind retry.
4. On **5xx** or transport errors → retry with **same** idempotency key; cap attempts.
5. Never call Cognito Admin from the Sheet script.

### Still TBD for Lucky / Mike

- Final path name and whether register lives under Profile or a `/registration` namespace.
- Service token vs shared-secret header (one scheme).
- Exact idempotency key formula (`email` vs `email`+`sheet_row_id`).
- Whether **409** is used or only **200** replay.
- Whether `name` is required in the body.

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
