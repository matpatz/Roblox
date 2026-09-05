// @ts-nocheck
// Long-lived, streaming proxy to Pollinations + per-user chat history.
// Not a classic serverless function — it holds a stream open, so run on Fluid compute.
//
// GET ?type=config  → public supabase config for the client
// GET               → (auth) this user's history
// POST              → (auth) stream an assistant reply (SSE)
//
// Uses its own supabase project (NOT the roblox one):
// POLLINATIONS, POLLINATIONS_SUPABASE_URL,
// POLLINATIONS_SUPABASE_SERVICE_ROLE_KEY, POLLINATIONS_SUPABASE_ANON_KEY

import { compressToBase64, decompressFromBase64 } from 'lz-string';
import { createClient } from '@supabase/supabase-js';
import { handler, successResponse } from '../../_lib/response.js';
import { handleOptions } from '../../_lib/cors.js';
import { ApiError } from '../../_lib/errors.js';

export const config = { runtime: 'nodejs' };

const POLL_URL = 'https://gen.pollinations.ai/text';
const DEFAULT_MODEL = 'openai';
const CONTEXT = 20;
const MAX_MSG = 4000;

// Compress message content at rest with lz-string (base64 is ASCII-safe for
// TEXT columns / JSON). Old uncompressed rows stay readable because we only
// treat content as compressed when it starts with the marker.
const LZ = '~lz:';
function pack(content) {
  const c = compressToBase64(content);
  // Only keep it compressed if it actually shrank (tiny messages inflate in base64).
  return c && c.length + LZ.length < content.length ? LZ + c : content;
}
function unpack(content) {
  if (typeof content === 'string' && content.startsWith(LZ)) {
    const d = decompressFromBase64(content.slice(LZ.length));
    if (d !== null && d !== undefined) return d;
  }
  return content;
}

function parseBody(req) {
  if (typeof req.body !== 'string') return req.body || {};
  try {
    return JSON.parse(req.body);
  } catch {
    throw new ApiError(400, 'Invalid JSON');
  }
}

// Rate limiting backed by Vercel KV. @vercel/kv is imported lazily (and its
// failures swallowed) because it instantiates its client at import time and
// throws when the deployment has no KV linked — that would crash this whole
// function at module load. No KV available = no rate limiting, chat still works.
async function limit(key, { limit, window: secs }) {
  try {
    const { kv } = await import('@vercel/kv');
    const k = `poll:${key}:${Math.floor(Date.now() / (secs * 1000))}`;
    const count = await kv.incr(k);
    if (count === 1) await kv.expire(k, secs);
    if (count > limit) throw new ApiError(429, 'Too many requests');
  } catch (err) {
    if (err instanceof ApiError) throw err;
  }
}

function ip(req) {
  const fwd = req.headers?.['x-forwarded-for'];
  const raw = Array.isArray(fwd) ? fwd[0] : (fwd || '');
  const left = raw.split(',')[0].trim();
  return /^\d{1,3}(?:\.\d{1,3}){3}$/.test(left) ? left : 'unknown';
}

let client;
function db() {
  if (!client) {
    client = createClient(
      process.env.POLLINATIONS_SUPABASE_URL,
      process.env.POLLINATIONS_SUPABASE_SERVICE_ROLE_KEY,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );
  }
  return client;
}

async function getUser(req) {
  const token = (req.headers?.authorization || '').replace(/^Bearer\s+/i, '');
  if (!token) throw new ApiError(401, 'Sign in required');
  const { data, error } = await db().auth.getUser(token);
  if (error || !data?.user) throw new ApiError(401, 'Invalid or expired session');
  return data.user;
}

async function history(userId) {
  const { data, error } = await db()
    .from('chat_messages')
    .select('id, role, content, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: true })
    .limit(200);
  if (error) throw new ApiError(500, 'Failed to load history');
  return (data || []).map((m) => ({ ...m, content: unpack(m.content) }));
}

async function chat(req, res, userId) {
  const body = parseBody(req);
  const message = typeof body.message === 'string' ? body.message.trim() : '';
  if (!message) throw new ApiError(400, 'Message is required');
  if (message.length > MAX_MSG) throw new ApiError(400, 'Message too long');
  const model =
    typeof body.model === 'string' && /^[A-Za-z0-9._/:+-]{1,64}$/.test(body.model)
      ? body.model
      : DEFAULT_MODEL;
  const rawT = Number(body.temperature);
  const temperature = Number.isFinite(rawT) ? Math.min(2, Math.max(0, rawT)) : 0.7;

  // Only charge rate limits after the request is valid.
  await limit(`u:${userId}`, { limit: 20, window: 60 }); // msgs / minute
  await limit(`u:${userId}`, { limit: 400, window: 86400 }); // msgs / day

  const past = await history(userId);
  const messages = [
    { role: 'system', content: 'You are a helpful assistant.' },
    ...past.slice(-CONTEXT).map((m) => ({ role: m.role, content: m.content })),
    { role: 'user', content: message }
  ];

  const { error: saveErr } = await db()
    .from('chat_messages')
    .insert({ user_id: userId, role: 'user', content: pack(message), model });
  if (saveErr) throw new ApiError(500, 'Failed to save message');

  let up;
  try {
    up = await fetch(POLL_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.POLLINATIONS}`
      },
      body: JSON.stringify({ model, messages, stream: true, temperature })
    });
  } catch {
    throw new ApiError(502, 'Upstream request failed');
  }
  if (!up.ok) {
    console.error('Pollinations error', up.status, await up.text().catch(() => ''));
    throw new ApiError(502, `Upstream error (${up.status})`);
  }

  res.writeHead(200, {
    'Content-Type': 'text/event-stream; charset=utf-8',
    'Cache-Control': 'no-cache, no-transform',
    Connection: 'keep-alive',
    'X-Accel-Buffering': 'no'
  });

  const emit = (o) => res.write(`data: ${JSON.stringify(o)}\n\n`);
  let out = '';

  try {
    if (!up.body || !(up.headers.get('content-type') || '').includes('text/event-stream')) {
      out = (await up.text()) || '';
      if (out) emit({ content: out });
    } else {
      const reader = up.body.getReader();
      const dec = new TextDecoder();
      let buf = '';
      let done = false;
      while (!done) {
        const { value, done: end } = await reader.read();
        if (end) break;
        buf += dec.decode(value, { stream: true });
        let i;
        while (!done && (i = buf.indexOf('\n')) !== -1) {
          const line = buf.slice(0, i).replace(/\r$/, '');
          buf = buf.slice(i + 1);
          if (!line.startsWith('data:')) continue;
          const p = line.slice(5).trim();
          if (!p) continue;
          if (p === '[DONE]') {
            done = true;
            break;
          }
          let j;
          try {
            j = JSON.parse(p);
          } catch {
            continue;
          }
          const text = j?.choices?.[0]?.delta?.content ?? j?.choices?.[0]?.message?.content ?? j?.content;
          if (typeof text === 'string' && text) {
            out += text;
            emit({ content: text });
          }
        }
      }
    }
    res.write('data: [DONE]\n\n');
    res.end();
  } catch (err) {
    console.error('Stream failed:', err?.message || err);
    try {
      emit({ error: 'Stream failed' });
      res.end();
    } catch {}
  }

  if (out.trim()) {
    const { error } = await db()
      .from('chat_messages')
      .insert({ user_id: userId, role: 'assistant', content: pack(out.trim()), model });
    if (error) console.error('Failed to save reply:', error.message);
  }
}

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);

  if (req.method === 'GET') {
    if (req.query?.type === 'config') {
      await limit(`ip:${ip(req)}`, { limit: 60, window: 60 });
      return successResponse(res, req, {
        supabaseUrl: process.env.POLLINATIONS_SUPABASE_URL || '',
        supabaseAnonKey: process.env.POLLINATIONS_SUPABASE_ANON_KEY || '',
        defaultModel: DEFAULT_MODEL
      });
    }
    const user = await getUser(req);
    await limit(`h:${user.id}`, { limit: 120, window: 60 });
    return successResponse(res, req, await history(user.id));
  }

  if (req.method === 'POST') {
    const user = await getUser(req);
    await chat(req, res, user.id);
    return;
  }

  throw new ApiError(405, 'Method not allowed');
}

export default (req, res) => handler(req, res, handler_fn);
