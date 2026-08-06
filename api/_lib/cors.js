const ALLOWED = ['https://roblox-alpha-murex.vercel.app'];

export function setCorsHeaders(res, origin) {
  if (ALLOWED.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Max-Age', '86400');
}

export function handleOptions(req, res) {
  setCorsHeaders(res, req.headers?.origin);
  return res.status(200).end();
}
