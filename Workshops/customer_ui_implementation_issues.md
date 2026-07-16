# Customer UI — Implementation Issues

Source: Customer Workshop 2 (`Workshops/customer_workshop_2.md`).  
Scope: Customer SPA, Customer API, and MongoDB.  
Existing epics: [#38](https://github.com/mentor-forge/mentorhub/issues/38) SPA · [#39](https://github.com/mentor-forge/mentorhub/issues/39) API · [#40](https://github.com/mentor-forge/mentorhub/issues/40) data · [#36](https://github.com/mentor-forge/mentorhub/issues/36) trial rules.

---

## Cross-cutting

| ID | Issue | Notes |
|----|--------|--------|
| F-W02 / #36 | Define free trial rules | Blocks Plans/Trial UI + API |
| — | Agree Customer ↔ Profile ↔ mentee seat model | Org Customer vs buyer Profile |
| — | Stripe Checkout + Portal + webhooks (per F-W03 research) | Shared by API + data |

---

## Database (`mentorhub_mongodb_api`)

| ID | Issue | Data |
|----|--------|------|
| F-D / #40 | Extend **Customer** collection | company, Stripe customer id, GDPR request, self-coordinator flag |
| F-D | Extend **Subscription** collection | capacity, status (trial/active/hold/cancel), seats/schedule, tokens, promo eligibility, Stripe sub id, failure/delay flags |
| F-D | Coordinator **Invite** model | name, email, status (new collection or embed on Customer) |
| F-D | Customer → mentee roster link | confirm/use `Profile.customer_id`; seat membership if needed |
| F-D | Customer notes to mentors | home for workshop “leave a note” (extend Note or Mentee) |
| F-D | Mentor rating (person, not resource) | workshop mentee-detail rating gap vs resource Rating |
| F-D | Discount / donated-capacity tokens | fields on Subscription or Token collection |
| F-D | GDPR deletion request status | on Customer |
| F-D | (Optional) Dashboard / ROI read model | weekly email + Program ROI aggregates |
| F-D | Test data for Customer subscription scenarios | trial, active, hold, failed payment |

---

## Customer API

| ID | Issue | Supports |
|----|--------|----------|
| F-CA / #39 | Customer API epic from Workshop 2 | umbrella |
| F-CA | Auth: signup, password reset, 2FA session support | Sign Up, Login |
| F-CA | Create/read Customer + Profile on signup | Sign Up |
| F-CA04 | Subscription / Billing API | Checkout, Billing, Subscription, Cancel, Promos |
| F-CA | Stripe Checkout session + return handling | Subscribe / Checkout |
| F-CA | Stripe Customer Portal session | Billing / payment method |
| F-CA | Stripe webhooks (idempotent; no double-charge) | subscription + invoice sync |
| F-CA | Trial start / eligibility (after #36) | Plans / Trial |
| F-CA | Capacity change, hold, delay payment, cancel | Subscription / Billing / Cancel |
| F-CA | Apply discount / donated-capacity codes | Checkout |
| F-CA | Coordinator invite create/list; self-mark coordinator | Invite Coordinator |
| F-CA | Available mentors + match-by-needs | Find Mentor |
| F-CA02 | Team progress + mentee activity APIs | Dashboard, Team Progress |
| F-CA | Mentee detail aggregate (rating, notes, events, TL;DRs) | Mentee Detail |
| F-CA | Post customer note for mentor | Mentee Detail |
| F-CA | Program ROI / status summary | Program ROI |
| F-CA | GDPR deletion request API | Account / Privacy |
| F-CA | Payment-failed signal for notify | Notifications |
| F-CA | Weekly progress summary payload (for email job) | Weekly Progress Email |

---

## Customer SPA (`mentorhub_customer_spa`)

| ID | Issue | Page / surface |
|----|--------|----------------|
| F-UC / #38 | Customer SPA epic from Workshop 2 UI checklist | umbrella |
| F-UC | Sign Up page | username, company, email |
| F-UC | Login / Reset Password | |
| F-UC | Login 2FA | double verification |
| F-UC | Plans / Trial page | blocked on #36 |
| F-UC | Subscribe / Checkout + Stripe return URLs | capacity, codes, pay |
| F-UC | Invite Coordinator page | name + email only |
| F-UC | Find Mentor / Available Mentors | choose by needs |
| F-UC | Dashboard / Mentee Activity | roster + activity |
| F-UC | Team Progress page | Dave persona |
| F-UC | Program ROI / Status page | Stacey / board |
| F-UC | Mentee Detail page | drill-down + leave mentor note |
| F-UC | Billing page | delay pay, failures, method |
| F-UC | Subscription page | seats, hold |
| F-UC | Promos page | long-tenure promos |
| F-UC | Cancel flow | |
| F-UC | Account / Privacy (GDPR) | |
| F-UC | Payment-failed notification UI (and/or email copy) | |
| F-UC | Weekly Progress Email template (no-login) | may be API/email only |

---

## Suggested build order

1. Data: Customer + Subscription (+ Profile links)
2. API: Signup/auth + Subscription/Billing (F-CA04) + Stripe
3. SPA: Sign Up → Checkout → Billing/Subscription
4. Data/API: Invites, mentor match
5. API/SPA: Dashboard, Mentee Detail, notes, ROI
6. Trial (#36), Promos, GDPR, notifications/email

---

## Out of Customer UI scope (workshop)

- Mentee Journey / “pick up studies” — Mentee product
- Dan’s mentee organize list — Coordinator / Mentor tooling
