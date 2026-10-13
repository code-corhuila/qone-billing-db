-- Synthetic invoices of the five students of the seed (06-data, ADR-009): the same ids the
-- portals' fixtures use. Santiago's invoice stays ISSUED (the tuition-gate demo); the rest are
-- PAID. Upsert on the id: reapplying never duplicates (Annex A rule 11). No credentials here.
INSERT INTO billing.invoice (id, student_id, student_name, term, amount_cents, status, provider_reference, paid_at, created_at, updated_at)
VALUES
    ('88888888-8888-4888-8888-888888888801', '11111111-1111-4111-8111-111111111111', 'Laura Gómez',        '2026-B', 185000000, 'PAID',   'SIM-00000001', '2026-08-10T15:30:00Z', '2026-08-01T12:00:00Z', '2026-08-10T15:30:00Z'),
    ('88888888-8888-4888-8888-888888888802', '11111111-1111-4111-8111-111111111112', 'Santiago Rojas',     '2026-B', 185000000, 'ISSUED', NULL,           NULL,                   '2026-08-01T12:00:00Z', '2026-08-01T12:00:00Z'),
    ('88888888-8888-4888-8888-888888888803', '11111111-1111-4111-8111-111111111113', 'María José Cabrera', '2026-B', 185000000, 'PAID',   'SIM-00000003', '2026-08-10T15:30:00Z', '2026-08-01T12:00:00Z', '2026-08-10T15:30:00Z'),
    ('88888888-8888-4888-8888-888888888804', '11111111-1111-4111-8111-111111111114', 'Andrés Pineda',      '2026-B', 185000000, 'PAID',   'SIM-00000004', '2026-08-10T15:30:00Z', '2026-08-01T12:00:00Z', '2026-08-10T15:30:00Z'),
    ('88888888-8888-4888-8888-888888888805', '11111111-1111-4111-8111-111111111115', 'Valentina Suárez',   '2026-B', 185000000, 'PAID',   'SIM-00000005', '2026-08-10T15:30:00Z', '2026-08-01T12:00:00Z', '2026-08-10T15:30:00Z')
ON CONFLICT (id) DO UPDATE SET
    student_id         = EXCLUDED.student_id,
    student_name       = EXCLUDED.student_name,
    term               = EXCLUDED.term,
    amount_cents       = EXCLUDED.amount_cents,
    status             = EXCLUDED.status,
    provider_reference = EXCLUDED.provider_reference,
    paid_at            = EXCLUDED.paid_at,
    created_at         = EXCLUDED.created_at,
    updated_at         = EXCLUDED.updated_at;
