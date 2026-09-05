import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const API = '/api/v1/misc/pollinations';
const $ = (id) => document.getElementById(id);

const el = {
  authView:     $('authView'),
  chatView:     $('chatView'),
  messages:     $('messages'),
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
  sidebar:      $('sidebar'),
  newChatBtn:   $('newChatBtn'),
  historyList:  $('historyList'),
  accountBlock: $('accountBlock'),
  accountEmail: $('accountEmail'),
  accountAvatar: $('accountAvatar'),
  logoutBtn:    $('logoutBtn')
};

const EMPTY_HTML = `
  <div class="empty-state" id="emptyState">
    <svg width="36" height="36" viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M18 3C9.72 3 3 9.16 3 16.75c0 3.97 1.8 7.55 4.7 10.09L6 30.75l5.3-1.98A16.1 16.1 0 0 0 18 30.5c8.28 0 15-6.16 15-13.75S26.28 3 18 3Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
    </svg>
    <p>Send a message to start the conversation.</p>
  </div>`;

let supabase = null;
let session  = null;
let busy     = false;
let mode     = 'login';
let convId   = null;
let MODELS   = [];

const setMsg = (n, text = '', error = false) => {
  n.textContent = text;
  n.classList.toggle('error', error && !!text);
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
  el.sidebar.classList.toggle('hidden', !authed);
  el.input.disabled = !authed;
  el.sendBtn.disabled = !authed;
  el.modelSelect.disabled = !authed;
  setMsg(el.chatMsg);

  if (authed) {
    el.accountEmail.textContent = session.user?.email || 'Signed in';
    el.accountAvatar.textContent = (session.user?.email || '?')[0].toUpperCase();
    el.accountBlock.classList.remove('hidden');
  } else {
    el.accountBlock.classList.add('hidden');
  }
};

const loadModels = async () => {
  try {
    const d = await (await fetch('MODELS.json')).json();
    if (Array.isArray(d)) return d;
  } catch {}
  return [{ label: 'GPT-5.4 Nano', id: 'openai' }];
};

const submitAuth = async (e) => {
  e.preventDefault();
  const email = el.email.value.trim();
  const password = el.password.value;
  if (!email || !password) return;
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
          'Account created. Check your inbox for a confirmation link before logging in.'
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

const showEmpty = () => {
  el.messages.innerHTML = EMPTY_HTML;
  el.emptyState = document.getElementById('emptyState');
};

const addMessage = (role, content) => {
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

const markActive = (id) => {
  el.historyList.querySelectorAll('.history-item').forEach((it) =>
    it.classList.toggle('active', it.dataset.id === id)
  );
};

const addConversation = (id, title, prepend = false) => {
  const item = document.createElement('div');
  item.className = 'history-item';
  item.dataset.id = id;
  item.textContent = title;
  item.title = title;
  item.onclick = () => openConversation(id);
  item.oncontextmenu = (e) => {
    e.preventDefault();
    openMenu(e.clientX, e.clientY, id);
  };
  if (prepend) el.historyList.prepend(item);
  else el.historyList.appendChild(item);
  return item;
};

let ctxMenu = null;
const closeMenu = () => {
  if (ctxMenu) { ctxMenu.remove(); ctxMenu = null; }
};
const openMenu = (x, y, id) => {
  closeMenu();
  ctxMenu = document.createElement('div');
  ctxMenu.className = 'ctx-menu';
  const del = document.createElement('button');
  del.type = 'button';
  del.textContent = 'Delete chat';
  del.onclick = async () => {
    closeMenu();
    await removeConversation(id);
  };
  ctxMenu.appendChild(del);
  ctxMenu.style.left = `${x}px`;
  ctxMenu.style.top = `${y}px`;
  document.body.appendChild(ctxMenu);
};
document.addEventListener('click', closeMenu);
document.addEventListener('contextmenu', (e) => {
  if (!e.target.closest('.history-item')) closeMenu();
});

const loadConversations = async () => {
  try {
    const res = await fetch(API, { headers: authHeaders() });
    if (!res.ok) {
      const j = await res.json().catch(() => null);
      setMsg(el.chatMsg, j?.error?.message || 'Could not load chats.', true);
      return;
    }
    const list = (await res.json())?.data || [];
    el.historyList.innerHTML = '';
    for (const c of list) addConversation(c.id, c.title);
    if (list.length) openConversation(list[0].id);
    else showEmpty();
  } catch {
    setMsg(el.chatMsg, 'Could not load chats.', true);
  }
};

const openConversation = async (id) => {
  convId = id;
  markActive(id);
  showEmpty();
  setMsg(el.chatMsg);
  try {
    const res = await fetch(`${API}?conv=${encodeURIComponent(id)}`, { headers: authHeaders() });
    if (!res.ok) {
      const j = await res.json().catch(() => null);
      setMsg(el.chatMsg, j?.error?.message || 'Could not open chat.', true);
      return;
    }
    const list = (await res.json())?.data || [];
    el.messages.innerHTML = '';
    for (const m of list) addMessage(m.role === 'assistant' ? 'assistant' : 'user', m.content || '');
    scrollBottom();
  } catch {
    setMsg(el.chatMsg, 'Could not open chat.', true);
  }
};

const removeConversation = async (id) => {
  try {
    const res = await fetch(`${API}?conv=${encodeURIComponent(id)}`, {
      method: 'DELETE',
      headers: authHeaders()
    });
    if (!res.ok) {
      const j = await res.json().catch(() => null);
      setMsg(el.chatMsg, j?.error?.message || 'Delete failed.', true);
      return;
    }
    el.historyList.querySelector(`.history-item[data-id="${id}"]`)?.remove();
    if (convId === id) newChat();
  } catch {
    setMsg(el.chatMsg, 'Delete failed.', true);
  }
};

const newChat = () => {
  convId = null;
  showEmpty();
  setMsg(el.chatMsg);
  el.historyList.querySelectorAll('.history-item').forEach((i) => i.classList.remove('active'));
  el.input.focus();
};

const readSSE = async (res, onMsg) => {
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
      try { obj = JSON.parse(payload); } catch { continue; }
      onMsg(obj);
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
  const botBubble = addMessage('assistant', '');
  botBubble.textContent = '…';
  el.input.value = '';
  el.input.style.height = 'auto';
  scrollBottom();

  let received = false;
  try {
    const res = await fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders() },
      body: JSON.stringify({
        message: text,
        model: el.modelSelect.value || 'openai',
        conversation_id: convId || undefined
      })
    });
    if (!res.ok) {
      const json = await res.json().catch(() => null);
      throw new Error(json?.error?.message || 'Request failed');
    }
    await readSSE(res, (obj) => {
      if (obj.conv) {
        // New chat was created server-side — register it in the sidebar.
        if (!convId || convId !== obj.conv.id) {
          convId = obj.conv.id;
          addConversation(obj.conv.id, obj.conv.title, true);
          markActive(convId);
        }
      } else if (obj.error) {
        setMsg(el.chatMsg, obj.error, true);
      } else if (obj.content) {
        if (!received) botBubble.textContent = '';
        received = true;
        botBubble.textContent += obj.content;
        scrollBottom();
      }
    });
  } catch (err) {
    setMsg(el.chatMsg, err.message || 'Network error', true);
  } finally {
    if (!received) botBubble.textContent = '(no response)';
    busy = false;
    el.sendBtn.disabled = false;
    el.input.focus();
  }
};

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
  session = (await supabase.auth.getSession()).data?.session || null;

  supabase.auth.onAuthStateChange((_e, next) => {
    session = next;
    renderAuth();
    if (next) loadConversations();
  });

  renderAuth();
  if (session) loadConversations();
};

el.tabLogin.onclick = () => setMode('login');
el.tabSignup.onclick = () => setMode('signup');
el.form.onsubmit = submitAuth;
el.sendBtn.onclick = send;
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
