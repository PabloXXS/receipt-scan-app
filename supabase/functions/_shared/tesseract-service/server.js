const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { performOcr } = require('./ocr');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    service: 'tesseract-ocr-api',
  });
});

// OCR endpoint
app.post('/ocr', async (req, res) => {
  const startTime = Date.now();

  try {
    const {
      image_url,
      language = 'rus+eng',
      psm = 6,
      preprocess = true,
    } = req.body;

    // Валидация
    if (!image_url) {
      return res.status(400).json({
        error: 'image_url is required',
      });
    }

    console.log(`[OCR] Processing: ${image_url.substring(0, 100)}...`);
    console.log(`[OCR] Language: ${language}, PSM: ${psm}, Preprocess: ${preprocess}`);

    // Выполнение OCR
    const result = await performOcr({
      imageUrl: image_url,
      language,
      psm,
      preprocess,
    });

    const processingTime = Date.now() - startTime;

    console.log(`[OCR] Success in ${processingTime}ms`);
    console.log(`[OCR] Text length: ${result.text.length} chars`);
    console.log(`[OCR] Confidence: ${result.confidence}%`);

    res.json({
      text: result.text,
      confidence: result.confidence,
      processing_time_ms: processingTime,
      lines_count: result.text.split('\n').filter(l => l.trim()).length,
    });
  } catch (error) {
    const processingTime = Date.now() - startTime;
    console.error('[OCR] Error:', error.message);
    console.error('[OCR] Stack:', error.stack);

    res.status(500).json({
      error: 'OCR processing failed',
      message: error.message,
      processing_time_ms: processingTime,
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    path: req.path,
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('[SERVER] Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[SERVER] Tesseract OCR API listening on port ${PORT}`);
  console.log(`[SERVER] Health check: http://localhost:${PORT}/health`);
  console.log(`[SERVER] OCR endpoint: POST http://localhost:${PORT}/ocr`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('[SERVER] SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('[SERVER] HTTP server closed');
    process.exit(0);
  });
});

