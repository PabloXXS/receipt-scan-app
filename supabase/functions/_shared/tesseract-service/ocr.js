const tesseract = require('node-tesseract-ocr');
const axios = require('axios');
const { preprocessImage } = require('./preprocessor');
const fs = require('fs').promises;
const path = require('path');
const { createWriteStream } = require('fs');
const { pipeline } = require('stream/promises');

/**
 * Загружает изображение по URL и сохраняет во временный файл
 */
async function downloadImage(url) {
  const tempDir = '/tmp';
  const fileName = `receipt_${Date.now()}_${Math.random().toString(36).substring(7)}.jpg`;
  const filePath = path.join(tempDir, fileName);

  console.log(`[DOWNLOAD] Fetching image from URL...`);

  const response = await axios({
    method: 'get',
    url: url,
    responseType: 'stream',
    timeout: 30000,
  });

  await pipeline(response.data, createWriteStream(filePath));

  console.log(`[DOWNLOAD] Image saved to ${filePath}`);

  return filePath;
}

/**
 * Удаляет временный файл
 */
async function cleanupFile(filePath) {
  try {
    await fs.unlink(filePath);
    console.log(`[CLEANUP] Deleted ${filePath}`);
  } catch (error) {
    console.warn(`[CLEANUP] Failed to delete ${filePath}:`, error.message);
  }
}

/**
 * Выполняет OCR распознавание
 */
async function performOcr({ imageUrl, language, psm, preprocess }) {
  let originalPath = null;
  let processedPath = null;

  try {
    // Скачиваем изображение
    originalPath = await downloadImage(imageUrl);

    // Предобработка изображения (опционально)
    if (preprocess) {
      console.log(`[PREPROCESS] Applying image preprocessing...`);
      processedPath = await preprocessImage(originalPath);
    }

    const imagePath = processedPath || originalPath;

    // Конфигурация Tesseract
    const config = {
      lang: language,
      oem: 3, // LSTM OCR Engine mode (наиболее точный)
      psm: psm, // Page segmentation mode
    };

    console.log(`[TESSERACT] Running OCR with config:`, config);

    // Выполняем OCR
    const text = await tesseract.recognize(imagePath, config);

    // Вычисляем примерную уверенность на основе качества текста
    const confidence = calculateConfidence(text);

    return {
      text: text.trim(),
      confidence,
    };
  } finally {
    // Очищаем временные файлы
    if (originalPath) await cleanupFile(originalPath);
    if (processedPath && processedPath !== originalPath) {
      await cleanupFile(processedPath);
    }
  }
}

/**
 * Вычисляет примерную уверенность распознавания
 * на основе эвристик качества текста
 */
function calculateConfidence(text) {
  if (!text || text.length < 10) return 0;

  let score = 100;

  // Штрафы за подозрительные паттерны
  const lines = text.split('\n').filter(l => l.trim());
  const totalChars = text.replace(/\s/g, '').length;

  // Слишком мало строк
  if (lines.length < 5) score -= 20;

  // Слишком много спецсимволов
  const specialChars = (text.match(/[^a-zA-Zа-яА-ЯёЁ0-9\s.,:\-\/()]/g) || []).length;
  const specialRatio = specialChars / totalChars;
  if (specialRatio > 0.15) score -= 30;

  // Слишком короткие строки (в среднем)
  const avgLineLength = totalChars / lines.length;
  if (avgLineLength < 5) score -= 20;

  // Слишком много одиночных символов
  const singleCharLines = lines.filter(l => l.trim().length === 1).length;
  if (singleCharLines > lines.length * 0.3) score -= 25;

  // Проверка на наличие цифр (чеки всегда содержат цифры)
  const hasNumbers = /\d/.test(text);
  if (!hasNumbers) score -= 30;

  // Проверка на наличие характерных слов для чеков
  const receiptKeywords = [
    'итого', 'итог', 'сумма', 'total', 'кассир', 'касса',
    'инн', 'чек', 'оплат', 'карт', 'наличн', 'руб',
  ];
  const hasKeywords = receiptKeywords.some(kw =>
    text.toLowerCase().includes(kw)
  );
  if (hasKeywords) score += 10;

  return Math.max(0, Math.min(100, score));
}

module.exports = {
  performOcr,
};

