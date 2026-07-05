-- 019: AxiomDB realtime notify trigger for listings
--
-- Enables the twendezanzibar_b2b Flutter app's AxiomDB Dart SDK to receive
-- live updates via Postgres LISTEN/NOTIFY instead of polling/manual refresh.
-- Purely additive: no existing columns, rows, or constraints are touched.
-- Payload/channel shape matches the axiomdb-cli schema DSL's DDL emitter
-- (apps/axiomdb-cli/src/schema/ddl.rs) so this table interoperates with the
-- same SDK runtime even though its schema is hand-written, not DSL-generated.

CREATE OR REPLACE FUNCTION axiomdb_notify_change() RETURNS trigger AS $$
DECLARE
  payload jsonb;
BEGIN
  payload := jsonb_build_object(
    'table', TG_TABLE_NAME,
    'op', TG_OP,
    'id',
      CASE
        WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD)->'id'
        ELSE to_jsonb(NEW)->'id'
      END
  );
  PERFORM pg_notify('axiomdb_changes', payload::text);
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS listings_notify_change ON listings;
CREATE TRIGGER listings_notify_change
AFTER INSERT OR UPDATE OR DELETE ON listings
FOR EACH ROW EXECUTE FUNCTION axiomdb_notify_change();
