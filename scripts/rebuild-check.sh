#!/usr/bin/env sh
# The rebuild check of Annex A and 06-data/migration-strategy.md, against a fresh instance:
#   1. migrate from an empty database        -> the schema builds from zero
#   2. migrate again                         -> "No migration necessary" (incremental)
#   3. every U script in reverse, with psql  -> the schema and the roles are gone
#   4. migrate again                         -> after undo, it builds again
#   5. validate                              -> checksums match the files
#   6. apply the seed twice, count the rows  -> seeds are idempotent
# Usage: scripts/rebuild-check.sh   (needs Docker; uses deploy/compose.yml with a throwaway project)
set -eu
cd "$(dirname "$0")/.."
export BILLING_DB_NAME="${BILLING_DB_NAME:-billing}"
export BILLING_DB_USER="${BILLING_DB_USER:-billing}"
export BILLING_DB_PASSWORD="${BILLING_DB_PASSWORD:-rebuild-check}"
PROJECT="billing-db-check"
DC="docker compose -p $PROJECT -f deploy/compose.yml"
docker network inspect platform >/dev/null 2>&1 || docker network create platform >/dev/null
cleanup() { $DC --profile tooling down -v --remove-orphans >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup

fail() { echo "FAIL: $1" >&2; exit 1; }
migrate() { $DC --profile tooling run --rm billing-db-migrate "$@"; }
psql_db() { $DC exec -T billing-db psql -v ON_ERROR_STOP=1 -U "$BILLING_DB_USER" -d "$BILLING_DB_NAME" "$@"; }

echo "== 1. migrate from an empty database"
$DC up -d billing-db --wait
migrate migrate | tee /tmp/migrate-1.log
grep -q "Successfully applied" /tmp/migrate-1.log || fail "the first migrate applied nothing"

echo "== 2. migrate again applies nothing"
migrate migrate | tee /tmp/migrate-2.log
grep -q "No migration necessary" /tmp/migrate-2.log || fail "the second migrate applied something"

echo "== 3. every U script, from the highest version to the lowest"
for v in $(ls migrations | grep -v undo >/dev/null; find migrations -path migrations/undo -prune -o -name 'V*__*.sql' -print | sed -E 's#.*/V([0-9]+)__.*#\1#' | sort -r); do
  u=$(find migrations/undo -name "U${v}__*.sql" | head -n1)
  [ -n "$u" ] || fail "V${v} has no U${v} script in migrations/undo"
  if [ "$v" = "002" ]; then
    # Only the Flyway history may remain before the schema itself is dropped: a missing U would show here.
    domain_tables=$(psql_db -tA -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'billing' AND table_name <> 'flyway_schema_history'")
    [ "$domain_tables" = "0" ] || fail "$domain_tables table(s) of the domain survived the undo scripts"
  fi
  echo "-- $u"
  psql_db < "$u" >/dev/null
done
left=$(psql_db -tA -c "SELECT count(*) FROM information_schema.schemata WHERE schema_name = 'billing'")
[ "$left" = "0" ] || fail "schema billing still exists after the undo scripts"
roles=$(psql_db -tA -c "SELECT count(*) FROM pg_roles WHERE rolname IN ('billing_reader','billing_writer')")
[ "$roles" = "0" ] || fail "the billing roles still exist after the undo scripts"

echo "== 4. migrate again (the history went with the schema)"
migrate migrate | tee /tmp/migrate-3.log
grep -q "Successfully applied" /tmp/migrate-3.log || fail "the rebuild after the undo applied nothing"

echo "== 5. validate"
migrate validate

echo "== 6. the seed is idempotent"
psql_db < migrations/02_dml/V007__seed_invoice.sql >/dev/null
psql_db < migrations/02_dml/V007__seed_invoice.sql >/dev/null
rows=$(psql_db -tA -c "SELECT count(*) FROM billing.invoice")
[ "$rows" = "5" ] || fail "expected 5 seeded invoices, found $rows"
public_tables=$(psql_db -tA -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'")
[ "$public_tables" = "0" ] || fail "a table lives in public"

echo "OK: qone-billing-db rebuilds from zero, applies nothing twice, undoes completely, rebuilds, validates and seeds idempotently"
