#!/usr/bin/env bash
# check-dep.sh — Verify a dependency meets quality thresholds
# Usage: check-dep.sh <package-name> [min-stars] [max-age-months]
# Example: check-dep.sh drizzle-orm 500 12

set -euo pipefail

PKG="$1"
MIN_STARS="${2:-500}"
MAX_AGE_MONTHS="${3:-12}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$PKG" ]; then
  echo "Usage: check-dep.sh <package-name> [min-stars] [max-age-months]"
  exit 1
fi

# Get GitHub repo URL from npm
REPO_URL=$(npm view "$PKG" repository.url 2>/dev/null | sed 's/git+//' | sed 's/\.git$//' | sed 's|git://|https://|' | sed 's|ssh://git@|https://|')

if [ -z "$REPO_URL" ]; then
  echo -e "${RED}FAIL${NC} $PKG — no repository URL found on npm"
  exit 1
fi

# Extract owner/repo from URL
REPO=$(echo "$REPO_URL" | sed -E 's|https://github.com/||' | sed 's|/$||')

if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo -e "${YELLOW}SKIP${NC} $PKG — not a GitHub repo ($REPO_URL). Manual review required."
  exit 0
fi

# Fetch stars and last push via GitHub API (no auth = 60 req/hr)
API_RESPONSE=$(curl -sf "https://api.github.com/repos/$REPO" 2>/dev/null) || {
  echo -e "${YELLOW}SKIP${NC} $PKG — GitHub API request failed for $REPO. Check manually."
  exit 0
}

STARS=$(echo "$API_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('stargazers_count', 0))" 2>/dev/null || echo "0")
PUSHED_AT=$(echo "$API_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('pushed_at', ''))" 2>/dev/null || echo "")
ARCHIVED=$(echo "$API_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('archived', False))" 2>/dev/null || echo "False")

# Check archived
if [ "$ARCHIVED" = "True" ]; then
  echo -e "${RED}FAIL${NC} $PKG — repository is archived"
  exit 1
fi

# Check stars
PASS=true
if [ "$STARS" -lt "$MIN_STARS" ]; then
  echo -e "${RED}FAIL${NC} $PKG — $STARS stars (minimum: $MIN_STARS)"
  PASS=false
else
  echo -e "${GREEN}PASS${NC} $PKG — $STARS stars"
fi

# Check last activity
if [ -n "$PUSHED_AT" ]; then
  LAST_PUSH_EPOCH=$(date -d "$PUSHED_AT" +%s 2>/dev/null || echo "0")
  NOW_EPOCH=$(date +%s)
  AGE_DAYS=$(( (NOW_EPOCH - LAST_PUSH_EPOCH) / 86400 ))
  AGE_MONTHS=$(( AGE_DAYS / 30 ))
  MAX_AGE_DAYS=$(( MAX_AGE_MONTHS * 30 ))

  if [ "$AGE_DAYS" -gt "$MAX_AGE_DAYS" ]; then
    echo -e "${RED}FAIL${NC} $PKG — last push ${AGE_MONTHS} months ago (maximum: ${MAX_AGE_MONTHS})"
    PASS=false
  else
    echo -e "${GREEN}PASS${NC} $PKG — last push ${AGE_DAYS} days ago"
  fi
fi

if [ "$PASS" = true ]; then
  echo -e "\n${GREEN}APPROVED${NC} $PKG ($REPO) — $STARS stars, last push $AGE_DAYS days ago"
  exit 0
else
  echo -e "\n${RED}REJECTED${NC} $PKG ($REPO) — does not meet thresholds"
  exit 1
fi
