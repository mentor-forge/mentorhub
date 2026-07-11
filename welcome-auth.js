/** Dev-only local IdP: mint HS256 JWTs and redirect back to journey SPAs. */
const DEV_JWT_SECRET = 'local-dev-jwt-secret-fixed'
const JWT_ISSUER = 'dev-idp'
const JWT_AUDIENCE = 'dev-api'
const TOKEN_TTL_SECONDS = 10 * 365 * 24 * 60 * 60

/** Static profiles from mentorhub_mongodb_api/configurator/test_data/Profile.0.1.0.0.json */
const PROFILES = {
  mike: {
    label: 'Mike Storey',
    sub: 'mike',
    name: 'Mike Storey',
    profile_id: 'A00000000000000000000001',
    roles: ['admin', 'coordinator', 'customer', 'mentee', 'mentor'],
    customer_id: 'D00000000000000000000006',
    mentor_id: '',
  },
  daniel: {
    label: 'Daniel Dissler',
    sub: 'daniel',
    name: 'Daniel Dissler',
    profile_id: 'A00000000000000000000002',
    roles: ['mentee'],
    customer_id: 'D00000000000000000000002',
    mentor_id: 'A00000000000000000000006',
  },
  lucky: {
    label: 'Lucky Minyard',
    sub: 'lucky',
    name: 'Lucky Minyard',
    profile_id: 'A00000000000000000000003',
    roles: ['mentee'],
    customer_id: 'D00000000000000000000002',
    mentor_id: 'A00000000000000000000006',
  },
  mary: {
    label: 'Mary Anderson',
    sub: 'mary',
    name: 'Mary Anderson',
    profile_id: 'A00000000000000000000004',
    roles: ['mentee'],
    customer_id: 'D00000000000000000000002',
    mentor_id: 'A00000000000000000000006',
  },
  luther: {
    label: 'Luther Still',
    sub: 'luther',
    name: 'Luther Still',
    profile_id: 'A00000000000000000000005',
    roles: ['mentee', 'admin'],
    customer_id: 'D00000000000000000000002',
    mentor_id: 'A00000000000000000000006',
  },
  marti: {
    label: 'Marti Lombardi',
    sub: 'marti',
    name: 'Marti Lombardi',
    profile_id: 'A00000000000000000000006',
    roles: ['mentor'],
    customer_id: '',
    mentor_id: '',
  },
  carol: {
    label: 'Carol Coordinator',
    sub: 'carol',
    name: 'Carol Coordinator',
    profile_id: 'A00000000000000000000007',
    roles: ['coordinator'],
    customer_id: 'D00000000000000000000006',
    mentor_id: '',
  },
  cat: {
    label: 'Cat Customer',
    sub: 'cat',
    name: 'Cat Customer',
    profile_id: 'A00000000000000000000008',
    roles: ['customer'],
    customer_id: 'D00000000000000000000001',
    mentor_id: '',
  },
  sam: {
    label: 'Sam Admin',
    sub: 'sam',
    name: 'Sam Admin',
    profile_id: 'A00000000000000000000013',
    roles: ['admin', 'coordinator', 'customer', 'mentee', 'mentor'],
    customer_id: 'D00000000000000000000006',
    mentor_id: '',
  },
  taylor: {
    label: 'Taylor Dual',
    sub: 'taylor',
    name: 'Taylor Dual',
    profile_id: 'A00000000000000000000014',
    roles: ['mentor', 'mentee'],
    customer_id: 'D00000000000000000000001',
    mentor_id: 'A00000000000000000000006',
  },
}

function base64UrlEncodeBytes(bytes) {
  let binary = ''
  bytes.forEach((b) => {
    binary += String.fromCharCode(b)
  })
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function base64UrlEncodeJson(value) {
  return base64UrlEncodeBytes(new TextEncoder().encode(JSON.stringify(value)))
}

function isAllowedReturnTo(urlString) {
  try {
    const url = new URL(urlString)
    if (url.protocol !== 'http:') return false
    return url.hostname === '127.0.0.1' || url.hostname === 'localhost'
  } catch {
    return false
  }
}

async function signJwt(payload) {
  const header = { alg: 'HS256', typ: 'JWT' }
  const encodedHeader = base64UrlEncodeJson(header)
  const encodedPayload = base64UrlEncodeJson(payload)
  const signingInput = `${encodedHeader}.${encodedPayload}`

  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(DEV_JWT_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  )
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(signingInput)
  )
  return `${signingInput}.${base64UrlEncodeBytes(new Uint8Array(signature))}`
}

function populateUserSelect() {
  const userSelect = document.getElementById('welcome-login-user-id')
  if (!(userSelect instanceof HTMLSelectElement)) return

  userSelect.replaceChildren()
  Object.entries(PROFILES).forEach(([value, profile]) => {
    const option = document.createElement('option')
    option.value = value
    option.textContent = profile.label
    userSelect.appendChild(option)
  })
}

function setLoginEnabled(enabled) {
  const submit = document.getElementById('welcome-login-submit')
  if (submit instanceof HTMLButtonElement) {
    submit.disabled = !enabled
  }
}

function showReturnToError(message) {
  const el = document.getElementById('welcome-login-return-to-error')
  if (el) {
    el.textContent = message
    el.hidden = !message
  }
}

function initWelcomeLogin() {
  const params = new URLSearchParams(window.location.search)
  const returnTo = params.get('return_to') ?? ''
  const returnToInput = document.getElementById('welcome-login-return-to')
  if (returnToInput instanceof HTMLInputElement) {
    returnToInput.value = returnTo
  }

  const validReturnTo = returnTo && isAllowedReturnTo(returnTo)
  if (!validReturnTo) {
    showReturnToError(
      returnTo
        ? 'Invalid return_to URL. Only http://127.0.0.1:* and http://localhost:* are allowed.'
        : 'Missing return_to query parameter. Open a journey SPA from the developer portal.'
    )
    setLoginEnabled(false)
  } else {
    showReturnToError('')
    setLoginEnabled(true)
  }

  populateUserSelect()

  const form = document.getElementById('welcome-login-form')
  if (form instanceof HTMLFormElement) {
    form.addEventListener('submit', async (event) => {
      event.preventDefault()
      if (!validReturnTo) return

      const userSelectEl = document.getElementById('welcome-login-user-id')
      if (!(userSelectEl instanceof HTMLSelectElement)) return

      const profile = PROFILES[userSelectEl.value]
      if (!profile) return

      showReturnToError('')

      const now = Math.floor(Date.now() / 1000)
      const exp = now + TOKEN_TTL_SECONDS
      const expiresAt = new Date(exp * 1000).toISOString()

      const token = await signJwt({
        iss: JWT_ISSUER,
        aud: JWT_AUDIENCE,
        sub: profile.sub,
        name: profile.name,
        iat: now,
        exp,
        roles: profile.roles,
        profile_id: profile.profile_id,
        customer_id: profile.customer_id,
        mentor_id: profile.mentor_id,
      })

      const hashParams = new URLSearchParams()
      hashParams.set('access_token', token)
      hashParams.set('expires_at', expiresAt)
      hashParams.set('roles', profile.roles.join(','))

      window.location.href = `${returnTo}#${hashParams.toString()}`
    })
  }
}

function bootWelcomeLogin() {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initWelcomeLogin)
  } else {
    initWelcomeLogin()
  }
}

bootWelcomeLogin()
