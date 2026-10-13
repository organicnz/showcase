-- ==============================================================================
-- Showcase App · Migration: Enable Supabase Vault & RPC Secret Resolver
-- 
-- Sets up encrypted secret management using Supabase Vault extension and
-- exposes a secured RPC endpoint for Edge Functions and server processes.
-- ==============================================================================

-- 1. Enable Vault extension in vault schema
create extension if not exists vault with schema vault;

-- 2. Function to resolve decrypted secret by name (service_role only)
create or replace function public.get_secret(secret_name text)
returns text
language plpgsql
security definer
set search_path = vault, public
as $$
declare
  secret_val text;
begin
  select decrypted_secret into secret_val
  from vault.decrypted_secrets
  where name = secret_name
  limit 1;
  return secret_val;
end;
$$;

comment on function public.get_secret(text) is 
  'Securely resolves a decrypted secret from Supabase Vault. Restricted to service_role.';

-- 3. Strict security permissions: only service_role can access Vault secrets
revoke all on function public.get_secret(text) from public;
revoke all on function public.get_secret(text) from anon;
revoke all on function public.get_secret(text) from authenticated;
grant execute on function public.get_secret(text) to service_role;
