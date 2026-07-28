import { setCorsHeaders } from './cors.js';
import { handleApiError } from './errors.js';

export function jsonResponse(res, req, status, data) {
  setCorsHeaders(res, req.headers?.origin);
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 'no-store');
  return res.status(status).json(data);
}

export function successResponse(res, req, data, status = 200) {
  return jsonResponse(res, req, status, { success: true, data });
}

export function paginatedResponse(res, req, { data, total, page, limit }) {
  return jsonResponse(res, req, 200, {
    success: true,
    data,
    pagination: {
      total,
      page,
      limit,
      pages: Math.ceil(total / limit)
    }
  });
}

export async function handler(req, res, fn) {
  try {
    return await fn(req, res);
  } catch (err) {
    return handleApiError(res, err);
  }
}
