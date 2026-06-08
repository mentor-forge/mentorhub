/** Dev-only local IdP: mint HS256 JWTs and redirect back to journey SPAs. */
const DEV_JWT_SECRET = 'local-dev-jwt-secret-fixed'
const JWT_ISSUER = 'dev-idp'
const JWT_AUDIENCE = 'dev-api'
const TOKEN_TTL_SECONDS = 10 * 365 * 24 * 60 * 60

const PERSONAS = {
  carol: { label: 'Carol', sub: 'carol', roles: ['coordinator'] },
  maria: { label: 'Maria', sub: 'maria', roles: ['mentor'] },
  cat: { label: 'Cat', sub: 'cat', roles: ['customer'] },
  mark: { label: 'Mark', sub: 'mark', roles: ['mentee'] },
  stan: { label: 'Stan', sub: 'stan', roles: ['admin'] },
}

const ROLE_IDS = ['coordinator', 'mentor', 'customer', 'mentee', 'admin']

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

function getSelectedRoles() {
  return ROLE_IDS.filter((role) => {
    const checkbox = document.getElementById(`welcome-login-role-${role}`)
    return checkbox instanceof HTMLInputElement && checkbox.checked
  })
}

function applyPersonaDefaults(sub) {
  const persona = PERSONAS[sub]
  if (!persona) return
  ROLE_IDS.forEach((role) => {
    const checkbox = document.getElementById(`welcome-login-role-${role}`)
    if (checkbox instanceof HTMLInputElement) {
      checkbox.checked = persona.roles.includes(role)
    }
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

  const userSelect = document.getElementById('welcome-login-user-id')
  if (userSelect instanceof HTMLSelectElement) {
    userSelect.addEventListener('change', () => {
      applyPersonaDefaults(userSelect.value)
    })
    applyPersonaDefaults(userSelect.value)
  }

  const form = document.getElementById('welcome-login-form')
  if (form instanceof HTMLFormElement) {
    form.addEventListener('submit', async (event) => {
      event.preventDefault()
      if (!validReturnTo) return

      const userSelectEl = document.getElementById('welcome-login-user-id')
      if (!(userSelectEl instanceof HTMLSelectElement)) return

      const persona = PERSONAS[userSelectEl.value]
      if (!persona) return

      const roles = getSelectedRoles()
      if (roles.length === 0) {
        showReturnToError('Select at least one role before signing in.')
        return
      }
      showReturnToError('')

      const now = Math.floor(Date.now() / 1000)
      const exp = now + TOKEN_TTL_SECONDS
      const expiresAt = new Date(exp * 1000).toISOString()

      const token = await signJwt({
        iss: JWT_ISSUER,
        aud: JWT_AUDIENCE,
        sub: persona.sub,
        iat: now,
        exp,
        roles,
      })

      const hashParams = new URLSearchParams()
      hashParams.set('access_token', token)
      hashParams.set('expires_at', expiresAt)
      hashParams.set('roles', roles.join(','))

      window.location.href = `${returnTo}#${hashParams.toString()}`
    })
  }
}

document.addEventListener('DOMContentLoaded', initWelcomeLogin)
