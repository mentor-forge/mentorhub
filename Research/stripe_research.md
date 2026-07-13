# F-W03: Stripe API, Billing & Subscriptions Research Summary

**Issue:** [#32 — F-W03: Stripe Research](https://github.com/mentor-forge/mentorhub/issues/32)

**Team assignments for Customer Subscription UI:**

| Person | Area | Repo |
| --- | --- | --- |
| **Daniel** | Customer SPA (UI) | `mentorhub_customer_spa` |
| **Lucky** | Customer API | `mentorhub_customer_api` |

**Recommended integration:** Stripe **Checkout** (subscribe) + **Customer Portal** (manage / unsubscribe) + **webhooks** (sync state). Stripe is not an IdP — login stays Cognito / local `welcome-auth.js`.

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
| **Product** | What is sold (e.g. MentorHub Basic, Pro, Enterprise) |
| **Price** | How much it costs ($10/mo, $99/yr). One Product can have many Prices |
| **Subscription** | Active recurring payment: customer + price + billing cycle + status |
| **Invoice** | Bill for each cycle: amount, taxes, discounts, payment status |
| **Payment Intent** | A payment in flight (authorization, 3D Secure, success/failure) |

### Example MentorHub plans (fictional)

| Plan | Price | Features |
| --- | --- | --- |
| **Basic** | $9.99/mo | 1 mentor profile, 5 mentees, basic messaging, email support |
| **Pro** | $39.99/mo | Unlimited mentees, video sessions, analytics, priority support |
| **Enterprise** | Custom | Unlimited orgs, SSO, API access, dedicated account manager |

---

## User journey: first login → subscribe → unsubscribe

Persona for this walkthrough: **Cat the Customer** (paying sponsor). Identity uses our IdP JWT (`roles: customer`, `customer_id`). Stripe only handles payment.

### Phase 1 — First login to the platform

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 1 | Opens Customer SPA (or welcome page with `return_to` Customer SPA) | Load Customer SPA; redirect unauthenticated users to IdP / `login.html` | — (auth is IdP / `spa_utils` session, not Stripe) |
| 2 | Signs in with customer persona | After redirect with JWT hash/claims, store session (token, `roles`, `customer_id`) | Validate JWT on every later request; reject if missing `customer` role |
| 3 | Lands on Customer home / dashboard | Show dashboard shell; if no active subscription, show CTA such as **“Choose a plan”** | `GET` subscription status for this JWT `customer_id` (from MongoDB, not Stripe live). Return `status: none` / `inactive` when missing |
| 4 | Sees “not subscribed” state | Render clear empty state: plans available, sponsorship benefits, **Subscribe** button | Do **not** call Stripe until user chooses a plan |

**Daniel does not:** call Stripe with a secret key, collect card numbers, or invent subscription state client-side.

**Lucky does not:** implement login UI; he consumes JWT claims and returns MentorHub subscription records.

---

### Phase 2 — Subscribe to a service

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 5 | Opens plan picker (Basic / Pro / …) | Plan selection screen: plan name, price, features, primary action **Subscribe** | Optional: `GET /plans` (or config) mapping our plan keys → Stripe Price IDs — if plans are Dashboard-only, document Price IDs as env config |
| 6 | Selects a plan and clicks Subscribe | `POST /billing/checkout-session` with selected plan (or Price id). Show loading; on success, **redirect browser** to URL in response | Create Stripe **Customer** if none linked to our `Customer` `_id`. Create Stripe **Checkout Session** (`mode: subscription`, success/cancel URLs, Price id). Return `{ checkout_url }` |
| 7 | Completes payment on Stripe Checkout | User is on **stripe.com** — Daniel’s SPA is idle until return. Use success/cancel query routes | Stripe collects card; no MentorHub form. Store `stripe_customer_id` on our Customer when known |
| 8a | Cancels on Checkout | Route: cancel URL → show “Payment cancelled” and link back to plans | No webhook required for cancel; no DB subscription created |
| 8b | Pays successfully | Route: success URL → “Confirming subscription…” then poll/refetch status | Stripe fires webhook (e.g. `checkout.session.completed`, `customer.subscription.created`) |
| 9 | Webhook arrives | — | `POST /webhooks/stripe`: verify signature (`whsec_…`); upsert MongoDB `Subscription` (`stripe_subscription_id`, `stripe_price_id`, `status: active`); write `Event` |
| 10 | Sees subscribed state | After success return, `GET` subscription; show **Active**, plan name, next renewal, **Manage billing** | `GET /subscription` (or equivalent) returns local MongoDB state for JWT customer |

**Daniel must build:** plan picker, call checkout-session, redirect, success/cancel pages, post-pay status refresh, active subscription summary.

**Lucky must build:** Stripe SDK with secret key, Checkout Session creation, Customer↔Stripe Customer linking, webhook endpoint + signature verify, MongoDB `Subscription` / `Event` updates, read APIs for SPA.

---

### Phase 3 — Use service while subscribed (ongoing)

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 11 | Uses Customer dashboard (sponsored mentees, progress) | Dashboard reads our APIs only; gate premium UI on `subscription.status === active` | Enforce access where needed (403 if not active). Stripe not called on every page load |
| 12 | Payment fails on renewal | Banner: “Payment failed — update billing” | Handle `invoice.payment_failed` webhook → set `status: past_due` (or agreed value) → optional `Event` |
| 13 | Opens Manage billing | Button → `POST /billing/portal-session` → redirect to Portal URL | Create Stripe **Billing Portal** session; return `{ portal_url }` |

---

### Phase 4 — Unsubscribe / cancel

| Step | What the user experiences | Daniel (UI) | Lucky (API) |
| --- | --- | --- | --- |
| 14 | Opens Billing hub or Manage billing | Prefer **Stripe Customer Portal** for cancel (recommended). Optional in-app “Cancel subscription” confirmation that opens Portal or calls cancel API | Portal: already covered by portal-session. Optional: `POST /billing/cancel` that calls Stripe Subscription cancel / cancel_at_period_end |
| 15 | Confirms cancel in Portal | After return URL from Portal, refetch subscription status | Webhook `customer.subscription.updated` / `deleted` → set MongoDB `status: canceled` (or `cancel_at_period_end` until period ends) |
| 16 | Sees unsubscribed state | Empty / re-subscribe CTA; hide premium sponsorship UI | Read APIs return inactive/canceled; enforce 403 on premium resources |

**Daniel must build:** Manage billing entry point, return handling after Portal, canceled UI state.

**Lucky must build:** Portal session (primary), webhook handling for cancel/end, MongoDB status sync; optional cancel endpoint if we cancel without Portal.

---

## End-to-end flow diagram

```text
First login
  IdP → Customer SPA (Daniel) → JWT on requests → Customer API (Lucky) validates role
       → GET subscription → "none" → plan CTA

Subscribe
  Daniel: plan picker → POST checkout-session
  Lucky:  Stripe Customer + Checkout Session → checkout_url
  Daniel: redirect to Stripe Checkout
  User pays (Stripe UI)
  Stripe → Lucky webhook → MongoDB Subscription active
  Daniel: success URL → GET subscription → show Active

Unsubscribe
  Daniel: Manage billing → POST portal-session
  Lucky:  Portal session → portal_url
  Daniel: redirect to Stripe Portal → user cancels
  Stripe → Lucky webhook → MongoDB Subscription canceled
  Daniel: refresh → show Resubscribe
```

---

## Integration options (decision)

| Option | What it is | Pros | Cons |
| --- | --- | --- | --- |
| **A. Checkout + Customer Portal** ⭐ | Redirect to Stripe for pay and manage | Fast, low PCI, matches workshop | Brief leave of MentorHub UI |
| **B. Embedded Payment Element** | Card fields inside Customer SPA | Stays on MentorHub | More SPA work, more testing |
| **C. Fully custom card forms** | We build card UI ourselves | Max UI control | High PCI risk — **avoid** |

**Recommendation:** Option A for v1. Daniel owns redirects and post-return UX; Lucky owns Stripe API + webhooks + DB sync.

---

## Webhooks Lucky must handle first

| Event | API action |
| --- | --- |
| `checkout.session.completed` | Link session → Customer; ensure subscription record exists |
| `customer.subscription.created` / `updated` | Upsert MongoDB `Subscription` status and Stripe ids |
| `customer.subscription.deleted` | Mark canceled / ended |
| `invoice.paid` | Confirm active; optional receipt Event |
| `invoice.payment_failed` | Mark `past_due`; surface for Daniel’s banner |

Always verify webhook signatures with `STRIPE_WEBHOOK_SECRET`.

---

## Authentication (Stripe keys, not login)

| Mode | Use |
| --- | --- |
| **Test** | Development — fake money, test cards |
| **Live** | Production — real charges |

- **Publishable key** (`pk_test_…`) — safe for frontend if we later embed Elements (Option B)
- **Secret key** (`sk_test_…`) — **Lucky / Customer API only**; never in `customer_spa`

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

- Never store raw card numbers in MentorHub (prefer Checkout / Portal)
- Secret keys and webhook secrets only on Customer API (Lucky)
- Verify webhook signatures; use env vars for credentials
- Test in Stripe Test Mode before live

---

## MentorHub touch points (by repo)

| Area | Who | Responsibility |
| --- | --- | --- |
| **Customer SPA** | Daniel | Login return, plan picker, Checkout/Portal redirects, success/cancel/canceled UI, status banners |
| **Customer API** | Lucky | Checkout Session, Portal Session, webhooks, Stripe Customer link, MongoDB `Subscription`/`Event`, status APIs |
| **MongoDB** | Data track | Schema fields for Stripe ids; deprecate storing PANs on `Card` |
| **IdP / welcome** | Shared | Login only — not billing |
| **SRE / compose** | Platform | Secrets, webhook URL, optional stripe-mock |

---

## Key takeaways

- Stripe = payments and recurring billing; MentorHub = login, sponsorship UX, and access rules.
- User journey: **login → no subscription → Checkout subscribe → webhook → active → Portal unsubscribe → webhook → canceled**.
- **Daniel (UI):** screens and redirects; call Lucky’s billing endpoints; display status from our API.
- **Lucky (API):** Stripe SDK, Checkout/Portal sessions, webhooks, MongoDB sync, JWT-protected status APIs.
- Start with **Checkout + Customer Portal**; avoid custom card forms.

---

## References

- [Stripe API](https://docs.stripe.com/api) · [Billing](https://docs.stripe.com/billing) · [Checkout](https://docs.stripe.com/payments/checkout) · [Customer Portal](https://docs.stripe.com/customer-management) · [Webhooks](https://docs.stripe.com/webhooks) · [Testing](https://docs.stripe.com/testing) · [Stripe CLI](https://docs.stripe.com/stripe-cli) · [stripe-mock](https://github.com/stripe/stripe-mock) · [stripe-samples](https://github.com/stripe-samples)
