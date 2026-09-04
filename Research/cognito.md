# AWS Cognito — Self-Registration & Invitation Requirements

**Related issue:** [F-W04: Cognito Research](https://github.com/mentor-forge/mentorhub/issues/33)

**Product:** [Amazon Cognito](https://aws.amazon.com/cognito/) — AWS identity provider for MentorHub login and JWT issuance.

**Context:** MentorHub APIs require JWT custom claims on every authenticated call. The Customer SPA redirects to Cognito Hosted UI for login and sign-up — it does **not** implement custom auth screens. **Customer API** orchestrates MongoDB records (Customer, Profile) and Cognito user attributes; Cognito owns passwords, MFA, and Hosted UI.

---

## JWT claim requirements

All domain APIs validate Bearer tokens via `api_utils` and expect these claims:

| Claim | Required | Source of truth | Notes |
| --- | --- | --- | --- |
| **`display_name`** | **Yes** — always-present string | Profile `display_name` | Human-readable identity label; use this claim instead of OIDC/JWT `name` |
| **`profile_id`** | **Yes** — request rejected without it | Profile `_id` | Primary identity for RBAC and document scoping |
| **`customer_id`** | Present (may be empty string for non-tenant personas) | Customer `_id` on Profile | Sponsoring org; set for Customer persona flows |
| **`mentor_id`** | **Reserved** — always present (may be empty string) | Profile `mentor_id` | Empty for Customer registrants and non-mentees; set when a mentee is assigned a mentor |
| **`roles`** | Present (list) | Profile `roles` | `user_roles` enum: `mentor`, `mentee`, `customer`, `coordinator`, `admin` |

**Pool storage vs token shape**

- Cognito **custom attributes** on the user pool: `custom:display_name`, `custom:profile_id`, `custom:customer_id`, `custom:mentor_id`, `custom:roles`.
- **JWT claims** (what APIs read): same names **without** the `custom:` prefix.
- A **Pre Token Generation** Lambda copies pool attributes into claims on every token issue/refresh. Hosted UI sign-up alone does **not** populate MentorHub claims — Customer API must create Profile/Customer and write attributes first.

**`roles` encoding:** Store in Cognito as a string (JSON array or comma-separated). Pre Token Generation emits a **list** in the JWT; `api_utils` also splits comma-separated strings.

**`mentor_id` reservation:** Define the attribute on the pool and always include the claim in tokens, even when `""`, so token shape is stable across personas.

---

## Onboarding model

MentorHub is **B2B multi-tenant**: one **Customer** org, many **Profiles**. Use exactly two paths:

| Path | Who | Mechanism |
| --- | --- | --- |
| **A. Primary org owner** | First user for a new company (paying sponsor) | **Self-registration** via Cognito Hosted UI sign-up → Customer API creates **new Customer** + **new Profile** → Cognito custom attributes |
| **B. Additional members** | People invited by an authenticated Customer | **Invitation only** — Customer API → `AdminCreateUser` under inviter’s `customer_id`; **no** public self-sign-up for invitees |

### Why two paths?

1. **Custom claims** — Sign-up collects email/password only. MentorHub ids and roles must be created in MongoDB first, then mirrored to Cognito.
2. **Tenant binding** — Invited users must inherit the **inviter’s `customer_id`**. Only Path A creates a new Customer document.
3. **Seat / capacity** — Invites can be checked against subscription before creating a Cognito user.
4. **Security** — Path B never uses open registration; orphan Cognito users without `customer_id` are prevented.

---

## Path A — Primary user self-registration

**Outcome:** New `Customer` org, new `Profile` for the owner, `roles: ["customer"]`, `mentor_id: ""`, Cognito user with all custom attributes, JWT usable on first SPA login after confirmation.

```text
Prospect
  → Cognito Hosted UI Sign up + email confirm
  → Post Confirmation Lambda (service auth)
       → Customer API: create Customer (org) + Profile (owner)
            profile_id: new
            customer_id: new  (links Profile to new Customer)
            roles: ["customer"]
            mentor_id: ""
       → AdminUpdateUserAttributes: set custom:* on Cognito user
  → Pre Token Generation → JWT with display_name and four authorization/scoping claims
  → Customer SPA (existing IdP redirect) → APIs accept token
```

**Customer API responsibilities**

- Create **Customer** and **Profile** atomically (single transaction or compensating rollback).
- Idempotent on Cognito `sub` and/or email — trigger retries must not duplicate org or user.
- Return ids to the trigger path that writes Cognito attributes, or write attributes directly if API holds Cognito Admin credentials.
- If MongoDB create fails after Cognito user exists: retry, quarantine, or disable user — **do not** allow API access without `profile_id`.

**Hosted UI fields (minimum):** email, password, and display name (maps to Profile `display_name`; username policy TBD — email-as-username is acceptable default).

**Not in Path A:** SPA registration screens; end-user JWT on the provisioning call (use service credential from Lambda).

---

## Path B — Primary user invites members

**Outcome:** New `Profile` under **inviter’s existing `customer_id`**, Cognito invite email, JWT with correct tenant on first login.

```text
Authenticated Customer (JWT customer_id set)
  → Customer SPA: name + email
  → Customer API:
       verify inviter customer_id from JWT (never from request body alone)
       optional seat/capacity check vs Customer.subscriptions[]
       create Profile: customer_id = inviter’s, roles = ["customer"], mentor_id = ""
       AdminCreateUser + invite message (RESEND if re-invite)
       set custom:profile_id, custom:customer_id, custom:mentor_id, custom:roles
  → Invitee: Hosted UI → set password
  → Pre Token Generation → JWT → member APIs scoped to same customer_id
```

**Rules**

- Invitee must **not** use public Hosted UI self-sign-up (would create a new Customer via Path A).
- Re-invite same email: idempotent — resend invite, no duplicate Profile or Cognito user.
- Revoke: disable Cognito user and/or mark invite revoked (product TBD in E4 tickets).

---

## Cognito setup before any user exists

### One-time per environment — infra / CloudFormation (not Customer API)

| # | Task | Notes |
| --- | --- | --- |
| **P1** | User pool | Password policy, MFA policy, email config |
| **P2** | Custom attribute schema | `custom:display_name`, `custom:profile_id`, `custom:customer_id`, `custom:mentor_id`, `custom:roles` — **names immutable after pool creation** |
| **P3** | App client + Hosted UI | Callback/logout URLs for Customer SPA; authorization code flow; **sign-up enabled** for Path A |
| **P4** | Cognito domain | Hosted UI hostname |
| **P5** | Pre Token Generation Lambda | Maps `custom:*` → JWT claims; use **V2** if access token must carry claims |
| **P6** | Post Confirmation Lambda | Calls Customer API for Path A; optional Pre Sign-up validation |
| **P7** | IAM — Customer API | `AdminCreateUser`, `AdminUpdateUserAttributes`, `AdminDisableUser`, `AdminDeleteUser` |
| **P8** | IAM — trigger Lambdas | Invoke Customer API + Cognito Admin as needed |
| **P9** | Service credential | M2M token or API key so triggers cannot be spoofed |

Implement via `mentorhub_cloudformation` (pool template is placeholder) or documented deploy runbook. **Not** manual console steps per Customer org.

### Per user — Customer API (steady state)

| Operation | MongoDB | Cognito Admin API |
| --- | --- | --- |
| Primary self-reg (Path A) | Create Customer + Profile | Set `custom:*` after API create |
| Invite member (Path B) | Create Profile under inviter `customer_id` | `AdminCreateUser` + invite |
| Role / mentor change | Update Profile | `AdminUpdateUserAttributes` |
| Suspend / GDPR | Redact Profile | `AdminDisableUser` / `AdminDeleteUser` |

Manual Cognito console edits are **break-glass only** — they bypass Profile/`customer_id` consistency.

**Local development (locked):** See `Research/local_dev_mocks.md` — extend **`login.html`** (register / invite / update tabs) + Customer API **dev routes** (`REGISTRATION_DEV_MODE`, `COGNITO_ENABLED=false`); **stripe-mock** for billing. No Cognito container or Hosted UI locally. Production path unchanged.

---

## API vs manual

| Concern | Infra (once per env) | Customer API |
| --- | --- | --- |
| User pool, custom attrs, Lambdas, Hosted UI URLs | ✅ | ❌ |
| Create Customer + Profile on primary sign-up | ❌ | ✅ |
| Set JWT claim attributes on Cognito user | ❌ | ✅ |
| Invite additional users | ❌ | ✅ |
| Sync claims when Profile changes | ❌ | ✅ |
| Login / password / MFA UI | Cognito Hosted UI | ❌ |

---

## Anti-patterns

| Anti-pattern | Prefer |
| --- | --- |
| Hosted UI sign-up **without** Post Confirmation → API callback | Path A with trigger + Customer API |
| Invited users use public self-sign-up | Path B `AdminCreateUser` only |
| Claims only in MongoDB, not on Cognito user | Sync `custom:*` on every provision/update |
| Manual Cognito user per registration | Customer API orchestration |
| Omit `mentor_id` from schema | Always include; empty when unset |

---

## Open decisions (lock in E1 / E4 issue text)

1. **Trigger** — Post Confirmation vs Post Authentication for Path A callback.
2. **Username** — email as Cognito username vs separate `Profile.name`.
3. **Email verified** — align Cognito confirm with Profile `email_verified`.
4. **Access vs ID token** — which token carries custom claims for SPA (`initAuth`).
5. **Invite seat rules** — hard block vs soft warning when at capacity.
6. **Invite persistence** — embed on Customer vs small Invite collection.

---

## References

- [AdminCreateUser](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_AdminCreateUser.html)
- [AdminUpdateUserAttributes](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_AdminUpdateUserAttributes.html)
- [Pre token generation Lambda trigger](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-pre-token-generation.html)
- [Post confirmation Lambda trigger](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-post-confirmation.html)
- [User pool custom attributes](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-attributes.html)
- Token validation: `mentorhub_api_utils/api_utils/flask_utils/token.py`
- Profile schema: `mentorhub_mongodb_api/configurator/dictionaries/Profile.0.1.0.yaml`
