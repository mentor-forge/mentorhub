const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');

const repo = path.resolve(__dirname, '..');
const token = 'synthetic-token-for-regression-test';

function fixture(t) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'mentorhub-auth-'));
  t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
  const home = path.join(temp, 'home');
  const bin = path.join(temp, 'bin');
  const project = path.join(temp, 'mentorhub');
  const log = path.join(temp, 'commands');
  const config = path.join(home, '.mentorhub');
  fs.mkdirSync(config, { recursive: true });
  fs.mkdirSync(path.join(home, '.aws'));
  fs.mkdirSync(bin);
  fs.mkdirSync(project);
  for (const entry of ['Makefile', 'DeveloperEdition', 'scripts', 'nginx.conf']) {
    fs.cpSync(path.join(repo, entry), path.join(project, entry), { recursive: true });
  }
  const managedFiles = {
    '.aws/config': '[default]\nregion=us-east-1\n',
    '.mentorhub/aws-platform.env': 'aws legacy-settings-must-not-run\n',
    '.mentorhub/aws-platform.local.env': 'aws local-override-must-not-run\n',
    '.mentorhub/codeartifact-pypi-auth.sh': 'aws legacy-helper-must-not-run\n',
    '.zshrc': '# Added by mentorhub CLI install\n# unrelated user settings\n',
  };
  for (const [name, contents] of Object.entries(managedFiles)) {
    fs.writeFileSync(path.join(home, name), contents);
  }
  fs.writeFileSync(path.join(home, '.npmrc'), 'registry=https://example.invalid/npm/\n');
  fs.writeFileSync(path.join(bin, 'tool'), `#!/bin/sh
name=\${0##*/}
case "$name" in
  aws) echo aws >> "$COMMAND_LOG"; exit 99 ;;
  docker)
    echo "docker $*" >> "$COMMAND_LOG"
    if [ "$1" = login ]; then
      IFS= read -r password
      [ "$password" = "$TEST_TOKEN" ] || exit 98
    fi ;;
  git)
    if [ "$1" = --version ]; then echo git; fi ;;
  node)
    if [ "$1" = --version ]; then echo v24.0.0; fi ;;
  yq)
    case "$*" in
      *git_org*) echo mentor-forge ;;
      *is_journey*type*api*) echo admin_api ;;
      *is_journey*type*spa*) echo admin_spa ;;
      *spa_ref*) printf '%s\\n' admin_api admin_spa ;;
    esac ;;
  brew) echo "brew $*" >> "$COMMAND_LOG" ;;
  *) echo "$name $*" >> "$COMMAND_LOG" ;;
esac
`, { mode: 0o755 });
  for (const tool of ['aws', 'brew', 'curl', 'docker', 'git', 'jq', 'node', 'pipenv', 'python3.12', 'yq']) {
    fs.symlinkSync('tool', path.join(bin, tool));
  }
  for (const sibling of ['mentorhub_admin_api', 'mentorhub_admin_spa']) {
    fs.mkdirSync(path.join(temp, sibling, '.git'), { recursive: true });
  }
  const realNpm = spawnSync('sh', ['-c', 'command -v npm'], { encoding: 'utf8' });
  assert.equal(realNpm.status, 0, 'npm is a Developer Edition prerequisite');
  fs.writeFileSync(path.join(bin, 'npm'), `#!/bin/sh
if [ "$1" = run ]; then
  [ "$GITHUB_TOKEN" = "$TEST_TOKEN" ] || exit 97
  echo "npm $*" >> "$COMMAND_LOG"
  exit 0
fi
PATH="$TEST_REAL_PATH" exec "$TEST_REAL_NPM" "$@"
`, { mode: 0o755 });
  const env = {
    PATH: `${bin}:${process.env.PATH}`,
    HOME: home,
    COMMAND_LOG: log,
    TEST_TOKEN: token,
    TEST_REAL_NPM: realNpm.stdout.trim(),
    TEST_REAL_PATH: process.env.PATH,
  };

  function run(command, args, expected = 0, extraEnv = {}) {
    const result = spawnSync(command, args, {
      cwd: project,
      env: { ...env, ...extraEnv },
      encoding: 'utf8',
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, expected, output || String(result.error));
    assert.ok(!output.includes(token), 'GitHub token leaked into output');
    return output;
  }

  function checkPreservedFiles() {
    for (const [name, contents] of Object.entries(managedFiles)) {
      assert.equal(fs.readFileSync(path.join(home, name), 'utf8'), contents, name);
    }
    if (fs.existsSync(log)) {
      assert.doesNotMatch(fs.readFileSync(log, 'utf8'), /^aws$/m);
    }
  }
  return { config, home, log, run, checkPreservedFiles };
}

test('missing GitHub credentials fail clearly for registry operations', (t) => {
  const { run, checkPreservedFiles } = fixture(t);
  for (const args of [[], ['pull', 'admin'], ['up', 'admin']]) {
    assert.match(run('zsh', ['./DeveloperEdition/mh', ...args], 1), /GITHUB_TOKEN.*read:packages/);
  }
  assert.match(run('make', ['verify'], 2), /FAIL: GITHUB_TOKEN/);
  assert.match(run('make', ['build-all'], 2), /GITHUB_TOKEN.*read:packages/);
  checkPreservedFiles();
});

test('Developer Edition registry commands work independently of AWS', (t) => {
  const { config, home, log, run, checkPreservedFiles } = fixture(t);
  run('make', ['install']);
  run('make', ['verify'], 0, { GITHUB_TOKEN: token });
  fs.writeFileSync(path.join(config, 'GITHUB_TOKEN'), token);
  run('make', ['update']);
  for (const args of [[], ['pull', 'admin'], ['up', 'admin']]) {
    run('zsh', [path.join(config, 'mh'), ...args]);
  }
  run('make', ['build-all']);
  const npmrc = fs.readFileSync(path.join(home, '.npmrc'), 'utf8');
  assert.match(npmrc, /^registry=https:\/\/example\.invalid\/npm\/$/m);
  assert.match(npmrc, /^@mentor-forge:registry=https:\/\/npm\.pkg\.github\.com\/$/m);
  assert.match(npmrc, /^\/\/npm\.pkg\.github\.com\/:_authToken=\$\{GITHUB_TOKEN\}$/m);
  assert.ok(!npmrc.includes(token));
  const commands = fs.readFileSync(log, 'utf8');
  assert.match(commands, /docker login ghcr\.io -u mentor-forge --password-stdin/);
  assert.match(commands, /docker compose .* pull/);
  assert.match(commands, /docker compose .* up --detach/);
  assert.match(commands, /pipenv run container/);
  assert.match(commands, /npm run container/);
  assert.doesNotMatch(commands, /brew (?:install|upgrade) awscli/);
  checkPreservedFiles();
});

test('replaces the default registry set by the retired CodeArtifact login', (t) => {
  const { home, run, checkPreservedFiles } = fixture(t);
  const npmrc = path.join(home, '.npmrc');
  fs.writeFileSync(npmrc, 'registry=https://mentor-forge-000000000000.d.codeartifact.us-east-1.amazonaws.com/npm/mentorhub-npm/\n');
  run('zsh', ['./DeveloperEdition/mh'], 0, { GITHUB_TOKEN: token });
  assert.doesNotMatch(fs.readFileSync(npmrc, 'utf8'), /^registry=/m);
  checkPreservedFiles();
});
