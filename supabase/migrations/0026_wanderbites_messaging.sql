-- Private 1:1 messaging (Premium, 18+).
--
-- Every rule lives server-side in dm_denial(): the sender must be a confirmed
-- adult with the direct_messaging entitlement and a healthy account, the peer
-- must be a visible adult account, and no block may exist in either direction.
-- Age comes before premium so a minor is refused as age_restricted, never as
-- premium_required - the client maps these codes onto EntitlementDenial and a
-- minor must never be routed to a paywall over messaging.
--
-- Peer-side refusals (blocked, minor, suspended, deleted) all collapse into
-- one deliberately vague 'unavailable': whether someone blocked you or how old
-- they are is not the caller's business.
--
-- Clients cannot write any of these tables directly; all writes go through
-- SECURITY DEFINER RPCs. Reads are plain RLS selects so paging stays cheap.
--
-- Rollback: drop functions dm_denial, start_conversation, send_message,
-- conversation_messages, my_conversations, mark_conversation_read,
-- delete_message; drop tables conversation_reads, messages, conversations;
-- restore the 0001 notifications type check (without 'message').

create table wanderbites.conversations (
  id uuid primary key default gen_random_uuid(),
  -- Canonical ordering (a < b) makes the pair unique regardless of who
  -- started the conversation.
  member_a uuid not null references wanderbites.profiles(id) on delete cascade,
  member_b uuid not null references wanderbites.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz,
  check (member_a < member_b),
  unique (member_a, member_b)
);

create index conversations_member_a_idx
  on wanderbites.conversations (member_a, last_message_at desc);
create index conversations_member_b_idx
  on wanderbites.conversations (member_b, last_message_at desc);

create table wanderbites.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references wanderbites.conversations(id) on delete cascade,
  sender_id uuid not null references wanderbites.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index messages_conversation_idx
  on wanderbites.messages (conversation_id, created_at desc);

create table wanderbites.conversation_reads (
  conversation_id uuid not null
    references wanderbites.conversations(id) on delete cascade,
  user_id uuid not null references wanderbites.profiles(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

alter table wanderbites.conversations enable row level security;
alter table wanderbites.messages enable row level security;
alter table wanderbites.conversation_reads enable row level security;

create policy conversations_read_member on wanderbites.conversations
  for select using (auth.uid() in (member_a, member_b));

create policy messages_read_member on wanderbites.messages
  for select using (exists (
    select 1 from wanderbites.conversations c
    where c.id = conversation_id and auth.uid() in (c.member_a, c.member_b)
  ));

create policy reads_read_own on wanderbites.conversation_reads
  for select using (user_id = auth.uid());

grant select on wanderbites.conversations to authenticated;
grant select on wanderbites.messages to authenticated;
grant select on wanderbites.conversation_reads to authenticated;

-- Message notifications ride the existing notifications pipeline (including
-- the block-suppression trigger from 0022).
alter table wanderbites.notifications drop constraint notifications_type_check;
alter table wanderbites.notifications add constraint notifications_type_check
  check (type = any (array[
    'follow', 'rec_feedback', 'comment', 'like', 'list_invite', 'list_update',
    'badge', 'city_activity', 'taster_activity', 'saved_list_update', 'message'
  ]));

-- Why the caller cannot message p_peer right now, or null when they can.
-- Callable by clients so a profile screen can pick the right button state;
-- the same function guards every write, so lying to it achieves nothing.
create or replace function wanderbites.dm_denial(p_peer uuid)
returns text language plpgsql stable security definer
set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
begin
  if me is null then return 'not_signed_in'; end if;
  if p_peer is null or p_peer = me then return 'unavailable'; end if;
  if exists (select 1 from profiles
              where id = me and (is_suspended or deleted_at is not null)) then
    return 'account_restricted';
  end if;
  if not exists (select 1 from profile_private where user_id = me) then
    return 'age_unconfirmed';
  end if;
  if not is_adult(me) then return 'age_restricted'; end if;
  if not has_entitlement('direct_messaging') then return 'premium_required'; end if;
  if not exists (select 1 from profiles
                  where id = p_peer and deleted_at is null and not is_suspended) then
    return 'unavailable';
  end if;
  if is_blocked_between(me, p_peer) then return 'unavailable'; end if;
  if not is_adult(p_peer) then return 'unavailable'; end if;
  return null;
end $$;

create or replace function wanderbites.start_conversation(p_peer uuid)
returns uuid language plpgsql security definer
set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
  denial text;
  conv uuid;
begin
  denial := dm_denial(p_peer);
  if denial is not null then
    raise exception 'dm_denied:%', denial;
  end if;
  -- The no-op update makes RETURNING work for the already-exists case.
  insert into conversations (member_a, member_b)
  values (least(me, p_peer), greatest(me, p_peer))
  on conflict (member_a, member_b)
    do update set member_a = excluded.member_a
  returning id into conv;
  return conv;
end $$;

create or replace function wanderbites.send_message(p_conversation uuid, p_body text)
returns uuid language plpgsql security definer
set search_path = wanderbites as $$
declare
  me uuid := auth.uid();
  peer uuid;
  denial text;
  msg uuid;
begin
  select case when member_a = me then member_b
              when member_b = me then member_a end
    into peer
  from conversations where id = p_conversation;
  if peer is null then raise exception 'dm_denied:unavailable'; end if;
  denial := dm_denial(peer);
  if denial is not null then
    raise exception 'dm_denied:%', denial;
  end if;
  if p_body is null or length(btrim(p_body)) = 0 then
    raise exception 'dm_denied:empty';
  end if;

  insert into messages (conversation_id, sender_id, body)
  values (p_conversation, me, btrim(p_body))
  returning id into msg;

  update conversations set last_message_at = now() where id = p_conversation;

  -- Sending implies having read everything before it.
  insert into conversation_reads (conversation_id, user_id)
  values (p_conversation, me)
  on conflict (conversation_id, user_id) do update set last_read_at = now();

  -- One unread notification per sender at a time, not one per message: a
  -- twelve-message burst should not bury the recipient in twelve alerts.
  -- The 0021 trigger still suppresses this row if a block exists.
  insert into notifications (user_id, actor_id, type, payload)
  select peer, me, 'message', jsonb_build_object('conversation_id', p_conversation)
  where not exists (
    select 1 from notifications n
    where n.user_id = peer and n.actor_id = me
      and n.type = 'message' and n.read_at is null
  );

  return msg;
end $$;

-- Newest-first page of a conversation. Membership is re-checked here rather
-- than trusting the RLS select, because this function is the read path the
-- app actually uses.
create or replace function wanderbites.conversation_messages(
  p_conversation uuid,
  p_before timestamptz default null,
  p_limit integer default 50
)
returns table (id uuid, sender_id uuid, body text, created_at timestamptz)
language sql stable security definer
set search_path = wanderbites as $$
  select m.id, m.sender_id, m.body, m.created_at
  from messages m
  join conversations c on c.id = m.conversation_id
  where m.conversation_id = p_conversation
    and auth.uid() in (c.member_a, c.member_b)
    and m.deleted_at is null
    and (p_before is null or m.created_at < p_before)
  order by m.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

-- The inbox. Conversations with no messages yet are hidden (starting one and
-- never writing should leave no trace), as are peers who are blocked either
-- way or deleted.
create or replace function wanderbites.my_conversations()
returns table (
  id uuid,
  peer_id uuid,
  peer_username text,
  peer_display_name text,
  peer_avatar_url text,
  last_message_at timestamptz,
  last_message_body text,
  last_message_sender_id uuid,
  unread_count integer
)
language sql stable security definer
set search_path = wanderbites as $$
  select c.id,
         p.id,
         p.username,
         p.display_name,
         p.avatar_url,
         c.last_message_at,
         lm.body,
         lm.sender_id,
         (select count(*)::int from messages m
           where m.conversation_id = c.id
             and m.deleted_at is null
             and m.sender_id <> auth.uid()
             and m.created_at > coalesce(r.last_read_at, 'epoch'::timestamptz))
  from conversations c
  join profiles p
    on p.id = case when c.member_a = auth.uid() then c.member_b else c.member_a end
  left join conversation_reads r
    on r.conversation_id = c.id and r.user_id = auth.uid()
  left join lateral (
    select body, sender_id from messages m
    where m.conversation_id = c.id and m.deleted_at is null
    order by m.created_at desc limit 1
  ) lm on true
  where auth.uid() in (c.member_a, c.member_b)
    and c.last_message_at is not null
    and p.deleted_at is null
    and not is_blocked_between(auth.uid(), p.id)
  order by c.last_message_at desc;
$$;

create or replace function wanderbites.mark_conversation_read(p_conversation uuid)
returns void language plpgsql security definer
set search_path = wanderbites as $$
begin
  if not exists (select 1 from conversations c
                  where c.id = p_conversation
                    and auth.uid() in (c.member_a, c.member_b)) then
    return;
  end if;
  insert into conversation_reads (conversation_id, user_id)
  values (p_conversation, auth.uid())
  on conflict (conversation_id, user_id) do update set last_read_at = now();
  -- Clear the unread message notifications from this conversation's peer.
  update notifications n
  set read_at = now()
  from conversations c
  where c.id = p_conversation
    and n.user_id = auth.uid()
    and n.type = 'message'
    and n.read_at is null
    and n.actor_id in (c.member_a, c.member_b);
end $$;

-- Soft delete of your own message. The row survives for moderation and the
-- other side's reports; readers just stop seeing it.
create or replace function wanderbites.delete_message(p_message uuid)
returns void language sql security definer
set search_path = wanderbites as $$
  update messages
  set deleted_at = now()
  where id = p_message and sender_id = auth.uid() and deleted_at is null;
$$;

revoke all on function wanderbites.dm_denial(uuid) from public, anon;
revoke all on function wanderbites.start_conversation(uuid) from public, anon;
revoke all on function wanderbites.send_message(uuid, text) from public, anon;
revoke all on function wanderbites.conversation_messages(uuid, timestamptz, integer) from public, anon;
revoke all on function wanderbites.my_conversations() from public, anon;
revoke all on function wanderbites.mark_conversation_read(uuid) from public, anon;
revoke all on function wanderbites.delete_message(uuid) from public, anon;

grant execute on function wanderbites.dm_denial(uuid) to authenticated;
grant execute on function wanderbites.start_conversation(uuid) to authenticated;
grant execute on function wanderbites.send_message(uuid, text) to authenticated;
grant execute on function wanderbites.conversation_messages(uuid, timestamptz, integer) to authenticated;
grant execute on function wanderbites.my_conversations() to authenticated;
grant execute on function wanderbites.mark_conversation_read(uuid) to authenticated;
grant execute on function wanderbites.delete_message(uuid) to authenticated;
