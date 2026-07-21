# F-W03: Stripe API, Billing & Subscriptions Research Summary

**Issue:** [#32 — F-W03: Stripe Research](https://github.com/mentor-forge/mentorhub/issues/32)

**Team assignments for Customer Subscription UI:**

| Person | Area | Repo |
| --- | --- | --- |
| **Daniel** | Customer SPA (UI) | `mentorhub_customer_spa` |
| **Lucky** | Customer API | `mentorhub_customer_api` |
| **Mary** | Stripe / Cognito data research | `mentorhub/Research` |

**Recommended integration:** Stripe **Checkout** (subscribe) + **Customer Portal** (manage / unsubscribe) + **webhooks** (persist payment outcomes). Stripe is not an IdP — login stays Cognito / local `welcome-auth.js`.

---

## Decisions from encounter 2026-07-21 (Mike / Mary)

Source: encounter transcript (Mike Storey, Mary Anderson), 2026-07-21.

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

**Under reflection (no action yet):** Mike is considering whether Customer and Coordinator journeys share one UI/API. Customer role would still own subscriptions; Coordinator would not. Final naming/repo boundaries TBD — do not delete customer SPA/API until that decision lands.

---

## Open research checklist (Mary)

Focus on **data structures and workflow** only for now.

### Stripe

1. **Confirm checkout workflow** — shopping cart in MentorHub → forward to Stripe Checkout with purchase payload → Stripe collects card → return to success/cancel URLs.
2. **Outbound (MentorHub → Stripe)** — exact fields required to create a Checkout Session for a subscription (Price/Product ids, quantity, customer email, success/cancel URLs, metadata linking our Customer `_id`, etc.).
3. **Stripe Dashboard config** — which **Products** and **Prices** must exist; how partner / third-party / individual offerings map to Product + Price.
4. **Inbound (Stripe → MentorHub webhooks)** — event types we care about (at least payment processed and payment rejected / failed) and the **JSON shape** of each payload so we can design a MongoDB collection to store them.
5. **Collection naming** — after reviewing payloads, recommend `Payment`, `PaymentAttempt`, or a broader webhook-events collection.

### Cognito (IdP)

1. **Create account** — required attributes / API fields.
2. **Update account** — required attributes / API fields.
3. Confirm Profile (and Customer) can hold every field those calls need. Login redirect research is already covered.

Document findings in `mentorhub/Research/` so the whole team can use them. Schema edits wait for tickets.

---

## What is Stripe?

Stripe is a payment processing platform that lets businesses accept online payments, manage subscriptions, send invoices, and handle customer billing — without building a payment system from scratch.

Stripe handles credit/debit cards, digital wallets (Apple Pay, Google Pay), bank transfers, subscription billing, invoicing, tax calculations, customer management, and fraud prevention.

---

## What is the Stripe API?

The Stripe API lets our application talk to Stripe's servers. We send requests (create a customer, create a subscription, charge a payment method, cancel, update billing, retrieve invoices) and get JSON responses.

---

## Core Stripe Objects

| Object | Purpose |
| --- | --- |
| **Customer** | Payer record: name, email, payment methods, billing history, subscriptions |
| **Product** | What is sold (e.g. MentorHub partner, third-party, individual offerings) |
| **Price** | How much it costs ($10/mo, $99/yr). One Product can have many Prices |
| **Subscription** | Active recurring payment: customer + price + billing cycle + status |
| **Invoice** | Bill for each cycle: amount, taxes, discounts, payment status |
| **Payment Intent** | A payment in flight (authorization, 3D Secure, success/failure) |
| **Checkout Session** | Hosted checkout for the cart we pass to Stripe |
| **Webhook Event** | Callback Stripe sends when payment succeeds, fails, subscription changes, etc. |

### Example MentorHub products (to refine)

| Offering | Role | Notes |
| --- | --- | --- |
| **Partner subscription** | Org / institutional buyer | Capacity / seats TBD |
| **Third-party subscription** | External program buyer | Pricing TBD |
| **Individual subscription** | Self-funding customer | Pricing TBD |

Exact Product/Price IDs and fields are an open research item (see checklist above).

---

## User journey: first login → subscribe → unsubscribe

Persona for this walkthrough: **Cat the Customer** (paying sponsor). Identity uses our IdP JWT (`roles: customer`, `customer_id`). Stripe only handles payment. Cards are never entered into MentorHub forms.

### Phase 1 — First login to the platform

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 1 | Opens Customer SPA (or welcome page with `return_to` Customer SPA) | Load Customer SPA; redirect unauthenticated users to IdP / `login.html` | — (auth is IdP / `spa_utils` session, not Stripe) |
| 2 | Signs in with customer persona | After redirect with JWT hash/claims, store session (token, `roles`, `customer_id`) | Validate JWT on every later request; reject if missing `customer` role |
| 3 | Lands on Customer home | Show shell; if no active subscription on Customer, show CTA such as **“Choose a plan”** | Read subscription status from **Customer.subscriptions[]** (MongoDB), not live Stripe. Return `none` / `inactive` when empty |
| 4 | Sees “not subscribed” state | Empty state: offerings available, sponsorship benefits, start-cart / **Subscribe** | Do **not** call Stripe until user builds a cart and checks out |

**Daniel does not:** call Stripe with a secret key, collect card numbers, or invent subscription state client-side.

**Lucky does not:** implement login UI; he consumes JWT claims and returns MentorHub customer/subscription records.

---

### Phase 2 — Subscribe (shopping cart → Stripe Checkout)

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 5 | Builds a **shopping cart** (subscription / product, quantity, unit price) | Cart UI: describe what they are buying; primary action **Checkout** | Optional: `GET /plans` or Product config mapping our offerings → Stripe Price IDs |
| 6 | Clicks Checkout | `POST /billing/checkout-session` with cart payload. Show loading; on success, **redirect browser** to Stripe | Ensure Stripe **Customer** linked to our Customer `_id`. Create **Checkout Session** (`mode: subscription`, line items from cart, success/cancel URLs, metadata). Return `{ checkout_url }` |
| 7 | Completes payment on Stripe Checkout | User is on **stripe.com** — SPA idle until return | Stripe collects card; **no MentorHub card form**. Store `stripe_customer_id` on Customer when known |
| 8a | Cancels on Checkout | Cancel URL → “Payment cancelled”; return to cart / plans | No payment webhook required; do not invent a paid subscription |
| 8b | Pays successfully | Success URL → “Confirming…” then refetch Customer | Stripe fires webhooks (e.g. `checkout.session.completed`, `invoice.paid`, subscription events) |
| 9 | Webhook arrives | — | `POST /webhooks/stripe`: verify signature; **persist webhook payload** in payments (or equivalent) collection; update **Customer.subscriptions[]** status / Stripe ids |
| 10 | Sees subscribed state | Refetch Customer; show **Active**, plan, renewal, **Manage billing** | Read APIs return Customer with subscriptions for JWT owner |

**Daniel must build:** cart / plan UI, checkout-session call, redirect, success/cancel pages, post-pay refresh, active subscription summary.

**Lucky must build:** Stripe SDK (secret key), Checkout Session from cart, Customer↔Stripe Customer linking, webhook endpoint + signature verify, persist webhook documents, update Customer.subscriptions[], read APIs for SPA.

---

### Phase 3 — Use service while subscribed (ongoing)

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 11 | Uses customer views (sponsored mentees, progress) | Gate premium UI on active subscription on Customer | Enforce access where needed (403 if not active). Stripe not called on every page load |
| 12 | Payment fails on renewal | Banner: “Payment failed — update billing” | Handle failure webhook (e.g. `invoice.payment_failed`); persist payload; mark subscription `past_due` (or agreed value) on Customer |
| 13 | Opens Manage billing | Button → `POST /billing/portal-session` → redirect to Portal URL | Create Stripe **Billing Portal** session; return `{ portal_url }` |

---

### Phase 4 — Unsubscribe / cancel

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 14 | Opens Manage billing | Prefer **Stripe Customer Portal** for cancel | Portal session endpoint |
| 15 | Confirms cancel in Portal | After return, refetch Customer | Webhook `customer.subscription.updated` / `deleted` → update Customer.subscriptions[]; persist webhook document |
| 16 | Sees unsubscribed state | Re-subscribe CTA; hide premium UI | Read APIs return inactive/canceled; enforce 403 on premium resources |

---

## End-to-end flow diagram

```text
First login
  IdP → Customer SPA (Daniel) → JWT → Customer API (Lucky)
       → GET Customer → subscriptions empty → plan / cart CTA

Subscribe
  Daniel: shopping cart → POST checkout-session (cart payload)
  Lucky:  Stripe Customer + Checkout Session → checkout_url
  Daniel: redirect to Stripe Checkout
  User pays (Stripe UI — card never hits MentorHub)
  Stripe → Lucky webhook → persist payment doc + update Customer.subscriptions[]
  Daniel: success URL → GET Customer → show Active

Unsubscribe
  Daniel: Manage billing → POST portal-session
  Lucky:  Portal session → portal_url
  Daniel: redirect to Stripe Portal → user cancels
  Stripe → Lucky webhook → persist payment/status doc + update Customer.subscriptions[]
  Daniel: refresh → show Resubscribe
```

---

## Integration options (decision)

| Option | What it is | Pros | Cons |
| --- | --- | --- | --- |
| **A. Checkout + Customer Portal** ⭐ | Redirect to Stripe for pay and manage | Fast, low PCI, matches Mike’s cart→checkout model | Brief leave of MentorHub UI |
| **B. Embedded Payment Element** | Card fields inside Customer SPA | Stays on MentorHub | More SPA work; still must not store PANs |
| **C. Fully custom card forms** | We build card UI ourselves | Max UI control | High PCI risk — **avoid**; contradicts 2026-07-21 decision |

**Recommendation:** Option A for v1. Daniel owns cart UI, redirects, and post-return UX; Lucky owns Stripe API + webhooks + Customer.subscriptions sync + payment persistence.

---

## Webhooks: events and persistence

Mike’s working assumption: we primarily care about **payment processed** and **payment rejected**, plus subscription lifecycle so Customer.subscriptions[] stays accurate. Confirm exact event names and payload fields in research.

| Event (starting set) | API action |
| --- | --- |
| `checkout.session.completed` | Link session → Customer; ensure subscription entry on Customer; persist event payload |
| `customer.subscription.created` / `updated` | Upsert Customer.subscriptions[] (status, Stripe ids, price/product refs) |
| `customer.subscription.deleted` | Mark canceled / ended on Customer.subscriptions[] |
| `invoice.paid` | Confirm active; persist as payment/receipt document |
| `invoice.payment_failed` | Mark `past_due`; persist failure; surface banner for SPA |

Always verify webhook signatures with `STRIPE_WEBHOOK_SECRET`.

**Persistence rule:** webhook payloads that represent charges/attempts should live in a dedicated collection (cross-customer reporting). Do not rely only on Customer-embedded data for billing history.

---

## Planned MongoDB shape (research-driven; schemas not changed yet)

| Collection / field | Status after encounter |
| --- | --- |
| **Customer.subscriptions[]** | **Keep / add** — source of truth for what the customer is buying; used to build Stripe Checkout cart |
| **Customer** Stripe / Cognito ids | **Keep / extend** — `stripe_customer_id`, Cognito account linkage on Profile/Customer as research dictates |
| **Product** (or equivalent) | **Likely add** — referenced from subscriptions; maps to Stripe Product/Price |
| **Payment** (name TBD) | **Add** — stores Stripe webhook payment / attempt payloads |
| **Card** | **Drop** — cards only in Stripe |
| **Subscription** (top-level) | **Drop** — moved into Customer |
| **Dashboard** | **Drop for MVP** — fixed customer dashboard later; no configurable dashboard collection now |

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

**Stack:** Customer SPA (Daniel) → Customer API (Lucky) → Stripe Test API

```sh
# Lucky: forward webhooks to Customer API (port 8387)
stripe listen --forward-to localhost:8387/api/webhooks/stripe
stripe trigger checkout.session.completed
```

**Test cards:** `4242 4242 4242 4242` (success), `4000 0000 0000 0002` (declined)

**stripe-mock** (optional CI / no network):

```sh
docker run --rm -p 12111:12111 stripe/stripe-mock:latest
```

Sketch already exists in `DeveloperEdition/docker-compose.yaml` (`mock_stripe_api`, port 12111).

---

## Security best practices

- Never store raw card numbers in MentorHub (Checkout / Portal only; drop `Card` collection)
- Secret keys and webhook secrets only on Customer API (Lucky)
- Verify webhook signatures; use env vars for credentials
- Test in Stripe Test Mode before live

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

- [Stripe API](https://docs.stripe.com/api) · [Billing](https://docs.stripe.com/billing) · [Checkout](https://docs.stripe.com/payments/checkout) · [Customer Portal](https://docs.stripe.com/customer-management) · [Webhooks](https://docs.stripe.com/webhooks) · [Products](https://docs.stripe.com/api/products) · [Prices](https://docs.stripe.com/api/prices) · [Testing](https://docs.stripe.com/testing) · [Stripe CLI](https://docs.stripe.com/stripe-cli) · [stripe-mock](https://github.com/stripe/stripe-mock) · [stripe-samples](https://github.com/stripe-samples)
