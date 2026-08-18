/* Notepad — a lightweight Pastefy-backed notepad.
 * Saves notes as pastes on https://pastefy.app via API v2,
 * proxied through /api/v1/pastefy (the token lives in .env server-side).
 */

const API_URL = '/api/v1/pastefy';
const DEFAULT_VISIBILITY = 'UNLISTED'; // PUBLIC | UNLISTED | PRIVATE

const titleEl = document.getElementById('title');
const noteEl = document.getElementById('note');
const noteIdEl = document.getElementById('noteId');
const saveBtn = document.getElementById('saveBtn');
const copyBtn = document.getElementById('copyBtn');
const loadBtn = document.getElementById('loadBtn');
const msgEl = document.getElementById('msg');
const errEl = document.getElementById('err');

function say(el, text) {
  el.textContent = text;
  el.style.display = text ? 'block' : 'none';
}

async function pastefy(path, options = {}) {
  const res = await fetch(API_URL + path, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
  });

  let data = null;
  try { data = await res.json(); } catch (_) { /* non-JSON body */ }

  if (!res.ok) {
    const message =
      (data &&
        (data.error?.message ||
          data.message ||
          (typeof data.error === 'string' && data.error))) ||
      `Request failed (${res.status})`;
    throw new Error(message);
  }
  // API wraps payloads as { success: true, data }
  return data && data.success ? data.data : data;
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
    const paste = await pastefy('', {
      method: 'POST',
      body: JSON.stringify({
        title: titleEl.value.trim(),
        content,
        visibility: DEFAULT_VISIBILITY,
        encrypted: false,
      }),
    });

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
  const id = noteIdEl.value.trim();
  if (!id) {
    say(errEl, 'Enter a paste ID to load.');
    noteIdEl.focus();
    return;
  }

  loadBtn.disabled = true;
  loadBtn.textContent = 'Loading...';
  say(msgEl, '');

  try {
    const data = await pastefy('?id=' + encodeURIComponent(id));
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