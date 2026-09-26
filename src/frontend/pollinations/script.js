import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const API = '/api/v1/misc/pollinations';
const $ = (id) => document.getElementById(id);
const marked    = window.marked || null;
const DOMPurify = window.DOMPurify || null;
const hljs      = window.hljs || null;

const FILE_INLINE_BYTES = 10 * 1024;         // files ≤ this are inlined into the prompt
const MAX_FILE_BYTES    = 5 * 1024 * 1024;   // per-file upload cap

const escapeHtml = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

if (marked) {
  marked.setOptions({
    gfm: true,
    breaks: true,
    highlight(code, lang) {
      if (lang && hljs && hljs.getLanguage(lang)) {
        try { return hljs.highlight(code, { language: lang }).value; } catch {}
      }
      if (hljs) { try { return hljs.highlightAuto(code).value; } catch {} }
      return escapeHtml(code);
    }
  });
}

function renderMarkdown(text) {
  if (!text) return '';
  let html;
  if (marked) html = marked.parse(text);
  else html = '<p>' + escapeHtml(text).replace(/\n/g, '<br>') + '</p>';
  if (DOMPurify) html = DOMPurify.sanitize(html);
  const tpl = document.createElement('div');
  tpl.innerHTML = html;
  tpl.querySelectorAll('pre code').forEach((c) => c.classList.add('hljs'));
  return tpl.innerHTML;
}

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
  logoutBtn:    $('logoutBtn'),
  attachBtn:    $('attachBtn'),
  fileInput:    $('fileInput'),
  pendingFiles: $('pendingFiles')
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
let activeConv   = null; // conversation currently displayed
let loadSeq      = 0;
let abortCtl     = null;
let pendingFiles = [];   // files staged in the composer

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
  el.attachBtn.disabled = !authed;
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

const clearMessages = () => {
  el.messages.innerHTML = '';
  el.emptyState = null;
};

const showEmpty = () => {
  clearMessages();
  el.messages.innerHTML = EMPTY_HTML;
  el.emptyState = document.getElementById('emptyState');
};

const setBubbleContent = (bubble, text) => {
  bubble.innerHTML = renderMarkdown(text);
  bubble.querySelectorAll('a').forEach((a) => {
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
  });
};

const addMessage = (role, content, attachments = []) => {
  if (el.emptyState) { el.emptyState.remove(); el.emptyState = null; }
  const group = document.createElement('div');
  group.className = `msg-group ${role}`;
  if (role === 'user' && attachments.length) {
    const tray = document.createElement('div');
    tray.className = 'attachments';
    for (const f of attachments) tray.appendChild(buildFileCard(f));
    group.appendChild(tray);
  }
  const bubble = document.createElement('div');
  bubble.className = 'bubble';
  setBubbleContent(bubble, content || '');
  group.appendChild(bubble);
  el.messages.appendChild(group);
  return bubble;
};

/* ---------- Files ---------- */

const fmtBytes = (n) => {
  n = Number(n) || 0;
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(2)} MB`;
};

const TEXT_TYPE_RE = /^(text\/|application\/(json|javascript|x-javascript|x-yaml|x-sh|xml)$)/;
const TEXT_EXT_RE = /\.(txt|md|markdown|json|js|mjs|cjs|ts|tsx|jsx|css|html?|xml|ya?ml|csv|tsv|lua|luau|py|rb|php|java|c|h|cpp|hpp|cs|go|rs|swift|kt|kts|sh|bash|bat|ps1|sql|toml|ini|cfg|conf|log|env|gitignore)$/i;

const isTextFile = (f) => TEXT_TYPE_RE.test(f.type || '') || TEXT_EXT_RE.test(f.name || '');

const fileIconFor = (f) => {
  const t = f.type || '';
  if (t.startsWith('image/')) return '🖼️';
  if (t.startsWith('video/')) return '🎞️';
  if (t.startsWith('audio/')) return '🎵';
  if (/\.(lua|luau)$/i.test(f.name || '')) return '🧩';
  return '📄';
};

// Decode an attachment's base64 payload back to UTF-8 text (or null if binary).
const fileText = (f) => {
  if (!f?.data || typeof f.data !== 'string') return null;
  const b64 = f.data.startsWith('data:') ? f.data.slice(f.data.indexOf(',') + 1) : f.data;
  if (!isTextFile(f)) return null;
  try {
    const bin = atob(b64);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new TextDecoder('utf-8', { fatal: false }).decode(bytes);
  } catch {
    return null;
  }
};

const fileDataUrl = (f) => {
  if (f?.data?.startsWith('data:')) return f.data;
  const mime = f.type || 'application/octet-stream';
  return `data:${mime};base64,${f.data}`;
};

const fileBtn = (label, fn) => {
  const b = document.createElement('button');
  b.type = 'button';
  b.className = 'file-btn';
  b.textContent = label;
  b.onclick = fn;
  return b;
};

const buildFileCard = (f) => {
  const card = document.createElement('div');
  card.className = 'file-card';
  const icon = document.createElement('span');
  icon.className = 'file-icon';
  icon.textContent = fileIconFor(f);
  const meta = document.createElement('div');
  meta.className = 'file-meta';
  const nm = document.createElement('span');
  nm.className = 'file-name';
  nm.textContent = f.name || 'file';
  nm.title = f.name || '';
  const sz = document.createElement('span');
  sz.className = 'file-size';
  sz.textContent = fmtBytes(f.size);
  if (f.inline) {
    const badge = document.createElement('span');
    badge.className = 'file-badge';
    badge.textContent = ' · inline';
    sz.append(badge);
  }
  meta.append(nm, sz);
  const actions = document.createElement('div');
  actions.className = 'file-actions';
  actions.append(
    fileBtn('Download', () => downloadFile(f)),
    fileBtn('Preview', () => previewFile(f)),
    fileBtn('Copy', () => copyFile(f))
  );
  card.append(icon, meta, actions);
  return card;
};

const downloadFile = (f) => {
  const a = document.createElement('a');
  a.href = fileDataUrl(f);
  a.download = f.name || 'download';
  document.body.appendChild(a);
  a.click();
  a.remove();
};

const copyFile = async (f) => {
  const text = fileText(f);
  const payload = text !== null ? text : fileDataUrl(f);
  try {
    await navigator.clipboard.writeText(payload);
    toast('Copied');
  } catch {
    toast('Copy failed');
  }
};

/* ---------- Preview modal / toast ---------- */

let modalEl = null;
const closeModal = () => { if (modalEl) { modalEl.remove(); modalEl = null; } };

const previewFile = (f) => {
  const mime = f.type || '';
  if (mime.startsWith('image/')) {
    showModal(`<img class="preview-img" src="${fileDataUrl(f)}" alt="${escapeHtml(f.name || '')}">`);
    return;
  }
  const text = fileText(f);
  if (text !== null) showModal(`<pre class="preview-text">${escapeHtml(text)}</pre>`);
  else showModal(`<div class="preview-none">No preview available.<br>${escapeHtml(f.name || '')} · ${fmtBytes(f.size)}</div>`);
};

const showModal = (inner) => {
  closeModal();
  modalEl = document.createElement('div');
  modalEl.className = 'modal-overlay';
  const box = document.createElement('div');
  box.className = 'modal-box';
  const close = document.createElement('button');
  close.type = 'button';
  close.className = 'modal-close';
  close.textContent = '×';
  close.onclick = closeModal;
  const body = document.createElement('div');
  body.className = 'modal-body';
  body.innerHTML = inner;
  box.append(close, body);
  modalEl.appendChild(box);
  modalEl.onclick = (e) => { if (e.target === modalEl) closeModal(); };
  document.body.appendChild(modalEl);
};

document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeModal(); });

let toastEl = null;
const toast = (msg) => {
  if (!toastEl) {
    toastEl = document.createElement('div');
    toastEl.className = 'toast';
    document.body.appendChild(toastEl);
  }
  toastEl.textContent = msg;
  toastEl.classList.add('show');
  clearTimeout(toastEl._t);
  toastEl._t = setTimeout(() => toastEl.classList.remove('show'), 1600);
};

/* ---------- Pending files (composer tray) ---------- */

const renderPendingFiles = () => {
  el.pendingFiles.innerHTML = '';
  el.pendingFiles.classList.toggle('hidden', !pendingFiles.length);
  pendingFiles.forEach((f, i) => {
    const item = document.createElement('div');
    item.className = 'pending-file';
    const info = document.createElement('span');
    info.className = 'pending-info';
    info.textContent = `${fileIconFor(f)} ${f.name} · ${fmtBytes(f.size)}`;
    const badge = document.createElement('span');
    badge.className = 'pending-badge';
    badge.textContent = f.size > FILE_INLINE_BYTES ? 'file' : 'inline';
    const rm = document.createElement('button');
    rm.type = 'button';
    rm.className = 'pending-remove';
    rm.textContent = '×';
    rm.onclick = () => { pendingFiles.splice(i, 1); renderPendingFiles(); };
    item.append(info, badge, rm);
    el.pendingFiles.appendChild(item);
  });
};

const handleFiles = (list) => {
  for (const file of Array.from(list || [])) {
    if (file.size > MAX_FILE_BYTES) {
      toast(`"${file.name}" is too large (${fmtBytes(file.size)})`);
      continue;
    }
    const fr = new FileReader();
    fr.onload = () => {
      const dataUrl = String(fr.result);
      pendingFiles.push({
        name: file.name,
        type: file.type,
        size: file.size,
        data: dataUrl.slice(dataUrl.indexOf(',') + 1)
      });
      renderPendingFiles();
    };
    fr.onerror = () => toast(`Couldn't read "${file.name}"`);
    fr.readAsDataURL(file);
  }
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
    if (activeConv) { markActive(activeConv); return; }
    if (list.length) {
      let saved = '';
      try { saved = sessionStorage.getItem('poll:conv') || ''; } catch {}
      const found = saved ? list.find((c) => c.id === saved) : null;
      openConversation(found ? found.id : list[0].id);
    } else {
      showEmpty();
    }
  } catch {
    setMsg(el.chatMsg, 'Could not load chats.', true);
  }
};

const openConversation = async (id) => {
  if (id === activeConv) return; // already showing — don't wipe a live stream
  activeConv = id;
  convId = id;
  markActive(id);
  showEmpty();
  setMsg(el.chatMsg);
  saveState();
  const seq = ++loadSeq;
  if (abortCtl) abortCtl.abort();
  abortCtl = new AbortController();
  try {
    const res = await fetch(`${API}?conv=${encodeURIComponent(id)}`, {
      headers: authHeaders(),
      signal: abortCtl.signal
    });
    if (seq !== loadSeq) return; // a newer open took over
    if (!res.ok) {
      const j = await res.json().catch(() => null);
      setMsg(el.chatMsg, j?.error?.message || 'Could not open chat.', true);
      return;
    }
    const list = (await res.json())?.data || [];
    if (seq !== loadSeq) return;
    clearMessages();
    for (const m of list) addMessage(m.role === 'assistant' ? 'assistant' : 'user', m.content || '', m.attachments || []);
    scrollBottom();
  } catch (err) {
    if (err?.name === 'AbortError') return;
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
  if (abortCtl) { abortCtl.abort(); abortCtl = null; }
  loadSeq++;
  convId = null;
  activeConv = null;
  showEmpty();
  setMsg(el.chatMsg);
  el.historyList.querySelectorAll('.history-item').forEach((i) => i.classList.remove('active'));
  saveState();
  el.input.focus();
};

const readSSE = async (res, onMsg) => {
  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buf = '';
  for (;;) {
    let value, done;
    try {
      ({ value, done } = await reader.read());
    } catch {
      return; // stream aborted (e.g. tab backgrounded) — stop gracefully
    }
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
  if ((!text && !pendingFiles.length) || busy || !session) return;

  // Split staged files: small text files inline into the prompt, big ones as attachments.
  const attachments = [];
  const cards = [];
  const inline = [];
  for (const f of pendingFiles) {
    const txt = fileText(f);
    if (f.size <= FILE_INLINE_BYTES && txt !== null) {
      inline.push(`--- File: ${f.name} ---\n\`\`\`\n${txt}\n\`\`\``);
      cards.push({ name: f.name, type: f.type, size: f.size, data: f.data, inline: true });
    } else {
      attachments.push({ name: f.name, type: f.type, size: f.size, data: f.data });
      cards.push({ name: f.name, type: f.type, size: f.size, data: f.data });
    }
  }

  let prompt = text;
  if (attachments.length) inline.push(attachments.map((a) => `[Attached file: ${a.name} (${fmtBytes(a.size)})]`).join('\n'));
  if (inline.length) prompt = [prompt, inline.join('\n')].filter(Boolean).join('\n\n');
  if (!prompt) prompt = 'Files attached below.';

  busy = true;
  el.sendBtn.disabled = true;
  setMsg(el.chatMsg);

  addMessage('user', text, cards);
  const botBubble = addMessage('assistant', '');
  setBubbleContent(botBubble, '…');
  el.input.value = '';
  el.input.style.height = 'auto';
  pendingFiles = [];
  renderPendingFiles();
  scrollBottom();

  let received = false;
  let acc = '';
  try {
    const res = await fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders() },
      body: JSON.stringify({
        message: prompt,
        model: el.modelSelect.value || 'openai',
        conversation_id: convId || undefined,
        attachments: attachments.length ? attachments : undefined
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
          activeConv = obj.conv.id;
          addConversation(obj.conv.id, obj.conv.title, true);
          markActive(convId);
          saveState();
        }
      } else if (obj.error) {
        setMsg(el.chatMsg, obj.error, true);
      } else if (obj.content) {
        if (!received) { setBubbleContent(botBubble, ''); received = true; }
        acc += obj.content;
        setBubbleContent(botBubble, acc);
        scrollBottom();
      }
    });
  } catch (err) {
    setMsg(el.chatMsg, err.message || 'Network error', true);
  } finally {
    if (!received) setBubbleContent(botBubble, '(no response)');
    busy = false;
    el.sendBtn.disabled = false;
    el.input.focus();
  }
};

const saveState = () => {
  try {
    sessionStorage.setItem('poll:draft', el.input.value);
    sessionStorage.setItem('poll:conv', convId || '');
  } catch {}
};

const restoreDraft = () => {
  try {
    const draft = sessionStorage.getItem('poll:draft');
    if (draft) {
      el.input.value = draft;
      el.input.style.height = 'auto';
      el.input.style.height = Math.min(el.input.scrollHeight, 140) + 'px';
    }
  } catch {}
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
    if (next) {
      loadConversations();
    } else {
      activeConv = null;
      convId = null;
      showEmpty();
    }
  });

  renderAuth();
  if (session) loadConversations();
  restoreDraft();
};

el.tabLogin.onclick = () => setMode('login');
el.tabSignup.onclick = () => setMode('signup');
el.form.onsubmit = submitAuth;
el.sendBtn.onclick = send;
el.newChatBtn.onclick = newChat;
el.logoutBtn.onclick = () => { if (supabase) supabase.auth.signOut(); };
el.attachBtn.onclick = () => el.fileInput.click();
el.fileInput.onchange = () => {
  handleFiles(el.fileInput.files);
  el.fileInput.value = '';
};

el.input.onkeydown = (e) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    send();
  }
};
el.input.oninput = () => {
  el.input.style.height = 'auto';
  el.input.style.height = Math.min(el.input.scrollHeight, 140) + 'px';
  saveState();
};

window.addEventListener('pagehide', saveState);
window.addEventListener('beforeunload', saveState);
document.addEventListener('visibilitychange', () => { if (document.hidden) saveState(); });

init();
