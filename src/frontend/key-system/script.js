const statusEl = document.getElementById('status');
const keyEl = document.getElementById('key');
const generateBtn = document.getElementById('generateBtn');
const copyBtn = document.getElementById('copyBtn');
const debugEl = document.getElementById('debug');

// src/frontend/key-system/ → root = ../../..
const API_URL = '../../../api/v1/key-system/generate-key.js';

const urlParams = new URLSearchParams(window.location.search);
const hash = urlParams.get('hash');

function setStatus(type, svgPath, message) {
  statusEl.className = type;
  statusEl.innerHTML = `<svg viewBox="0 0 24 24">${svgPath}</svg> ${message}`;
}

if (hash && hash.length === 64) {
  setStatus(
    'success',
    '<circle cx="12" cy="12" r="10"/><path d="M9 12l2 2 4-4"/>',
    'Hash verified, click to generate your key'
  );
  generateBtn.disabled = false;
  debugEl.textContent = `Hash: ${hash.slice(0, 12)}...${hash.slice(-12)}`;
} else {
  setStatus(
    'error',
    '<circle cx="12" cy="12" r="10"/><path d="M15 9l-6 6M9 9l6 6"/>',
    'No valid hash found. Complete the Linkvertise ad first.'
  );
  debugEl.textContent = 'URL should contain: ?hash=64charhashhere';
}

generateBtn.addEventListener('click', async () => {
  if (!hash || hash.length !== 64) return;

  generateBtn.disabled = true;
  setStatus(
    'loading',
    '<path d="M21 12a9 9 0 11-6.219-8.56"/>',
    'Verifying ad and generating key...'
  );
  statusEl.querySelector('svg').style.animation = 'spin 1s linear infinite';
  keyEl.className = 'empty';
  keyEl.textContent = 'Generating...';

  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ hash }),
    });

    let data;
    const clone = response.clone();
    try {
      data = await clone.json();
    } catch {
      data = { error: 'parse_error', detail: await response.text() };
    }

    if (!response.ok || data.error) {
      if (data.error === 'daily_limit_reached') {
        setStatus(
          'error',
          '<circle cx="12" cy="12" r="10"/><path d="M12 8v4m0 4h.01"/>',
          data.message
        );
        debugEl.textContent = `Used: ${data.keys_used}/2 keys today`;
      } else {
        setStatus(
          'error',
          '<circle cx="12" cy="12" r="10"/><path d="M15 9l-6 6M9 9l6 6"/>',
          data.message || `Error: ${data.error}`
        );
        const detailText =
          data.detail && typeof data.detail === 'object'
            ? JSON.stringify(data.detail, null, 2)
            : data.detail || 'Try again';
        debugEl.textContent = detailText;
      }
      keyEl.className = 'empty';
      keyEl.textContent = 'Key will appear here';
      return;
    }

    setStatus(
      'success',
      '<circle cx="12" cy="12" r="10"/><path d="M9 12l2 2 4-4"/>',
      'Key generated successfully'
    );
    keyEl.className = '';
    keyEl.textContent = data.key;
    debugEl.textContent = `Expires: ${new Date(data.expires_at).toLocaleString()} | ${data.keys_remaining} key${data.keys_remaining !== 1 ? 's' : ''} remaining today`;
    copyBtn.style.display = 'flex';
    generateBtn.style.display = 'none';

    await navigator.clipboard.writeText(data.key).catch(() => {});
  } catch (error) {
    setStatus(
      'error',
      '<circle cx="12" cy="12" r="10"/><path d="M15 9l-6 6M9 9l6 6"/>',
      'Network error, check your connection'
    );
    keyEl.className = 'empty';
    keyEl.textContent = 'Key will appear here';
    debugEl.textContent = error.message;
  } finally {
    generateBtn.disabled = false;
  }
});

copyBtn.addEventListener('click', async () => {
  await navigator.clipboard.writeText(keyEl.textContent).catch(() => {});
  const original = copyBtn.innerHTML;
  copyBtn.innerHTML = `
    <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M9 12l2 2 4-4"/></svg>
    Copied!
  `;
  setTimeout(() => { copyBtn.innerHTML = original; }, 2000);
});

// Auto-generate if hash is already present in URL
if (hash && hash.length === 64) {
  setTimeout(() => generateBtn.click(), 1200);
}