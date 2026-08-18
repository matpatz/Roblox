import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { ApiError } from '../_lib/errors.js';
import { rateLimit } from '../_lib/validate.js';

export const config = { runtime: 'nodejs' };

const PASTEFY_BASE = 'https://pastefy.app/api/v2/paste';
const ID_RE = /^[a-zA-Z0-9_-]+$/;

function authHeaders() {
  const token = process.env.PASTEFY_API_KEY;
  if (!token) throw new ApiError(500, 'Server config missing');
  return { Authorization: `Token ${token}` };
}

async function pastefyFetch(path, options = {}) {
  let response;
  try {
    response = await fetch(PASTEFY_BASE + path, {
      ...options,
      headers: {
        ...authHeaders(),
        ...(options.headers || {}),
      },
    });
  } catch (err) {
    console.error('Pastefy fetch error:', err);
    throw new ApiError(502, 'Pastefy is unreachable, try again');
  }

  let data = null;
  try { data = await response.json(); } catch (_) { /* non-JSON body */ }

  if (!response.ok) {
    const message =
      (data &&
        (data.message ||
          (data.error && data.error.message) ||
          (typeof data.error === 'string' && data.error))) ||
      `Pastefy error (${response.status})`;
    console.error('Pastefy rejected:', response.status, message);
    throw new ApiError(response.status >= 500 ? 502 : 400, message);
  }
  return data;
}

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);

  if (req.method === 'GET') {
    await rateLimit(req, { limit: 30, window: 60 });
    const id = String(req.query?.id || '').trim();
    if (!id || !ID_RE.test(id)) throw new ApiError(400, 'Invalid paste id');
    const data = await pastefyFetch('/' + encodeURIComponent(id));
    return successResponse(res, req, data);
  }

  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req, { limit: 10, window: 60 });

  const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request');

  const payload = {
    title: typeof body.title === 'string' ? body.title : '',
    content: typeof body.content === 'string' ? body.content : '',
    visibility: body.visibility || 'UNLISTED', // PUBLIC | UNLISTED | PRIVATE
    encrypted: Boolean(body.encrypted),
  };
  if (!payload.content) throw new ApiError(400, 'Content is required');

  const data = await pastefyFetch('', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const paste = data && data.paste;
  if (!paste || !paste.id) throw new ApiError(502, 'Unexpected Pastefy response');

  return successResponse(res, req, paste, 201);
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
