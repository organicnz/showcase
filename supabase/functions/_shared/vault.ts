// ==============================================================================
// Showcase App · Supabase Vault & Edge Secrets Client
//
// Provides secure access to secrets following the hierarchy:
// 1. Supabase Vault (PostgreSQL vault.decrypted_secrets via get_secret RPC)
// 2. Supabase Edge Function Secrets (Deno.env.get)
// 3. Optional local fallback
// ==============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Retrieves a secret securely from Supabase Vault with Edge Function secret fallback.
 *
 * @param name - The identifier of the secret (e.g., 'SUPABASE_SERVICE_ROLE_KEY', 'API_KEY')
 * @param fallback - Optional fallback value for local development
 * @returns The decrypted secret string or null if not found
 */
export async function getSecret(name: string, fallback?: string): Promise<string | null> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  // 1. Try querying Supabase Vault via RPC
  if (supabaseUrl && serviceRoleKey) {
    try {
      const supabase = createClient(supabaseUrl, serviceRoleKey);
      const { data, error } = await supabase.rpc("get_secret", { secret_name: name });

      if (!error && data) {
        return data as string;
      }
    } catch (_err) {
      // Vault RPC failed or unavailable, fallback to Edge Function environment
    }
  }

  // 2. Fallback to Supabase Edge Function Secrets (Deno.env)
  const envVal = Deno.env.get(name);
  if (envVal) {
    return envVal;
  }

  // 3. Optional fallback
  return fallback ?? null;
}
