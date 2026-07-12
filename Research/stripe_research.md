# F-W03: Stripe API, Billing & Subscriptions Research Summary

**Issue:** [#32 — F-W03: Stripe Research](https://github.com/mentor-forge/mentorhub/issues/32)

---

## What is Stripe?

Stripe is a payment processing platform that lets businesses accept online payments, manage subscriptions, send invoices, and handle customer billing — without building a payment system from scratch.

Stripe handles credit/debit cards, digital wallets (Apple Pay, Google Pay), bank transfers, subscription billing, invoicing, tax calculations, customer management, and fraud prevention.

---

## What is the Stripe API?

The Stripe API lets our application talk to Stripe's servers. We send requests (create a customer, create a subscription, charge a payment method, cancel, update billing, retrieve invoices) and get JSON responses.

**Typical signup flow:**

```text
User signs up → App creates Stripe Customer → Customer enters payment info
→ Stripe stores payment method → App creates Subscription → Stripe bills monthly
```

---

## Core Stripe Objects

| Object | Purpose |
| --- | --- |
| **Customer** | Payer record: name, email, payment methods, billing history, subscriptions |
| **Product** | What is sold (e.g. MentorHub Basic, Pro, Enterprise) |
| **Price** | How much it costs ($10/mo, $99/yr, usage-based). One Product can have many Prices |
| **Subscription** | Active recurring payment: customer + price + billing cycle + status |
| **Invoice** | Bill for each cycle: amount, taxes, discounts, payment status |
| **Payment Intent** | A payment in flight (authorization, 3D Secure, success/failure) |

### Example MentorHub plans (fictional)

| Plan | Price | Features |
| --- | --- | --- |
| **Basic** | $9.99/mo | 1 mentor profile, 5 mentees, basic messaging, email support |
| **Pro** | $39.99/mo | Unlimited mentees, video sessions, analytics, priority support |
| **Enterprise** | Custom | Unlimited orgs, SSO, API access, dedicated account manager |

In Stripe: **Product** = MentorHub; **Prices** = Basic / Pro / Enterprise. Customer picks a price → Stripe creates a **Subscription** → bills on cycle → sends webhooks so our app knows status.

### Sample invoice (simplified)

Mary Anderson subscribes to MentorHub Pro ($39.99/mo). Stripe generates an invoice:

- Subtotal: $39.99 → Discount (WELCOME10): -$4.00 → Tax (8%): $2.88 → **Total: $38.87**
- Status: **Paid** (or **Payment Failed** → webhook `invoice.payment_failed` → email customer, suspend access, retry)

---

## Billing and Subscriptions

Stripe Billing automates recurring payments: monthly/annual plans, trials, upgrades, downgrades, coupons, renewals, and failed-payment retries.

```text
Customer buys Premium → Stripe bills today → 30 days later bills again → Customer cancels → Subscription ends
```

---

## Stripe Checkout

Pre-built, secure, mobile-friendly, PCI-compliant payment page. We redirect users to Checkout instead of building our own form.

**Supported:** Visa, Mastercard, Amex, Apple Pay, Google Pay, ACH, SEPA, Klarna, Affirm, and more (varies by country).

**Not supported:** Cash, checks, PayPal, crypto (direct), gift cards, COD.

---

## Webhooks

Stripe notifies our app when events happen (instead of us polling):

| Event | When |
| --- | --- |
| `checkout.session.completed` | Checkout finished |
| `customer.subscription.created/updated/deleted` | Subscription lifecycle |
| `invoice.paid` / `invoice.payment_failed` | Billing success or failure |
| `payment_intent.succeeded` | Payment completed |

Always verify webhook signatures (`whsec_…`).

---

## Authentication

| Mode | Use |
| --- | --- |
| **Test** | Development — fake money, test cards |
| **Live** | Production — real charges |

- **Publishable key** (`pk_test_…`) — safe for frontend
- **Secret key** (`sk_test_…`) — backend only, never expose in frontend

---

## Local Development & Testing

**Stack:** Frontend → Backend API → Stripe Test API (no real charges)

**Stripe CLI** — forward webhooks to localhost, trigger fake events, test subscriptions:

```sh
stripe listen --forward-to localhost:8387/api/webhooks/stripe
stripe trigger checkout.session.completed
```

**Test cards:** `4242 4242 4242 4242` (success), `4000 0000 0000 0002` (declined)

**stripe-mock** (optional, for automated tests without network):

```sh
docker run --rm -p 12111:12111 stripe/stripe-mock:latest
```

Point SDK at `http://127.0.0.1:12111` with any `sk_test_…` key.

### Sample integration flow

```text
User selects plan → App creates Checkout Session → Redirect to Stripe Checkout
→ Payment processed → Webhook received → Backend verifies → DB updated → User gets access
```

---

## Security Best Practices

- Never store raw card numbers (use Stripe Checkout / PaymentMethods)
- Secret keys on backend only; HTTPS in production
- Verify webhook signatures; use `.env` for credentials
- Test in Test Mode before going live

---

## MentorHub Touch Points

| Area | Details |
| --- | --- |
| **Customer journey** | Owns `Subscription`, `Card`, `Dashboard` (`mentorhub_customer_api`, `mentorhub_customer_spa`) |
| **MongoDB** | `Subscription`, `Card`, `Customer`, `Event` collections in `mentorhub_mongodb_api` |
| **Workshops** | Customer workshop: checkout, billing hub, pause billing, receipts |
| **Local dev** | Commented `mock_stripe_api` in `DeveloperEdition/docker-compose.yaml` (port 12111) |
| **Not built yet** | No Stripe SDK in customer repos; no cloudformation Stripe resources |

**Our app will interact with Stripe for:** customer creation, subscriptions, Checkout, payment processing, billing history, upgrades/cancellations, webhooks, and DB updates after payment events.

---

## Key Takeaways

- Stripe handles payments and recurring billing; we handle sponsorship, mentee access, and dashboards.
- Core objects: Customer, Product, Price, Subscription, Invoice, Payment Intent, Webhooks.
- Use **Checkout** for signup, **Customer Portal** for self-service billing, **webhooks** to sync state.
- Develop locally with **Test Mode**, **Stripe CLI**, and optionally **stripe-mock**.
- Secret keys stay on the backend; publishable keys go in the frontend.

---

## References

- [Stripe API](https://docs.stripe.com/api) · [Billing](https://docs.stripe.com/billing) · [Checkout](https://docs.stripe.com/payments/checkout) · [Webhooks](https://docs.stripe.com/webhooks) · [Testing](https://docs.stripe.com/testing) · [Stripe CLI](https://docs.stripe.com/stripe-cli) · [stripe-mock](https://github.com/stripe/stripe-mock) · [stripe-samples](https://github.com/stripe-samples)
