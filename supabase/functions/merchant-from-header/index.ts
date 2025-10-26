// Supabase Edge Function: merchant-from-header
// Контракт: POST { header_text: string[] } → { suggestions: Array<{id, name, confidence}> }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type MerchantSuggestion = {
  id: string;
  name: string;
  confidence: number;
};

type MerchantFromHeaderRequest = { header_text: string[] };

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY =
  Deno.env.get("SERVICE_ROLE_KEY") ??
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";

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

function unauthorized(message = "Unauthorized") {
  return json({ error: message }, { status: 401 });
}

function getAdminClient() {
  return createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function normalizeMerchantName(name: string): string {
  return (
    name
      .trim()
      // Убираем кавычки
      .replace(/^["']|["']$/g, "")
      // Нормализуем ООО, ИП и другие формы
      .replace(/\b(ооо|оао|зао|пао|ип|индивидуальный предприниматель)\b/gi, "")
      // Убираем лишние пробелы и знаки препинания
      .replace(/\s+/g, " ")
      .replace(/[.,;:!?]+$/, "")
      .trim()
      // Приводим к нижнему регистру для сравнения
      .toLowerCase()
  );
}

function calculateMerchantSimilarity(name1: string, name2: string): number {
  const norm1 = normalizeMerchantName(name1);
  const norm2 = normalizeMerchantName(name2);

  if (norm1 === norm2) return 1.0;

  // Простой алгоритм схожести на основе общих слов
  const words1 = norm1.split(/\s+/).filter((w) => w.length > 2);
  const words2 = norm2.split(/\s+/).filter((w) => w.length > 2);

  if (words1.length === 0 || words2.length === 0) return 0;

  const commonWords = words1.filter((w) => words2.includes(w));
  const similarity = (commonWords.length * 2) / (words1.length + words2.length);

  return similarity;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return badRequest("Method not allowed");
  }

  try {
    const { header_text }: MerchantFromHeaderRequest = await req.json();

    if (!header_text || !Array.isArray(header_text)) {
      return badRequest("header_text is required and must be an array");
    }

    const admin = getAdminClient();

    // Получаем все магазины
    const { data: merchants, error } = await admin
      .from("merchants")
      .select("id, name")
      .eq("is_deleted", false)
      .limit(100);

    if (error) throw error;

    // Вычисляем схожесть для каждой строки шапки
    const suggestions: MerchantSuggestion[] = [];

    for (const headerLine of header_text) {
      for (const merchant of merchants || []) {
        const similarity = calculateMerchantSimilarity(
          headerLine,
          merchant.name
        );
        if (similarity > 0.4) {
          // Более низкий порог для шапки чека
          suggestions.push({
            id: merchant.id,
            name: merchant.name,
            confidence: similarity,
          });
        }
      }
    }

    // Убираем дубликаты и сортируем по убыванию схожести
    const uniqueSuggestions = suggestions.reduce((acc, current) => {
      const existing = acc.find((item) => item.id === current.id);
      if (!existing || current.confidence > existing.confidence) {
        if (existing) {
          acc.splice(acc.indexOf(existing), 1);
        }
        acc.push(current);
      }
      return acc;
    }, [] as MerchantSuggestion[]);

    uniqueSuggestions.sort((a, b) => b.confidence - a.confidence);

    return json({
      suggestions: uniqueSuggestions.slice(0, 10), // Возвращаем топ-10
    });
  } catch (error) {
    console.error("Error in merchant-from-header:", error);
    return json({ error: "Internal server error" }, { status: 500 });
  }
});
