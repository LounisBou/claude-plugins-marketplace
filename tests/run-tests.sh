#!/bin/bash
# Catalogue test suite. Offline by default; ONLINE=1 adds the remote checks.
#
# Checks the marketplace manifest and the README table that mirrors it.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT="$HERE/.."
CATALOGUE="$ROOT/.claude-plugin/marketplace.json"
README="$ROOT/README.md"
SEMVER='^[0-9]+\.[0-9]+\.[0-9]+$'
REPO_RE='^LounisBou/[A-Za-z0-9._-]+$'

pass=0
fail=0

# ok <name> / bad <name> [detail]
ok() { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
bad() {
  printf '  FAIL %s\n' "$1"
  [ -n "${2:-}" ] && printf '       %s\n' "$2"
  fail=$((fail + 1))
}

# check <name> <expected> <actual>
check() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected: $2 / actual: $3"; fi
}

echo "== catalogue file =="

if jq -e . "$CATALOGUE" >/dev/null 2>&1; then
  ok "the JSON parses"
else
  bad "the JSON parses" "$CATALOGUE is missing or invalid"
  printf '\n%d passed, %d failed\n' "$pass" "$fail"
  exit 1
fi

check "name is lounisbou" "lounisbou" "$(jq -r '.name' "$CATALOGUE")"
if [ "$(jq '(.plugins | type) == "array" and (.plugins | length) > 0' "$CATALOGUE")" = "true" ]; then
  ok "the catalogue lists at least one plugin"
else
  bad "the catalogue lists at least one plugin"
fi
metadata_version=$(jq -r '.metadata.version // ""' "$CATALOGUE")
if [[ "$metadata_version" =~ $SEMVER ]]; then ok "metadata version is semver"; else bad "metadata version is semver" "got: $metadata_version"; fi

echo "== entries =="

while IFS= read -r entry; do
  name=$(jq -r '.name // ""' <<<"$entry")
  label="${name:-<unnamed>}"
  for field in name source description version; do
    if [ "$(jq "has(\"$field\") and (.$field | . != null and . != \"\")" <<<"$entry")" = "true" ]; then
      ok "$label has $field"
    else
      bad "$label has $field"
    fi
  done
  version=$(jq -r '.version // ""' <<<"$entry")
  if [[ "$version" =~ $SEMVER ]]; then ok "$label version is semver"; else bad "$label version is semver" "got: $version"; fi
  kind=$(jq -r '.source | type' <<<"$entry")
  src=$(jq -r 'if (.source | type) == "object" then .source.source // "" else "" end' <<<"$entry")
  repo=$(jq -r 'if (.source | type) == "object" then .source.repo // "" else "" end' <<<"$entry")
  if [ "$kind" = "object" ] && [ "$src" = "github" ] && [[ "$repo" =~ $REPO_RE ]]; then
    ok "$label source is a GitHub object on a LounisBou repository"
  else
    bad "$label source is a GitHub object on a LounisBou repository" "got: $(jq -c '.source' <<<"$entry")"
  fi
done < <(jq -c '.plugins[]' "$CATALOGUE")

dupes=$(jq -r '[.plugins[].name] | group_by(.) | map(select(length > 1) | .[0]) | join(",")' "$CATALOGUE")
check "names are unique" "" "$dupes"

echo "== README =="

if [ -f "$README" ]; then
  catalogue_names=$(jq -r '.plugins[].name' "$CATALOGUE" | sort)
  readme_names=$(sed -n 's/^| `\([^`]*\)` |.*/\1/p' "$README" | sort)
  check "the table lists exactly the catalogue's names" "$catalogue_names" "$readme_names"
  if grep -qF '/plugin marketplace add LounisBou/claude-plugins-marketplace' "$README"; then
    ok "the install line is present"
  else
    bad "the install line is present"
  fi
else
  bad "README.md exists"
fi

if [ "${ONLINE:-0}" = "1" ]; then
  echo "== online: source repositories =="
  while IFS=$'\t' read -r name repo version; do
    if ! gh repo view "$repo" >/dev/null 2>&1; then
      bad "$name: repository $repo exists"
      continue
    fi
    ok "$name: repository $repo exists"
    remote=$(gh api "repos/$repo/contents/.claude-plugin/plugin.json" --jq '.content' 2>/dev/null \
      | base64 -d 2>/dev/null | jq -r '.version // ""' 2>/dev/null)
    if [ "$remote" = "$version" ]; then
      ok "$name: plugin.json version $remote matches the catalogue"
    else
      bad "$name: plugin.json version matches the catalogue" "catalogue: $version / $repo: ${remote:-<unreadable>}"
    fi
  done < <(jq -r '.plugins[] | [.name, .source.repo, .version] | @tsv' "$CATALOGUE")
fi

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
