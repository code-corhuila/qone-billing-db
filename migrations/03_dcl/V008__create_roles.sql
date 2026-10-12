-- Roles carry permissions and have no password (Annex A rule 10): NOLOGIN. The login users
-- that qone-billing-api connects with are created by qone-infra from secrets and granted a role.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'billing_reader') THEN
        CREATE ROLE billing_reader NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'billing_writer') THEN
        CREATE ROLE billing_writer NOLOGIN;
    END IF;
END
$$;
