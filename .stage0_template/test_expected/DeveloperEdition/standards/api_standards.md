# API Standards

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
- The `api_utils` shared library is installed via HTTPS from GitHub
- Docker builds use `GITHUB_TOKEN` build argument for authentication
- Local development requires git credential configuration (see Developer Edition [README](../README.md))

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
- Open API Specification (swagger) is a Design Specification, NOT a code build artifact
- Route blueprints use factory functions (e.g., `create_*_routes()`) that return Flask Blueprints
- Route registration should be grouped together in `server.py` for clarity

## Separation of Concerns
- `server.py` is the standard API entry point
- `command.py` is the standard CLI entry point
- `/routes/*domain*_routes.py` handle HTTP request/response logic
- `/services/*domain*_service.py` handles business logic/RBAC for domain

## Authentication
- **API responsibility:** Domain APIs **validate** Bearer JWTs only. They must **not** register HTTP routes that mint credentials, exchange user passwords for tokens, or otherwise act as an identity provider.
- **Validation:** Use `api_utils` `create_flask_token()` or `Token` on protected routes. Verification uses `JWT_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE`, and `JWT_ALGORITHM` from `Config` (applications fail fast if `JWT_SECRET` is left at an insecure default).
- **Claims:** Tokens are expected to include at least `iss`, `aud`, `sub`, and `exp`. Use a `roles` claim (list) where RBAC is required; route logic and `create_flask_breadcrumb()` consume the dict returned by `create_flask_token()` (`user_id` is derived from `sub`).
- **Developer Edition:** The umbrella **welcome** page (`index.html`) drives local sign-in with persona links that open SPAs carrying URL-hash parameters (`access_token`, `expires_at`, `roles`). The same **stable `JWT_SECRET`** in compose must sign those JWTs and be trusted by every API. SPAs load tokens into `localStorage` via `bootstrapAuthFromUrl()` from **`@agile-learning-institute/mentorhub_spa_utils`** (call once before the router mounts, e.g. `src/initAuth.ts`); clearing stored tokens uses the SPA-side query `?clear_stored_auth=1`, not an API endpoint. See [SPA standards](./spa_standards.md).
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
  ```