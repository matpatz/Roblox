import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const API = '/api/v1/misc/pollinations';
const $ = (id) => document.getElementById(id);

const el = {
  authView:     $('authView'),
  chatView:     $('chatView'),
  messages:     $('messages'),
  emptyState:   $('emptyState'),
  input:        $('input'),
  sendBtn:      $('send'),
  modelSelect:  $('modelSelect'),
  chatMsg:      $('chatMsg'),
  authMsg:      $('authMsg'),
  form:         $('authForm'),
  email:        $('email'),
  password:     $('password'),
  submit:       $('authSubmit'),
  tabLogin:     $('tabLogin'),
  tabSignup:    $('tabSignup'),
  // sidebar
  sidebar:      $('sidebar'),
  newChatBtn:   $('newChatBtn'),
  historyList:  $('historyList'),
  accountBlock: $('accountBlock'),
  accountEmail: $('accountEmail'),
  accountAvatar:$('accountAvatar'),
  logoutBtn:    $('logoutBtn'),
};

let supabase = null;
let session  = null;
let busy     = false;
let mode     = 'login';
let MODELS   = []; // loaded from MODELS.json in init()

// [{ label, id }, ...] — first entry is the default model
const loadModels = async () => {
  try {
    const data = await (await fetch('MODELS.json')).json();
    if (Array.isArray(data)) return data;
  } catch {}
  return [{ label: 'GPT-5.4 Nano', id: 'openai' }]; // fallback if fetch fails
};

// ── helpers ──────────────────────────────────────────────
const setMsg = (node, text = '', error = false) => {
  node.textContent = text;
  node.classList.toggle('error', error && !!text);
};

const scrollBottom = () => {
  el.messages.scrollTop = el.messages.scrollHeight;
};

const authHeaders = () =>
  session ? { Authorization: `Bearer ${session.access_token}` } : {};

// ── auth mode ────────────────────────────────────────────
const setMode = (next) => {
  mode = next;
  el.tabLogin.classList.toggle('active',  mode === 'login');
  el.tabSignup.classList.toggle('active', mode === 'signup');
  el.submit.textContent = mode === 'login' ? 'Log in' : 'Create account';
  setMsg(el.authMsg);
};

// ── render layout based on auth ──────────────────────────
const renderAuth = () => {
  const authed = !!session;
  el.authView.classList.toggle('hidden', authed);
  el.chatView.classList.toggle('hidden', !authed);
  el.sidebar.classList.toggle('hidden', !authed);
  el.input.disabled   = !authed;
  el.sendBtn.disabled = !authed;
  el.modelSelect.disabled = !authed;
  setMsg(el.chatMsg);

  if (authed) {
    const email = session.user?.email || 'Signed in';
    el.accountEmail.textContent  = email;
    el.accountAvatar.textContent = email[0].toUpperCase();
    el.accountBlock.classList.remove('hidden');
  } else {
    el.accountBlock.classList.add('hidden');
  }
};

// ── sidebar history ──────────────────────────────────────
const addHistoryItem = (label, active = false) => {
  // Remove empty-state placeholder text if present
  const placeholder = el.historyList.querySelector('.history-placeholder');
  if (placeholder) placeholder.remove();

  const item = document.createElement('div');
  item.className = 'history-item' + (active ? ' active' : '');
  item.textContent = label;
  el.historyList.prepend(item);
  return item;
};

// ── submit auth ──────────────────────────────────────────
const submitAuth = async (e) => {
  e.preventDefault();
  const email    = el.email.value.trim();
  const password = el.password.value;
  if (!email || !password) return;

  // supabase is created asynchronously in init(); config failure or a fast
  // submit leaves it null until then.
  if (!supabase) {
    setMsg(el.authMsg, 'Still connecting — try again in a moment.', true);
    return;
  }

  el.submit.disabled = true;
  try {
    if (mode === 'signup') {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: { emailRedirectTo: `${window.location.origin}/pollinations` }
      });
      if (error) throw error;
      if (!data.session) {
        setMode('login');
        setMsg(el.authMsg,
          `Account created. Check your inbox for a confirmation link before logging in.`
        );
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

// ── messages ─────────────────────────────────────────────
const addMessage = (role, content) => {
  // Remove empty state
  if (el.emptyState) el.emptyState.remove();

  const bubble = document.createElement('div');
  bubble.className = 'bubble';
  bubble.textContent = content;

  const group = document.createElement('div');
  group.className = `msg-group ${role}`;
  group.appendChild(bubble);
  el.messages.appendChild(group);
  return bubble;
};

const loadHistory = async () => {
  // Clear messages but keep empty state structure
  el.messages.innerHTML = `
    <div class="empty-state" id="emptyState">
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M18 3C9.72 3 3 9.16 3 16.75c0 3.97 1.8 7.55 4.7 10.09L6 30.75l5.3-1.98A16.1 16.1 0 0 0 18 30.5c8.28 0 15-6.16 15-13.75S26.28 3 18 3Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
      </svg>
      <p>Send a message to start the conversation.</p>
    </div>`;

  try {
    const res  = await fetch(API, { headers: authHeaders() });
    if (!res.ok) {
      const j = await res.json().catch(() => null);
      setMsg(el.chatMsg, j?.error?.message || 'Could not load history.', true);
      return;
    }
    const list = (await res.json())?.data || [];
    if (!list.length) return;

    // Clear empty state since we have messages
    el.messages.innerHTML = '';
    list.forEach((m) =>
      addMessage(m.role === 'assistant' ? 'assistant' : 'user', m.content || '')
    );
    scrollBottom();

    // Add a sidebar entry for the restored session
    if (list.length) {
      const firstUser = list.find(m => m.role === 'user');
      const label = firstUser?.content?.slice(0, 36) || 'Previous chat';
      addHistoryItem(label, true);
    }
  } catch {
    setMsg(el.chatMsg, 'Could not load history.', true);
  }
};

// ── SSE reader ───────────────────────────────────────────
const readSSE = async (res, onData, onError) => {
  const reader  = res.body.getReader();
  const decoder = new TextDecoder();
  let buf = '';
  for (;;) {
    const { value, done } = await reader.read();
    if (done) break;
    buf += decoder.decode(value, { stream: true });
    let i;
    while ((i = buf.indexOf('\n')) !== -1) {
      const line    = buf.slice(0, i).replace(/\r$/, '');
      buf           = buf.slice(i + 1);
      if (!line.startsWith('data:')) continue;
      const payload = line.slice(5).trim();
      if (!payload || payload === '[DONE]') return;
      let obj;
      try { obj = JSON.parse(payload); } catch { continue; }
      if (obj.error)   return onError(obj.error);
      if (obj.content) onData(obj.content);
    }
  }
};

// ── send ─────────────────────────────────────────────────
const send = async () => {
  const text = el.input.value.trim();
  if (!text || busy || !session) return;

  busy = true;
  el.sendBtn.disabled = true;
  setMsg(el.chatMsg);

  const userBubble = addMessage('user', text);
  const botBubble  = addMessage('assistant', '');
  botBubble.textContent = '…';
  el.input.value        = '';
  el.input.style.height = 'auto';
  scrollBottom();

  // Add to sidebar history on first message of the session
  if (el.historyList.children.length === 0 ||
      el.historyList.querySelector('.active') === null) {
    addHistoryItem(text.slice(0, 36), true);
  }

  let received = false;
  try {
    const res = await fetch(API, {
      method:  'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders() },
      body:    JSON.stringify({ message: text, model: el.modelSelect.value || 'openai' })
    });
    if (!res.ok) {
      const json = await res.json().catch(() => null);
      throw new Error(json?.error?.message || 'Request failed');
    }
    await readSSE(
      res,
      (chunk) => {
        if (!received) botBubble.textContent = '';
        received = true;
        botBubble.textContent += chunk;
        scrollBottom();
      },
      (msg) => setMsg(el.chatMsg, msg, true)
    );
  } catch (err) {
    setMsg(el.chatMsg, err.message || 'Network error', true);
  } finally {
    if (!received) botBubble.textContent = '(no response)';
    busy = false;
    el.sendBtn.disabled = false;
    el.input.focus();
  }
};

// ── new chat ─────────────────────────────────────────────
const newChat = () => {
  // Clear messages, restore empty state
  el.messages.innerHTML = `
    <div class="empty-state" id="emptyState">
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M18 3C9.72 3 3 9.16 3 16.75c0 3.97 1.8 7.55 4.7 10.09L6 30.75l5.3-1.98A16.1 16.1 0 0 0 18 30.5c8.28 0 15-6.16 15-13.75S26.28 3 18 3Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
      </svg>
      <p>Send a message to start the conversation.</p>
    </div>`;
  setMsg(el.chatMsg);

  // Deselect history items
  document.querySelectorAll('.history-item').forEach(i => i.classList.remove('active'));
  el.input.focus();
};

// ── init ─────────────────────────────────────────────────
const init = async () => {
  setMode('login');

  MODELS = await loadModels();
  for (const { label, id } of MODELS) {
    const opt = document.createElement('option');
    opt.value = id;
    opt.textContent = label;
    el.modelSelect.appendChild(opt);
  }

  let cfg = {};
  try {
    cfg = (await (await fetch(`${API}?type=config`)).json())?.data || {};
  } catch {}

  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey) {
    renderAuth();
    setMsg(el.authMsg, 'Server config unavailable — check the API env/logs.', true);
    return;
  }

  supabase = createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
  session  = (await supabase.auth.getSession()).data?.session || null;

  supabase.auth.onAuthStateChange((_e, next) => {
    session = next;
    renderAuth();
    if (next) loadHistory();
  });

  renderAuth();
  if (session) loadHistory();
};

// ── event bindings ───────────────────────────────────────
el.tabLogin.onclick  = () => setMode('login');
el.tabSignup.onclick = () => setMode('signup');
el.form.onsubmit     = submitAuth;
el.sendBtn.onclick   = send;
el.newChatBtn.onclick = newChat;
el.logoutBtn.onclick = () => { if (supabase) supabase.auth.signOut(); };

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