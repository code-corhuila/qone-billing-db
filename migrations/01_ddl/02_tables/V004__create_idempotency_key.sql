-- idempotency_key: the database half of idempotent creation (norm 5.3.8, Annex A).
-- The service inserts the invoice and its key in one transaction with ON CONFLICT DO NOTHING;
-- when the key already exists it rolls back and returns the first invoice.
CREATE TABLE billing.idempotency_key (
    key           text        NOT NULL,
    resource_type text        NOT NULL,
    resource_id   uuid        NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_idempotency_key              PRIMARY KEY (key),
    CONSTRAINT chk_idempotency_key_length      CHECK (length(key) BETWEEN 8 AND 128),
    CONSTRAINT chk_idempotency_key_resource    CHECK (resource_type IN ('invoice'))
);

COMMENT ON TABLE billing.idempotency_key IS 'Idempotency-Key of every creation; rows older than 24 h may be pruned by qone-worker.';
