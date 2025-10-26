// Supabase Edge Function: analyze
// Контракт: POST { file_id: uuid, force?: boolean } → { receipt_id: uuid, status: 'processing' }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import OpenAI from "https://esm.sh/openai@4";
import {
  callTesseractOcr,
  checkTesseractHealth,
} from "../_shared/tesseract-client.ts";

type AnalyzeRequest = { file_id?: string; url?: string; force?: boolean };

type AiItem = { name: string; qty?: number; price?: number };
type AiResult = {
  store?: string;
  date?: string; // YYYY-MM-DD
  time?: string; // HH:mm:ss
  currency?: string; // e.g., RUB
  total?: number;
  items?: AiItem[];
  store_confidence?: number; // 0-1, уверенность в определении названия магазина
};

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
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OCR_SPACE_API_KEY = Deno.env.get("OCR_SPACE_API_KEY") ?? "";
const TESSERACT_OCR_URL = Deno.env.get("TESSERACT_OCR_URL") ?? "";
const AI_PROVIDER = Deno.env.get("AI_PROVIDER") ?? "openai";

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

function internalError(message: string, hint?: unknown) {
  return json({ error: message, hint }, { status: 500 });
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
}

async function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  let timer: number | undefined;
  return new Promise<T>((resolve, reject) => {
    timer = setTimeout(
      () => reject(new Error("timeout")),
      ms
    ) as unknown as number;
    promise
      .then((v) => resolve(v))
      .catch((e) => reject(e))
      .finally(() => clearTimeout(timer));
  });
}

async function fetchWithRetry<T>(
  task: () => Promise<T>,
  attempts = 3,
  baseDelayMs = 500
): Promise<T> {
  let lastErr: unknown = null;
  for (let i = 0; i < attempts; i++) {
    try {
      return await withTimeout(task(), 30_000);
    } catch (e) {
      lastErr = e;
      // exponential backoff with jitter
      const jitter = Math.floor(Math.random() * 200);
      const delay = baseDelayMs * Math.pow(2, i) + jitter;
      await sleep(delay);
    }
  }
  throw lastErr ?? new Error("retry failed");
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

function getAdminClient() {
  return createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function sanitizeItemName(name: string | null | undefined): string {
  let s = (name ?? "").replace(/\s+/g, " ").trim();
  if (!s) return "";
  // Drop leading value triplet like: "3.55 *1.000 3.55 ..."
  s = s.replace(
    /^(?:[\d\s,.]+)\s*[x×\*]\s*(?:[\d\s,.]+)\s+(?:[\d\s,.]+)\s*/i,
    ""
  );
  // Drop markers like [M]
  s = s.replace(/^\[[^\]]+\]\s*/i, "");
  // Drop leading long numeric codes (barcodes/article), e.g. 4810268034770 or 000695182
  s = s.replace(/^(?:\d[\d\s-]{5,})\s+/i, "");
  // Drop trailing long numeric codes at the end if present
  s = s.replace(/\s+(?:\d[\d\s-]{5,})\s*$/i, "");
  // Drop prefixes like EAN:, GTIN:, UPC:
  s = s.replace(/^(?:ean|gtin|upc)[:\s-]*/i, "");
  // Normalize spaces and commas
  s = s
    .replace(/\s{2,}/g, " ")
    .replace(/\s+,/g, ", ")
    .trim();
  return s;
}

function isOwnedPathByUser(path: string, userId: string): boolean {
  // Ожидаемый формат: `${userId}/yyyy/mm/<uuid>.<ext>`
  return path?.startsWith(`${userId}/`);
}

async function getSignedImageUrl(
  admin: ReturnType<typeof createClient>,
  bucket: string,
  path: string
): Promise<string> {
  const { data, error } = await admin.storage
    .from(bucket)
    .createSignedUrl(path, 60 * 60);
  if (error || !data?.signedUrl)
    throw new Error(`Signed URL error: ${error?.message}`);
  return data.signedUrl;
}

function buildReceiptJsonSchema() {
  return {
    name: "receipt_schema",
    schema: {
      type: "object",
      additionalProperties: false,
      properties: {
        store: { type: ["string", "null"] },
        store_confidence: {
          type: ["number", "null"],
          minimum: 0,
          maximum: 1,
          description: "Уверенность в определении названия магазина (0-1)",
        },
        date: {
          type: ["string", "null"],
          pattern: "^\\d{4}-\\d{2}-\\d{2}$",
          description: "YYYY-MM-DD",
        },
        time: {
          type: ["string", "null"],
          pattern: "^\\d{2}:\\d{2}(:\\d{2})?$",
          description: "HH:mm[:ss]",
        },
        currency: { type: ["string", "null"] },
        total: { type: ["number", "null"] },
        items: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            properties: {
              name: { type: ["string", "null"] },
              qty: { type: ["number", "null"] },
              price: { type: ["number", "null"] },
            },
            required: ["name"],
          },
        },
      },
      required: ["items"],
    },
    strict: true,
  } as const;
}

function detectCurrencyFromText(lines: string[]): string | undefined {
  const text = lines.join(" \n ").toLowerCase();
  // Strong matches: ISO codes and symbols
  const patterns: Array<{ code: string; regex: RegExp }> = [
    { code: "BYN", regex: /\bby[nr]\b|\bby[n]\b|\bbyr\b|\sbr\b|бел\.?\s*руб/ },
    { code: "RUB", regex: /₽|\bруб\.?\b|\brur\b|\brub\b|\br\b/ },
    { code: "KZT", regex: /₸|\bkzt\b|\bтг\b/ },
    { code: "UAH", regex: /₴|\buah\b|грн|грив/ },
    { code: "UZS", regex: /\buzs\b|сум/ },
    { code: "KGS", regex: /\bkgs\b|сом\b/ },
    { code: "PLN", regex: /zł|\bpln\b|зл\b/ },
    { code: "EUR", regex: /€|\beur\b|евро/ },
    { code: "USD", regex: /\$|\busd\b|долл|доллар/ },
    { code: "GBP", regex: /£|\bgbp\b|фунт/ },
    { code: "TRY", regex: /₺|\btry\b|лира/ },
    { code: "AED", regex: /د\.إ|\baed\b/ },
    { code: "INR", regex: /₹|\binr\b/ },
    { code: "JPY", regex: /¥|\bjpy\b|иена|йена/ },
    { code: "CNY", regex: /¥|\bcny\b|юань|元/ },
    { code: "GEL", regex: /₾|\bgel\b|лари/ },
    { code: "AMD", regex: /\bamd\b|դր|драм/ },
    { code: "AZN", regex: /₼|\bazn\b/ },
  ];
  for (const p of patterns) {
    if (p.regex.test(text)) {
      console.log(`[CURRENCY] Определена валюта: ${p.code}`);
      return p.code;
    }
  }
  console.log(`[CURRENCY] Валюта не определена, используется RUB по умолчанию`);
  return undefined;
}

async function callVisionLLM(imageUrl: string): Promise<AiResult> {
  if (!OPENAI_API_KEY) throw new Error("OPENAI_API_KEY is not set");
  const openai = new OpenAI({ apiKey: OPENAI_API_KEY });
  const prompt =
    `Извлеки из изображения чека строго JSON согласно схеме. ` +
    `Если поле отсутствует, верни null. Цены и qty как числа с точкой. ` +
    `НЕ включай в items служебные строки (адрес, ИНН/УНП/РНМ, кассир, ` +
    `дата/время, способ оплаты, итог/сумма, заголовки таблиц). ` +
    `Каждый item должен быть только товаром/услугой. ` +
    `Для store: ` +
    `1. Ищи название в ВЕРХНЕЙ части чека (шапка/заголовок) ` +
    `2. Извлекай основное название организации/магазина ` +
    `3. Игнорируй служебную информацию: адрес, ИНН, телефон, касса, терминал ` +
    `4. Если есть логотип с названием - используй его ` +
    `5. Убирай слова: "касса", "терминал", "чек", "документ", "счет" ` +
    `6. Оценивай уверенность в store_confidence (0-1) на основе четкости названия ` +
    `Примеры: "Магнит" вместо "Касса Магнит", "Пятерочка" вместо "Пятерочка ул. Ленина"`;

  const schema = buildReceiptJsonSchema();

  const run = () =>
    openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "Ты извлекаешь структуру чеков и отвечаешь только JSON по схеме.",
        },
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "image_url", image_url: { url: imageUrl } as any },
          ] as any,
        },
      ],
      temperature: 0,
      response_format: { type: "json_schema", json_schema: schema } as any,
    });

  const response = await fetchWithRetry(() => run());
  const content = response.choices?.[0]?.message?.content ?? "";
  console.log(`[LLM] Ответ от GPT:`, content);
  try {
    const parsed = JSON.parse(content) as AiResult;
    console.log(
      `[LLM] Распознано LLM - магазин: "${parsed.store}", уверенность: ${parsed.store_confidence}`
    );
    return parsed;
  } catch (_e) {
    // на случай, если модель вернула текст с обрамлением
    try {
      const jsonStart = content.indexOf("{");
      const jsonEnd = content.lastIndexOf("}");
      const jsonText =
        jsonStart >= 0 && jsonEnd >= 0
          ? content.slice(jsonStart, jsonEnd + 1)
          : content;
      return JSON.parse(jsonText) as AiResult;
    } catch (e2) {
      throw new Error("LLM returned non-JSON response");
    }
  }
}

async function callOcrSpace(imageUrl: string): Promise<AiResult> {
  if (!OCR_SPACE_API_KEY) throw new Error("OCR_SPACE_API_KEY is not set");
  const base64 = await fetchImageAsBase64(imageUrl);
  const form = new FormData();
  form.append("base64Image", `data:image/jpeg;base64,${base64}`);
  form.append("language", "rus");
  form.append("isOverlayRequired", "false");
  form.append("OCREngine", "2");
  form.append("detectOrientation", "true");
  form.append("scale", "true");
  const res = await fetchWithRetry(() =>
    fetch("https://api.ocr.space/parse/image", {
      method: "POST",
      headers: { apikey: OCR_SPACE_API_KEY },
      body: form,
    })
  );
  if (!res.ok) throw new Error(`OCR.space HTTP ${res.status}`);
  const json = await res.json();
  if (json?.IsErroredOnProcessing) {
    const msg = Array.isArray(json?.ErrorMessage)
      ? json.ErrorMessage.join("; ")
      : json?.ErrorMessage || json?.ErrorDetails || "OCR.space error";
    throw new Error(String(msg));
  }
  const text: string = json?.ParsedResults?.[0]?.ParsedText ?? "";
  console.log(`[OCR] Извлеченный текст:`, text.substring(0, 200) + "...");
  const result = parseReceiptFromText(text);
  console.log(`[OCR] Распознано OCR - магазин: "${result.store}"`);
  return result;
}

async function callTesseract(imageUrl: string): Promise<AiResult> {
  if (!TESSERACT_OCR_URL) throw new Error("TESSERACT_OCR_URL is not set");

  console.log(`[TESSERACT] Вызов Tesseract OCR сервиса`);

  const { text, confidence } = await callTesseractOcr(imageUrl, {
    language: "rus+eng",
    psm: 6,
    preprocess: true,
  });

  console.log(`[TESSERACT] Извлеченный текст:`, text.substring(0, 200) + "...");
  console.log(`[TESSERACT] Уверенность: ${confidence}%`);

  const result = parseReceiptFromText(text);
  console.log(`[TESSERACT] Распознано Tesseract - магазин: "${result.store}"`);

  return result;
}

async function fetchImageAsBase64(url: string): Promise<string> {
  const resp = await fetch(url);
  if (!resp.ok) throw new Error(`fetch image HTTP ${resp.status}`);
  const buf = new Uint8Array(await resp.arrayBuffer());
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < buf.length; i += chunkSize) {
    const chunk = buf.subarray(i, i + chunkSize);
    binary += String.fromCharCode(...chunk);
  }
  // deno-lint-ignore no-deprecated-deno-api
  return btoa(binary);
}

function parseReceiptFromText(text: string): AiResult {
  const lines = text
    .split(/\r?\n+/)
    .map((l: string) => l.trim())
    .filter((l: string) => l.length > 0);

  // currency detection
  let currency: string | undefined = detectCurrencyFromText(lines);

  // total detection (take the last reasonable total-like number)
  let total: number | undefined;
  for (let i = lines.length - 1; i >= 0; i--) {
    const l = lines[i];
    const m = l.match(
      /(?:итог|итого|итого к оплате|всего|сумма|total|sum|amount)[^\d]*([\d\s,.]+)/i
    );
    if (m) {
      const n = Number((m[1] || "").replace(/\s/g, "").replace(",", "."));
      if (isFinite(n) && n > 0) {
        total = n;
        break;
      }
    }
  }

  // date/time detection
  let date: string | undefined;
  let time: string | undefined;
  for (const l of lines) {
    const m1 = l.match(/(\d{2})[./-](\d{2})[./-](\d{4})/); // dd.MM.yyyy
    const m2 = l.match(/(\d{4})[./-](\d{2})[./-](\d{2})/); // yyyy-MM-dd
    if (!date && m1) {
      const dd = m1[1],
        mm = m1[2],
        yyyy = m1[3];
      date = `${yyyy}-${mm}-${dd}`;
    } else if (!date && m2) {
      const yyyy = m2[1],
        mm = m2[2],
        dd = m2[3];
      date = `${yyyy}-${mm}-${dd}`;
    }
    const t = l.match(/\b(\d{2}):(\d{2})(?::(\d{2}))?\b/);
    if (!time && t) {
      time = t[3] ? `${t[1]}:${t[2]}:${t[3]}` : `${t[1]}:${t[2]}`;
    }
  }

  const items: AiItem[] = [];
  const nameBuffer: string[] = [];
  const noisePatterns: RegExp[] = [
    /^(касс(ир|а|овый)|терминал|карта|банк(овск|\.)|оплат|код|rrn|авт\.|одобрено)/i,
    /^(инн|унп|огрн|рнм|рн скко|уи)\b/i,
    /^(итог|итого|всего|сумма|к оплате|че(к|к№)|платежный документ)/i,
    /^(г\.|ул\.|пр\.|просп\.|пл\.|дом|кв\.|город|улица|проспект)\b/i,
    /^[-=\u2500\u2501\u2502\u253c\u2550\s]+$/,
    /^(цена|кол-во|количество|итого|наименование)\b/i,
    /^\*+для клиента\*+$/i,
  ];
  for (const raw of lines) {
    const l = raw.replace(/[\t ]+/g, " ").trim();
    if (noisePatterns.some((re) => re.test(l))) {
      nameBuffer.length = 0;
      continue;
    }
    let m: RegExpMatchArray | null = null;
    // detect pattern: price * qty total  (name accumulated before)
    m = l.match(/^([\d\s,.]+)\s*[x×\*]\s*([\d\s,.]+)\s+([\d\s,.]+)\s*$/i);
    if (m && nameBuffer.length > 0) {
      let name = nameBuffer
        .join(" ")
        .replace(/\s{2,}/g, " ")
        .trim();
      name = sanitizeItemName(name);
      nameBuffer.length = 0;
      const price = Number(m[1].replace(/\s/g, "").replace(",", "."));
      const qty = Number(m[2].replace(/\s/g, "").replace(",", "."));
      if (name && isFinite(qty) && qty > 0 && isFinite(price) && price > 0) {
        items.push({ name, qty, price });
        continue;
      }
    }
    // pattern: "Название qty x price"
    m = l.match(/^(.*?)[\s]+([\d]+[\d\s,.]*)(?:\s*[x×\*]\s*)([\d\s,.]+)\s*$/i);
    if (m) {
      const name = sanitizeItemName(m[1].replace(/\s{2,}/g, " ").trim());
      const qty = Number(m[2].replace(/\s/g, "").replace(",", "."));
      const price = Number(m[3].replace(/\s/g, "").replace(",", "."));
      if (name && isFinite(qty) && qty > 0 && isFinite(price) && price > 0) {
        items.push({ name, qty, price });
        continue;
      }
    }
    // pattern: "Название ... по price" (qty=1)
    m = l.match(/^(.*?)(?:\s+по\s+)([\d\s,.]+)\s*$/i);
    if (m) {
      const name = sanitizeItemName(m[1].replace(/\s{2,}/g, " ").trim());
      const price = Number(m[2].replace(/\s/g, "").replace(",", "."));
      if (name && isFinite(price) && price > 0) {
        items.push({ name, qty: 1, price });
        continue;
      }
    }
    // pattern: weighted items "Название qty кг price"
    m = l.match(/^(.*?)[\s]+([\d\s,.]+)\s*(?:кг|kg)\b.*?([\d\s,.]+)\s*$/i);
    if (m) {
      const name = sanitizeItemName(m[1].replace(/\s{2,}/g, " ").trim());
      const qty = Number(m[2].replace(/\s/g, "").replace(",", "."));
      const price = Number(m[3].replace(/\s/g, "").replace(",", "."));
      if (name && isFinite(qty) && qty > 0 && isFinite(price) && price > 0) {
        items.push({ name, qty, price });
        continue;
      }
    }
    // fallback: name + price at end
    m = l.match(/^(.*?)[\s]+([\d]+[\d\s,.]*)$/);
    if (m) {
      const name = sanitizeItemName(m[1].replace(/\s{2,}/g, " ").trim());
      const price = Number(m[2].replace(/\s/g, "").replace(",", "."));
      if (name && isFinite(price) && price > 0) {
        items.push({ name, qty: 1, price });
        continue;
      }
    }
    // accumulate potential name lines for two-line item names
    if (!/^[-=\u2500\u2501\u2502\u253c\u2550\s]*$/.test(l)) {
      // skip pure separators
      nameBuffer.push(l);
      if (nameBuffer.length > 3) nameBuffer.shift();
    }
  }

  // Section-oriented extraction: if the receipt has many structured value lines,
  // prefer extracting ONLY from them (to avoid address/doc/header noise)
  const valueLineRe =
    /^(?:\s*)([\d\s,.]+)\s*[x×\*]\s*([\d\s,.]+)\s+([\d\s,.]+)\s*$/i;
  const structuredIndices: number[] = [];
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i].replace(/[\t ]+/g, " ").trim();
    if (valueLineRe.test(l)) structuredIndices.push(i);
  }
  const structuredItems: AiItem[] = [];
  if (structuredIndices.length >= 2) {
    // Build items using the preceding 1-2 lines as the name (skipping noise/barcodes)
    const isBarcode = (s: string) => /^(\[M\]\s*)?[\d\s]{6,}$/.test(s);
    for (const idx of structuredIndices) {
      const v = lines[idx].replace(/[\t ]+/g, " ").trim();
      const mm = v.match(valueLineRe)!;
      const price = Number(mm[1].replace(/\s/g, "").replace(",", "."));
      const qty = Number(mm[2].replace(/\s/g, "").replace(",", "."));
      let name = "";
      const c1 = idx - 1 >= 0 ? lines[idx - 1].trim() : "";
      const c2 = idx - 2 >= 0 ? lines[idx - 2].trim() : "";
      const c1ok =
        c1 && !noisePatterns.some((re) => re.test(c1)) && !isBarcode(c1);
      const c2ok =
        c2 && !noisePatterns.some((re) => re.test(c2)) && !isBarcode(c2);
      if (c1ok && c2ok) name = `${c2} ${c1}`.replace(/\s{2,}/g, " ").trim();
      else if (c1ok) name = c1;
      else if (c2ok) name = c2;
      name = sanitizeItemName(name);
      name = name.replace(/\s{2,}/g, " ").trim();
      if (name && isFinite(qty) && qty > 0 && isFinite(price) && price > 0) {
        structuredItems.push({ name, qty, price });
      }
    }
  }

  // If structured items exist, use them exclusively
  if (structuredItems.length >= 2) {
    return {
      currency: currency ?? "RUB",
      date,
      time,
      total,
      items: structuredItems,
    };
  }

  const result = {
    currency: currency ?? "RUB",
    date,
    time,
    total,
    items,
  };

  console.log(
    `[TEXT_PARSER] Распознано текстовым парсером - магазин: "${
      result.store || "не определен"
    }"`
  );

  return result;
}

function isSafeHttpUrl(url: string): boolean {
  try {
    const u = new URL(url);
    if (!u.protocol || (u.protocol !== "http:" && u.protocol !== "https:")) {
      return false;
    }
    if (u.hostname === "169.254.169.254") return false; // block cloud metadata
    return true;
  } catch {
    return false;
  }
}

async function fetchWebReceiptText(url: string): Promise<string> {
  const res = await fetchWithRetry(() => fetch(url, { method: "GET" }));
  if (!res.ok) throw new Error(`fetch url HTTP ${res.status}`);
  const contentType = res.headers.get("content-type") ?? "";
  if (contentType.includes("text/")) {
    const html = await res.text();
    // naive tag strip
    return html
      .replace(/<style[\s\S]*?<\/style>/gi, " ")
      .replace(/<script[\s\S]*?<\/script>/gi, " ")
      .replace(/<[^>]+>/g, "\n")
      .replace(/&nbsp;/g, " ")
      .replace(/&quot;/g, '"')
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">");
  }
  // fallback: if image/*, return special token to force LLM path later
  return await res.text();
}

async function processFromUrl(
  admin: ReturnType<typeof createClient>,
  userId: string,
  receiptId: string,
  url: string
): Promise<void> {
  try {
    if (!isSafeHttpUrl(url)) throw new Error("URL is not allowed");
    const text = await fetchWebReceiptText(url);
    // Heuristic: if looks like HTML cleaned text, try text parser first
    console.log(`[ANALYZE] Пробуем текстовый парсер для URL`);
    const aiText = parseReceiptFromText(text);
    const hasUseful = isResultUseful(aiText);
    const ai = hasUseful ? aiText : await callVisionLLM(url);

    if (!hasUseful) {
      console.log(
        `[ANALYZE] Текстовый парсер дал слабый результат, переключаемся на LLM`
      );
    } else {
      console.log(`[ANALYZE] Текстовый парсер дал хороший результат`);
    }
    const mapped = mapAiToDb(ai);

    // Логируем распознанное название магазина
    console.log(
      `[ANALYZE] Распознанное название магазина: "${mapped.store}" (уверенность: ${mapped.store_confidence})`
    );

    const { error: updErr } = await admin
      .from("receipts")
      .update({
        merchant_name: mapped.store,
        purchase_date: mapped.purchase_date,
        purchase_time: mapped.purchase_time,
        currency: mapped.currency,
        total: mapped.total ?? 0,
        store_confidence: mapped.store_confidence,
        status: "ready",
      })
      .eq("id", receiptId);
    if (updErr) throw updErr;

    if (mapped.items.length > 0) {
      // Присвоить категории товарам через ИИ
      const itemsWithCategories = await assignItemCategories(
        admin,
        mapped.items
      );

      const rows = itemsWithCategories.map((it) => ({
        receipt_id: receiptId,
        name: it.name,
        qty: it.qty,
        price: it.price,
        category_id: it.category_id,
      }));
      const { error: itemsErr } = await admin
        .from("receipt_items")
        .insert(rows);
      if (itemsErr) throw itemsErr;
    }
  } catch (e) {
    const message = getErrorMessage(e);
    await admin
      .from("receipts")
      .update({ status: "failed", error_text: message })
      .eq("id", receiptId);
  }
}

function coerceNumber(value: unknown): number | null {
  if (typeof value === "number" && isFinite(value)) return value;
  if (typeof value === "string") {
    const n = Number(value.replace(",", "."));
    return isFinite(n) ? n : null;
  }
  return null;
}

function normalizeMoney(
  value: number | null,
  fallback = 0,
  max = 1_000_000
): number {
  if (value === null || !isFinite(value)) return fallback;
  const rounded = Math.round(value * 100) / 100;
  if (rounded < 0 || rounded > max) return fallback;
  return rounded;
}

function normalizeQty(value: number | null, fallback = 1, max = 1000): number {
  if (value === null || !isFinite(value)) return fallback;
  const v = Math.round((value + Number.EPSILON) * 1000) / 1000;
  if (v <= 0 || v > max) return fallback;
  return v;
}

function mapAiToDb(ai: AiResult) {
  const rawTotal = coerceNumber(ai.total);
  const itemsRaw = (ai.items ?? []).map((it) => {
    const qty = normalizeQty(coerceNumber(it.qty));
    const price = normalizeMoney(coerceNumber(it.price));
    return { name: it.name?.trim() ?? "Item", qty, price };
  });
  // Ensure qty*price equals line total if pattern contains explicit total
  const items = itemsRaw
    .map((r) => ({ ...r, name: sanitizeItemName(r.name) }))
    .filter((r) => r.price > 0 && r.name.length > 0);
  // Доп. фильтр шума: убираем строки, похожие на служебные, даже если прошли ранее
  const serviceRe =
    /^(итог|итого|всего|сумма|к оплате|касс(ир|а)|терминал|банк|карта|оплат|код|rrn|авт\.|одобрено|платежный документ|наименование|кол-во|количество)\b/i;
  const addrRe =
    /^(г\.|ул\.|пр\.|просп\.|пл\.|дом|кв\.|город|улица|проспект)\b/i;
  const cleaned = items.filter(
    (r) => !serviceRe.test(r.name) && !addrRe.test(r.name)
  );
  const itemsSum = items.reduce((acc, r) => acc + r.qty * r.price, 0);
  const cleanedSum = cleaned.reduce((acc, r) => acc + r.qty * r.price, 0);
  let total = normalizeMoney(
    rawTotal,
    cleaned.length > 0 ? cleanedSum : itemsSum
  );
  // Если сильное расхождение — доверяем сумме позиций (динамический порог)
  if (
    items.length > 0 &&
    (total <= 0 || Math.abs(total - itemsSum) / Math.max(1, total) > 0.3)
  ) {
    total = normalizeMoney(itemsSum, 0);
  }

  // Название магазина берем из результата ИИ
  const store = ai.store?.trim() || null;
  const storeConfidence = ai.store_confidence ?? null;

  const result = {
    store,
    store_confidence: storeConfidence,
    purchase_date: ai.date ?? null,
    purchase_time: ai.time ?? null,
    currency: ai.currency ?? "RUB",
    total,
    items: cleaned,
  } as const;

  console.log(
    `[FINAL] Итоговый результат: магазин="${result.store}", уверенность=${result.store_confidence}, товаров=${result.items.length}, сумма=${result.total}`
  );

  return result;
}

function isResultUseful(ai: AiResult): boolean {
  const hasItems = Array.isArray(ai.items) && (ai.items?.length ?? 0) > 0;
  const total = coerceNumber(ai.total);
  const isUseful = hasItems || (total !== null && total > 0);

  console.log(
    `[QUALITY] Проверка качества результата: товары=${
      ai.items?.length || 0
    }, сумма=${total}, полезен=${isUseful}`
  );

  return isUseful;
}

async function assignItemCategories(
  admin: ReturnType<typeof createClient>,
  items: Array<{ name: string; qty: number; price: number }>
): Promise<
  Array<{
    name: string;
    qty: number;
    price: number;
    category_id: string | null;
  }>
> {
  if (!OPENAI_API_KEY || items.length === 0) {
    return items.map((it) => ({ ...it, category_id: null }));
  }

  try {
    // Получить все существующие категории товаров
    const { data: categories, error } = await admin
      .from("categories")
      .select("id, name")
      .eq("is_deleted", false);

    if (error || !categories || categories.length === 0) {
      console.log("[CATEGORIZE] Нет доступных категорий товаров");
      return items.map((it) => ({ ...it, category_id: null }));
    }

    console.log(
      `[CATEGORIZE] Найдено ${categories.length} категорий: ${categories
        .map((c) => c.name)
        .join(", ")}`
    );

    // Для каждого товара через OpenAI определить категорию
    const prompt = `Определи категорию для каждого товара из списка.
Доступные категории: ${categories.map((c) => c.name).join(", ")}.
Если подходящей категории нет, верни null для category_name.

Товары: ${items.map((it) => it.name).join(", ")}

Верни JSON массив с такой структурой:
[{ "name": "точное название товара", "category_name": "название категории или null" }]

ВАЖНО: name должен точно совпадать с названием товара из списка.`;

    const openai = new OpenAI({ apiKey: OPENAI_API_KEY });
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "Ты помогаешь категоризировать товары из чеков. Отвечай только валидным JSON.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0,
    });

    const content = response.choices?.[0]?.message?.content ?? "";
    console.log(`[CATEGORIZE] Ответ от GPT:`, content.substring(0, 500));

    let result: Array<{ name: string; category_name: string | null }>;
    try {
      result = JSON.parse(content);
    } catch (_e) {
      // Try to extract JSON from response
      const jsonStart = content.indexOf("[");
      const jsonEnd = content.lastIndexOf("]");
      if (jsonStart >= 0 && jsonEnd >= 0) {
        result = JSON.parse(content.slice(jsonStart, jsonEnd + 1));
      } else {
        throw new Error("Failed to parse categorization response");
      }
    }

    // Сопоставить результаты с товарами
    const itemsWithCategories = items.map((item) => {
      const match = result.find(
        (r) => r.name.toLowerCase() === item.name.toLowerCase()
      );
      const categoryName = match?.category_name;
      const category = categories.find(
        (c) => c.name.toLowerCase() === categoryName?.toLowerCase()
      );

      if (category) {
        console.log(
          `[CATEGORIZE] Товар "${item.name}" → категория "${category.name}"`
        );
      }

      return { ...item, category_id: category?.id || null };
    });

    return itemsWithCategories;
  } catch (e) {
    console.log(
      `[CATEGORIZE] Ошибка категоризации: ${getErrorMessage(e)}, пропускаем`
    );
    return items.map((it) => ({ ...it, category_id: null }));
  }
}

async function processInline(
  admin: ReturnType<typeof createClient>,
  userId: string,
  receiptId: string,
  bucket: string,
  path: string
): Promise<void> {
  try {
    const signed = await getSignedImageUrl(admin, bucket, path);
    let ai: AiResult;

    if (AI_PROVIDER === "tesseract") {
      // primary Tesseract → fallback to LLM
      console.log(`[ANALYZE] Используем Tesseract как основной метод`);
      try {
        ai = await callTesseract(signed);
        if (!isResultUseful(ai)) {
          console.log(
            `[ANALYZE] Tesseract дал слабый результат, переключаемся на LLM`
          );
          const ai2 = await callVisionLLM(signed);
          if (isResultUseful(ai2)) ai = ai2;
        }
      } catch (e) {
        console.log(
          `[ANALYZE] Tesseract ошибка: ${getErrorMessage(
            e
          )}, переключаемся на LLM`
        );
        ai = await callVisionLLM(signed);
      }
    } else if (AI_PROVIDER === "ocrspace") {
      // primary OCR.space → fallback to LLM when weak/no result
      console.log(`[ANALYZE] Используем OCR.space как основной метод`);
      try {
        ai = await callOcrSpace(signed);
        if (!isResultUseful(ai)) {
          console.log(
            `[ANALYZE] OCR дал слабый результат, переключаемся на LLM`
          );
          const ai2 = await callVisionLLM(signed);
          if (isResultUseful(ai2)) ai = ai2;
        }
      } catch (_e) {
        console.log(`[ANALYZE] OCR ошибка, переключаемся на LLM`);
        ai = await callVisionLLM(signed);
      }
    } else {
      // primary LLM → fallback to Tesseract/OCR when weak/no result
      console.log(`[ANALYZE] Используем LLM как основной метод`);
      try {
        ai = await callVisionLLM(signed);
        if (!isResultUseful(ai)) {
          console.log(
            `[ANALYZE] LLM дал слабый результат, переключаемся на Tesseract`
          );
          try {
            const ai2 = await callTesseract(signed);
            if (isResultUseful(ai2)) ai = ai2;
          } catch (e) {
            console.log(
              `[ANALYZE] Tesseract fallback ошибка, пробуем OCR.space`
            );
            const ai3 = await callOcrSpace(signed);
            if (isResultUseful(ai3)) ai = ai3;
          }
        }
      } catch (_e) {
        console.log(`[ANALYZE] LLM ошибка, переключаемся на Tesseract`);
        try {
          ai = await callTesseract(signed);
        } catch (e2) {
          console.log(`[ANALYZE] Tesseract fallback ошибка, пробуем OCR.space`);
          ai = await callOcrSpace(signed);
        }
      }
    }
    const mapped = mapAiToDb(ai);

    // Логируем распознанное название магазина
    console.log(
      `[ANALYZE] Распознанное название магазина: "${mapped.store}" (уверенность: ${mapped.store_confidence})`
    );

    const { error: updErr } = await admin
      .from("receipts")
      .update({
        merchant_name: mapped.store,
        purchase_date: mapped.purchase_date,
        purchase_time: mapped.purchase_time,
        currency: mapped.currency,
        total: mapped.total ?? 0,
        store_confidence: mapped.store_confidence,
        status: "ready",
      })
      .eq("id", receiptId);
    if (updErr) throw updErr;

    if (mapped.items.length > 0) {
      // Присвоить категории товарам через ИИ
      const itemsWithCategories = await assignItemCategories(
        admin,
        mapped.items
      );

      const rows = itemsWithCategories.map((it) => ({
        receipt_id: receiptId,
        name: it.name,
        qty: it.qty,
        price: it.price,
        category_id: it.category_id,
      }));
      const { error: itemsErr } = await admin
        .from("receipt_items")
        .insert(rows);
      if (itemsErr) throw itemsErr;
    }
  } catch (e) {
    const message = getErrorMessage(e);
    await admin
      .from("receipts")
      .update({ status: "failed", error_text: message })
      .eq("id", receiptId);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return badRequest("Use POST");

  const { user, supabaseUser } = await getUserClient(req);
  if (!user) return unauthorized();

  let payload: AnalyzeRequest;
  try {
    payload = (await req.json()) as AnalyzeRequest;
  } catch {
    return badRequest("Invalid JSON body");
  }
  if (!payload?.file_id && !payload?.url)
    return badRequest("file_id or url is required");
  if (payload.file_id && payload.url)
    return badRequest("provide only one of file_id or url");

  const admin = getAdminClient();

  // 1) Создаем запись чека в статусе processing
  const { data: receiptIns, error: recErr } = await admin
    .from("receipts")
    .insert({
      user_id: user.id,
      status: "processing",
      ...(payload.file_id ? { source_file_id: payload.file_id } : {}),
    })
    .select("id")
    .single();
  if (recErr || !receiptIns)
    return internalError("failed to create receipt", recErr);

  const receiptId = receiptIns.id as string;

  // 2) Обрабатываем чек inline (MVP) — без очередей
  if (payload.file_id) {
    const { data: fileRow, error: fileErr } = await admin
      .from("files")
      .select("id, bucket, path")
      .eq("id", payload.file_id)
      .single();
    if (fileErr || !fileRow) return badRequest("file not found");
    if (!isOwnedPathByUser(fileRow.path, user.id))
      return unauthorized("Not an owner of the file");
    await processInline(
      admin,
      user.id,
      receiptId,
      fileRow.bucket,
      fileRow.path
    );
  } else if (payload.url) {
    await processFromUrl(admin, user.id, receiptId, payload.url);
  }

  // Возвращаем контракт — статус processing (даже если уже готово)
  return json({ receipt_id: receiptId, status: "processing" });
});
