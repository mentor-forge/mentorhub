#!/usr/bin/env bash
# mh-nightly.sh — Markdown report of commits in the last 24 hours.
# Walks architecture.yaml sibling repos the same way as `make clone-all`,
# plus this umbrella repo. Git/yq noise is discarded; only the report is printed.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UMBRELLA="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAUNCHPAD="$(cd "${UMBRELLA}/.." && pwd)"
ARCH="${UMBRELLA}/Specifications/architecture.yaml"

report="$(mktemp)"
body="$(mktemp)"
authors_file="$(mktemp)"
quiet_file="$(mktemp)"
skipped_file="$(mktemp)"
cleanup() {
  rm -f "$report" "$body" "$authors_file" "$quiet_file" "$skipped_file"
}
trap cleanup EXIT

append_body() {
  printf '%s\n' "$*" >>"$body"
}

since_disp='24 hours ago'
until_disp="$(date -u '+%Y-%m-%d %H:%M UTC' 2>/dev/null || echo 'now')"
if since_try="$(date -u -d '24 hours ago' '+%Y-%m-%d %H:%M UTC' 2>/dev/null)"; then
  since_disp="$since_try"
elif since_try="$(date -u -v-24H '+%Y-%m-%d %H:%M UTC' 2>/dev/null)"; then
  since_disp="$since_try"
fi

{
  total_commits=0
  active_count=0

  process_repo() {
    local label="$1"
    local path="$2"
    local log line hash author subject rest

    if [[ ! -d "$path" ]]; then
      printf '%s\n' "- \`${label}\` — missing local clone" >>"$skipped_file"
      return
    fi
    if ! git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      printf '%s\n' "- \`${label}\` — not a git repository" >>"$skipped_file"
      return
    fi

    git -C "$path" fetch --all --prune --quiet || true

    log="$(git -C "$path" log --all --since='24 hours ago' --pretty=format:'%h%x09%an%x09%s' 2>/dev/null || true)"
    if [[ -z "$log" ]]; then
      printf '%s\n' "- \`${label}\`" >>"$quiet_file"
      return
    fi

    append_body "## \`${label}\`"
    append_body ""
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      hash="${line%%$'\t'*}"
      rest="${line#*$'\t'}"
      author="${rest%%$'\t'*}"
      subject="${rest#*$'\t'}"
      subject="$(printf '%s' "$subject" | tr '\r\n' '  ' | sed "s/\`/'/g")"
      append_body "- \`${hash}\` — **${author}** — ${subject}"
      printf '%s\n' "$author" >>"$authors_file"
      total_commits=$((total_commits + 1))
    done <<<"$log"
    append_body ""
    active_count=$((active_count + 1))
  }

  if ! command -v yq >/dev/null 2>&1; then
    printf '%s\n' "Could not generate the report: \`yq\` is required." >"$body"
  elif [[ ! -f "$ARCH" ]]; then
    printf '%s\n' "Could not generate the report: missing architecture.yaml." >"$body"
  else
    names="$(yq -r '.architecture.["journey-domains"][] | .repos[] | select(.type != "spa_ref") | .name' "$ARCH" || true)"
    process_repo "mentorhub" "$UMBRELLA"
    for name in $names; do
      [[ -z "$name" ]] && continue
      process_repo "mentorhub_${name}" "${LAUNCHPAD}/mentorhub_${name}"
    done
  fi

  unique_authors=0
  author_list='(none)'
  if [[ -s "$authors_file" ]]; then
    author_list="$(sort -u "$authors_file" | paste -sd ',' - | sed 's/,/, /g')"
    unique_authors="$(sort -u "$authors_file" | grep -c . || true)"
  fi

  {
    printf '%s\n' "# Mentor Hub daily activity"
    printf '%s\n' ""
    printf '%s\n' "**Period:** ${since_disp} → ${until_disp}"
    printf '%s\n' ""
    printf '%s\n' "## Totals"
    printf '%s\n' ""
    printf '%s\n' "| | |"
    printf '%s\n' "| --- | ---: |"
    printf '%s\n' "| Commits | ${total_commits} |"
    printf '%s\n' "| Repositories with activity | ${active_count} |"
    printf '%s\n' "| Authors | ${unique_authors} |"
    printf '%s\n' ""
    printf '%s\n' "**Authors:** ${author_list}"
    printf '%s\n' ""
    cat "$body"
    if [[ -s "$quiet_file" ]]; then
      printf '%s\n' "## Repositories with no activity"
      printf '%s\n' ""
      cat "$quiet_file"
      printf '%s\n' ""
    fi
    if [[ -s "$skipped_file" ]]; then
      printf '%s\n' "## Skipped"
      printf '%s\n' ""
      cat "$skipped_file"
      printf '%s\n' ""
    fi
  } >"$report"
} >/dev/null 2>&1

cat "$report"
