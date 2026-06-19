'use strict';

const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const PORT = parseInt(process.env.PORT || '8000', 10);
const PROMETHEUS_BASE_URL = process.env.PROMETHEUS_BASE_URL || '';
const TEMPO_BASE_URL = process.env.TEMPO_BASE_URL || '';
const LOG_LEVEL = (process.env.LOG_LEVEL || 'INFO').toUpperCase();

const app = express();

function log(level, message) {
  const levels = { DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3 };
  if ((levels[level] || 0) >= (levels[LOG_LEVEL] || 1)) {
    console.log(JSON.stringify({ time: new Date().toISOString(), level, message }));
  }
}

app.get('/healthz', (_req, res) => {
  res.json({ status: 'ok' });
});

if (PROMETHEUS_BASE_URL) {
  app.use(
    '/prometheus',
    createProxyMiddleware({
      target: PROMETHEUS_BASE_URL,
      changeOrigin: true,
      pathRewrite: { '^/prometheus': '' },
      on: {
        error: (err, _req, res) => {
          log('ERROR', `Prometheus proxy error: ${err.message}`);
          res.status(502).json({ error: 'Bad Gateway', detail: err.message });
        },
      },
    })
  );
  log('INFO', `Prometheus proxy enabled → ${PROMETHEUS_BASE_URL}`);
} else {
  app.use('/prometheus', (_req, res) => {
    res.status(503).json({ error: 'PROMETHEUS_BASE_URL not configured' });
  });
  log('WARN', 'PROMETHEUS_BASE_URL not set; /prometheus routes will return 503');
}

if (TEMPO_BASE_URL) {
  app.use(
    '/tempo',
    createProxyMiddleware({
      target: TEMPO_BASE_URL,
      changeOrigin: true,
      pathRewrite: { '^/tempo': '' },
      on: {
        error: (err, _req, res) => {
          log('ERROR', `Tempo proxy error: ${err.message}`);
          res.status(502).json({ error: 'Bad Gateway', detail: err.message });
        },
      },
    })
  );
  log('INFO', `Tempo proxy enabled → ${TEMPO_BASE_URL}`);
} else {
  app.use('/tempo', (_req, res) => {
    res.status(503).json({ error: 'TEMPO_BASE_URL not configured' });
  });
  log('WARN', 'TEMPO_BASE_URL not set; /tempo routes will return 503');
}

app.listen(PORT, () => {
  log('INFO', `argocd-otel-extension-api listening on port ${PORT}`);
});
