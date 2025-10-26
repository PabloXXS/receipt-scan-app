const sharp = require('sharp');
const path = require('path');

/**
 * Предобработка изображения для улучшения качества OCR
 */
async function preprocessImage(inputPath) {
  const outputPath = inputPath.replace(/(\.\w+)$/, '_processed$1');

  console.log(`[PREPROCESS] Input: ${inputPath}`);
  console.log(`[PREPROCESS] Output: ${outputPath}`);

  try {
    const image = sharp(inputPath);
    const metadata = await image.metadata();

    console.log(`[PREPROCESS] Original size: ${metadata.width}x${metadata.height}`);

    // Пайплайн обработки:
    // 1. Конвертация в grayscale (ч/б)
    // 2. Увеличение контраста
    // 3. Нормализация яркости
    // 4. Повышение резкости
    // 5. Бинаризация (threshold) для четкости текста

    await image
      .rotate() // Автоповорот по EXIF
      .grayscale() // Черно-белое изображение
      .normalize() // Нормализация яркости
      .sharpen() // Повышение резкости
      .threshold(128) // Бинаризация (черно-белое, порог 128)
      .toFile(outputPath);

    console.log(`[PREPROCESS] Processing complete`);

    return outputPath;
  } catch (error) {
    console.error(`[PREPROCESS] Error:`, error.message);
    // Если предобработка не удалась, возвращаем оригинал
    return inputPath;
  }
}

/**
 * Альтернативная агрессивная предобработка для плохих изображений
 */
async function preprocessImageAggressive(inputPath) {
  const outputPath = inputPath.replace(/(\.\w+)$/, '_aggressive$1');

  try {
    await sharp(inputPath)
      .rotate()
      .resize(null, 2000, { // Масштабирование по высоте
        kernel: sharp.kernel.lanczos3,
        withoutEnlargement: true,
      })
      .grayscale()
      .linear(1.5, -(128 * 1.5) + 128) // Увеличение контраста
      .normalize()
      .median(3) // Удаление шума (медианный фильтр)
      .sharpen(2)
      .threshold(140) // Более агрессивная бинаризация
      .toFile(outputPath);

    console.log(`[PREPROCESS] Aggressive processing complete`);

    return outputPath;
  } catch (error) {
    console.error(`[PREPROCESS] Aggressive error:`, error.message);
    return inputPath;
  }
}

module.exports = {
  preprocessImage,
  preprocessImageAggressive,
};

