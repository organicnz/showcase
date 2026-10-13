import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  try {
    // 1. Purge old workflow_states beyond 30 days
    const { error: wsError } = await supabase
      .from("workflow_states")
      .delete()
      .lt("updated_at", new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());

    if (wsError) throw wsError;

    // 2. Deactivate obsolete records if needed
    const { error: videoError } = await supabase
      .from("videos")
      .update({ active: false })
      .lt("created_at", new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString())
      .eq("active", false);

    if (videoError) throw videoError;

    return new Response(
      JSON.stringify({ 
        status: "success", 
        message: "Daily cleanup completed" 
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Daily cleanup error:", error);
    return new Response(
      JSON.stringify({ status: "error", message: error.message }),
      { 
        status: 500,
        headers: { "Content-Type": "application/json" } 
      }
    );
  }
});