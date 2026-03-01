#!/usr/bin/env bash
set -euo pipefail

# Publish Astro build output (dist/) to a fixed PR branch in miniade/miniade.github.io,
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
BODY_DEFAULT=$(cat <<EOF
Automated publish PR.

- Source: ${SOURCE_REPO}@${SOURCE_SHA}
- Built at (UTC): ${BUILD_TS}
- Workflow run: ${RUN_URL}

Notes:
- This branch is reset to ${UPSTREAM_REPO}:${UPSTREAM_BASE} on each publish to preserve a common ancestor.
- The site content is replaced by the latest Astro build output (dist/).
EOF
)

PR_TITLE="${PR_TITLE:-$TITLE_DEFAULT}"
PR_BODY="${PR_BODY:-$BODY_DEFAULT}"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

PAGES_URL="https://x-access-token:${TOKEN}@github.com/${PAGES_REPO}.git"

# Clone the pages repo (fork) and wire upstream.
git clone --quiet "$PAGES_URL" "$WORKDIR/pages"
cd "$WORKDIR/pages"

git config user.name "miniade-bot"
git config user.email "miniade-bot@users.noreply.github.com"

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "https://github.com/${UPSTREAM_REPO}.git"
fi

git fetch --quiet upstream "$UPSTREAM_BASE"

# Reset PR branch to upstream base every time (ensures common ancestry).
git checkout -B "$PR_BRANCH" "upstream/${UPSTREAM_BASE}"

# Replace repo content with dist/
shopt -s dotglob
for p in * .[^.]* ..?*; do
  [[ "$p" == ".git" ]] && continue
  rm -rf "$p" || true
done
shopt -u dotglob

rsync -a --delete --exclude '.git' "${GITHUB_WORKSPACE:-$PWD}/$DIST_DIR/" ./

# Commit/push if anything changed.
git add -A
if git diff --cached --quiet; then
  echo "No changes in dist; branch not updated."
else
  COMMIT_MSG="chore(pages): publish latest blog build (${SOURCE_SHA:0:7})"
  git commit -m "$COMMIT_MSG" >/dev/null
  git push --force-with-lease origin "$PR_BRANCH" >/dev/null
  echo "Pushed ${PAGES_REPO}:${PR_BRANCH}"
fi

# Create or reuse PR to upstream.
EXISTING_URL=$(gh pr list \
  --repo "$UPSTREAM_REPO" \
  --head "miniade:${PR_BRANCH}" \
  --base "$UPSTREAM_BASE" \
  --state open \
  --json url \
  --jq '.[0].url' \
  2>/dev/null || true)

if [[ -n "$EXISTING_URL" && "$EXISTING_URL" != "null" ]]; then
  echo "PR already open: $EXISTING_URL"
else
  NEW_URL=$(gh pr create \
    --repo "$UPSTREAM_REPO" \
    --base "$UPSTREAM_BASE" \
    --head "miniade:${PR_BRANCH}" \
    --title "$PR_TITLE" \
    --body "$PR_BODY")
  echo "PR created: $NEW_URL"
fi
