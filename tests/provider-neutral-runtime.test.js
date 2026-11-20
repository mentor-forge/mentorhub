const assert = require('node:assert/strict')
const { execFileSync } = require('node:child_process')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')

const root = path.join(__dirname, '..')
const journeys = ['admin', 'customer', 'discovery', 'mentor', 'mentee']

function profileServices(profile, env = process.env) {
  const config = execFileSync(
    'docker',
    ['compose', '--env-file', '/dev/null', '-f', 'DeveloperEdition/docker-compose.yaml', '--profile', profile, 'config', '--format', 'json'],
    { cwd: root, encoding: 'utf8', env, stdio: ['ignore', 'pipe', 'inherit'] }
  )
  return JSON.parse(config).services
}

test('core profiles do not start the Cognito fixture or inject provider settings', () => {
  const loginUri = 'http://localhost:8080/login.html'
  const env = { ...process.env, IDP_LOGIN_URI: loginUri }
  for (const profile of ['all', 'admin', 'admin-api', 'customer', 'customer-api']) {
    const services = profileServices(profile, env)
    assert.ok(services.welcome, profile)
    assert.equal(services.mock_cognito, undefined, profile)

    for (const [name, service] of Object.entries(services)) {
      const settings = service.environment ?? {}
      assert.ok(Object.keys(settings).every((key) => !/^(AWS|COGNITO)_/.test(key)), name)
      if (journeys.some((journey) => name === `${journey}_spa`)) {
        assert.equal(settings.IDP_LOGIN_URI, loginUri, name)
      }
    }
  }
})

test('Customer keeps local registration, billing and mail configuration', () => {
  const env = { ...process.env }
  for (const key of ['REGISTRATION_DEV_MODE', 'STRIPE_API_BASE', 'SMTP_HOST']) {
    delete env[key]
  }
  const services = profileServices('customer-api', env)
  const settings = services.customer_api.environment
  assert.equal(settings.REGISTRATION_DEV_MODE, 'true')
  assert.equal(settings.STRIPE_API_BASE, 'http://mock_stripe_api:12111')
  assert.equal(settings.SMTP_HOST, 'mock_mailpit')
  assert.ok(services.mock_stripe_api)
  assert.ok(services.mock_mailpit)
})

test('Cognito wire-protocol fixture is available on demand', () => {
  const services = profileServices('cognito-mock')
  assert.deepEqual(Object.keys(services), ['mock_cognito'])
  assert.equal(services.mock_cognito.ports[0].host_ip, '127.0.0.1')
  assert.equal(services.mock_cognito.ports[0].target, 9229)
})

test('Welcome edge keeps the same-origin journey routes', () => {
  const nginx = fs.readFileSync(path.join(root, 'nginx.conf'), 'utf8')
  for (const journey of journeys) {
    assert.ok(nginx.includes(`location = /${journey} { return 302 /${journey}/; }`), journey)
    assert.ok(nginx.includes(`location /${journey}/ {`), journey)
    assert.ok(nginx.includes(`set $upstream http://${journey}_spa:80;`), journey)
  }
})
