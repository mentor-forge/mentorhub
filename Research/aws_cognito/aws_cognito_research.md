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

From this overview page alone (not the Admin API docs):

- MentorHub uses **AWS Cognito as the IdP** for Customer SPA login / JWT — not for collecting registration form fields (that stays Squarespace → Sheet → `POST Profile`).
- Cognito’s branded Hosted UI / sign-in features align with “login redirect already done”; they do **not** by themselves define MentorHub custom claims (`profile_id`, `customer_id`, `mentor_id`, `roles`).
- M2M / client-credentials may matter later for service-to-service calls (e.g. Sheet script → API), but that is separate from end-user Customer login.
- Passwordless / social / passkeys are optional Cognito capabilities; MentorHub has not committed to them in the Customer journey plans.

**Naming reminder:** Say **AWS Cognito** (or Amazon Cognito) for this IdP. Say **Cognito Forms** only for the form product under `Research/cognito_forms/`.

---

## Gaps (not covered by the Cognito marketing page)

The overview at [aws.amazon.com/cognito](https://aws.amazon.com/cognito/) does **not** document:

- `AdminCreateUser` / `AdminUpdateUserAttributes` request fields
- How to attach custom attributes or JWT claims (`profile_id`, etc.)
- Pre token generation Lambda behavior
- Exact Hosted UI self-signup vs admin-provisioned user differences for MentorHub

Those items are Do This First **R1** and need AWS API / developer guide research in a follow-up pass of this folder (after review of this overview note).

---

## References

- [Amazon Cognito — product overview](https://aws.amazon.com/cognito/)
- Related MentorHub plans: `Workshops/customer_journey_issues.md` (Do This First R1; Auth = AWS Cognito)
- Adjacent form tooling (different product): `Research/cognito_forms/cognito_forms_research.md`
