# Customer Workshop Follow-up Issues

Sources:

- `Workshops/customer_workshop_2.md` (User Journey Make — pages, rules, data)
- `Research/stripe_research.md` (2026-07-21 encounter decisions + research checklist)
- Cognito notes in `Research/stripe_research.md` (no separate Cognito research file yet — create/update account payloads still open research)
- `Workshops/exercise_templates/` (journey mapping Make → tickets per UI page, API, data)
- Existing SPA nav in `mentorhub_customer_spa` (legacy Subscriptions / Dashboards / Cards / Events / Profiles / …)

Naming: `Type-UserLayer##` per [CONTRIBUTING.md](../CONTRIBUTING.md) (`F-UC` Customer SPA, `F-AC` Customer API, `F-D` Data, `F-W` Welcome). **Mary assigns `##` when filing.**

**Do not change schemas until research tickets are ready** (Mike, 2026-07-21). Use this list to open GitHub issues.

---

## Customer SPA (`mentorhub_customer_spa`) — `F-UC`

| Issue title | Description |
| --- | --- |
| **Clean up Customer SPA navigation drawer** | Replace legacy CRUD nav (Subscriptions list/new, Dashboards list/new, Cards list/new, Events, Profiles, Customers, Journeys, Ratings, Notes) with Customer-journey destinations only (Dashboard, Plans/Cart, Billing/Subscription, Mentors, Account). Keep Admin (role-gated) and Logout. Align labels/routes with the pages below. |
| **Plans / Trial page** | Show offerings and free-trial entry. Blocked on free-trial rules ([#36](https://github.com/mentor-forge/mentorhub/issues/36)). |
| **Shopping cart / Subscribe / Checkout page** | Build cart (product, quantity, unit price / capacity). Checkout redirects to Stripe Checkout; handle success and cancel return URLs. Support discount / donated-capacity codes. No card form in MentorHub. |
| **Invite Coordinator page** | Invite with name + email only; optional self-mark as coordinator. |
| **Find Mentor / Available Mentors page** | Let Customer choose a mentor by needs (not only assigned). |
| **Dashboard / Mentee Activity page** | Home view: mentee roster and activity (resources completed, notes, encounters). Default after login when subscribed. |
| **Team Progress page** | Team-level progress with mentors (Dave persona). |
| **Program ROI / Status page** | Board/budget-ready mentorship status summary (Stacey persona). |
| **Mentee Detail page** | Drill-down: encounters, ratings, mentor notes, customer notes, last-week events, encounter TL;DRs; leave a focus note for the mentor. |
| **Billing page** | Delay payment, payment-failure state, entry to Stripe Customer Portal for payment method. |
| **Subscription page** | Change capacity (add/remove mentee schedule), hold, view plan status from `Customer.subscriptions[]`. |
| **Promos page** | Long-tenure promos (e.g. after two years). |
| **Cancel subscription page / flow** | Cancel via Stripe Customer Portal (preferred) or confirmed cancel path; return to unsubscribed CTA. |
| **Account / Privacy page** | Request PII removal (GDPR) for Profile/Encounter PII — action + status, not a Customer commerce editor. |
| **Payment-failed notification UI** | In-app banner (and/or copy for email) when webhook marks payment failed / `past_due`. |
| **Weekly Progress Email surface** | No-login weekly progress email template/content (may ship as email job + template rather than SPA route). |
| **Post-Cognito Customer onboarding** | After Cognito identity exists, collect company/org fields and wire Customer + Profile linkage (signup/password/2FA stay in Cognito Hosted UI / Amplify — not custom auth pages). |

---

## Customer API (`mentorhub_customer_api`) — `F-AC`

One issue per collection the Customer API owns or fronts for this journey (endpoints for that collection’s lifecycle + SPA needs). Stripe Checkout/Portal/webhooks hang off **Customer** and **Payment** as noted.

| Issue title | Description |
| --- | --- |
| **Customer collection API** | Endpoints for Customer CRUD/read for JWT owner; embedded `subscriptions[]` status; cart → Checkout Session; Billing Portal session; capacity/hold/delay/cancel; trial start (after #36); discount/token apply; coordinator invite; self-mark coordinator; privacy action trigger. Link `stripe_customer_id`. No card PANs. |
| **Product collection API** | Endpoints to list/read Products (and Price mappings) used by Plans / cart. Map partner / third-party / individual offerings to Stripe Product/Price IDs (config or DB). |
| **Payment collection API** | Stripe webhook receiver (signature verify, idempotent); persist payment / attempt payloads; read APIs for billing history and payment-failed signals; support weekly/ROI aggregates that need payment outcomes. |
| **Profile collection API (Customer journey)** | Post-Cognito provisioning/update: ensure Profile claims and `customer_id` linkage; fields required by Cognito **create account** / **update account** (per Cognito research). Password reset / MFA remain Cognito — not custom auth APIs. |

---

## MongoDB API (`mentorhub_mongodb_api`) — `F-D`

One issue per collection to **define schema and test data** (dictionary + `test_data`). Align with Stripe research planned shape.

| Issue title | Description |
| --- | --- |
| **Customer schema + test data** | Extend Customer for org/payer fields, `stripe_customer_id`, and **`subscriptions[]`** (capacity, trial/active/hold/cancel, product/price refs, Stripe subscription ids, failure/delay flags). Seed test customers covering trial, active, hold, past_due, canceled. Drop reliance on top-level Subscription docs. |
| **Product schema + test data** | New Product dictionary (name, description, Stripe product/price ids, offering type: partner / third-party / individual, status, breadcrumbs). Seed products matching Plans/cart research. |
| **Payment schema + test data** | New Payment (or PaymentAttempt — name after webhook research) dictionary matching Stripe webhook payloads (paid + failed). Seed documents linked by customer/subscription/Stripe ids for success and failure scenarios. |
| **Profile schema + test data (Cognito fields)** | Ensure Profile can store every attribute needed for Cognito create/update account; keep `customer_id` roster link; seed profiles tied to Customer test data. |
| **Remove Card collection schema + test data** | Delete Card dictionary, configuration, and test data — cards live only in Stripe. |
| **Remove Subscription collection schema + test data** | Delete top-level Subscription dictionary/config/test data after subscriptions are embedded on Customer. |
| **Remove Dashboard collection schema + test data** | Delete Dashboard dictionary/config/test data for MVP (no configurable dashboard). Fixed customer dashboard is SPA/API aggregation, not a Dashboard collection. |

---

## Welcome / platform cleanup — `F-W` / `F-S`

| Issue title | Description |
| --- | --- |
| **Remove coordinator_api / coordinator_spa and mentorhub references** | Remove `mentorhub_coordinator_api` and `mentorhub_coordinator_spa` from local/dev usage and strip references in the **mentorhub** repo: welcome/`index.html` links, `welcome-auth.js` personas if coordinator-only entries should go, `DeveloperEdition/docker-compose.yaml` services (`coordinator_api`, `coordinator_spa`) and depends_on profiles, workspace/docs mentions, and any other mentorhub pointers to those images/repos. Coordinate with Mike before deleting remote repos; this issue is mentorhub reference + compose cleanup. |

---

## Suggested filing order

1. MongoDB: Customer (+ subscriptions) → Product → Payment → Profile Cognito fields → drop Card / Subscription / Dashboard  
2. Customer API: Customer → Product → Payment → Profile provisioning  
3. Customer SPA: **nav cleanup** → Cognito onboarding → Plans/Cart/Checkout → Billing/Subscription → Dashboard/Mentee Detail → Invites/Mentors → ROI/Promos/Privacy/notifications  
4. Welcome: remove coordinator_api/spa references  

---

## Out of scope (from workshop / encounter)

- Mentee Journey “pick up studies” — Mentee product  
- Organizing mentees as Dev Lead tooling — Coordinator/Mentor product (until Mike finishes reflecting on merge)  
- Custom password/2FA/login APIs — **AWS Cognito**  
- Storing payment cards in MongoDB  
- Configurable Dashboard collection for MVP  
- Schema edits before Stripe/Cognito research findings are recorded  
