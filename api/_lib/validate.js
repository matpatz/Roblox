import { kv } from '@vercel/kv';
import { ApiError } from './errors.js';

const IP_RE = /^\d{1,3}(?:\.\d{1,3}){3}$/;

export function extractIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  const raw = Array.isArray(forwarded) ? forwarded[0] : (forwarded || '');
  const leftmost = raw.split(',')[0].trim();
  if (leftmost && IP_RE.test(leftmost)) return leftmost;

  const realIp = req.headers['x-real-ip'];
  if (realIp && IP_RE.test(realIp)) return realIp;

  const remote = req.socket?.remoteAddress || '';
  const cleaned = remote.replace(/^::ffff:/, '');
  if (cleaned && IP_RE.test(cleaned)) return cleaned;

  return 'unknown';
}

export async function rateLimit(req, { limit = 10, window = 60 } = {}) {
  const ip = extractIp(req);
  const bucket = Math.floor(Date.now() / (window * 1000));
  const key = `rl:${ip}:${bucket}`;

  const count = await kv.incr(key);
  if (count === 1) {
    await kv.expire(key, window);
  }
  if (count > limit) throw new ApiError(429, 'Too many requests');
}

export function requireFields(body, fields) {
  const missing = fields.filter(f => body[f] === undefined || body[f] === null || body[f] === '');
  if (missing.length > 0) {
    throw new ApiError(400, 'Missing required fields');
  }
}

export function validateString(value, name, { min, max, pattern } = {}) {
  if (typeof value !== 'string') {
    throw new ApiError(400, 'Invalid field');
  }
  const trimmed = value.trim();
  if (min && trimmed.length < min) {
    throw new ApiError(400, 'Field too short');
  }
  if (max && trimmed.length > max) {
    throw new ApiError(400, 'Field too long');
  }
  if (pattern && !pattern.test(trimmed)) {
    throw new ApiError(400, 'Invalid format');
  }
  return trimmed;
}

export function validateArray(value, name) {
  if (!Array.isArray(value)) {
    throw new ApiError(400, 'Invalid field');
  }
  return value;
}

export function parsePagination(query) {
  const page = Math.max(1, parseInt(query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit) || 20));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
}
