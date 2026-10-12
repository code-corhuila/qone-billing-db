# qone-billing-db

> billing bounded context: database (schema, seeds, migrations)

Part of the **Qampus (Quorum One)** distributed system — team `quorum-one`, Grupo 1.
Governance and documentation live in [`qone-docs`](https://github.com/code-corhuila/qone-docs).

## Purpose

The database of the **billing** domain (course norm 5.2, Annex A): its own PostgreSQL 16
instance, the schema `billing` and the migrations that build it. `qone-billing-api` consumes
this structure and never versions it; no other service connects here (ADR-006). The tool is
**Flyway Community** (ADR-007): one SQL file, one version number, and a mirror `U` script per
version because Community does not roll back.

Specification: `06-data/models.md` (schema `billing`), `06-data/modeling-conventions.md`,
`06-data/migration-strategy.md` in `qone-docs`. Story: `code-corhuila/qone-docs#43` (HU-BIL-001).

## Schema

| Table | What it keeps | Rules the database enforces |
|---|---|---|
| `invoice` | the term invoice of a student, money in COP cents | one invoice per student and term (`ux_invoice_student_id_term`, INV-BIL-001); `PAID` if and only if `paid_at` and `provider_reference` are set (INV-BIL-002); amount `> 0`; status is a `CHECK`, not an `ENUM` |
| `idempotency_key` | the `Idempotency-Key` of every issue, written in the same transaction as the invoice (norm 5.3.8) | key of 8 to 128 characters |
| `outbox` | `InvoiceIssued` and `TuitionPaid`, written in the transaction of the change, relayed later by `qone-worker` (norm 5.3.11) | event type from the closed list; partial index on the unpublished rows |

`student_id` is an id of `identity.app_user` and is **not** a foreign key: a key to another
domain is a value, not a constraint. Roles `billing_reader` and `billing_writer` are `NOLOGIN`;
`qone-infra` creates the login users from secrets.

## Layout

```
migrations/
├── 01_ddl/   00_extensions · 01_schemas · 02_tables · 04_alter · 05_indexes   (V001..V006)
├── 02_dml/   seeds as upserts                                                 (V007)
├── 03_dcl/   roles and grants                                                 (V008, V009)
├── 04_tcl/   recorded one-off recoveries, never automatic
└── undo/     U001..U009, one per V, same relative path
flyway.toml   the locations, in order; undo/ is not one of them
deploy/       the instance and the Flyway runner that qone-infra includes
scripts/      rebuild-check.sh, what db-ci runs
```

The version number decides the order, not the folder. A new migration takes the next number
in the folder of its family; a merged migration is never edited (a fix is a new version).

## How to run it

```bash
cp .env.example .env            # set BILLING_DB_PASSWORD; .env is ignored by git
docker network create platform  # once; qone-infra creates it in the full platform
docker compose --env-file .env -f deploy/compose.yml up -d billing-db
docker compose --env-file .env -f deploy/compose.yml --profile migrate run --rm billing-db-migrate
```

The runner accepts any Flyway action (`info`, `validate`, `migrate`). The rebuild check of
Annex A, the same `db-ci.yml` runs on every pull request:

```bash
sh scripts/rebuild-check.sh
```

It migrates a throwaway instance from zero, migrates again (nothing applied), applies every
`U` script in reverse with `psql` and checks the schema and the roles are gone, rebuilds,
validates the checksums and applies the seed twice. The Flyway history table lives in the
`billing` schema, so nothing at all is created in `public`.

## Branching

Three permanent branches. **None of them accepts a direct commit** — you enter through a child
branch and leave through a Pull Request.

```
develop  <--PR--  feat/... fix/... chore/...
qa       <--PR--  qa/...
main     <--PR--  release/...  hotfix/...
```

Promotion happens **by re-application** (`git cherry-pick -x`), never by merging one permanent
branch into another: `merge develop -> qa` and `merge qa -> main` do not exist in this model.

`main` requires **1 approval from `ariel5253`**. On `develop` and `qa` the team sets its own review
rule.

Full policy: `00-governance/branching-policy.md` in `qone-docs`.
