-- Back to one key for everyone: when two owners used the same key, the first one recorded stays.
DELETE FROM billing.idempotency_key a
USING billing.idempotency_key b
WHERE a.key = b.key AND (a.created_at, a.owner_id) > (b.created_at, b.owner_id);

ALTER TABLE billing.idempotency_key
    DROP CONSTRAINT IF EXISTS chk_idempotency_key_request_hash,
    DROP CONSTRAINT IF EXISTS chk_idempotency_key_owner,
    DROP CONSTRAINT pk_idempotency_key,
    ADD CONSTRAINT pk_idempotency_key PRIMARY KEY (key),
    DROP COLUMN IF EXISTS request_hash,
    DROP COLUMN IF EXISTS owner_id;
