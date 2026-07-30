/** Dev-only local IdP: mint HS256 JWTs and redirect back to journey SPAs. */
const DEV_JWT_SECRET = 'local-dev-jwt-secret-fixed'
const JWT_ISSUER = 'dev-idp'
const JWT_AUDIENCE = 'dev-api'
const TOKEN_TTL_SECONDS = 10 * 365 * 24 * 60 * 60

/** Static profiles from mentorhub_mongodb_api/configurator/test_data/Profile.0.1.0.0.json */
const PROFILES = {
  mike: {
    label: 'Mike the Admin (admin)',
    sub: 'mike',
    name: 'Mike Storey',
    profile_id: 'A00000000000000000000001',
    roles: ['admin'],
    customer_id: '',
    mentor_id: '',
  },
  daniel: {
    label: 'Daniel the Mentee (mentee)',
    sub: 'daniel',
    name: 'Daniel Dissler',
    profile_id: 'A00000000000000000000002',
    roles: ['mentee'],
    customer_id: 'D00000000000000000000002',
    mentor_id: 'A00000000000000000000010',
  },
  lucky: {
    label: 'Lucky the Mentee (mentee)',
    sub: 'lucky',
    name: 'Lucky Minyard',
    profile_id: 'A00000000000000000000003',
    roles: ['mentee'],
    customer_id: 'D00000000000000000000007',
    mentor_id: 'A00000000000000000000014',
  },
  mary: {
    label: 'Mary the Super Mentee (customer, coordinator, mentee)',
    sub: 'mary',
    name: 'Mary Anderson',
    profile_id: 'A00000000000000000000004',
    roles: ['customer', 'coordinator', 'mentee'],
    customer_id: 'D00000000000000000000001',
    mentor_id: 'A00000000000000000000006',
  },
  linda: {
    label: 'Linda the Archived Mentee (mentee)',
    sub: 'linda',
    name: 'Linda Left',
    profile_id: 'A00000000000000000000005',
    roles: ['mentee'],
    customer_id: 'D00000000000000000000006',
    mentor_id: 'A00000000000000000000006',
  },
  marti: {
    label: 'Marti the Mentor (mentor)',
    sub: 'marti',
    name: 'Marti Lombardi',
    profile_id: 'A00000000000000000000006',
    roles: ['mentor'],
    customer_id: '',
    mentor_id: '',
  },
  emma: {
    label: 'Emma the Coordinator (coordinator)',
    sub: 'emma',
    name: 'Emma Coordinator',
    profile_id: 'A00000000000000000000007',
    roles: ['coordinator'],
    customer_id: 'D00000000000000000000002',
    mentor_id: '',
  },
  stacey: {
    label: 'Stacey the CEO (customer)',
    sub: 'stacey',
    name: 'Stacey CEO',
    profile_id: 'A00000000000000000000008',
    roles: ['customer'],
    customer_id: 'D00000000000000000000002',
    mentor_id: '',
  },
  margaret: {
    label: 'Margaret the Coordinator (coordinator)',
    sub: 'margaret',
    name: 'Margaret Coordinator',
    profile_id: 'A00000000000000000000009',
    roles: ['coordinator'],
    customer_id: 'D00000000000000000000002',
    mentor_id: '',
  },
  paula: {
    label: 'Paula the Persevere Mentor (mentor)',
    sub: 'paula',
    name: 'Paula Persevere',
    profile_id: 'A00000000000000000000010',
    roles: ['mentor'],
    customer_id: '',
    mentor_id: '',
  },
  elon: {
    label: 'Elon the Money Mentor (mentor)',
    sub: 'elon',
    name: 'Elon Money',
    profile_id: 'A00000000000000000000011',
    roles: ['mentor'],
    customer_id: '',
    mentor_id: '',
  },
  eddy: {
    label: 'Eddy the Entrepreneur (customer)',
    sub: 'eddy',
    name: 'Eddy Entrepreneur',
    profile_id: 'A00000000000000000000012',
    roles: ['customer'],
    customer_id: 'D00000000000000000000007',
    mentor_id: '',
  },
  donny: {
    label: 'Donny the Deadbeat (customer)',
    sub: 'donny',
    name: 'Donny Deadbeat',
    profile_id: 'A00000000000000000000013',
    roles: ['customer'],
    customer_id: 'D00000000000000000000008',
    mentor_id: '',
  },
  danny: {
    label: 'Danny the Dev Lead (coordinator, mentor)',
    sub: 'danny',
    name: 'Danny Dev Lead',
    profile_id: 'A00000000000000000000014',
    roles: ['coordinator', 'mentor'],
    customer_id: 'D00000000000000000000007',
    mentor_id: '',
  },
  melinda: {
    label: 'Melinda the Multi Customer Mentor (mentor)',
    sub: 'melinda',
    name: 'Melinda Multi',
    profile_id: 'A00000000000000000000015',
    roles: ['mentor'],
    customer_id: '',
    mentor_id: '',
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
    // Local development, plus Tailscale MagicDNS hosts (*.ts.net) so journey
    // SPAs opened over the team VPN can redirect back after dev sign-in.
    return (
      url.hostname === '127.0.0.1' ||
      url.hostname === 'localhost' ||
      url.hostname.endsWith('.ts.net')
    )
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
  if (userSelect.options.length > 0) return

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
