/* Notepad — a lightweight Pastefy-backed notepad.
 * Saves notes as pastes on https://pastefy.app via API v2.
 *
 * API key resolution order:
 *   1. window.PASTEFY_API_KEY  (set via a config script / build env)
 *   2. localStorage            (saved after first prompt)
 *   3. prompt the user once
 */

const API_URL = 'https://pastefy.app/api/v2/paste';
const TOKEN_KEY = 'pastefy_token';
const DEFAULT_VISIBILITY = 'UNLISTED'; // PUBLIC | UNLISTED | PRIVATE

const titleEl = document.getElementById('title');
const noteEl = document.getElementById('note');
const noteIdEl = document.getElementById('noteId');
const loadIdEl = document.getElementById('loadId');
const saveBtn = document.getElementById('saveBtn');
const copyBtn = document.getElementById('copyBtn');
const loadBtn = document.getElementById('loadBtn');
const msgEl = document.getElementById('msg');
const errEl = document.getElementById('err');

function say(el, text) {
  el.textContent = text;
  el.style.display = text ? 'block' : 'none';
}

function getToken() {
  const fromWindow = (typeof window !== 'undefined' && window.PASTEFY_API_KEY) || '';
  const stored = (localStorage.getItem(TOKEN_KEY) || '').trim();
  if (fromWindow.trim() || stored) return fromWindow.trim() || stored;

  const entered = (window.prompt(
    'Pastefy API token required.\nGet one at https://pastefy.app/settings.'
  ) || '').trim();
  if (entered) localStorage.setItem(TOKEN_KEY, entered);
  return entered || null;
}

async function pastefy(path, options = {}) {
  const token = getToken();
  if (!token) throw new Error('A Pastefy API token is required.');

  const res = await fetch(API_URL + path, {
    ...options,
    headers: {
      Authorization: `Token ${token}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });

  let data = null;
  try { data = await res.json(); } catch (_) { /* non-JSON body */ }

  if (!res.ok) {
    const message =
      (data &&
        (data.message ||
          (data.error && data.error.message) ||
          (typeof data.error === 'string' && data.error))) ||
      `Request failed (${res.status})`;
    throw new Error(message);
  }
  return data;
}

async function saveNote() {
  say(errEl, '');
  const content = noteEl.value.trim();
  if (!content) {
    say(errEl, 'Write something before saving.');
    noteEl.focus();
    return;
  }

  saveBtn.disabled = true;
  saveBtn.textContent = 'Saving...';
  say(msgEl, '');

  try {
    const data = await pastefy('', {
      method: 'POST',
      body: JSON.stringify({
        title: titleEl.value.trim(),
        content,
        visibility: DEFAULT_VISIBILITY,
        encrypted: false,
      }),
    });

    const paste = data && data.paste;
    if (!paste || !paste.id) throw new Error('Pastefy returned an unexpected response.');

    noteIdEl.value = paste.id;
    say(msgEl, `Saved! Paste ID: ${paste.id}`);
  } catch (err) {
    say(errEl, err.message || 'Save failed.');
  } finally {
    saveBtn.disabled = false;
    saveBtn.textContent = 'Save';
  }
}

async function loadNote() {
  say(errEl, '');
  const id = loadIdEl.value.trim();
  if (!id) {
    say(errEl, 'Enter a paste ID to load.');
    loadIdEl.focus();
    return;
  }

  loadBtn.disabled = true;
  loadBtn.textContent = 'Loading...';
  say(msgEl, '');

  try {
    const data = await pastefy('/' + encodeURIComponent(id));
    if (!data || typeof data.content !== 'string') {
      throw new Error('Paste not found.');
    }

    titleEl.value = data.title || '';
    noteEl.value = data.content;
    noteIdEl.value = data.id || '';
    say(msgEl, 'Note loaded.');
  } catch (err) {
    say(errEl, err.message || 'Load failed.');
  } finally {
    loadBtn.disabled = false;
    loadBtn.textContent = 'Load';
  }
}

async function copyId() {
  const id = noteIdEl.value.trim();
  if (!id) {
    say(errEl, 'Nothing to copy yet — save a note first.');
    return;
  }
  try {
    await navigator.clipboard.writeText(id);
    say(msgEl, 'Paste ID copied to clipboard.');
  } catch (err) {
    say(errEl, `Copy failed: ${err.message}`);
  }
}

saveBtn.addEventListener('click', saveNote);
loadBtn.addEventListener('click', loadNote);
copyBtn.addEventListener('click', copyId);

// Ctrl/Cmd + S to save from anywhere
noteEl.addEventListener('keydown', (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
    e.preventDefault();
    saveNote();
  }
});