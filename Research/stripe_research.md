# F-W03: Stripe API, Billing & Subscriptions Research Summary

**Issue:** [#32 — F-W03: Stripe Research](https://github.com/mentor-forge/mentorhub/issues/32)

**Source encounter:** [2026-07-21 Mary Anderson](file:///mnt/c/Users/mande/Downloads/2026-07-21%20Mary-Anderson.md) (Mike Storey / Mary Anderson) — shopping-cart → Stripe Checkout workflow, data-model simplification, research-before-schema-change.

**Team assignments for Customer Subscription UI:**

| Person | Area | Repo |
| --- | --- | --- |
| **Daniel** | Customer SPA (UI) | `mentorhub_customer_spa` |
| **Lucky** | Customer API | `mentorhub_customer_api` |
| **Mary** | Stripe / Cognito data research | `mentorhub/Research` |

**Recommended integration:** Stripe **Checkout** (subscribe) + **Customer Portal** (manage / unsubscribe) + **webhooks** (persist payment outcomes). Stripe is not an IdP — login stays Cognito / local `welcome-auth.js`.

**Schema rule (Mike):** Do **not** change MongoDB dictionaries/schemas yet. Research workflows and payloads first; schema + test-data work become tickets after ERD / journey reflection.

---

## Decisions from encounter 2026-07-21 (Mike / Mary)

| Decision | Detail |
| --- | --- |
| **No card storage in MentorHub** | Credit/debit card data stays in Stripe only. Drop the `Card` collection to avoid PCI / regulatory burden. |
| **Checkout workflow (to verify)** | In MentorHub UI the customer builds a **shopping cart** (subscription + quantity / unit price). MentorHub **forwards** the user to Stripe Checkout with that cart payload. Stripe collects payment. |
| **Subscriptions on Customer** | Drop the standalone `Subscription` collection. A **Customer** document owns an **array of subscriptions**. Subscriptions have no meaning outside a customer. |
| **Persist webhook payloads** | Add a collection (likely **`Payment`** / payment attempts — final name TBD after webhook research) for Stripe callback data so we keep a cross-customer billing history (success and failure). |
| **Products / prices** | Expect a **Product** (or subscription-type) concept referenced from customer subscriptions — e.g. partner vs third-party vs individual, each with pricing. Research what Stripe Product/Price IDs we must configure and store. |
| **Drop MVP custom dashboard** | Drop the `Dashboard` collection for MVP. Customer gets a fixed customer dashboard later; configurable dashboards are a future feature. |
| **Do not change schemas yet** | Research workflows and data structures first. Schema + test-data changes become tickets after Mike reflects on ERD / journey boundaries. |
| **Cognito (related)** | Login redirect / mock login is largely done. Still research **create account** and **update account** payloads so Profile has the fields those calls need. |
| **Configurator hygiene** | Prefer **delete + create** over rename when replacing collections (rename touches many places). Manual delete is often easiest. |

**Under reflection (no action yet):** Mike is considering whether Customer and Coordinator journeys share one UI/API (likely named coordinator). **Customer role would still own subscriptions; Coordinator would not.** Final naming/repo boundaries TBD — do not delete customer SPA/API until that decision lands.

---

## Design method (from encounter)

Mike’s breakdown for finishing F-W02-style work — apply the same pattern to billing:

1. **User journey** — write the pages the user visits and what they do on each.
2. **UI (one ticket per page)** — what appears on screen; what the user can click.
3. **API** — what each page needs the API to do; where data must be combined for the front end.
4. **Data** — what must live in MongoDB vs what Stripe/Cognito own; what test data each page needs.

For billing, identity uses our IdP JWT (`roles: customer`, `customer_id`). Stripe only handles payment. Cards are never entered into MentorHub forms.

---

## Workflow (as discussed — to verify in Stripe docs)

```text
First login
  IdP → Customer SPA (Daniel) → JWT → Customer API (Lucky)
       → GET Customer → subscriptions empty → plan / cart CTA

Subscribe
  Daniel: shopping cart page → “this is what I’m buying”
  Daniel: Checkout → POST checkout-session (cart payload)
  Lucky:  ensure Stripe Customer linked; create Checkout Session → checkout_url
  Daniel: redirect browser to Stripe Checkout (card collected on stripe.com)
  User pays (or cancels)
  Stripe → Lucky webhook → persist payment/attempt doc + update Customer.subscriptions[]
  Daniel: success/cancel URL → refetch Customer → Active or cancelled cart state

Manage / unsubscribe
  Daniel: Manage billing → POST portal-session
  Lucky:  Billing Portal session → portal_url
  Daniel: redirect to Stripe Portal → user updates card / cancels
  Stripe → Lucky webhook → persist + update Customer.subscriptions[]
  Daniel: refresh → show Resubscribe / past_due banner as needed
```

**Amazon analogy (Mike):** MentorHub owns “browse + cart”; Stripe owns “checkout where you enter the card.”

**Webhook assumption to verify:** Mike’s starting belief is we mainly care about **payment processed** and **payment rejected**. Research must confirm actual [event types](https://docs.stripe.com/api/events/types) — subscription lifecycle events are also required to keep `Customer.subscriptions[]` accurate.

---

## UI (Customer SPA — Daniel)

Persona: **Cat the Customer** (paying sponsor).

### Pages / surfaces (candidate tickets — one per page)

| Page / surface | User experience | Notes from encounter |
| --- | --- | --- |
| **Login / return** | IdP or mock `login.html` → land in Customer SPA with JWT | Cognito login redirect largely done; not Stripe |
| **Customer home / fixed dashboard** | Shell + sponsored views; CTA **“Choose a plan”** if no active subscription | Configurable `Dashboard` collection **dropped for MVP** |
| **Shopping cart / plan picker** | Describe offering (partner / third-party / individual), quantity, displayed price; primary action **Checkout** | Cart is the MentorHub-side purchase description before Stripe |
| **Checkout redirect** | Loading → browser leaves for Stripe Checkout | No MentorHub card form |
| **Checkout success** | “Confirming…” → refetch Customer → show **Active**, plan, renewal, **Manage billing** | Do not invent paid state from URL alone — wait for API / webhook-synced data |
| **Checkout cancel** | “Payment cancelled” → return to cart / plans | No paid subscription |
| **Active subscription summary** | Status, plan, renewal; gate premium UI | Reads MentorHub Customer, not live Stripe on every paint |
| **Payment failed banner** | “Payment failed — update billing” | Driven by failure webhook → `past_due` (or agreed status) |
| **Manage billing** | Button → redirect to Stripe Customer Portal | Cancel / update payment method in Portal |
| **Profile** | Name, email, basics; account create/update fields for Cognito | Must hold every Cognito create/update attribute we need |

**Daniel does not:** call Stripe with a secret key, collect card numbers, or invent subscription state client-side.

### Phase tables (UI ↔ API)

#### Phase 1 — First login

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 1 | Opens Customer SPA (or welcome with `return_to`) | Load SPA; redirect unauthenticated users to IdP / `login.html` | — (auth is IdP / `spa_utils`, not Stripe) |
| 2 | Signs in with customer persona | Store session (token, `roles`, `customer_id`) | Validate JWT; reject if missing `customer` role |
| 3 | Lands on Customer home | Shell; if no active subscription, CTA **Choose a plan** | Read status from **Customer.subscriptions[]** (MongoDB), not live Stripe |
| 4 | Sees “not subscribed” state | Offerings, benefits, start-cart / **Subscribe** | Do **not** call Stripe until checkout |

#### Phase 2 — Subscribe (cart → Checkout)

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 5 | Builds **shopping cart** | Cart UI; **Checkout** | Optional `GET /plans` mapping offerings → Stripe Price IDs |
| 6 | Clicks Checkout | `POST /billing/checkout-session` with cart; redirect to Stripe | Link Stripe Customer; create Checkout Session (`mode: subscription`, line items, success/cancel URLs, metadata); return `{ checkout_url }` |
| 7 | Pays on Stripe Checkout | On **stripe.com** — SPA idle | Card never hits MentorHub; store `stripe_customer_id` when known |
| 8a | Cancels Checkout | Cancel URL → cancelled messaging | Do not invent paid subscription |
| 8b | Pays successfully | Success URL → confirming → refetch | Webhooks: e.g. `checkout.session.completed`, `invoice.paid`, subscription events |
| 9 | Webhook arrives | — | Verify signature; **persist payload**; update **Customer.subscriptions[]** |
| 10 | Sees subscribed state | Show **Active**, plan, renewal, **Manage billing** | Return Customer with subscriptions for JWT owner |

#### Phase 3 — Use while subscribed

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 11 | Uses sponsored views | Gate premium UI on active subscription | Enforce access (403 if not active); no Stripe call per page load |
| 12 | Renewal payment fails | Banner → update billing | `invoice.payment_failed` → persist; mark `past_due` |
| 13 | Opens Manage billing | `POST /billing/portal-session` → Portal | Create Portal session; return `{ portal_url }` |

#### Phase 4 — Unsubscribe

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 14–15 | Cancels in Portal | Prefer Portal for cancel; refetch after return | `customer.subscription.updated` / `deleted` → update Customer; persist webhook doc |
| 16 | Unsubscribed | Resubscribe CTA; hide premium UI | Inactive/canceled; 403 on premium resources |

---

## API (Customer API — Lucky)

### Endpoints (planned)

| Method / path | Purpose | Stripe call |
| --- | --- | --- |
| `GET /plans` (or Product config) | Map MentorHub offerings → Stripe Price/Product IDs for cart UI | Optional read of configured Price IDs (usually env/config, not live Stripe list on every request) |
| `GET` Customer (existing / extended) | Return Customer including `subscriptions[]` for SPA | None |
| `POST /billing/checkout-session` | Accept cart payload; return `{ checkout_url }` | [Create Checkout Session](https://docs.stripe.com/api/checkout/sessions/create) (`mode: subscription`) |
| `POST /billing/portal-session` | Return `{ portal_url }` for manage/cancel | [Create Billing Portal Session](https://docs.stripe.com/api/customer_portal/sessions/create) |
| `POST /webhooks/stripe` | Inbound Stripe events | Verify signature; persist; sync Customer |

**Lucky must build:** Stripe SDK (secret key), Checkout Session from cart, Customer↔Stripe Customer linking, webhook endpoint + signature verify, persist webhook documents, update `Customer.subscriptions[]`, read APIs for SPA.

**Lucky does not:** implement login UI; he consumes JWT claims and returns MentorHub customer/subscription records.

### Outbound: Checkout Session (fields to confirm in research)

Mike’s cart concept: subscription / product, quantity, unit price → forwarded to Stripe. Research must lock the exact create payload. Typical subscription Checkout fields:

| Field | Role | Notes |
| --- | --- | --- |
| `mode` | `subscription` | Recurring billing |
| `line_items[].price` | Stripe Price ID | Prefer Dashboard-configured Prices over client-supplied amounts |
| `line_items[].quantity` | Seats / quantity | Partner capacity TBD |
| `customer` or `customer_email` | Stripe Customer linkage | Prefer persistent `stripe_customer_id` on our Customer |
| `success_url` / `cancel_url` | Return to SPA | Success URL is UX only — not source of truth |
| `metadata` / `subscription_data.metadata` | Link our Customer `_id` | Needed for webhook reconciliation |
| `client_reference_id` | Optional MentorHub Customer `_id` | Useful for matching sessions |

Full parameter list: [Checkout Sessions — Create](https://docs.stripe.com/api/checkout/sessions/create).

### Inbound: Webhooks (events to confirm in research)

| Event (starting set) | API action |
| --- | --- |
| `checkout.session.completed` | Link session → Customer; ensure subscription entry; persist payload |
| `customer.subscription.created` / `updated` | Upsert `Customer.subscriptions[]` (status, Stripe ids, price/product refs) |
| `customer.subscription.deleted` | Mark canceled / ended on Customer |
| `invoice.paid` | Confirm active; persist as payment/receipt document |
| `invoice.payment_failed` | Mark `past_due`; persist failure; surface banner for SPA |

Always verify signatures with `STRIPE_WEBHOOK_SECRET` ([signature verification](https://docs.stripe.com/webhooks/signatures)).

**Persistence rule:** webhook payloads that represent charges/attempts live in a dedicated collection (cross-customer reporting). Do not rely only on Customer-embedded data for billing history.

### Integration options (decision)

| Option | What it is | Pros | Cons |
| --- | --- | --- | --- |
| **A. Checkout + Customer Portal** ⭐ | Redirect to Stripe for pay and manage | Fast, low PCI, matches Mike’s cart→checkout model | Brief leave of MentorHub UI |
| **B. Embedded Payment Element** | Card fields inside Customer SPA | Stays on MentorHub | More SPA work; still must not store PANs |
| **C. Fully custom card forms** | We build card UI ourselves | Max UI control | High PCI risk — **avoid**; contradicts 2026-07-21 decision |

**Recommendation:** Option A for v1.

---

## Data (MongoDB + Stripe + Cognito)

### Planned MongoDB shape (research-driven; schemas not changed yet)

| Collection / field | Status after encounter |
| --- | --- |
| **Customer.subscriptions[]** | **Keep / add** — source of truth for what the customer is buying; used to build Stripe Checkout cart |
| **Customer** Stripe / Cognito ids | **Keep / extend** — `stripe_customer_id`; Cognito linkage on Profile/Customer as research dictates |
| **Product** (or equivalent) | **Likely add** — referenced from subscriptions; maps to Stripe Product/Price (partner / third-party / individual) |
| **Payment** (name TBD) | **Add** — stores Stripe webhook payment / attempt payloads (or broader webhook-events collection) |
| **Card** | **Drop** — cards only in Stripe |
| **Subscription** (top-level) | **Drop** — moved into Customer |
| **Dashboard** | **Drop for MVP** — fixed customer dashboard later; no configurable dashboard collection now |

**Profile / ERD notes (Mike):** Profile is central — holds Cognito account, Stripe account linkage, and `customer_id`. Webhook/payment documents also reference `customer_id` so reporting can span customers. Arrows on the ERD show where IDs are stored (not typical relational-only notation).

**Open Customer field questions:** name + description exist today; do we need shipping address? What exact shape does each embedded subscription need (Stripe subscription id, Price/Product refs, status, quantity, period end)?

### Example MentorHub products (to refine)

| Offering | Role | Notes |
| --- | --- | --- |
| **Partner subscription** | Org / institutional buyer | Capacity / seats TBD |
| **Third-party subscription** | External program buyer | Pricing TBD |
| **Individual subscription** | Self-funding customer | Pricing TBD |

### Core Stripe objects (for mapping)

| Object | Purpose |
| --- | --- |
| **Customer** | Payer record in Stripe; link via `stripe_customer_id` |
| **Product** | What is sold |
| **Price** | How much / interval; referenced from Checkout `line_items` |
| **Subscription** | Recurring entitlement in Stripe; mirrored into `Customer.subscriptions[]` |
| **Invoice** | Per-cycle bill; paid / failed webhooks |
| **Checkout Session** | Hosted checkout for the cart we pass |
| **Webhook Event** | Signed callback envelope + typed `data.object` |

### Current dictionaries (provisional — do not treat as source of truth for edits)

Per `tasks/_PLANNING.md`, definitive schema JSON comes from the **running MongoDB configurator**, not repo YAML:

```bash
# Start DB if needed, then:
curl -X GET "http://localhost:8383/api/configurations/json_schema/Customer.yaml/latest/" -H "accept: application/json"
```

Provisional files (as of research writing — **do not edit until tickets**):

- `mentorhub_mongodb_api/configurator/dictionaries/Customer.0.1.0.yaml` — `_id`, `name`, `description`, breadcrumbs, status (no `subscriptions[]` yet)
- `mentorhub_mongodb_api/configurator/dictionaries/Subscription.0.1.0.yaml` — standalone (to be dropped / embedded)
- `mentorhub_mongodb_api/configurator/dictionaries/Card.0.1.0.yaml` — stores card **number** (to be dropped; PCI anti-pattern)
- `mentorhub_mongodb_api/configurator/dictionaries/Dashboard.0.1.0.yaml` — MVP drop
- ERD: `mentorhub_mongodb_api/erd.svg` (and `erd.drawio`)

### Cognito (IdP) data research (adjacent)

| Call | Research need |
| --- | --- |
| **Create account** | Required attributes / API fields so Profile can hold them |
| **Update account** | Required attributes / API fields |
| **Login redirect** | Largely done (mock / welcome login) |

Document Cognito findings in `mentorhub/Research/` alongside Stripe so Profile schema tickets are complete.

---

## Open research checklist (Mary)

Focus on **data structures and workflow** only for now.

### Stripe

1. **Confirm checkout workflow** — shopping cart in MentorHub → forward to Stripe Checkout with purchase payload → Stripe collects card → return to success/cancel URLs.
2. **Outbound (MentorHub → Stripe)** — exact fields required to create a Checkout Session for a subscription (Price/Product ids, quantity, customer email, success/cancel URLs, metadata linking our Customer `_id`, etc.).
3. **Stripe Dashboard config** — which **Products** and **Prices** must exist; how partner / third-party / individual offerings map to Product + Price.
4. **Inbound (Stripe → MentorHub webhooks)** — event types we care about (at least payment processed and payment rejected / failed, plus subscription lifecycle) and the **JSON shape** of each payload so we can design a MongoDB collection to store them.
5. **Collection naming** — after reviewing payloads, recommend `Payment`, `PaymentAttempt`, or a broader webhook-events collection.

### Cognito (IdP)

1. **Create account** — required attributes / API fields.
2. **Update account** — required attributes / API fields.
3. Confirm Profile (and Customer) can hold every field those calls need.

Document findings in `mentorhub/Research/` so the whole team can use them. Schema edits wait for tickets.

---

## Anti-patterns

| Anti-pattern | Why it’s wrong | Prefer |
| --- | --- | --- |
| **Store card PAN / CVV in MentorHub** (`Card` collection) | PCI DSS / regulatory burden | Stripe Checkout / Portal only; drop `Card` |
| **Custom card forms in SPA** | Same PCI exposure | Option A: hosted Checkout + Portal |
| **Secret key or webhook secret in SPA** | Key leak = full account compromise | Keys only on Customer API (Lucky) |
| **Trust Checkout `success_url` as paid** | User can hit URL without paying; race with webhooks | Webhook (or Session retrieve server-side) updates `Customer.subscriptions[]`; SPA refetches |
| **Invent subscription state in the browser** | Diverges from MongoDB / Stripe | Display only what Customer API returns |
| **Client-trusted unit price as charge amount** | Cart tampering / underpay | Server maps cart line → configured Stripe **Price ID**; quantity only where seats are intentional |
| **Payment history only on Customer document** | Cannot run cross-customer billing reports | Dedicated Payment / attempt / webhook collection |
| **Live Stripe round-trip on every page load** | Latency, rate limits, coupling | Persist status on Customer; Stripe via Checkout/Portal/webhooks |
| **Rename collections in configurator casually** | Many touch points | Delete + create new dictionary/config |
| **Change schemas before research + Mike’s ERD reflection** | Rework / wrong shapes | Research → tickets → then schema/test-data |
| **Assume only “paid / rejected” webhooks** | Misses cancel, update, `past_due`, Checkout completion | Enumerate [event types](https://docs.stripe.com/api/events/types); store what we need |
| **Edit dictionary YAML as source of truth** | Configurator runtime is definitive | Fetch schema via configurator API (`tasks/_PLANNING.md`) |
| **Delete Customer SPA/API while journey merge is undecided** | Big irreversible product decision | Wait for Mike’s Customer ↔ Coordinator reflection |

---

## Gaps (open questions)

| Gap | Impact | How to close |
| --- | --- | --- |
| Exact Checkout Session create fields for our cart | Blocks API contract + Customer.subscriptions cart shape | Walk [Create Checkout Session](https://docs.stripe.com/api/checkout/sessions/create); sample payload in Research |
| Exact webhook JSON shapes + event list | Blocks Payment collection design + test data | [Event types](https://docs.stripe.com/api/events/types), [Event object](https://docs.stripe.com/api/events/object); capture fixtures via CLI |
| Product / Price ID configuration | Blocks `GET /plans` and Dashboard Product setup | [Products](https://docs.stripe.com/api/products) + [Prices](https://docs.stripe.com/api/prices); define partner / third-party / individual |
| Seats / quantity model | Partner offerings unclear | Decide if quantity = seats; map to `line_items[].quantity` |
| Payment collection name & schema | Persistence + reporting | After webhook sample payloads: `Payment` vs `PaymentAttempt` vs multi-type store |
| Embedded `subscriptions[]` field list | Customer dictionary ticket | Status, Stripe subscription id, Price/Product refs, quantity, current period end, etc. |
| Customer shipping address (and other fields) | Profile/Customer completeness | Decide after Cognito + Stripe customer field research |
| Cognito create/update attribute lists | Profile schema gaps | AWS Cognito Admin APIs (see references) |
| Customer vs Coordinator single UI/API | Repo / role / naming | Mike reflecting; roles stay split for who can subscribe |
| Portal configuration (what customers may cancel/update) | Manage-billing UX | [Customer Portal configuration](https://docs.stripe.com/customer-management/configure-portal) |
| Tax, coupons, trials | May affect Checkout Session fields | Defer unless product requires; see Billing docs |

---

## Authentication (Stripe keys, not login)

| Mode | Use |
| --- | --- |
| **Test** | Development — fake money, test cards |
| **Live** | Production — real charges |

- **Publishable key** (`pk_test_…`) — safe for frontend if we later embed Elements (Option B)
- **Secret key** (`sk_test_…`) — **Lucky / Customer API only**; never in SPA

---

## Local development & testing

**Stack:** Customer SPA (Daniel) → Customer API (Lucky, port **8387**) → Stripe Test API

```sh
# Lucky: forward webhooks to Customer API
stripe listen --forward-to localhost:8387/api/webhooks/stripe
stripe trigger checkout.session.completed
```

**Test cards:** `4242 4242 4242 4242` (success), `4000 0000 0000 0002` (declined) — [Testing](https://docs.stripe.com/testing)

**stripe-mock** (optional CI / no network):

```sh
docker run --rm -p 12111:12111 stripe/stripe-mock:latest
```

Sketch exists in `DeveloperEdition/docker-compose.yaml` (`mock_stripe_api`, port 12111 — currently commented).

**Configurator schemas (definitive):**

```sh
curl -X GET "http://localhost:8383/api/configurations/json_schema/<Dictionary>.yaml/latest/" -H "accept: application/json"
```

---

## Security best practices

- Never store raw card numbers in MentorHub (Checkout / Portal only; drop `Card` collection)
- Secret keys and webhook secrets only on Customer API (Lucky)
- Verify webhook signatures; use env vars for credentials
- Test in Stripe Test Mode before live
- Do not put PII or PANs in Stripe `metadata`

---

## MentorHub touch points (by repo)

| Area | Who | Responsibility |
| --- | --- | --- |
| **Customer SPA** | Daniel | Login return, shopping cart, Checkout/Portal redirects, success/cancel UI, status banners |
| **Customer API** | Lucky | Checkout Session from cart, Portal Session, webhooks, Stripe Customer link, Customer.subscriptions[], payment persistence, status APIs |
| **MongoDB** | Data track | After research tickets: embed subscriptions on Customer; drop Card / top-level Subscription / Dashboard; add Payment (+ Product as needed) |
| **Research** | Mary | Stripe outbound/inbound payloads, Products/Prices, Cognito create/update fields — in `mentorhub/Research/` |
| **IdP / welcome** | Shared | Login only — not billing |
| **SRE / compose** | Platform | Secrets, webhook URL, optional stripe-mock |

---

## Key takeaways

- Stripe = payments and recurring billing; MentorHub = login, cart/subscription UX, and access rules — **not** card storage.
- Target flow: **login → cart on Customer → Stripe Checkout → webhook → Customer.subscriptions[] active (+ payment doc) → Portal cancel → webhook → canceled**.
- **Data model direction:** subscriptions on Customer; persist Stripe webhooks; drop Card and MVP Dashboard; Product pricing TBD.
- **Do not change schemas until research tickets are ready** and Mike finishes reflecting on journey/UI boundaries.
- **Daniel (UI):** cart and redirects; call Lucky’s billing endpoints; display status from our API.
- **Lucky (API):** Stripe SDK, Checkout/Portal, webhooks, Customer.subscriptions sync, payment persistence.
- Start with **Checkout + Customer Portal**; avoid custom card forms.

---

## References

### Stripe — workflow & configuration

- [Checkout](https://docs.stripe.com/payments/checkout) — hosted payment page (cart → redirect model)
- [Checkout Sessions API overview](https://docs.stripe.com/payments/checkout-sessions)
- [Create a Checkout Session](https://docs.stripe.com/api/checkout/sessions/create) — outbound fields (`mode`, `line_items`, URLs, `metadata`, …)
- [Checkout Session object](https://docs.stripe.com/api/checkout/sessions/object) — response / webhook `data.object` shape
- [Billing](https://docs.stripe.com/billing) — subscriptions overview
- [Customer Portal](https://docs.stripe.com/customer-management) — manage / cancel
- [Configure the Customer Portal](https://docs.stripe.com/customer-management/configure-portal) — Dashboard options (cancel, payment method update, etc.)
- [Create Portal Session](https://docs.stripe.com/api/customer_portal/sessions/create)
- [Products](https://docs.stripe.com/api/products) · [Create Product](https://docs.stripe.com/api/products/create)
- [Prices](https://docs.stripe.com/api/prices) · [Create Price](https://docs.stripe.com/api/prices/create)
- [Subscriptions](https://docs.stripe.com/api/subscriptions/object) — status values to mirror on Customer
- [Invoices](https://docs.stripe.com/api/invoices/object) — paid / failed payment payloads

### Stripe — webhooks & events

- [Webhooks](https://docs.stripe.com/webhooks)
- [Webhook signature verification](https://docs.stripe.com/webhooks/signatures)
- [Event types](https://docs.stripe.com/api/events/types) — full catalog (do not assume only paid/rejected)
- [Event object](https://docs.stripe.com/api/events/object)
- [Checkout `checkout.session.completed`](https://docs.stripe.com/api/events/types#event_types-checkout.session.completed)
- [Handling failed payments](https://docs.stripe.com/billing/revenue-recovery) (context for `invoice.payment_failed`)

### Stripe — testing & tooling

- [Testing](https://docs.stripe.com/testing) — test cards
- [Stripe CLI](https://docs.stripe.com/stripe-cli) — `stripe listen`, `stripe trigger`
- [stripe-mock](https://github.com/stripe/stripe-mock)
- [stripe-samples](https://github.com/stripe-samples)
- [API reference root](https://docs.stripe.com/api)

### Cognito — account create / update (Profile research)

- [AdminCreateUser](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_AdminCreateUser.html)
- [AdminUpdateUserAttributes](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_AdminUpdateUserAttributes.html)
- [SignUp](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_SignUp.html) (if self-service signup)
- [User pool attributes](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-attributes.html)

### MentorHub — local schema & ERD

- Planning: `mentorhub/tasks/_PLANNING.md` — configurator is definitive for dictionary schemas; OpenAPI from running APIs
- Configurator (port **8383**): `GET /api/configurations/json_schema/<Dictionary>.yaml/latest/`
- ERD: `mentorhub_mongodb_api/erd.svg`
- Compose ports: `DeveloperEdition/docker-compose.yaml` (configurator `8383`, customer API `8387`, optional stripe-mock `12111`)
- Encounter source: `2026-07-21 Mary-Anderson.md` (Obsidian / Downloads)
)
