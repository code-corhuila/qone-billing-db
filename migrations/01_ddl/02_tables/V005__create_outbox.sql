-- outbox: the event row is written in the transaction of the change (norm 5.3.11);
-- qone-worker relays it to RabbitMQ later and sets published_at. Shared shape of 06-data/models.md.
CREATE TABLE billing.outbox (
    id             uuid        NOT NULL DEFAULT gen_random_uuid(),
    aggregate_type text        NOT NULL,
    aggregate_id   uuid        NOT NULL,
    event_type     text        NOT NULL,
    payload        jsonb       NOT NULL,
    occurred_at    timestamptz NOT NULL DEFAULT now(),
    published_at   timestamptz NULL,
    CONSTRAINT pk_outbox                PRIMARY KEY (id),
    CONSTRAINT chk_outbox_aggregate     CHECK (aggregate_type IN ('invoice')),
    CONSTRAINT chk_outbox_event_type    CHECK (event_type IN ('InvoiceIssued', 'TuitionPaid'))
);

COMMENT ON TABLE billing.outbox IS 'Events of the billing domain (02-domain/domain-events.md): InvoiceIssued, TuitionPaid. Payload in camelCase, the API shape.';
