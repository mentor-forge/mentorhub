# SPA Standards

## Technology Stack
 - VueJs v3 
 - Vite v7.2
 - TypeScript v5.9
 - Vuetify v3.11
 - Vue Router v4
 - Pinia v3
 - TanStack Query (Vue Query) v5
 - Cypress E2E v15.8

## Standard Developer Commands
- npm run build (package code for deployment)
- npm run dev (run dev server)
- npm run test (run unit tests)
- npm run test:coverage (run unit tests with coverage report)
- npm run test:ui (run unit tests with Vitest UI)
- npm run cypress (open Cypress E2E test runner)
- npm run cypress:run (run Cypress E2E tests headlessly)
- npm run api (start db + api containers)
- npm run service (start db + api + spa containers)
- npm run container (build SPA container)

## Configurability
- /api/config will return runtime configuration values
- Use runtime configuration values for enumerator values not OpenAPI Spec
- Container uses NGINX template substitution for API proxy configuration

## Testing Standards
- **Unit Testing**: Vitest v3 for unit testing with 90% coverage target
- **E2E Testing**: Cypress v15.8 for end-to-end testing
- **Coverage Requirements**:
  - API client: 90% lines, 90% functions, 75% branches
  - Composables: 90% lines, 90% functions, 60% branches
  - Components: 90% lines, 90% functions, 85% branches
  - Pages tested via E2E tests
- **Test Organization**:
  - Unit tests: `src/**/*.test.ts` (co-located with source)
  - E2E tests: `cypress/e2e/**/*.cy.ts`
  - Test support: `cypress/support/`
- **Testing Patterns**:
  - Mock external dependencies (API calls, localStorage)
  - Use shallow mounting for component tests to avoid Vuetify CSS issues
  - E2E tests cover all main user workflows
  - Custom Cypress commands for common operations (e.g., login)

## Authentication Pattern
- JWT tokens stored in localStorage (`access_token`, `token_expires_at`, `user_roles` when present)
- `useAuth()` composable manages authentication state
- **URL bootstrap:** Call **`bootstrapAuthFromUrl()`** from `spa_utils` once before the router mounts. Hash `#access_token=...&expires_at=...&roles=...` seeds localStorage (Developer Edition welcome page / IdP-style callback). Query `?clear_stored_auth=1` clears stored tokens when needed.
- Router guards protect authenticated routes; unauthenticated users redirect using **`VITE_IDP_LOGIN_URI`** / runtime login base URL (welcome page in Developer Edition, real IdP in production)
- Config is loaded when the app runs; it does not depend on a backend-issued “login” exchange in the SPA product flow

## Component Patterns
- **AutoSave Components**: Field-level save-on-blur for edit pages
  - `AutoSaveField`: Text input with auto-save (supports textarea mode)
  - `AutoSaveSelect`: Select dropdown with auto-save
  - Show saving/saved/error states
  - Accept `onSave` callback returning Promise

## Data Management
- **TanStack Query** (Vue Query) for server state
- Query keys: `['resource', id]` or `['resources', filters]`
- Mutations invalidate related queries on success
- No state duplication between server and client

## Automation IDs

### Philosophy

Automation IDs (`data-automation-id` attributes) are **sacred geometry** - stable API contracts that enable programmatic interaction with the UI. Once established, these IDs should:

- **Survive refactoring**: Changes to component structure, styling, or text content should NOT change automation IDs
- **Be carefully chosen**: Select meaningful, descriptive IDs that reflect the element's purpose, not its implementation
- **Remain stable**: Only change automation IDs when there are breaking changes to the element's purpose or function
- **Be documented**: Treat ID changes like API versioning - document breaking changes

### Purpose

Automation IDs support multiple use cases:
- **Testing frameworks**: Cypress, Playwright, Selenium, etc.
- **Browser automation**: Puppeteer, Chromium DevTools Protocol
- **RPA tools**: UiPath, Automation Anywhere, Blue Prism
- **Workflow automation**: Zapier, Make, n8n
- **AI agents**: Browser-based AI assistants and autonomous agents
- **Accessibility tools**: Screen readers and assistive technologies

### Naming Convention

Follow the pattern: `{domain}-{page}-{element}`

**Components**:
- `{domain}`: The business domain (control, create, consume, etc.)
- `{page}`: The page type (list, new, edit, view, admin)
- `{element}`: The element's purpose (search, name-input, submit-button, etc.)

**Examples**:
```html
<!-- List page -->
<input data-automation-id="control-list-search" />
<button data-automation-id="control-list-new-button" />

<!-- New/Create page -->
<input data-automation-id="control-new-name-input" />
<textarea data-automation-id="control-new-description-input" />
<select data-automation-id="control-new-status-select" />
<button data-automation-id="control-new-submit-button" />
<button data-automation-id="control-new-cancel-button" />

<!-- Edit page -->
<input data-automation-id="control-edit-name-input" />
<button data-automation-id="control-edit-save-button" />

<!-- Navigation -->
<button data-automation-id="nav-drawer-toggle" />
<a data-automation-id="nav-controls-list-link" />
```

### Implementation Guidelines

1. **Add to all interactive elements**:
   - Form inputs (text, textarea, select, checkbox, radio)
   - Buttons (submit, cancel, action buttons)
   - Links that trigger navigation or actions
   - Data tables and their controls

2. **Add to key display elements**:
   - Page headings (for verification)
   - Data display fields on view pages
   - Error/success messages
   - Loading states

3. **Use descriptive suffixes**:
   - `-input` for text/textarea inputs
   - `-select` for dropdown/select elements
   - `-button` for clickable buttons
   - `-link` for navigation links
   - `-checkbox` / `-radio` for boolean inputs
   - `-display` for read-only data display
   - `-table` for data tables

4. **Keep IDs semantic, not structural**:
   - ✅ Good: `control-new-name-input` (describes purpose)
   - ❌ Bad: `form-field-1` (describes structure)
   - ✅ Good: `control-list-search` (describes what it does)
   - ❌ Bad: `input-at-top-left` (describes location)

5. **One ID per interactive element**:
   - Don't reuse automation IDs across different elements
   - If an element has multiple purposes, choose the primary purpose for the ID

### Testing with Automation IDs

In Cypress tests:
```javascript
// Instead of fragile selectors like:
cy.contains('label', 'Name').parent().parent().find('input').type('value')

// Use automation IDs:
cy.get('[data-automation-id="control-new-name-input"]').type('value')
```

### Breaking Changes

Treat automation ID changes as **breaking changes to the UI API**:

1. **Document the change**: Note in commit messages and release notes
2. **Update all tests**: Ensure E2E tests reflect the new IDs
3. **Consider migration**: If external automation depends on the old ID, provide a migration window
4. **Only when necessary**: Change IDs only when the element's purpose fundamentally changes

### Version Control

- Automation IDs are part of your codebase and should be reviewed in PRs
- Reviewers should flag unexpected changes to existing automation IDs
- New features should include automation IDs from the start, not added later

## Security
- Run `npm audit` regularly to identify security vulnerabilities
- Use `npm audit --audit-level=high` to focus on high/critical issues
- For vulnerabilities in transitive dependencies, use `overrides` in package.json to force secure versions
- Example: `"overrides": { "qs": "^6.14.1" }` to fix vulnerabilities in Cypress dependencies
- Verify fixes with `npm audit` and `npm ls <package>` to confirm version resolution