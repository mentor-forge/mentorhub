# Cognito Forms Research Summary

**Related issue:** [F-W04: Cognito Research](https://github.com/mentor-forge/mentorhub/issues/33) (AWS Cognito IdP research is adjacent — this document is **Cognito Forms**, the form product at [cognitoforms.com](https://www.cognitoforms.com), not AWS Cognito).

**Context:** Customer onboarding journey — public registration form → automation → MentorHub `POST Profile` → AWS Cognito Admin create user with custom claims (`profile_id`, `customer_id`, `mentor_id`, `roles`). See `Workshops/customer_journey_issues.md` (Do This First R1–R2; Experience E1).

**Team touch points:**

| Person | Area | Repo |
| --- | --- | --- |
| **Mary** | Registration / form / IdP data research | `mentorhub/Research` |
| **Lucky** | Customer API (special `POST Profile`) | `mentorhub_customer_api` |
| **Daniel** | Customer SPA (login only — no signup form) | `mentorhub_customer_spa` |

**Naming rule:** Prefer **Cognito Forms** in docs when meaning the form builder. Prefer **AWS Cognito** when meaning the IdP.

**Schema rule (Mike):** Do **not** change MongoDB dictionaries/schemas until research workflows and payloads are locked; then create tickets.

---

## Decisions (MentorHub onboarding)

| Decision | Detail |
| --- | --- |
| **Public registration off SPA** | New customers register on a **public form** (Cognito Forms and/or site embed), not via Customer SPA Cognito Hosted UI self-signup. |
| **Why not Hosted UI self-signup alone** | APIs require JWT custom claims (`profile_id`, `customer_id`, `mentor_id`, `roles`). Hosted UI self-onboarding does not reliably set those MentorHub claims. |
| **Provision via Admin path** | After form submission, Customer API creates Profile (+ Customer as designed) and creates the IdP user via **AWS Cognito Admin API** with custom claims. |
| **SPA auth already done** | Customer SPA IdP redirect / JWT guards are sufficient; no new signup UI ticket. |
| **Do not change schemas yet** | Research form fields + webhook/Sheet payloads first. |

---

## Recommended integration options

| Option | Flow | Pros | Cons |
| --- | --- | --- | --- |
| **A. Cognito Forms → JSON Webhook → Customer API** ⭐ | Form Settings → Post JSON Data to Website → `POST` special Profile endpoint | Direct, real-time, no Sheet hop; full entry JSON | Needs Pro/Team/Enterprise; endpoint must be public HTTPS + auth |
| **B. Cognito Forms → Zapier/Make → Google Sheets → script → API** | Matches earlier Sheet-based ops idea | Human-visible queue in Sheets; easy retries/manual fix | Extra latency/moving parts; Zapier/Make plan limits |
| **C. Cognito Forms → Zapier/Make → HTTP to Customer API** | Skip Sheet; automation posts to API | No custom webhook config in form; field mapping in Zap | Third-party dependency |
| **D. Squarespace native form only** | Site form → Sheet/script | Already discussed in journey draft | Not Cognito Forms; document separately if chosen |

**Recommendation for research:** Prefer **Option A** (webhook → special `POST Profile`) for production reliability; keep **Option B** as an ops-visible alternative if the team wants a Sheet buffer.

---

## Workflow (to verify)

```text
Prospect
  → opens public Cognito Form (standalone link or embedded on public site)
  → submits registration (name, company, email, … TBD)

Cognito Forms
  → Option A: POST JSON webhook (Submit Entry Endpoint) → Customer API special POST Profile
  → Option B: Zapier/Make → new Google Sheet row → Apps Script / automation → POST Profile

Customer API (Lucky)
  → authenticate service caller (shared secret / API key / m2m — TBD)
  → create Profile (+ Customer org as designed)
  → AWS Cognito AdminCreateUser (or equivalent) with custom claims:
        profile_id, customer_id, mentor_id, roles (e.g. ["customer"])
  → idempotent on email / entry id

Customer (later)
  → opens Customer SPA → existing auth guards → AWS Cognito login
  → JWT already carries required claims → Customer API accepts calls
```

---

## Outbound: Cognito Forms → MentorHub

### JSON Webhooks (native)

Per [Webhooks docs](https://www.cognitoforms.com/support/66/data-integration/webhooks) (Pro / Team / Enterprise):

| Setting | Role |
| --- | --- |
| **Post JSON Data to a Website** | Enable under form Settings |
| **Submit Entry Endpoint** | HTTPS URL for **new** entries |
| **Update Entry Endpoint** | HTTPS URL for **updated** entries (status not Incomplete) |
| **Delete Entry Endpoint** | HTTPS URL for **deleted** entries |

Notes from vendor docs:

- All entry field data is included; customize JSON property names in Developer Mode.
- Save & Resume does **not** trigger webhooks.
- File/document links in JSON expire quickly (~30 minutes) — download promptly if needed.
- On 4XX/5XX, Cognito Forms retries up to **15 times over 72 hours** (no retry on 404, 410, 413).
- Use entry **audit log** to debug integration failures.

**Research must capture:** a real sample Submit Entry JSON for our registration form (use [webhook.site](https://webhook.site) or local tunnel) and map each field → Profile / Customer / Cognito attributes.

### Google Sheets path (Zapier / Make)

Per [Send form data to Google Sheets](https://www.cognitoforms.com/support/814/how-to-guides/send-form-data-to-google-sheets-automatically):

- Cognito Forms does **not** write Sheets natively; use **Zapier** or **Make** (Pro/Team/Enterprise + Zapier/Make account).
- Typical: Trigger **New Entry** → Action **Create Spreadsheet Row**; map form fields → columns.
- Optional: Update Entry → update row; Sheets change → update Cognito Forms entry (two-way).
- Use Entry Number / Entry ID as stable key when updating rows.

**If MentorHub uses Sheets as a buffer:** document Sheet columns, script auth to Customer API, and idempotency (do not double-create Cognito users).

---

## Inbound: MentorHub expectations (special POST Profile)

| Concern | Research need |
| --- | --- |
| **Auth** | How the webhook/script proves itself (Bearer service token, HMAC signature, IP allowlist, API key header) |
| **Payload** | Exact JSON (native webhook vs Sheet-mapped body) |
| **Idempotency** | Key on Cognito Forms Entry Id / email so retries do not create duplicate Profiles or Cognito users |
| **Success / error** | Return codes that play well with Cognito Forms retry rules (avoid 404/410/413 if retry is desired) |
| **AWS Cognito** | Admin create/update attribute list + custom claims (see F-W04 / AWS Cognito research) |

---

## Candidate registration fields (workshop-aligned; confirm on form)

| Field | Likely destination |
| --- | --- |
| Name / full name | Profile / Cognito |
| Email | Profile / Cognito username or email |
| Company / org name | Customer |
| Optional phone, etc. | TBD after form design |

Workshop (Customer Workshop 2): signup needs **username, company name, and email** — map Cognito Forms labels to those concepts.

---

## Anti-patterns

| Anti-pattern | Why it’s wrong | Prefer |
| --- | --- | --- |
| **Rely on Cognito Hosted UI self-signup for MentorHub claims** | Custom claims required by all APIs won’t be set | Form → API → AdminCreateUser with claims |
| **Build registration UI in Customer SPA** | Duplicates public form; auth redirect already exists | Public Cognito Form + SPA login only |
| **Trust webhook body without service auth** | Anyone could POST fake profiles | Authenticate special POST Profile |
| **Non-idempotent create on webhook retry** | Cognito Forms retries on 5XX → duplicate users | Idempotent on entry id / email |
| **Confusing Cognito Forms with AWS Cognito in tickets** | Wrong research / wrong owners | Explicit product names in issue titles |
| **Change Profile schema before sample payloads** | Rework | Capture webhook JSON first → then tickets |

---

## Gaps (open research checklist)

1. **Confirm product choice** — Cognito Forms vs Squarespace native form vs both (embed).
2. **Plan tier** — Webhooks / Zapier require Pro+; confirm org plan.
3. **Capture sample Submit Entry JSON** for the real registration form.
4. **Choose Option A vs B vs C** for MentorHub handoff.
5. **Lock special POST Profile** auth, payload, idempotency, and error codes.
6. **Complete AWS Cognito Admin create/update + custom claims research** (F-W04) so Profile fields are complete.
7. **Embed vs hosted link** — how the public site presents the form.
8. **PII / retention** — where form entries live (Cognito Forms, Sheet, MentorHub) and GDPR implications.

Document findings in this folder (`Research/cognito_forms/`) so the team can use them. Schema edits wait for tickets.

---

## MentorHub touch points (by repo)

| Area | Responsibility |
| --- | --- |
| **Research (this folder)** | Form workflow, webhook/Sheet payloads, field map, gaps |
| **Customer API** | Special `POST Profile` + AWS Cognito Admin provisioning |
| **Customer SPA** | Login/return only — no registration form |
| **AWS Cognito (IdP)** | User pool custom attributes / claims (separate from Cognito Forms) |
| **Public site** | Link or embed Cognito Form |

---

## Key takeaways

- **Cognito Forms** = public registration data collection; **AWS Cognito** = login IdP with MentorHub custom claims.
- Target flow: **form submit → webhook (or Sheet automation) → POST Profile → AdminCreateUser with claims → SPA login**.
- Prefer native **JSON webhooks** to Customer API when plan allows; Sheets via Zapier/Make if ops need a visible queue.
- Do not invent SPA signup or trust unauthenticated webhook posts.
- Finish sample payloads + AWS Cognito claim research before schema/tickets.

---

## References

### Cognito Forms

- [Cognito Forms home](https://www.cognitoforms.com)
- [Webhooks](https://www.cognitoforms.com/support/66/data-integration/webhooks)
- [JSON Webhooks integration](https://www.cognitoforms.com/integrations/26/json-webhooks)
- [Google Sheets integration](https://www.cognitoforms.com/integrations/94/google-sheets)
- [Send form data to Google Sheets (Zapier/Make)](https://www.cognitoforms.com/support/814/how-to-guides/send-form-data-to-google-sheets-automatically)
- [Integration tools / API overview](https://www.cognitoforms.com/integrations/integration-tools)
- [webhook.site](https://webhook.site) — capture sample payloads

### MentorHub

- Journey / E1: `Workshops/customer_journey_issues.md`
- Stripe parallel research style: `Research/stripe_research.md`
- AWS Cognito create/update (IdP): F-W04 + AWS docs linked from `Research/stripe_research.md` Cognito section
