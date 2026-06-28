# API Standards

## Current State
This repository functions as a **versioned asset** managing core API utilities and standards. 
- **Lifecycle Stage:** Pre-release alpha development.
- **Breaking Changes Policy:** Because the architecture is pre-release, maintaining strict backward compatibility is **not** a primary constraint. Breaking changes are acceptable when aligning to core architectural goals, though they remain undesirable and should be communicated clearly across the team.
- **Upcoming Evolution Considerations:** The architecture is currently evaluating a potential transition from a purely "model-less" pass-through pattern toward a centralized Object Document Mapper (ODM) implemented directly into `api_utils` to simplify service layer implementations.

## Technology Stack
- Python v3.12^
- pipenv v2026.0.2
- pymongo v4.15.5
- Flask 
- PyJWT 
- prometheus-flask-exporter 
- pytest for unit testing
- pytest-cov for code coverage
- requests for black box E2E testing

## Dependency Management
- All dependencies are managed by `pipenv` via `Pipfile` and `Pipfile.lock`
- The `api_utils` shared library is published to AWS CodeArtifact (PyPI name `api-utils`, distribution `api_utils`) — see [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md)
- Domain API Pipfiles use a **single** CodeArtifact `[[source]]` with PyPI upstream so public packages (Flask, pymongo, etc.) and `api-utils` resolve from one index
- Pin exact semver for `api-utils` (for example `==0.2.1`); do not track `main` or use bare `*` (public PyPI package `api-utils` is unrelated and breaks Config/auth)
- Local development: run `mh` before `pipenv run install` / `pipenv install --dev` (see [SRE Standards](./sre_standards.md#codeartifact-local-authentication))
- Docker builds: GitHub Actions obtains a short-lived CodeArtifact token and passes `PIP_INDEX_URL` as a build arg — no git or `GH_PAT` for dependency install (see [docker-push-codeartifact.yml](./examples/docker-push-codeartifact.yml))

All journey domain APIs use CodeArtifact as of [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md) Phase 2. Stage0 templates and utility publish workflows are tracked separately in that document.

## Standard Developer Commands
- pipenv run build (package code for deployment)
- pipenv run dev (run dev server)
- pipenv run db (start backing db container)
- pipenv run api (start db + api containers)
- pipenv run service (start db, api, spa containers)
- pipenv run container (build API container)

## API Design
- Create, Retrieve, Patch design pattern
- API's work with a model-less document management approach
- **Data Quality Delegation:** In our model-less API architecture, data quality constraints are fully delegated to the database layer (via MongoDB Schema Validation), *not* implemented in application code. No duplicate validation logic should exist in the API layer.
- **Specification Source of Truth:** The OpenAPI Specification Schema is strictly grounded in the Database Validation Schema. It remains a Design Specification, NOT a code build artifact.
- Route blueprints use factory functions (e.g., `create_*_routes()`) that return Flask Blueprints
- Route registration should be grouped together in `server.py` for clarity

## Separation of Concerns
- `server.py` is the standard API entry point
- `command.py` is the standard CLI entry point
- `/routes/*domain*_routes.py` handle HTTP request/response logic
  - **HTTP Scope Only:** This is a single-purpose layer responsible for HTTP-related code: request/reply access, token verification, tracking breadcrumb creation, handling HTTP exceptions, and extracting payloads or parameters. It must **not** validate, process, or alter payloads in any way.
- `/services/*domain*_service.py` handles business logic/RBAC for domain
  - **Stateless & Aligned:** Services are a single-purpose layer strictly aligned to a single Database Collection. Responsible for Business Logic, RBAC enforcement, and system-managed guardrails. If a service file exceeds a few hundred lines, it must be audited for architectural leakage.
  - **Service-to-Service Calls:** Service layers are static and completely stateless. Service-to-service calls are the preferred reuse pattern for cross-collection dependencies (e.g., calling `ProfileService.getProfileByToken(...)` instead of duplicating raw MongoDB queries locally).
  - **Dependency Isolation:** In scenarios where circular service dependencies arise, a special "Aggregation" service layer must be introduced to isolate orchestration logic.
  - **RBAC & Ownership:** RBAC enforcement happens strictly at the Service layer. "Ownership" verification is an RBAC function (frequently utilizing `profile_service.getByToken` to verify if the User ID matches the target Resource Owner ID). RBAC functions can retrieve current state from the database to enforce these rules, but this fetch of state must *never* be used to modify incoming updates being authorized.

### 📊 Dependency & Relationship Mapping
For system entity relationships and collection dependencies, reference the system ERD directly:
- **Source Diagram:** `../mentorhub_mongodb_api/erd.drawio`
- **Vector Alternative:** `../mentorhub_mongodb_api/erd.svg`

## Authentication
- **API responsibility:** Domain APIs **validate** Bearer JWTs only. They must **not** register HTTP routes that mint credentials, exchange user passwords for tokens, or otherwise act as an identity provider.
- **Validation:** Use `api_utils` `create_flask_token()` or `Token` on protected routes. Verification uses `JWT_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE`, and `JWT_ALGORITHM` from `Config` (applications fail fast if `JWT_SECRET` is left at an insecure default).
- **Claims:** Tokens are expected to include at least `iss`, `aud`, `sub`, and `exp`. Use a `roles` claim (list) where RBAC is required; route logic and `create_flask_breadcrumb()` consume the dict returned by `create_flask_token()` (`user_id` is derived from `sub`).
- **Developer Edition:** The umbrella **developer sign-in page** (`login.html`) mints local persona JWTs (HS256, `iss: dev-idp`, `aud: dev-api`). The same **stable `JWT_SECRET`** in compose must sign those JWTs and be trusted by every API. SPAs load tokens into `localStorage` via `bootstrapAuthFromUrl()` from **`@mentor-forge/mentorhub_spa_utils`** (call once before the router mounts, e.g. `src/initAuth.ts`); clearing stored tokens uses the SPA-side query `?clear_stored_auth=1`, not an API endpoint. See [SPA standards](./spa_standards.md).
- **Production:** Access tokens are issued by your commercial IdP (OAuth2/OIDC) or a BFF; domain APIs keep the same validation contract (`iss`/`aud`/`sub`/`exp`/roles).
- **Automated tests:** Send `Authorization: Bearer <jwt>` using a JWT signed with the same `JWT_SECRET` and claim expectations as the running stack (see each repo’s `tests/e2e_auth.py` or equivalent).

# api_utils standards
The api_utils library implements standard API features and functions, with a goal of making it easy to comply with standards. 

### Required Endpoints
All APIs must implement the following standard endpoints:

- **`/metrics`** — Prometheus text exposition metrics (use api_utils `create_metric_routes()`)
  - **Note:** `create_metric_routes()` attaches middleware to the Flask app; it is not a blueprint.
- **`/api/config`** — Configuration endpoint (use api_utils `create_config_routes()`)
- **`/docs/*`** — API explorer / OpenAPI docs (use api_utils `create_explorer_routes()`)
  - **OpenAPI spec:** Each API maintains `docs/openapi.yaml`.

## Server.py Organization Pattern
All API servers should follow the organizational pattern established in api_utils/server.py:

1. **Module docstring** - Describe the server purpose and capabilities
2. **Imports** - `sys`, `os`, `signal`, `api_utils`, Flask imports
3. **Config singleton initialization** - Initialize before logging
4. **MongoIO singleton and configuration** - Set enumerators and versions
5. **Flask app initialization** - Create app with MongoJSONEncoder
6. **Route registration** - Register all routes
7. **Logging summary** - Clear summary of registered routes
8. **Signal handlers** - SIGTERM and SIGINT for graceful shutdown
9. **Main entry point** - `if __name__ == "__main__"` block

- **Config Singleton**: Use `Config.get_instance()` for all configuration values
  - Configuration follows precedence: Config File → Environment Variable → Default Value
  - Non-secret values are exposed via `/api/config` endpoint
  
- **MongoIO Singleton**: Use `MongoIO.get_instance()` for all MongoDB operations
  - Provides connection pooling and error handling
  - Thin wrapper around MongoDB pymongo library
  - Supports enumerators and versions on initialization
  - Responsible for all MongoDB IO operations

- **Flask Utilities**:
  - `create_flask_token()` — Validate `Authorization: Bearer` JWTs (signature, `iss`, `aud`, `exp`); see [Authentication](#authentication)
  - `create_flask_breadcrumb(token)` - Generate request breadcrumbs for logging
  - `handle_route_exceptions` - Decorator for consistent exception handling
  - `MongoJSONEncoder` - Custom JSON encoder for MongoDB document types
  - Custom exceptions: `HTTPUnauthorized`, `HTTPForbidden`, `HTTPNotFound`, `HTTPInternalServerError`
  - **Security**: Do not include PII or User Data in exceptions

- **Protected Routes**: Use `@handle_route_exceptions` decorator and `create_flask_token()` to protect routes:
  ```python
  @route.route('/protected', methods=['GET'])
  @handle_route_exceptions
  def protected_route():
      token = create_flask_token()  # Full JWT validation; raises HTTPUnauthorized if invalid
      breadcrumb = create_flask_breadcrumb(token)
      # ... route logic
      