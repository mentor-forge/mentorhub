# F-W03: Stripe Research

**Issue:** [#32 — F-W03: Stripe Research](https://github.com/mentor-forge/mentorhub/issues/32)  
**Type:** Human research (not Cursor task orchestration)  
**Audience:** MentorHub team — developers, designers, and stakeholders planning Customer billing

---

## Executive summary

Stripe is a payments platform we plan to use for **Customer subscriptions and billing** in MentorHub. Stripe owns card processing, subscription lifecycle, invoicing, and the customer self-service portal. MentorHub owns **who** is sponsored (Customer → Profile/Mentee), **what** they can see (Dashboard), and **when** to react to payment events (webhooks → MongoDB `Subscription` / `Event` records).

Today Stripe is **not wired into application code** yet. The data model (`Subscription`, `Card`), Customer journey architecture, and developer compose file already anticipate it. Local development can use **Stripe test mode**, **stripe-mock**, and official **stripe-samples** before we integrate production keys.

---

## What is Stripe?

[Stripe](https://stripe.com) is a developer-first payments API. Integrations call Stripe over HTTPS; Stripe handles PCI-sensitive card data, payment networks, fraud tooling, and compliance boundaries so our apps never store raw card numbers if we use Stripe Checkout or Elements correctly.

### Core ideas

| Concept | What it is | MentorHub relevance |
| --- | --- | --- |
| **REST API** | Resource-oriented JSON API at `https://api.stripe.com` | Customer API will create/read Customers, Subscriptions, PaymentMethods |
| **Test mode vs live mode** | Separate API keys; test mode uses fake cards and no real money | All local/dev work uses `sk_test_…` keys |
| **Customer** | Stripe's record of a payer (email, default payment method) | Maps to our `Customer` profile / sponsoring account |
| **Product & Price** | Catalog item and recurring (or one-time) price point | MentorHub plan tiers (family, Persevere Now, enterprise) |
| **Subscription** | Recurring billing link between Customer and Price | Maps to our MongoDB `Subscription` collection |
| **Checkout** | Hosted payment page (low PCI scope) | Likely first UX for "sign up and pay" |
| **Customer Portal** | Hosted billing self-service (pause, update card, invoices) | Matches workshop "Billing & Subscription hub" goals |
| **Webhooks** | Stripe POSTs signed events to our endpoint | Sync payment state → MongoDB `Event` / `Subscription` |
| **Invoices** | Itemized bills for subscription periods | Receipts, annual summaries for customers |

### API characteristics ([docs](https://docs.stripe.com/api))

- Predictable REST URLs, JSON request/response, standard HTTP status codes
- **Sandboxes** (newer) and **test mode** for development without touching live banking
- One object per request (no bulk update)
- API version pinned per account; SDKs track versions

---

## Stripe Billing & subscriptions ([docs](https://docs.stripe.com/billing))

Billing is the Stripe product area for **recurring revenue**:

1. **Define Products and Prices** (monthly/annual, per-seat, usage-based, trials)
2. **Create a Subscription** linking a Stripe Customer to a Price
3. **Collect payment** via Checkout, saved payment method, or invoice
4. **Lifecycle events** — renewals, failed payments (Smart Retries), cancellations, proration
5. **Customer Portal** — customers manage subscription without custom UI

### Typical subscription flow (Checkout + Billing)

```text
Customer SPA  →  Customer API  →  Stripe Checkout Session
                      ↑                    │
                      │              Customer pays
                      │                    ↓
                 Webhook handler  ←  checkout.session.completed
                      │
                      ↓
              MongoDB Subscription + Event
```

### Webhooks we will likely care about first

| Event | Why |
| --- | --- |
| `checkout.session.completed` | New subscription after signup |
| `customer.subscription.created` / `updated` / `deleted` | Sync status, plan changes, cancellation |
| `invoice.paid` / `invoice.payment_failed` | Receipts, dunning, "payment problem" UX |
| `customer.subscription.trial_will_end` | Remind before first charge |

Always verify webhook signatures with the endpoint secret (`whsec_…`).

---

## Stripe sample integrations ([stripe-samples](https://github.com/stripe-samples))

Official sample repos worth studying for MentorHub:

| Sample | Stars | Use for MentorHub |
| --- | --- | --- |
| [checkout-single-subscription](https://github.com/stripe-samples/checkout-single-subscription) | ~900 | Fastest path to a subscription signup page |
| [subscription-use-cases](https://github.com/stripe-samples/subscription-use-cases) | ~900 | Fixed vs usage-based pricing patterns |
| [checkout-one-time-payments](https://github.com/stripe-samples/checkout-one-time-payments) | ~1000 | One-time charges (if we sell single Encounter blocks) |
| [accept-a-payment](https://github.com/stripe-samples/accept-a-payment) | ~800 | Payment Element / multiple payment methods |

Samples are reference architectures — copy patterns, not paste production secrets.

---

## MentorHub touch points

### 1. Customer user journey (primary owner)

From `Specifications/architecture.yaml`, the **Customer** journey **controls**:

- `Subscription` — subscription to the service for a customer
- `Card` — payment method metadata (today's dictionary stores card fields locally; **production should prefer Stripe PaymentMethod IDs**, not PANs)
- `Dashboard` — customer visibility into mentee progress

The Customer journey **consumes** `Profile`, `Customer`, `Journey`, `Rating`, `Note` and **creates** `Event` records — the natural place to log billing-related activity.

**Repos:** `mentorhub_customer_api`, `mentorhub_customer_spa`

### 2. MongoDB data dictionaries (`mentorhub_mongodb_api`)

| Collection | Status today | Stripe alignment |
| --- | --- | --- |
| `Subscription` | Schema exists (`Subscription.0.1.0.yaml`); basic fields | Add Stripe ids: `stripe_customer_id`, `stripe_subscription_id`, `stripe_price_id`, status mirror |
| `Card` | Schema stores `number`, `expiry`, `billing_zip` | **Do not store full card numbers in prod** — store Stripe `payment_method` id or rely entirely on Stripe |
| `Customer` | Sponsor organization / family account | Link to Stripe Customer object |
| `Event` | Audit trail | Record webhook-driven billing events |

Enumerators already include subscription cost tiers (`Subscription - Low/Medium/High Cost`).

### 3. Product / UX research (workshops)

`Workshops/customer_workshop.md` captured Customer needs that map directly to Stripe features:

- **Subscription Checkout** — one screen: plan + mentee slot + price + first charge date → **Stripe Checkout**
- **Billing & Subscription Hub** — pause, compare plans, explain charges, receipts → **Customer Portal** + webhooks
- **Paperless billing / annual receipt** → Stripe Invoices + email
- **Pause billing for vacation month** → subscription `pause_collection` or custom logic

### 4. Platform / SRE

`DeveloperEdition/standards/sre_standards.md` — AWS **Management account** owns org billing; application **payment processing** is separate (Stripe merchant account, not AWS billing).

Cloud deployment diagrams (referenced in Encounter summaries) show **Stripe** alongside Cognito, SES, MongoDB — payment is an external SaaS dependency in the AWS topology.

### 5. Local developer edition (`DeveloperEdition/docker-compose.yaml`)

A **commented-out** `mock_stripe_api` service is already sketched:

```yaml
# mock_stripe_api:
#   image: stripe/strip-mock:latest   # note: correct image is stripe/stripe-mock
#   ports:
#     - "127.0.0.1:12111:12111"
#   profiles:
#     - customer-api
#     - customer
```

This is the intended local touch point once Customer API integrates Stripe.

### 6. What is **not** Stripe today

- No Stripe SDK usage found in `mentorhub_customer_api` / `mentorhub_customer_spa` yet
- No Stripe resources in `mentorhub_cloudformation` yet
- `Card` test data is placeholder — not PCI-safe for production

---

## How to test Stripe locally

### Option A — Stripe test mode (recommended for integration dev)

1. Create a [Stripe account](https://dashboard.stripe.com/register) (free).
2. Use **test mode** API keys from Dashboard → Developers → API keys (`pk_test_…`, `sk_test_…`).
3. Use [test card numbers](https://docs.stripe.com/testing#cards) (e.g. `4242 4242 4242 4242`).
4. Forward webhooks to localhost with the [Stripe CLI](https://docs.stripe.com/stripe-cli):

```sh
stripe listen --forward-to localhost:8387/api/webhooks/stripe
```

5. Trigger test events:

```sh
stripe trigger checkout.session.completed
```

### Option B — stripe-mock (fast automated tests, no network)

[stripe-mock](https://github.com/stripe/stripe-mock) is Stripe's open-source mock HTTP server. It returns spec-shaped JSON without calling Stripe's servers.

**Docker (matches our compose sketch):**

```sh
docker run --rm -p 12111-12112:12111-12112 stripe/stripe-mock:latest
```

**Point the SDK at the mock:**

```python
# Python example
import stripe
stripe.api_key = "sk_test_any_value"  # mock accepts any test key
stripe.api_base = "http://127.0.0.1:12111"
```

```javascript
// Node example
const stripe = require('stripe')('sk_test_any_value', {
  host: '127.0.0.1',
  port: 12111,
  protocol: 'http',
});
```

**Verify mock is up:**

```sh
curl -i http://127.0.0.1:12111/v1/customers \
  -H "Authorization: Bearer sk_test_123"
```

Use stripe-mock for **unit/integration tests**; use **test mode** for end-to-end Checkout and webhook flows.

### Option C — stripe-samples locally

Clone a sample (e.g. `checkout-single-subscription`), add your test keys to `.env`, run the sample server, and walk through Checkout in the browser. Good for team demos before MentorHub wires its own Customer SPA.

### Suggested MentorHub local stack (future)

```text
mh up customer          # Customer SPA + API + MongoDB
stripe-mock (or stripe listen)   # Payment API / webhooks
```

Environment variables (convention):

| Variable | Purpose |
| --- | --- |
| `STRIPE_SECRET_KEY` | `sk_test_…` |
| `STRIPE_PUBLISHABLE_KEY` | `pk_test_…` (SPA Checkout) |
| `STRIPE_WEBHOOK_SECRET` | `whsec_…` from CLI or Dashboard |
| `STRIPE_API_BASE` | `http://127.0.0.1:12111` when using stripe-mock |

---

## Recommended integration sequence (for the team)

1. **Stripe Dashboard setup** — Products/Prices for MentorHub plans; test mode keys in secrets manager (not git).
2. **Customer API webhook endpoint** — verify signatures; idempotent handlers; write `Event` + update `Subscription`.
3. **Checkout Session API** — Customer SPA "Subscribe" button → redirect to Stripe Checkout → return URL.
4. **Link MongoDB `Customer` ↔ Stripe Customer** — store `stripe_customer_id` on our Customer document.
5. **Customer Portal link** — "Manage billing" in Customer SPA.
6. **Enable `mock_stripe_api` in docker-compose** — fix image name to `stripe/stripe-mock`; wire `STRIPE_API_BASE` in Customer API for CI.
7. **Retire local `Card.number` storage** — PaymentMethods live in Stripe only.

---

## References

- [Stripe API Reference](https://docs.stripe.com/api)
- [Stripe Billing](https://docs.stripe.com/billing)
- [Stripe Checkout](https://docs.stripe.com/payments/checkout)
- [Customer Portal](https://docs.stripe.com/customer-management)
- [Webhooks](https://docs.stripe.com/webhooks)
- [Testing](https://docs.stripe.com/testing)
- [Stripe CLI](https://docs.stripe.com/stripe-cli)
- [stripe-mock](https://github.com/stripe/stripe-mock)
- [stripe-samples](https://github.com/stripe-samples)
- MentorHub: `Specifications/architecture.yaml`, `Specifications/catalog.yaml`, `Workshops/customer_workshop.md`, `DeveloperEdition/docker-compose.yaml`

---

## Team playback checklist

Use this document in a short team session:

- [ ] Everyone understands Stripe vs our MongoDB `Subscription` / `Customer` split
- [ ] Agree on Checkout-first vs custom payment form
- [ ] Agree on webhook ownership (`customer_api`)
- [ ] Agree on local dev: test mode + CLI vs stripe-mock in compose
- [ ] Identify who creates Stripe Products/Prices in Dashboard
