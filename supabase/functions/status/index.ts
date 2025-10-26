// Supabase Edge Function: status
// Контракт: GET /status?receipt_id=uuid → { receipt_id, status, error }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

function json(body: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(body), {
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...corsHeaders,
    },
    ...init,
  });
}

function badRequest(message: string) {
  return json({ error: message }, { status: 400 });
}

async function getUserClient(req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  const supabaseUser = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await supabaseUser.auth.getUser();
  if (error || !data?.user) return { user: null, supabaseUser } as const;
  return { user: data.user, supabaseUser } as const;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response(null, { headers: corsHeaders });
  if (req.method !== "GET") return badRequest("Use GET");

  const { user } = await getUserClient(req);
  if (!user) return json({ error: "Unauthorized" }, { status: 401 });

  const url = new URL(req.url);
  const receiptId = url.searchParams.get("receipt_id");
  if (!receiptId) return badRequest("receipt_id is required");

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: { Authorization: req.headers.get("Authorization") ?? "" },
    },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await supabase
    .from("receipts")
    .select("id, status, error_text")
    .eq("id", receiptId)
    .single();
  if (error || !data) return json({ error: "not found" }, { status: 404 });

  return json({
    receipt_id: data.id,
    status: data.status,
    error: data.error_text,
  });
});
