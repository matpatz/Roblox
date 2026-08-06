import crypto from 'crypto';
import { handler, successResponse } from '../../_lib/response.js';
import { handleOptions } from '../../_lib/cors.js';
import { getSupabase } from '../../_lib/supabase.js';
import { ApiError } from '../../_lib/errors.js';
import { extractIp, rateLimit, validateString } from '../../_lib/validate.js';

export const config = { runtime: 'nodejs' };

const DAILY_KEY_LIMIT = 2;
const HASH_RE = /^[a-zA-Z0-9]{64}$/;

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
  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req, { limit: 10, window: 60 });

  const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request');

  const hash = validateString(body.hash, 'hash', { min: 64, max: 64, pattern: HASH_RE });

  await verifyLinkvertise(hash);

  const ip = extractIp(req);
  const today = new Date().toISOString().slice(0, 10);
  const supabase = getSupabase();

  const { data: limitRows, error: limitError } = await supabase
    .from('user_limits')
    .select('keys_used')
    .eq('ip', ip)
    .eq('date', today);
  if (limitError) throw new ApiError(500, 'Failed to check daily limit');

  const keysUsed = (limitRows && limitRows[0]?.keys_used) || 0;
  if (keysUsed >= DAILY_KEY_LIMIT) {
    throw new ApiError(429, `Daily limit reached (${DAILY_KEY_LIMIT}/${DAILY_KEY_LIMIT} keys used today). Try again tomorrow.`);
  }

  const key = crypto.randomUUID().replace(/-/g, '').toUpperCase().slice(0, 32);
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const { error: insertError } = await supabase
    .from('keys')
    .insert({ key, expires_at: expiresAt, used: false, created_ip: ip });
  if (insertError) {
    console.error('Key insert failed:', insertError.message);
    throw new ApiError(500, 'Key storage failed, try again');
  }

  await supabase
    .from('user_limits')
    .upsert({ ip, date: today, keys_used: keysUsed + 1 }, { onConflict: 'ip,date' });

  return successResponse(res, req, {
    key,
    expires_at: expiresAt,
    keys_remaining: DAILY_KEY_LIMIT - keysUsed - 1
  });
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
