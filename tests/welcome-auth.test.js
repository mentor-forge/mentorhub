const test = require('node:test')
const assert = require('node:assert')
const fs = require('node:fs')
const path = require('node:path')

const welcomeAuth = require('../welcome-auth.js')
const {
  isAllowedReturnTo,
  PROFILES,
  DEV_JWT_SECRET,
  JWT_ISSUER,
  JWT_AUDIENCE,
  TOKEN_TTL_SECONDS,
  signJwt,
  initWelcomeLogin,
} = welcomeAuth

test('Portal links in index.html inherit current origin', () => {
  const indexPath = path.join(__dirname, '..', 'index.html')
  const indexHtml = fs.readFileSync(indexPath, 'utf-8')

  // Verify journey links use same-origin relative paths
  assert.match(
    indexHtml,
    /document\.getElementById\('discovery-app-link'\)\.href\s*=\s*['"]\/discovery\/['"]/,
    'Discovery link must be /discovery/'
  )
  assert.match(
    indexHtml,
    /document\.getElementById\('customer-app-link'\)\.href\s*=\s*['"]\/customer\/['"]/,
    'Customer link must be /customer/'
  )
  assert.match(
    indexHtml,
    /document\.getElementById\('admin-app-link'\)\.href\s*=\s*['"]\/admin\/['"]/,
    'Admin link must be /admin/'
  )
  assert.match(
    indexHtml,
    /document\.getElementById\('mentor-app-link'\)\.href\s*=\s*['"]\/mentor\/['"]/,
    'Mentor link must be /mentor/'
  )
  assert.match(
    indexHtml,
    /document\.getElementById\('mentee-app-link'\)\.href\s*=\s*['"]\/mentee\/['"]/,
    'Mentee link must be /mentee/'
  )

  // Verify journey links do not hardcode http:// or :8080
  const journeyLinkIds = [
    'discovery-app-link',
    'customer-app-link',
    'admin-app-link',
    'mentor-app-link',
    'mentee-app-link',
  ]

  for (const id of journeyLinkIds) {
    const regexHttp = new RegExp(`document\\.getElementById\\(['"]${id}['"]\\)\\.href\\s*=\\s*\`http:`, 'g')
    const regex8080 = new RegExp(`document\\.getElementById\\(['"]${id}['"]\\)\\.href\\s*=\\s*\`[^:]*:8080`, 'g')
    assert.doesNotMatch(indexHtml, regexHttp, `${id} must not hardcode http://`)
    assert.doesNotMatch(indexHtml, regex8080, `${id} must not hardcode port 8080`)
  }
})

test('Return URL validation allows permitted destinations and rejects others', () => {
  const acceptedUrls = [
    'http://localhost:8080/discovery/',
    'http://localhost:8398/discovery/',
    'http://127.0.0.1:8080/discovery/',
    'http://node.example-tailnet.ts.net:8080/discovery/',
    'https://node.example-tailnet.ts.net/discovery/',
    'https://spark-478a.tailb0d293.ts.net/discovery/',
  ]

  for (const url of acceptedUrls) {
    assert.strictEqual(
      isAllowedReturnTo(url),
      true,
      `Expected ${url} to be accepted by isAllowedReturnTo`
    )
  }

  const rejectedUrls = [
    'http://example.com/discovery/',
    'https://example.com/discovery/',
    'javascript:alert(1)',
    'data:text/html,test',
    'file:///tmp/test',
    'not-a-url',
    '',
    'ftp://localhost:8080/discovery/',
    'https://localhost:8080/discovery/', // only http is permitted for localhost loopback
  ]

  for (const url of rejectedUrls) {
    assert.strictEqual(
      isAllowedReturnTo(url),
      false,
      `Expected ${url} to be rejected by isAllowedReturnTo`
    )
  }

  // When loaded on a specific host in browser, same-host return URLs are permitted
  const prevWindow = global.window
  try {
    global.window = {
      location: {
        hostname: 'spark-478a.tailb0d293.ts.net',
        protocol: 'https:',
      },
    }
    assert.strictEqual(isAllowedReturnTo('https://spark-478a.tailb0d293.ts.net/discovery/'), true)
    assert.strictEqual(isAllowedReturnTo('https://spark-478a.tailb0d293.ts.net/customer/'), true)
    assert.strictEqual(isAllowedReturnTo('https://evil.com/discovery/'), false)
  } finally {
    global.window = prevWindow
  }
})

test('Default return URL is derived from origin', () => {
  // HTTP localhost login page defaults to HTTP localhost discovery
  const localhostOrigin = 'http://localhost:8080'
  const localhostDefault = new URL('/discovery/', localhostOrigin).href
  assert.strictEqual(localhostDefault, 'http://localhost:8080/discovery/')
  assert.strictEqual(isAllowedReturnTo(localhostDefault), true)

  // Public HTTPS login page defaults to HTTPS discovery
  const funnelOrigin = 'https://spark-478a.tailb0d293.ts.net'
  const funnelDefault = new URL('/discovery/', funnelOrigin).href
  assert.strictEqual(funnelDefault, 'https://spark-478a.tailb0d293.ts.net/discovery/')
  assert.strictEqual(isAllowedReturnTo(funnelDefault), true)
})

test('initWelcomeLogin behavior with default, explicit valid, and explicit invalid return_to', () => {
  // Helper to simulate a minimal DOM environment
  function createMockDom({ origin, search }) {
    const elements = {
      'welcome-login-return-to': { value: '', nodeType: 1, tagName: 'INPUT' },
      'welcome-login-return-to-error': { textContent: '', hidden: true, nodeType: 1 },
      'welcome-login-submit': { disabled: false, nodeType: 1, tagName: 'BUTTON' },
      'welcome-login-user-id': {
        children: [],
        replaceChildren() { this.children = [] },
        appendChild(child) { this.children.push(child) },
        nodeType: 1,
        tagName: 'SELECT',
      },
      'welcome-login-form': {
        listeners: {},
        addEventListener(event, fn) { this.listeners[event] = fn },
        nodeType: 1,
        tagName: 'FORM',
      },
    }

    // Set prototypes so `instanceof HTMLInputElement` checks behave correctly
    class MockHTMLInputElement {}
    class MockHTMLButtonElement {}
    class MockHTMLSelectElement {}
    class MockHTMLFormElement {}

    Object.setPrototypeOf(elements['welcome-login-return-to'], MockHTMLInputElement.prototype)
    Object.setPrototypeOf(elements['welcome-login-submit'], MockHTMLButtonElement.prototype)
    Object.setPrototypeOf(elements['welcome-login-user-id'], MockHTMLSelectElement.prototype)
    Object.setPrototypeOf(elements['welcome-login-form'], MockHTMLFormElement.prototype)

    const globalWindow = {
      location: {
        origin,
        search,
        href: `${origin}/login.html${search}`,
      },
    }

    const globalDocument = {
      getElementById(id) {
        return elements[id] || null
      },
      createElement(tag) {
        return { tagName: tag.toUpperCase() }
      },
      readyState: 'complete',
      addEventListener() {},
    }

    return {
      elements,
      globalWindow,
      globalDocument,
      classes: {
        HTMLInputElement: MockHTMLInputElement,
        HTMLButtonElement: MockHTMLButtonElement,
        HTMLSelectElement: MockHTMLSelectElement,
        HTMLFormElement: MockHTMLFormElement,
      },
    }
  }

  // Scenario A: Localhost without return_to -> defaults to http://localhost:8080/discovery/ and enabled
  {
    const mock = createMockDom({ origin: 'http://localhost:8080', search: '' })
    const prevWindow = global.window
    const prevDoc = global.document
    const prevInput = global.HTMLInputElement
    const prevButton = global.HTMLButtonElement
    const prevSelect = global.HTMLSelectElement
    const prevForm = global.HTMLFormElement

    try {
      global.window = mock.globalWindow
      global.document = mock.globalDocument
      global.HTMLInputElement = mock.classes.HTMLInputElement
      global.HTMLButtonElement = mock.classes.HTMLButtonElement
      global.HTMLSelectElement = mock.classes.HTMLSelectElement
      global.HTMLFormElement = mock.classes.HTMLFormElement

      initWelcomeLogin()

      assert.strictEqual(
        mock.elements['welcome-login-return-to'].value,
        'http://localhost:8080/discovery/'
      )
      assert.strictEqual(mock.elements['welcome-login-submit'].disabled, false)
      assert.strictEqual(mock.elements['welcome-login-return-to-error'].hidden, true)
    } finally {
      global.window = prevWindow
      global.document = prevDoc
      global.HTMLInputElement = prevInput
      global.HTMLButtonElement = prevButton
      global.HTMLSelectElement = prevSelect
      global.HTMLFormElement = prevForm
    }
  }

  // Scenario B: Public HTTPS Funnel without return_to -> defaults to https://spark-478a.tailb0d293.ts.net/discovery/ and enabled
  {
    const mock = createMockDom({ origin: 'https://spark-478a.tailb0d293.ts.net', search: '' })
    const prevWindow = global.window
    const prevDoc = global.document
    const prevInput = global.HTMLInputElement
    const prevButton = global.HTMLButtonElement
    const prevSelect = global.HTMLSelectElement
    const prevForm = global.HTMLFormElement

    try {
      global.window = mock.globalWindow
      global.document = mock.globalDocument
      global.HTMLInputElement = mock.classes.HTMLInputElement
      global.HTMLButtonElement = mock.classes.HTMLButtonElement
      global.HTMLSelectElement = mock.classes.HTMLSelectElement
      global.HTMLFormElement = mock.classes.HTMLFormElement

      initWelcomeLogin()

      assert.strictEqual(
        mock.elements['welcome-login-return-to'].value,
        'https://spark-478a.tailb0d293.ts.net/discovery/'
      )
      assert.strictEqual(mock.elements['welcome-login-submit'].disabled, false)
      assert.strictEqual(mock.elements['welcome-login-return-to-error'].hidden, true)
    } finally {
      global.window = prevWindow
      global.document = prevDoc
      global.HTMLInputElement = prevInput
      global.HTMLButtonElement = prevButton
      global.HTMLSelectElement = prevSelect
      global.HTMLFormElement = prevForm
    }
  }

  // Scenario C: Valid explicit return_to overrides default
  {
    const explicitUrl = 'https://spark-478a.tailb0d293.ts.net/mentor/'
    const mock = createMockDom({
      origin: 'https://spark-478a.tailb0d293.ts.net',
      search: `?return_to=${encodeURIComponent(explicitUrl)}`,
    })
    const prevWindow = global.window
    const prevDoc = global.document
    const prevInput = global.HTMLInputElement
    const prevButton = global.HTMLButtonElement
    const prevSelect = global.HTMLSelectElement
    const prevForm = global.HTMLFormElement

    try {
      global.window = mock.globalWindow
      global.document = mock.globalDocument
      global.HTMLInputElement = mock.classes.HTMLInputElement
      global.HTMLButtonElement = mock.classes.HTMLButtonElement
      global.HTMLSelectElement = mock.classes.HTMLSelectElement
      global.HTMLFormElement = mock.classes.HTMLFormElement

      initWelcomeLogin()

      assert.strictEqual(mock.elements['welcome-login-return-to'].value, explicitUrl)
      assert.strictEqual(mock.elements['welcome-login-submit'].disabled, false)
      assert.strictEqual(mock.elements['welcome-login-return-to-error'].hidden, true)
    } finally {
      global.window = prevWindow
      global.document = prevDoc
      global.HTMLInputElement = prevInput
      global.HTMLButtonElement = prevButton
      global.HTMLSelectElement = prevSelect
      global.HTMLFormElement = prevForm
    }
  }

  // Scenario D: Invalid explicit return_to disables submit and displays error
  {
    const invalidUrl = 'http://example.com/malicious'
    const mock = createMockDom({
      origin: 'https://spark-478a.tailb0d293.ts.net',
      search: `?return_to=${encodeURIComponent(invalidUrl)}`,
    })
    const prevWindow = global.window
    const prevDoc = global.document
    const prevInput = global.HTMLInputElement
    const prevButton = global.HTMLButtonElement
    const prevSelect = global.HTMLSelectElement
    const prevForm = global.HTMLFormElement

    try {
      global.window = mock.globalWindow
      global.document = mock.globalDocument
      global.HTMLInputElement = mock.classes.HTMLInputElement
      global.HTMLButtonElement = mock.classes.HTMLButtonElement
      global.HTMLSelectElement = mock.classes.HTMLSelectElement
      global.HTMLFormElement = mock.classes.HTMLFormElement

      initWelcomeLogin()

      assert.strictEqual(mock.elements['welcome-login-return-to'].value, invalidUrl)
      assert.strictEqual(mock.elements['welcome-login-submit'].disabled, true)
      assert.strictEqual(mock.elements['welcome-login-return-to-error'].hidden, false)
      assert.match(
        mock.elements['welcome-login-return-to-error'].textContent,
        /Invalid return_to URL/
      )
    } finally {
      global.window = prevWindow
      global.document = prevDoc
      global.HTMLInputElement = prevInput
      global.HTMLButtonElement = prevButton
      global.HTMLSelectElement = prevSelect
      global.HTMLFormElement = prevForm
    }
  }
})

test('Existing authentication behavior is preserved', async () => {
  // 1. Constants
  assert.strictEqual(DEV_JWT_SECRET, 'local-dev-jwt-secret-fixed')
  assert.strictEqual(JWT_ISSUER, 'dev-idp')
  assert.strictEqual(JWT_AUDIENCE, 'dev-api')
  assert.strictEqual(TOKEN_TTL_SECONDS, 10 * 365 * 24 * 60 * 60)

  // 2. Personas
  assert.ok(PROFILES.mike, 'Mike admin persona must exist')
  assert.strictEqual(PROFILES.mike.display_name, 'Mike Storey')
  assert.deepStrictEqual(PROFILES.mike.roles, ['admin'])
  assert.ok(PROFILES.daniel, 'Daniel mentee persona must exist')
  assert.ok(PROFILES.mary, 'Mary persona must exist')

  // 3. JWT Signing and Claims
  const now = Math.floor(Date.now() / 1000)
  const exp = now + TOKEN_TTL_SECONDS
  const token = await signJwt({
    iss: JWT_ISSUER,
    aud: JWT_AUDIENCE,
    sub: PROFILES.mike.sub,
    display_name: PROFILES.mike.display_name,
    iat: now,
    exp,
    roles: PROFILES.mike.roles,
    profile_id: PROFILES.mike.profile_id,
    customer_id: PROFILES.mike.customer_id,
    mentor_id: PROFILES.mike.mentor_id,
  })

  // Verify structure header.payload.signature
  const parts = token.split('.')
  assert.strictEqual(parts.length, 3, 'JWT must have 3 parts')

  const header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf-8'))
  assert.strictEqual(header.alg, 'HS256')
  assert.strictEqual(header.typ, 'JWT')

  const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf-8'))
  assert.strictEqual(payload.iss, 'dev-idp')
  assert.strictEqual(payload.aud, 'dev-api')
  assert.strictEqual(payload.sub, 'mike')
  assert.strictEqual(payload.display_name, 'Mike Storey')
  assert.strictEqual(payload.profile_id, 'A00000000000000000000001')
  assert.deepStrictEqual(payload.roles, ['admin'])
  assert.strictEqual(payload.exp, exp)
  assert.strictEqual(payload.iat, now)

  // 4. Redirect-fragment format
  const hashParams = new URLSearchParams()
  hashParams.set('access_token', token)
  hashParams.set('expires_at', new Date(exp * 1000).toISOString())
  hashParams.set('roles', PROFILES.mike.roles.join(','))

  const fragment = hashParams.toString()
  assert.ok(fragment.includes('access_token='), 'Fragment must contain access_token parameter')
  assert.ok(fragment.includes('expires_at='), 'Fragment must contain expires_at parameter')
  assert.ok(fragment.includes('roles=admin'), 'Fragment must contain roles parameter')
})
