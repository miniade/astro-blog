#!/usr/bin/env bash
set -euo pipefail

# Publish Astro build output (dist/) to a PR branch in miniade/miniade.github.io,
# rooted at edxi/edxi.github.io:master (so GitHub can generate a clean PR diff).
#
# Required env:
#   GH_TOKEN (or GITHUB_TOKEN): token with permission to push to miniade/miniade.github.io
#
# Optional env:
#   DIST_DIR            (default: dist)
#   PAGES_REPO          (default: miniade/miniade.github.io)
#   UPSTREAM_REPO       (default: edxi/edxi.github.io)
#   PR_BRANCH           (default: pr-to-edxi)
#   UPSTREAM_BASE       (default: master)
#   PR_TITLE            (default: auto)
#   PR_BODY             (default: auto)

DIST_DIR="${DIST_DIR:-dist}"
PAGES_REPO="${PAGES_REPO:-miniade/miniade.github.io}"
UPSTREAM_REPO="${UPSTREAM_REPO:-edxi/edxi.github.io}"
PR_BRANCH="${PR_BRANCH:-pr-to-edxi}"
UPSTREAM_BASE="${UPSTREAM_BASE:-master}"

if [[ ! -d "$DIST_DIR" ]]; then
  echo "ERROR: DIST_DIR not found: $DIST_DIR" >&2
  exit 2
fi

TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -z "$TOKEN" ]]; then
  echo "ERROR: missing GH_TOKEN (or GITHUB_TOKEN)" >&2
  exit 2
fi

SOURCE_REPO="${GITHUB_REPOSITORY:-miniade/astro-blog}"
SOURCE_SHA="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}"
RUN_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-miniade/astro-blog}/actions/runs/${GITHUB_RUN_ID:-}"
BUILD_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

TITLE_DEFAULT="Publish blog build from ${SOURCE_REPO}@${SOURCE_SHA:0:7}"
BODY_DEFAULT=$(cat <<EOB
Automated publish PR.

- Source: ${SOURCE_REPO}@${SOURCE_SHA}
- Built at (UTC): ${BUILD_TS}
- Workflow run: ${RUN_URL}

Notes:
- This branch is reset to ${UPSTREAM_REPO}:${UPSTREAM_BASE} on each publish to preserve a common ancestor.
- The site content is replaced by the latest Astro build output (dist/).
EOB
)

PR_TITLE="${PR_TITLE:-$TITLE_DEFAULT}"
PR_BODY="${PR_BODY:-$BODY_DEFAULT}"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

PAGES_URL="https://x-access-token:${TOKEN}@github.com/${PAGES_REPO}.git"

git clone --quiet "$PAGES_URL" "$WORKDIR/pages"
cd "$WORKDIR/pages"

git config user.name "miniade-bot"
git config user.email "miniade-bot@users.noreply.github.com"

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "https://github.com/${UPSTREAM_REPO}.git"
fi

git fetch --quiet upstream "$UPSTREAM_BASE"

git checkout -B "$PR_BRANCH" "upstream/${UPSTREAM_BASE}"

shopt -s dotglob
for p in * .[^.]* ..?*; do
  [[ "$p" == ".git" ]] && continue
  rm -rf "$p" || true
done
shopt -u dotglob

rsync -a --delete --exclude '.git' "${GITHUB_WORKSPACE:-$PWD}/$DIST_DIR/" ./

# GitHub Pages legacy branch deploy ignores underscore-prefixed assets without this.
: > .nojekyll

git add -A
if git diff --cached --quiet; then
  echo "No changes in dist; branch content unchanged."
else
  COMMIT_MSG="chore(pages): publish latest blog build (${SOURCE_SHA:0:7})"
  git commit -m "$COMMIT_MSG" >/dev/null
  git push --force-with-lease origin "$PR_BRANCH" >/dev/null
  echo "Pushed ${PAGES_REPO}:${PR_BRANCH}"
fi

OPEN_PR_JSON=$(gh pr list \
  --repo "$UPSTREAM_REPO" \
  --head "miniade:${PR_BRANCH}" \
  --base "$UPSTREAM_BASE" \
  --state open \
  --json number,url,state \
  --jq '.[0]' \
  2>/dev/null || true)

if [[ -n "$OPEN_PR_JSON" && "$OPEN_PR_JSON" != "null" ]]; then
  OPEN_PR_URL=$(printf '%s' "$OPEN_PR_JSON" | jq -r '.url')
  echo "PR already open: $OPEN_PR_URL"
  exit 0
fi

ANY_PR_JSON=$(gh pr list \
  --repo "$UPSTREAM_REPO" \
  --head "miniade:${PR_BRANCH}" \
  --base "$UPSTREAM_BASE" \
  --state all \
  --json number,url,state,mergedAt \
  --jq 'sort_by(.number) | reverse | .[0]' \
  2>/dev/null || true)

HEAD_BRANCH="miniade:${PR_BRANCH}"
ACTUAL_PR_BRANCH="$PR_BRANCH"

if [[ -n "$ANY_PR_JSON" && "$ANY_PR_JSON" != "null" ]]; then
  LAST_PR_URL=$(printf '%s' "$ANY_PR_JSON" | jq -r '.url')
  LAST_PR_STATE=$(printf '%s' "$ANY_PR_JSON" | jq -r '.state')
  LAST_PR_MERGED_AT=$(printf '%s' "$ANY_PR_JSON" | jq -r '.mergedAt // empty')

  if [[ "$LAST_PR_STATE" == "MERGED" || "$LAST_PR_STATE" == "CLOSED" || -n "$LAST_PR_MERGED_AT" ]]; then
    ACTUAL_PR_BRANCH="${PR_BRANCH}-${SOURCE_SHA:0:7}"
    git branch -M "$ACTUAL_PR_BRANCH"
    git push --force-with-lease origin "$ACTUAL_PR_BRANCH" >/dev/null
    HEAD_BRANCH="miniade:${ACTUAL_PR_BRANCH}"
    echo "Previous PR already closed/merged ($LAST_PR_URL); using fresh branch: $ACTUAL_PR_BRANCH"
  fi
fi

NEW_URL=$(gh pr create \
  --repo "$UPSTREAM_REPO" \
  --base "$UPSTREAM_BASE" \
  --head "$HEAD_BRANCH" \
  --title "$PR_TITLE" \
  --body "$PR_BODY")
echo "PR created: $NEW_URL"
