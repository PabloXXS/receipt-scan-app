// Клиент для вызова Tesseract OCR сервиса из Edge Functions

type TesseractRequest = {
  image_url: string;
  language?: string;
  psm?: number;
  preprocess?: boolean;
};

type TesseractResponse = {
  text: string;
  confidence: number;
  processing_time_ms: number;
  lines_count: number;
};

/**
 * Вызов Tesseract OCR сервиса с retry логикой
 */
export async function callTesseractOcr(
  imageUrl: string,
  options: {
    language?: string;
    psm?: number;
    preprocess?: boolean;
    retries?: number;
    timeout?: number;
  } = {}
): Promise<{ text: string; confidence: number }> {
  const TESSERACT_URL =
    Deno.env.get("TESSERACT_OCR_URL") || "http://localhost:3000";

  const {
    language = "rus+eng",
    psm = 6,
    preprocess = true,
    retries = 3,
    timeout = 30000,
  } = options;

  console.log(`[TESSERACT] Calling Tesseract OCR service at ${TESSERACT_URL}`);
  console.log(
    `[TESSERACT] Config: language=${language}, psm=${psm}, preprocess=${preprocess}`
  );

  const request: TesseractRequest = {
    image_url: imageUrl,
    language,
    psm,
    preprocess,
  };

  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      console.log(`[TESSERACT] Attempt ${attempt}/${retries}`);

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeout);

      const response = await fetch(`${TESSERACT_URL}/ocr`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(request),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Tesseract API error ${response.status}: ${errorText}`);
      }

      const result: TesseractResponse = await response.json();

      console.log(`[TESSERACT] Success!`);
      console.log(`[TESSERACT] Text length: ${result.text.length} chars`);
      console.log(`[TESSERACT] Lines: ${result.lines_count}`);
      console.log(`[TESSERACT] Confidence: ${result.confidence}%`);
      console.log(
        `[TESSERACT] Processing time: ${result.processing_time_ms}ms`
      );

      return {
        text: result.text,
        confidence: result.confidence,
      };
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      console.warn(
        `[TESSERACT] Attempt ${attempt} failed: ${lastError.message}`
      );

      if (attempt < retries) {
        const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000);
        console.log(`[TESSERACT] Retrying in ${delay}ms...`);
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError || new Error("Tesseract OCR failed after all retries");
}

/**
 * Проверка доступности Tesseract сервиса
 */
export async function checkTesseractHealth(): Promise<boolean> {
  const TESSERACT_URL =
    Deno.env.get("TESSERACT_OCR_URL") || "http://localhost:3000";

  try {
    const response = await fetch(`${TESSERACT_URL}/health`, {
      method: "GET",
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return false;

    const data = await response.json();
    console.log(`[TESSERACT] Health check:`, data);

    return data.status === "healthy";
  } catch (error) {
    console.error(`[TESSERACT] Health check failed:`, error);
    return false;
  }
}
