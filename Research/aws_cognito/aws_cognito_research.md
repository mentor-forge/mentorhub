# AWS Cognito Research Summary

**Related issue:** [F-W04: Cognito Research](https://github.com/mentor-forge/mentorhub/issues/33)

**Product:** [Amazon Cognito](https://aws.amazon.com/cognito/) — AWS identity and access management (IdP).  
**Not this product:** Cognito Forms (form builder) — see `Research/cognito_forms/cognito_forms_research.md`.

**Source for this note:** Public Cognito overview page — [https://aws.amazon.com/cognito/](https://aws.amazon.com/cognito/) (reviewed for MentorHub context). Deeper Admin API / custom-claims research belongs in follow-up sections or a later revision of this file.

---

## What Amazon Cognito is (from AWS)

Amazon Cognito helps implement secure sign-in and access control for users, AI agents, and microservices. AWS positions it as customer identity and access management (CIAM) plus support for machine identities: a managed identity store with federation options, used at very large authentication volume.

Cognito is described as helping teams:

- Create branded customer sign-in experiences
- Improve security
- Adapt authentication to customer needs (e.g. social IdPs, passwordless options)

It is also described as integrating with Amazon Bedrock AgentCore Identity as a trusted identity provider for agent access to AWS and third-party resources.

---

## Benefits called out on the Cognito page

### Unified authentication (human and machine)

One AWS-native service for user and machine authentication, reducing separate identity tools and keeping auth consistent across users, agents, and workloads.

### Secure, scalable CIAM

Enterprise-oriented, cost-effective, customizable identity. Supports:

- Login with social identity providers
- Passwordless login (WebAuthn passkeys, SMS/email one-time passwords)
- Scaling to large user directories via a managed user directory

### Integration and customization

Low-code / no-code options for branded sign-up and sign-in. Works with many frameworks (examples listed by AWS: Amplify, React, Next.js, Angular, Vue, Flutter, Java, .NET, C++, PHP, Python, Go, Ruby, iOS, Android).

### Advanced security for sign-up and sign-in

Examples AWS lists:

- Risk-based adaptive authentication
- Compromised credential monitoring
- IP geo-velocity tracking
- Security metrics for threat detection / malicious login protection

---

## Use cases called out on the Cognito page

| Use case | Summary from AWS |
| --- | --- |
| **Customer authentication** | Secure access (including passwordless) and branded experiences (enhanced UI editor) |
| **B2B / multi-tenant** | Multi-tenancy options with different policy and tenant isolation levels |
| **Machine-to-machine (M2M)** | Secure microservice / backend connections |
| **App / microservice auth** | OAuth 2.0 **client-credentials** flow; short-lived scoped tokens instead of static API keys |
| **High availability** | Multiple auth methods (social, SAML/OIDC, API authorization); multi-region replication called out |

---

## MentorHub relevance (high level)

- MentorHub uses **AWS Cognito as the IdP** for Customer SPA login / JWT (Hosted UI).
- **JWT claims** required by APIs: `profile_id`, `customer_id`, `mentor_id`, `roles` — stored as Cognito custom attributes and/or injected via Pre Token Generation; values come from MentorHub **Profile / Customer** records created (or updated) by Customer API callbacks.
- **New Customer self-registration** (R1 / R2): Cognito **Hosted UI** sign-up, with **calls back to Customer API** to create Profile, Customer, and roles so those ids can be written onto the Cognito user and appear in JWTs. Squarespace → Sheet remains a related intake/ops path under R2 research; Cognito Hosted UI + API callback is the IdP registration workflow defined here.
- **Invite User** (R6) and **Update User** (including **Delete PII** / GDPR) are separate Cognito-facing workflows below.
- M2M / client-credentials may matter for trusted API callbacks from Cognito triggers (or Admin API from Customer API).

**Naming reminder:** Say **AWS Cognito** (or Amazon Cognito) for this IdP. Say **Cognito Forms** only for the form product under `Research/cognito_forms/`.

---

## Shared Cognito prerequisites (all workflows)

| # | Task | What it does | Owner layer |
| --- | --- | --- | --- |
| **S1** | **User pool custom attributes** | Pool defines `custom:profile_id`, `custom:customer_id`, `custom:mentor_id`, `custom:roles` | IdP / infra |
| **S2** | **Pre Token Generation trigger** | Copies custom attrs into JWT claims `profile_id`, `customer_id`, `mentor_id`, `roles` (access token as needed — often trigger V2) | IdP / Lambda |
| **S3** | **Trusted API auth for Cognito→API** | Cognito trigger (or Admin path) can call Customer API with a service credential; never rely on an incomplete end-user JWT to create the first Profile | IdP + Customer API |

---

## Workflow: New Customer self-registration (Cognito Hosted UI + API callback) — R1 / R2

**Intent:** Prospect signs up on the **Cognito Hosted UI** page. Cognito (via Lambda triggers) **calls back to Customer API** to create **Profile**, **Customer**, and **roles**, then Cognito user attributes are set so **JWT claims** are populated on subsequent tokens.

### Tasks

| # | Task | What it does | Owner layer |
| --- | --- | --- | --- |
| **N1** | **Enable Hosted UI sign-up** | App client allows self-registration; branded Hosted UI collects username/email/password (and any allowed standard attrs) | IdP config |
| **N2** | **Pre Sign-up trigger (optional)** | Validate email domain / duplicate rules; auto-confirm policy TBD | IdP / Lambda |
| **N3** | **Post Confirmation (or Post Authentication) callback → Customer API** | On successful confirm: API creates **Customer** (org) + **Profile** with `roles` (e.g. `["customer"]`); returns `profile_id`, `customer_id`, `mentor_id` (often empty), `roles` | Customer API |
| **N4** | **Write custom attributes on Cognito user** | After API response: set `custom:profile_id`, `custom:customer_id`, `custom:mentor_id`, `custom:roles` (`AdminUpdateUserAttributes` from trigger/backend) | IdP trigger and/or Customer API |
| **N5** | **Idempotent callback** | Same Cognito `sub` / email must not create duplicate Profile/Customer on trigger retry | Customer API |
| **N6** | **First SPA login** | Existing SPA `redirectToIdpLogin` → Hosted UI sign-in → tokens include claims via **S2** | SPA + Cognito |
| **N7** | **Failure / compensation** | If API create fails after Cognito user exists: retry callback, or mark user for ops repair; do not issue usable API access without claims | IdP + Customer API |

### Sequence

```text
Prospect → Cognito Hosted UI Sign up / Confirm (N1–N2)
  → Trigger calls Customer API (N3)
       → create Customer + Profile + roles
       → return profile_id, customer_id, mentor_id, roles
  → Set Cognito custom attributes (N4)  [S1]
  → Customer opens SPA → Hosted UI login (N6)
  → Pre Token Generation (S2) → JWT claims → Customer API accepts calls
```

### Still to lock (R1 / R2)

1. Which trigger fires the API callback (Post Confirmation vs custom auth flow vs backend after first login).
2. Whether Squarespace → Sheet is **replaced by**, **feeds**, or **runs in parallel with** Hosted UI self-reg.
3. Exact Hosted UI fields vs Profile/Customer field map (see `Research/squarespace_sheet/` for attribute homes).
4. Username = email vs separate; `email_verified` timing vs API `email_verified`.

---

## Workflow: Invite User — R6

**Intent:** An authenticated Customer invites a person (**name + email** per workshop). Invitee receives a Cognito path to set credentials; Profile is created/linked under the inviting **Customer** with roles decided by R6.

### Tasks

| # | Task | What it does | Owner layer |
| --- | --- | --- | --- |
| **I1** | **Customer API create invite** | Authenticated customer submits name + email; persist invite; enforce seat/capacity when R6 defines them | Customer API + SPA |
| **I2** | **AdminCreateUser (invited)** | Create Cognito user for invitee email; send invite / temp password (`MessageAction`); do **not** use Hosted UI public sign-up for the invitee’s first credential handoff | Customer API → Cognito Admin |
| **I3** | **Create/link Profile under inviting Customer** | Profile with `customer_id` = inviter’s customer; `roles` per R6 (e.g. `customer` member vs former coordinator) | Customer API |
| **I4** | **Set custom attributes** | `custom:profile_id`, `custom:customer_id`, `custom:mentor_id`, `custom:roles` before or at first token | Customer API / AdminUpdate |
| **I5** | **Invitee first login** | Hosted UI: force change password / complete invite; SPA redirect; JWT claims via **S2** | Cognito + SPA |
| **I6** | **Idempotent invite** | Re-invite same email does not duplicate Cognito user or Profile; resend message if allowed | Customer API |
| **I7** | **Revoke invite (optional)** | Disable Cognito user and/or mark invite revoked; clear pending access | Customer API + Cognito Admin |

### Sequence

```text
Customer SPA → Invite API (I1)
  → AdminCreateUser + invite message (I2)
  → Profile under customer_id + roles (I3–I4)
Invitee → Hosted UI accept / set password (I5)
  → JWT claims (S2) → member can call APIs as allowed by roles
```

### Still to lock (R6)

1. Invitee roles enum values and whether coordinator is in scope.
2. Seat/capacity coupling to Stripe subscription.
3. Invite persistence collection vs Profile-only (journey F-D24).

---

## Workflow: Update User (including Delete PII) — R1 / GDPR

**Intent:** Keep Cognito attributes aligned when Profile/Customer/roles change; on GDPR forget, remove or neutralize person PII in Cognito and MentorHub (Profile ± Encounter) without a GDPR data property on Customer.

### Update User tasks

| # | Task | What it does | Owner layer |
| --- | --- | --- | --- |
| **U1** | **Profile/role change → AdminUpdateUserAttributes** | When `roles`, `customer_id`, `mentor_id`, email, or display-related attrs change in MentorHub, update Cognito `custom:*` (and standard attrs as needed) | Customer API |
| **U2** | **Disable / enable user** | Suspend access without delete (`AdminDisableUser` / `AdminEnableUser`) when product requires | Customer API |
| **U3** | **Token freshness** | After claim-changing updates, next token (S2) reflects new attrs; document whether refresh is forced | IdP + SPA |

### Delete PII tasks (GDPR forget)

| # | Task | What it does | Owner layer |
| --- | --- | --- | --- |
| **D1** | **SPA Privacy action** | Customer (or subject) triggers forget — **no** GDPR field on Customer/Profile documents | Customer SPA |
| **D2** | **API redact MentorHub PII** | Redact Profile PII (± Encounter transcript/summary/tldr); cancel Stripe if required by journey | Customer API |
| **D3** | **Cognito PII delete / neutralize** | Clear or hash email/phone/name attrs; clear `custom:*` claim attrs; and/or `AdminDeleteUser` if product deletes the IdP user | Customer API → Cognito Admin |
| **D4** | **Block re-auth** | Disabled or deleted Cognito user cannot obtain JWTs with old claims | Cognito |
| **D5** | **Idempotent forget** | Second forget request is safe no-op | Customer API |

### Sequence (Delete PII)

```text
SPA Privacy button (D1)
  → Customer API redact Profile/Encounter (+ billing cancel if needed) (D2)
  → Cognito AdminDeleteUser or attribute wipe (D3–D4)
  → subsequent login/API calls fail or have no PII claims
```

### Still to lock

1. Soft redact + disable Cognito user vs hard `AdminDeleteUser`.
2. Whether org **Customer** document remains (yes per journey — org/billing not GDPR-person).
3. Encounter scope for redact.

---

## Gaps (not covered by the Cognito marketing page)

The overview at [aws.amazon.com/cognito](https://aws.amazon.com/cognito/) does **not** document:

- `AdminCreateUser` / `AdminUpdateUserAttributes` / `AdminDeleteUser` request fields
- Hosted UI sign-up **trigger → Customer API** callback contract for Profile/Customer/roles
- How custom attributes become JWT claims (Pre Token Generation)
- Invite vs self-reg vs GDPR delete sequencing for MentorHub

Those items remain Do This First **R1** (and touch **R2** registration handoff, **R6** invite model) — see workflows above. Field mapping for Profile/Customer attributes: `Research/squarespace_sheet/squarespace_sheet_research.md`. Optional form alternate: `Research/cognito_forms/`.

---

## References

- [Amazon Cognito — product overview](https://aws.amazon.com/cognito/)
- Related MentorHub plans: `Workshops/customer_journey_issues.md` (Do This First R1, R2, R6; Experiences E1, E4, E8)
- Registration field / POST Profile research (R2): `Research/squarespace_sheet/squarespace_sheet_research.md`
- Adjacent form tooling (different product): `Research/cognito_forms/cognito_forms_research.md`
