-- What each role may do. Nothing is ever deleted by the application (no soft delete in v2):
-- the writer has no DELETE on invoice or outbox; idempotency keys are pruned by age.
GRANT USAGE ON SCHEMA billing TO billing_reader, billing_writer;

GRANT SELECT ON ALL TABLES IN SCHEMA billing TO billing_reader;

GRANT SELECT, INSERT, UPDATE         ON billing.invoice         TO billing_writer;
GRANT SELECT, INSERT, DELETE         ON billing.idempotency_key TO billing_writer;
GRANT SELECT, INSERT, UPDATE         ON billing.outbox          TO billing_writer;
