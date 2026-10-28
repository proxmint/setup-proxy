#!/usr/bin/env bash
# Trades the job's GitHub OIDC token for one Proxmint proxy line (https://proxmint.com/docs/github-actions).
set -euo pipefail
audience=https://proxmint.com
api=${PROXMINT_API:-$audience} # override only to test against a stub

if [ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ]; then
  echo "::error::No OIDC token available: give the job 'permissions: id-token: write'."
  exit 1
fi
oidc=$(curl -fsS -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=$audience" | jq -r .value)
echo "::add-mask::$oidc"

body=$(jq -nc --arg product "$PRODUCT" --arg country "$COUNTRY" --arg session "$SESSION" --arg sticky "$STICKY" \
  '{session: $session, sticky_minutes: ($sticky | tonumber)}
   + (if $product != "" then {product: $product} else {} end)
   + (if $country != "" then {country: $country} else {} end)')
res=$(curl -sS -w '\n%{http_code}' -X POST "$api/api/github/proxy" \
  -H "Authorization: Bearer $oidc" -H "Content-Type: application/json" -d "$body")
code=${res##*$'\n'}
json=${res%$'\n'*}
if [ "$code" != 200 ]; then
  echo "::error::Proxmint answered $code: $(jq -r '.error // .' <<<"$json" 2>/dev/null || echo "$json")"
  exit 1
fi

field() { jq -r ".$1" <<<"$json"; }
echo "::add-mask::$(field password)"
echo "::add-mask::$(field url)"
{
  echo "url=$(field url)"
  echo "host=$(field host)"
  echo "port=$(field port)"
  echo "username=$(field username)"
  echo "password=$(field password)"
} >>"$GITHUB_OUTPUT"

[ "$(field status)" = active ] || echo "::warning::The $(field product) product is $(field status), so the gateway may refuse requests."
echo "Proxy ready: $(field product) through $(field host):$(field port)"

if [ "$EXPORT" = true ]; then
  for v in HTTP_PROXY HTTPS_PROXY http_proxy https_proxy; do echo "$v=$(field url)" >>"$GITHUB_ENV"; done
fi
