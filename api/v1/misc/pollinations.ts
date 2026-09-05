// @ts-nocheck
// Long-lived, streaming proxy to Pollinations + per-user conversations.
// Not a classic serverless function — it holds a stream open, run on Fluid compute.
//
// GET ?type=config   public supabase config for the client
// GET                 (auth) list this user's conversations
// GET ?conv=<id>      (auth) messages in one conversation
// POST                (auth) send a message (creates a conversation if none given)
// DELETE ?conv=<id>   (auth) delete a conversation and its messages
//
// Uses its own supabase project (NOT the roblox one):
// POLLINATIONS, POLLINATIONS_SUPABASE_URL,
// POLLINATIONS_SUPABASE_SERVICE_ROLE_KEY, POLLINATIONS_SUPABASE_ANON_KEY

import { createClient } from '@supabase/supabase-js';
import { handler, successResponse } from '../../_lib/response.js';
import { handleOptions } from '../../_lib/cors.js';
import { ApiError } from '../../_lib/errors.js';
import { gzipSync, gunzipSync } from 'node:zlib';

export const config = { runtime: 'nodejs' };

const POLL_URL = 'https://gen.pollinations.ai/text';
const DEFAULT_MODEL = 'openai';
const TITLE_MODEL = 'openai';
const CONTEXT = 20;
const MAX_MSG = 4000;

// Message `content` is compressed at rest with Node's built-in zlib (gzip → base64),
// stored in the TEXT column under a `~z:` marker. Short messages stay as-is so the
// column remains human-readable when skimming the DB.
const Z = '~z:';
// Legacy marker for rows written with lz-string — read-only so old chats still load.
const LZ = '~lz:';
function pack(content) {
  if (typeof content !== 'string' || !content) return content;
  const gz = gzipSync(Buffer.from(content, 'utf8'), { level: 9 }).toString('base64');
  return gz.length + Z.length < content.length ? Z + gz : content;
}

async function unpack(content) {
  if (typeof content !== 'string') return content;
  if (content.startsWith(Z)) {
    try {
      return gunzipSync(Buffer.from(content.slice(Z.length), 'base64')).toString('utf8');
    } catch {
      return content; // corrupt/undecodable — surface raw rather than fail the read
    }
  }
  if (content.startsWith(LZ)) {
    // Old lz-string rows (pre-zlib): decompress lazily so they stay readable.
    try {
      const m = await import('lz-string');
      const lib = m?.decompressFromBase64 ? m : m?.default;
      if (!lib) return content;
      const d = lib.decompressFromBase64(content.slice(LZ.length));
      return d !== null && d !== undefined ? d : content;
    } catch {
      return content;
    }
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

// KV-backed rate limiting; lazy import + swallowed failures so missing KV never breaks the chat.
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

async function listConversations(userId) {
  const { data, error } = await db()
    .from('conversations')
    .select('id, title, updated_at')
    .eq('user_id', userId)
    .order('updated_at', { ascending: false });
  if (error) throw new ApiError(500, 'Failed to load chats');
  return data || [];
}

async function findConversation(userId, convId) {
  const { data, error } = await db()
    .from('conversations')
    .select('id, title')
    .eq('id', convId)
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw new ApiError(500, 'Failed to load chat');
  return data || null;
}

async function messagesFor(convId) {
  const { data, error } = await db()
    .from('chat_messages')
    .select('id, role, content, created_at')
    .eq('conversation_id', convId)
    .order('created_at', { ascending: true })
    .limit(200);
  if (error) throw new ApiError(500, 'Failed to load messages');
  return Promise.all((data || []).map(async (m) => ({ ...m, content: await unpack(m.content) })));
}

async function deleteConversation(userId, convId) {
  const conv = await findConversation(userId, convId);
  if (!conv) throw new ApiError(404, 'Chat not found');
  await db().from('chat_messages').delete().eq('conversation_id', convId);
  const { error } = await db().from('conversations').delete().eq('id', convId);
  if (error) throw new ApiError(500, 'Delete failed');
}

async function generateTitle(text) {
  try {
    const r = await fetch(POLL_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.POLLINATIONS}`
      },
      body: JSON.stringify({
        model: TITLE_MODEL,
        messages: [
          { role: 'system', content: 'Write a short chat title, 2 to 5 words. No quotes, no period. Reply with only the title.' },
          { role: 'user', content: text }
        ],
        stream: false,
        temperature: 0.4
      })
    });
    if (!r.ok) return null;
    const raw = ((await r.text()) || '').trim();
    let title = raw;
    if (raw && (raw[0] === '{' || raw[0] === '[')) {
      try {
        const o = JSON.parse(raw);
        const c = o?.choices?.[0]?.message?.content ?? o?.content;
        if (typeof c === 'string') title = c;
      } catch {}
    }
    title = title.replace(/["'\n]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 60);
    return title || null;
  } catch {
    return null;
  }
}

async function createConversation(userId, firstMessage) {
  const generated = await generateTitle(firstMessage);
  const title = generated || firstMessage.slice(0, 40) || 'New chat';
  const { data, error } = await db()
    .from('conversations')
    .insert({ user_id: userId, title })
    .select('id, title')
    .single();
  if (error) throw new ApiError(500, 'Failed to create chat');
  return data;
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

  await limit(`u:${userId}`, { limit: 20, window: 60 });
  await limit(`u:${userId}`, { limit: 400, window: 86400 });

  // Resolve (or create) the conversation this message belongs to.
  let conv;
  const given = typeof body.conversation_id === 'string' ? body.conversation_id.trim() : '';
  if (given) {
    conv = await findConversation(userId, given);
    if (!conv) throw new ApiError(404, 'Chat not found');
  } else {
    conv = await createConversation(userId, message);
  }
  const convId = conv.id;

  const past = await messagesFor(convId);
  const upstream = [
    { role: 'system', content: 'You are a helpful assistant.' },
    ...past.slice(-CONTEXT).map((m) => ({ role: m.role, content: m.content })),
    { role: 'user', content: message }
  ];

  const { error: saveErr } = await db()
    .from('chat_messages')
    .insert({ user_id: userId, conversation_id: convId, role: 'user', content: await pack(message), model });
  if (saveErr) throw new ApiError(500, 'Failed to save message');
  await db().from('conversations').update({ updated_at: new Date().toISOString() }).eq('id', convId);

  let up;
  try {
    up = await fetch(POLL_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.POLLINATIONS}`
      },
      body: JSON.stringify({ model, messages: upstream, stream: true, temperature })
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
    emit({ conv: { id: convId, title: conv.title } });

    if (!up.body || !(up.headers.get('content-type') || '').includes('text/event-stream')) {
      // Non-streaming response: plain text, or a JSON completion to unpack.
      const t = ((await up.text()) || '').trim();
      let content = t;
      if (t && (t[0] === '{' || t[0] === '[')) {
        try {
          const o = JSON.parse(t);
          const c = o?.choices?.[0]?.message?.content ?? o?.choices?.[0]?.text ?? o?.content ?? o?.output_text;
          if (typeof c === 'string') content = c;
        } catch {}
      }
      out = content;
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
          // Tolerate OpenAI JSON deltas, JSON strings, or plain-text tokens.
          let text = null;
          try {
            const j = JSON.parse(p);
            if (typeof j === 'string') text = j;
            else
              text =
                j?.choices?.[0]?.delta?.content ??
                j?.choices?.[0]?.message?.content ??
                j?.choices?.[0]?.text ??
                j?.content ??
                j?.delta ??
                j?.text;
            if (typeof text !== 'string') text = null;
          } catch {
            text = p;
          }
          if (text && typeof text === 'string') {
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
      .insert({ user_id: userId, conversation_id: convId, role: 'assistant', content: await pack(out.trim()), model });
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
    await limit(`u:${user.id}`, { limit: 120, window: 60 });
    if (req.query?.conv) {
      const conv = await findConversation(user.id, req.query.conv);
      if (!conv) throw new ApiError(404, 'Chat not found');
      return successResponse(res, req, await messagesFor(req.query.conv));
    }
    return successResponse(res, req, await listConversations(user.id));
  }

  if (req.method === 'POST') {
    const user = await getUser(req);
    try {
      await chat(req, res, user.id);
    } catch (err) {
      if (err instanceof ApiError) throw err;
      console.error('Chat crashed:', err?.stack || err);
      throw new ApiError(500, `Chat failed: ${err?.message || err}`);
    }
    return;
  }

  if (req.method === 'DELETE') {
    const user = await getUser(req);
    if (!req.query?.conv) throw new ApiError(400, 'Missing chat id');
    await deleteConversation(user.id, req.query.conv);
    return successResponse(res, req, { deleted: true });
  }

  throw new ApiError(405, 'Method not allowed');
}

export default (req, res) => handler(req, res, handler_fn);
