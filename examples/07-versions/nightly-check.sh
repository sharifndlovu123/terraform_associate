#!/usr/bin/env bash
# Nightly canary: would tomorrow's provider releases break us?
#
# Production keeps using the committed .terraform.lock.hcl. This script ignores it on purpose:
# it copies the config to a temp dir WITHOUT the lock file, lets `init -upgrade` pick the newest
# versions the constraints allow, then validates and plans. Failure = something upstream broke.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp "$here"/*.tf "$here"/hello.txt "$work"/   # note: no .terraform.lock.hcl
cd "$work"

echo "==> resolving the newest versions the constraints allow"
terraform init -input=false -upgrade -no-color >/dev/null

echo "==> versions that moved since the committed lock file"
moved=0
for p in random null local; do
  old=$(grep -A1 "hashicorp/$p\"" "$here/.terraform.lock.hcl" | sed -n 's/.*version *= *"\(.*\)"/\1/p')
  new=$(grep -A1 "hashicorp/$p\"" .terraform.lock.hcl | sed -n 's/.*version *= *"\(.*\)"/\1/p')
  if [ "$old" != "$new" ]; then echo "    $p: $old -> $new"; moved=1; fi
done
[ "$moved" = 0 ] && echo "    none, lock file is already the newest allowed"

broken() {
  echo "BROKEN: $1 failed on the newest allowed versions. Fix it in the morning (update the code, or tighten a constraint)." >&2
  exit 1
}

echo "==> validate"
terraform validate -no-color || broken "validate"

echo "==> plan"
set +e
terraform plan -input=false -detailed-exitcode -no-color >/dev/null
code=$?
set -e
# 0 = no changes, 2 = changes to apply (fine for a canary), 1 = error = something broke
[ "$code" = 1 ] && broken "plan"

echo "OK: the newest allowed versions still work."
[ "$moved" = 1 ] && echo "    Safe to refresh the lock file: terraform init -upgrade, then commit .terraform.lock.hcl"
exit 0
