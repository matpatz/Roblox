import { ApiError } from './errors.js';

const hits = new Map();

export function rateLimit(ip, { limit = 10, window = 60000 } = {}) {
  const now = Date.now();
  const entry = hits.get(ip);
  if (!entry || now - entry.start > window) {
    hits.set(ip, { start: now, count: 1 });
    return;
  }
  entry.count++;
  if (entry.count > limit) throw new ApiError(429, 'Too many requests');
  if (hits.size > 10000) hits.clear();
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
