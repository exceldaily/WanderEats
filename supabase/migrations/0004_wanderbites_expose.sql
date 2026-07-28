-- WanderBites 0004: expose the wanderbites schema to PostgREST.
--
-- CRITICAL in this shared project: pgrst.db_schemas carries every sibling
-- app (public, storage, graphql_public, orbitstack, orbit_probe, gamespeak,
-- phaseforge, ...). We READ the live value and APPEND. If the current value
-- cannot be read, we refuse rather than risk overwriting it.

do $$
declare
  current_schemas text;
begin
  select split_part(unnest.s, '=', 2) into current_schemas
  from (
    select unnest(setconfig) as s
    from pg_db_role_setting drs
    join pg_roles r on r.oid = drs.setrole
    where r.rolname = 'authenticator'
  ) unnest
  where unnest.s like 'pgrst.db_schemas=%';

  if current_schemas is null or current_schemas = '' then
    raise exception 'refusing to write pgrst.db_schemas: current value unreadable';
  end if;

  if current_schemas not like '%wanderbites%' then
    execute format('alter role authenticator set pgrst.db_schemas = %L',
                   current_schemas || ', wanderbites');
  end if;
end $$;

notify pgrst, 'reload config';
