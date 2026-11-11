-- An Idempotency-Key belongs to whoever sent it (qone-docs#55): the same key from another caller is
-- another key, so a replay never returns an invoice someone else created. owner_id is the user id
-- of the token (an ADMIN issues invoices), or the subject of a SERVICE token. request_hash is the
-- SHA-256 of the canonical request body: the same owner and key with another body is refused (422).
-- The keys recorded before this version name no owner and cannot be attributed; they are a retry
-- window of 24 h (V004), so they are dropped: a late retry of one meets ux_invoice_student_id_term
-- (INV-BIL-001) instead of creating a second invoice.
DELETE FROM billing.idempotency_key;

ALTER TABLE billing.idempotency_key
    ADD COLUMN owner_id     text NOT NULL,
    ADD COLUMN request_hash text NOT NULL,
    DROP CONSTRAINT pk_idempotency_key,
    ADD CONSTRAINT pk_idempotency_key PRIMARY KEY (owner_id, key),
    ADD CONSTRAINT chk_idempotency_key_owner        CHECK (length(owner_id) BETWEEN 1 AND 128),
    ADD CONSTRAINT chk_idempotency_key_request_hash CHECK (request_hash ~ '^[0-9a-f]{64}$');

COMMENT ON COLUMN billing.idempotency_key.owner_id IS 'Who sent the key: the user id of the token, or the SERVICE subject.';
COMMENT ON COLUMN billing.idempotency_key.request_hash IS 'SHA-256 (hex) of the canonical request body the key was first used with.';
