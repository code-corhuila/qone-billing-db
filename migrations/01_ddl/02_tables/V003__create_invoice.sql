-- invoice: the aggregate of the billing domain (06-data/models.md, schema billing).
-- student_id points to identity.app_user and is NOT a foreign key (cross-domain id, rule 8).
-- Money is an integer in COP cents (norm 5.4.3); the status set is a CHECK, never an ENUM.
CREATE TABLE billing.invoice (
    id                 uuid        NOT NULL DEFAULT gen_random_uuid(),
    student_id         uuid        NOT NULL,
    student_name       text        NOT NULL,
    term               text        NOT NULL,
    amount_cents       bigint      NOT NULL,
    status             text        NOT NULL DEFAULT 'ISSUED',
    provider_reference text        NULL,
    paid_at            timestamptz NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_invoice                 PRIMARY KEY (id),
    CONSTRAINT chk_invoice_student_name   CHECK (length(student_name) BETWEEN 2 AND 120),
    CONSTRAINT chk_invoice_term           CHECK (term ~ '^[0-9]{4}-[AB]$'),
    CONSTRAINT chk_invoice_amount_cents   CHECK (amount_cents > 0),
    CONSTRAINT chk_invoice_status         CHECK (status IN ('ISSUED', 'PAID')),
    CONSTRAINT chk_invoice_provider_ref   CHECK (provider_reference IS NULL OR length(provider_reference) <= 40),
    -- A row never says two contradictory things: PAID if and only if it has a payment (INV-BIL-002).
    CONSTRAINT chk_invoice_paid_at        CHECK ((status = 'PAID') = (paid_at IS NOT NULL)),
    CONSTRAINT chk_invoice_paid_reference CHECK ((status = 'PAID') = (provider_reference IS NOT NULL))
);

COMMENT ON TABLE  billing.invoice IS 'The term invoice of a student: ISSUED until the simulated provider approves it, then PAID (terminal).';
COMMENT ON COLUMN billing.invoice.student_id IS 'Id in identity.app_user; no foreign key across domains.';
COMMENT ON COLUMN billing.invoice.amount_cents IS 'COP cents, integer; never a float.';
