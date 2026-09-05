import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';

const API = '/api/v1/misc/pollinations';
const $ = (id) => document.getElementById(id);

const el = {
  authBox: $('authBox'), authView: $('authView'), chatView: $('chatView'),
  messages: $('messages'), input: $('input'), sendBtn: $('send'),
  chatMsg: $('chatMsg'), authMsg: $('authMsg'), form: $('authForm'),
  email: $('email'), password: $('password'), submit: $('authSubmit'),
  tabLogin: $('tabLogin'), tabSignup: $('tabSignup')
};

let supabase = null;
let session = null;
let busy = false;
let mode = 'login';

const setMsg = (node, text = '', error = false) => {
  node.textContent = text;
  node.classList.toggle('error', error && !!text);
};
const scrollBottom = () => (el.messages.scrollTop = el.messages.scrollHeight);
const authHeaders = () => (session ? { Authorization: `Bearer ${session.access_token}` } : {});

const setMode = (next) => {
  mode = next;
  el.tabLogin.classList.toggle('active', mode === 'login');
  el.tabSignup.classList.toggle('active', mode === 'signup');
  el.submit.textContent = mode === 'login' ? 'Log in' : 'Create account';
  setMsg(el.authMsg);
};

const renderAuth = () => {
  const authed = !!session;
  el.authView.classList.toggle('hidden', authed);
  el.chatView.classList.toggle('hidden', !authed);
  el.input.disabled = !authed;
  el.sendBtn.disabled = !authed;
  setMsg(el.chatMsg);

  el.authBox.innerHTML = '';
  if (!authed) return;

  const who = document.createElement('span');
  who.textContent = session.user?.email || 'Signed in';
  const out = document.createElement('button');
  out.type = 'button';
  out.textContent = 'Log out';
  out.onclick = () => supabase.auth.signOut();
  el.authBox.append(who, out);
};

const submitAuth = async (e) => {
  e.preventDefault();
  const email = el.email.value.trim();
  const password = el.password.value;
  if (!email || !password) return;

  el.submit.disabled = true;
  try {
    if (mode === 'signup') {
      const { data, error } = await supabase.auth.signUp({ email, password });
      if (error) throw error;
      if (!data.session) {
        setMsg(el.authMsg, 'Check your email for a confirmation link, then log in.');
        setMode('login');
        return;
      }
    } else {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
    }
    el.password.value = '';
  } catch (err) {
    setMsg(el.authMsg, err.message || 'Something went wrong', true);
  } finally {
    el.submit.disabled = false;
  }
};

const addMessage = (role, content) => {
  const text = document.createElement('div');
  text.textContent = content;
  const row = document.createElement('div');
  row.className = `row ${role}`;
  row.appendChild(text);
  el.messages.appendChild(row);
  return text;
};

const loadHistory = async () => {
  el.messages.innerHTML = '';
  try {
    const res = await fetch(API, { headers: authHeaders() });
    if (!res.ok) return;
    const list = (await res.json())?.data || [];
    if (!list.length) {
      const empty = document.createElement('div');
      empty.className = 'empty';
      empty.textContent = 'No messages yet.';
      el.messages.appendChild(empty);
      return;
    }
    list.forEach((m) => addMessage(m.role === 'assistant' ? 'assistant' : 'user', m.content || ''));
    scrollBottom();
  } catch {
    setMsg(el.chatMsg, 'Could not load history.', true);
  }
};

const readSSE = async (res, onData, onError) => {
  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buf = '';
  for (;;) {
    const { value, done } = await reader.read();
    if (done) break;
    buf += decoder.decode(value, { stream: true });
    let i;
    while ((i = buf.indexOf('\n')) !== -1) {
      const line = buf.slice(0, i).replace(/\r$/, '');
      buf = buf.slice(i + 1);
      if (!line.startsWith('data:')) continue;
      const payload = line.slice(5).trim();
      if (!payload || payload === '[DONE]') return;
      let obj;
      try {
        obj = JSON.parse(payload);
      } catch {
        continue;
      }
      if (obj.error) return onError(obj.error);
      if (obj.content) onData(obj.content);
    }
  }
};

const send = async () => {
  const text = el.input.value.trim();
  if (!text || busy || !session) return;

  busy = true;
  el.sendBtn.disabled = true;
  setMsg(el.chatMsg);

  addMessage('user', text);
  const assistantText = addMessage('assistant', '');
  assistantText.textContent = '…';
  el.input.value = '';
  el.input.style.height = 'auto';
  scrollBottom();

  let received = false;
  try {
    const res = await fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders() },
      body: JSON.stringify({ message: text })
    });
    if (!res.ok) {
      const json = await res.json().catch(() => null);
      throw new Error(json?.error?.message || 'Request failed');
    }
    await readSSE(
      res,
      (chunk) => {
        if (!received) assistantText.textContent = '';
        received = true;
        assistantText.textContent += chunk;
        scrollBottom();
      },
      (msg) => setMsg(el.chatMsg, msg, true)
    );
  } catch (err) {
    setMsg(el.chatMsg, err.message || 'Network error', true);
  } finally {
    if (!received) assistantText.textContent = '(no response)';
    busy = false;
    el.sendBtn.disabled = false;
    el.input.focus();
  }
};

const init = async () => {
  setMode('login');
  let cfg = {};
  try {
    cfg = (await (await fetch(`${API}?type=config`)).json())?.data || {};
  } catch {}

  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey) {
    setMsg(el.authMsg, 'Server missing POLLINATIONS_SUPABASE_* env vars.', true);
    el.authView.classList.remove('hidden');
    return;
  }

  supabase = createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
  session = (await supabase.auth.getSession()).data?.session || null;

  supabase.auth.onAuthStateChange((_e, next) => {
    session = next;
    renderAuth();
    if (next) loadHistory();
  });

  renderAuth();
  if (session) loadHistory();
};

el.tabLogin.onclick = () => setMode('login');
el.tabSignup.onclick = () => setMode('signup');
el.form.onsubmit = submitAuth;
el.sendBtn.onclick = send;
el.input.onkeydown = (e) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    send();
  }
};
el.input.oninput = () => {
  el.input.style.height = 'auto';
  el.input.style.height = Math.min(el.input.scrollHeight, 140) + 'px';
};

init();
