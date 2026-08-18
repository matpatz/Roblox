import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { ApiError } from '../_lib/errors.js';
import { rateLimit } from '../_lib/validate.js';
import { createPaste, getPaste } from '../_lib/pastefy.js';

export const config = { runtime: 'nodejs' };

const ID_RE = /^[a-zA-Z0-9_-]+$/;

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);

  if (req.method === 'GET') {
    await rateLimit(req, { limit: 30, window: 60 });
    const id = String(req.query?.id || '').trim();
    if (!id || !ID_RE.test(id)) throw new ApiError(400, 'Invalid paste id');
    const data = await getPaste(id);
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

  const paste = await createPaste(payload);
  return successResponse(res, req, paste, 201);
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
