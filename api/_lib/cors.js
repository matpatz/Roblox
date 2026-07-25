const ALLOWED_ORIGINS = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map(s => s.trim())
  : [];

export function setCorsHeaders(res, origin) {
  if (ALLOWED_ORIGINS.length === 0) {
    res.setHeader('Access-Control-Allow-Origin', origin || 'https://roblox-alpha-murex.vercel.app');
  } else if (ALLOWED_ORIGINS.includes('*') || ALLOWED_ORIGINS.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin || ALLOWED_ORIGINS[0]);
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Admin-Key, X-Setup-Key');
  res.setHeader('Access-Control-Max-Age', '86400');
}

export function handleOptions(req, res) {
  setCorsHeaders(res, req.headers?.origin);
  return res.status(200).end();
}
