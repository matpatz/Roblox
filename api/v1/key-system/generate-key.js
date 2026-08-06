import crypto from 'crypto';
import { handler, successResponse } from '../../_lib/response.js';
import { handleOptions } from '../../_lib/cors.js';
import { getSupabase } from '../../_lib/supabase.js';
import { ApiError } from '../../_lib/errors.js';
import { extractIp, rateLimit, validateString } from '../../_lib/validate.js';

export const config = { runtime: 'nodejs' };

const HASH_RE = /^[a-zA-Z0-9]{64}$/;
const KEY_RE = /^[A-Za-z0-9]{32}$/;

async function lookupKey(key, res, req, supabase) {
  const { data: rows, error } = await supabase
    .from('keys')
    .select('key, expires_at, used, created_at')
    .ilike('key', key)
    .limit(1);

  if (error) throw new ApiError(500, 'Key lookup failed, try again');

  const row = rows && rows[0];
  if (!row) {
    return successResponse(res, req, { status: 'not_found', message: 'Key not found' });
  }

  if (row.used) {
    return successResponse(res, req, { status: 'used', message: 'Key has already been used', ...row });
  }

  if (new Date(row.expires_at).getTime() < Date.now()) {
    return successResponse(res, req, { status: 'expired', message: 'Key has expired', ...row });
  }

  return successResponse(res, req, { status: 'valid', message: 'Key is valid', ...row });
}

async function verifyLinkvertise(hash) {
  const token = process.env.LINKVERTISE_TOKEN;
  if (!token) throw new ApiError(500, 'Server config missing');

  let response;
  try {
    response = await fetch(
      `https://publisher.linkvertise.com/api/v1/anti_bypassing?token=${encodeURIComponent(token)}&hash=${encodeURIComponent(hash)}`,
      {
        headers: {
          Accept: 'text/plain, application/json',
          'User-Agent': 'VoltexHub-Server/1.0'
        }
      }
    );
  } catch (err) {
    console.error('Linkvertise fetch error:', err);
    throw new ApiError(502, 'Ad verification failed, try again');
  }

  const text = (await response.text()).trim();
  let valid = text === '1' || /true/i.test(text);
  if (!valid) {
    try {
      const json = JSON.parse(text);
      valid = json === true || json?.status === true || json?.valid === true || json?.success === true;
    } catch (e) {
      console.log('Linkvertise response not JSON:', text);
    }
  }

  if (!valid) {
    console.log('Linkvertise rejected hash, status:', response.status, 'body:', text);
    throw new ApiError(403, 'Complete the ad properly (disable VPN/adblock)');
  }
}

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);

  const supabase = getSupabase();

  if (req.method === 'GET') {
    await rateLimit(req, { limit: 30, window: 60 });
    const key = validateString(req.query?.key, 'key', { min: 32, max: 32, pattern: KEY_RE });
    return lookupKey(key, res, req, supabase);
  }

  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req, { limit: 10, window: 60 });

  const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request');

  const hash = validateString(body.hash, 'hash', { min: 64, max: 64, pattern: HASH_RE });

  await verifyLinkvertise(hash);

  const ip = extractIp(req);

  const key = crypto.randomUUID().replace(/-/g, '').toUpperCase().slice(0, 32);
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const { error: insertError } = await supabase
    .from('keys')
    .insert({ key, expires_at: expiresAt, used: false, created_ip: ip });
  if (insertError) {
    console.error('Key insert failed:', insertError.message);
    throw new ApiError(500, 'Key storage failed, try again');
  }

  return successResponse(res, req, {
    key,
    expires_at: expiresAt
  });
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
