import { ApiError } from './errors.js';

export function requireFields(body, fields) {
  const missing = fields.filter(f => body[f] === undefined || body[f] === null || body[f] === '');
  if (missing.length > 0) {
    throw new ApiError(400, `Missing required fields: ${missing.join(', ')}`);
  }
}

export function validateString(value, name, { min, max, pattern } = {}) {
  if (typeof value !== 'string') {
    throw new ApiError(400, `${name} must be a string`);
  }
  const trimmed = value.trim();
  if (min && trimmed.length < min) {
    throw new ApiError(400, `${name} must be at least ${min} characters`);
  }
  if (max && trimmed.length > max) {
    throw new ApiError(400, `${name} must be at most ${max} characters`);
  }
  if (pattern && !pattern.test(trimmed)) {
    throw new ApiError(400, `${name} has invalid format`);
  }
  return trimmed;
}

export function validateArray(value, name) {
  if (!Array.isArray(value)) {
    throw new ApiError(400, `${name} must be an array`);
  }
  return value;
}

export function parsePagination(query) {
  const page = Math.max(1, parseInt(query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit) || 20));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
}
