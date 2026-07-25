import { ApiError } from './errors.js';

export function requireAdmin(req) {
  const key = req.headers['x-admin-key'] || req.headers['authorization']?.replace('Bearer ', '');
  if (!key || key !== process.env.ADMIN_KEY) {
    throw new ApiError(403, 'Unauthorized');
  }
}
