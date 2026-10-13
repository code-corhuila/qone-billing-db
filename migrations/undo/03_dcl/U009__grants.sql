REVOKE ALL ON ALL TABLES IN SCHEMA billing FROM billing_writer;
REVOKE ALL ON ALL TABLES IN SCHEMA billing FROM billing_reader;
REVOKE USAGE ON SCHEMA billing FROM billing_reader, billing_writer;
