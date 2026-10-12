-- Every index names the query it serves (Annex A rule 3; 06-data/modeling-conventions.md).
-- INV-BIL-001: one invoice per student and term, enforced by the database.
CREATE UNIQUE INDEX ux_invoice_student_id_term ON billing.invoice (student_id, term);
-- BI-02: a student's invoices, newest first.
CREATE INDEX ix_invoice_student_id_created_at ON billing.invoice (student_id, created_at DESC);
-- The relay reads only what is not published yet.
CREATE INDEX ix_outbox_unpublished ON billing.outbox (occurred_at) WHERE published_at IS NULL;
-- The pruner of idempotency keys reads by age.
CREATE INDEX ix_idempotency_key_created_at ON billing.idempotency_key (created_at);
