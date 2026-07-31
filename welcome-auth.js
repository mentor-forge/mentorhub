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

/** SHA-256 for dev JWT signing when Web Crypto is unavailable (non-secure http://*.ts.net). */
function sha256Pure(messageBytes) {
  const K = new Uint32Array([
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ])
  const H = new Uint32Array([
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ])

  const bitLen = messageBytes.length * 8
  const withOne = messageBytes.length + 1
  const padLen = (withOne % 64 <= 56 ? 56 : 120) - (withOne % 64)
  const totalLen = withOne + padLen + 8
  const padded = new Uint8Array(totalLen)
  padded.set(messageBytes)
  padded[messageBytes.length] = 0x80
  const view = new DataView(padded.buffer)
  view.setUint32(totalLen - 4, bitLen, false)

  const w = new Uint32Array(64)
  for (let offset = 0; offset < totalLen; offset += 64) {
    for (let i = 0; i < 16; i += 1) {
      w[i] = view.getUint32(offset + i * 4, false)
    }
    for (let i = 16; i < 64; i += 1) {
      const s0 = (rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3)) >>> 0
      const s1 = (rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10)) >>> 0
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) >>> 0
    }

    let a = H[0]
    let b = H[1]
    let c = H[2]
    let d = H[3]
    let e = H[4]
    let f = H[5]
    let g = H[6]
    let h = H[7]

    for (let i = 0; i < 64; i += 1) {
      const S1 = (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) >>> 0
      const ch = ((e & f) ^ (~e & g)) >>> 0
      const temp1 = (h + S1 + ch + K[i] + w[i]) >>> 0
      const S0 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) >>> 0
      const maj = ((a & b) ^ (a & c) ^ (b & c)) >>> 0
      const temp2 = (S0 + maj) >>> 0
      h = g
      g = f
      f = e
      e = (d + temp1) >>> 0
      d = c
      c = b
      b = a
      a = (temp1 + temp2) >>> 0
    }

    H[0] = (H[0] + a) >>> 0
    H[1] = (H[1] + b) >>> 0
    H[2] = (H[2] + c) >>> 0
    H[3] = (H[3] + d) >>> 0
    H[4] = (H[4] + e) >>> 0
    H[5] = (H[5] + f) >>> 0
    H[6] = (H[6] + g) >>> 0
    H[7] = (H[7] + h) >>> 0
  }

  const out = new Uint8Array(32)
  const outView = new DataView(out.buffer)
  for (let i = 0; i < 8; i += 1) {
    outView.setUint32(i * 4, H[i], false)
  }
  return out

  function rotr(value, shift) {
    return (value >>> shift) | (value << (32 - shift))
  }
}

function hmacSha256Pure(keyBytes, messageBytes) {
  const blockSize = 64
  let key = keyBytes
  if (key.length > blockSize) {
    key = sha256Pure(key)
  }
  if (key.length < blockSize) {
    const paddedKey = new Uint8Array(blockSize)
    paddedKey.set(key)
    key = paddedKey
  }

  const outerPad = new Uint8Array(blockSize)
  const innerPad = new Uint8Array(blockSize)
  for (let i = 0; i < blockSize; i += 1) {
    outerPad[i] = key[i] ^ 0x5c
    innerPad[i] = key[i] ^ 0x36
  }

  const inner = new Uint8Array(innerPad.length + messageBytes.length)
  inner.set(innerPad)
  inner.set(messageBytes, innerPad.length)
  const innerHash = sha256Pure(inner)

  const outer = new Uint8Array(outerPad.length + innerHash.length)
  outer.set(outerPad)
  outer.set(innerHash, outerPad.length)
  return sha256Pure(outer)
}

async function hmacSha256(keyBytes, messageBytes) {
  if (globalThis.crypto?.subtle) {
    const key = await crypto.subtle.importKey(
      'raw',
      keyBytes,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )
    return new Uint8Array(await crypto.subtle.sign('HMAC', key, messageBytes))
  }
  return hmacSha256Pure(keyBytes, messageBytes)
}

async function signJwt(payload) {
  const header = { alg: 'HS256', typ: 'JWT' }
  const encodedHeader = base64UrlEncodeJson(header)
  const encodedPayload = base64UrlEncodeJson(payload)
  const signingInput = `${encodedHeader}.${encodedPayload}`

  const signature = await hmacSha256(
    new TextEncoder().encode(DEV_JWT_SECRET),
    new TextEncoder().encode(signingInput)
  )
  return `${signingInput}.${base64UrlEncodeBytes(signature)}`
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
        ? 'Invalid return_to URL. Only http://127.0.0.1:*, http://localhost:*, and http://*.ts.net:* are allowed.'
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

      try {
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
      } catch (err) {
        const detail = err instanceof Error ? err.message : String(err)
        showReturnToError(`Sign-in failed: ${detail}`)
      }
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
