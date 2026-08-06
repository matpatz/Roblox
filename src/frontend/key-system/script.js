const keyEl = document.getElementById('key');
const generateBtn = document.getElementById('generateBtn');
const copyBtn = document.getElementById('copyBtn');
const debugEl = document.getElementById('debug');

const API_URL = '/api/v1/key-system/generate-key';
const NOTIFY_TIME = 10;

const urlParams = new URLSearchParams(window.location.search);
const hash = urlParams.get('hash');

if (hash && hash.length === 64) {
  notify('success', 'Hash verified, click to generate your key', NOTIFY_TIME);
  generateBtn.disabled = false;
  debugEl.textContent = `Hash: ${hash.slice(0, 12)}...${hash.slice(-12)}`;
} else {
  notify('error', 'No valid hash found. Complete the Linkvertise ad first.', NOTIFY_TIME);
}

generateBtn.addEventListener('click', async () => {
  if (!hash || hash.length !== 64) return;

  generateBtn.disabled = true;
  const loadingNotify = notify('loading', 'Verifying ad and generating key...', NOTIFY_TIME);
  keyEl.className = 'empty';
  keyEl.textContent = 'Generating...';

  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ hash }),
    });

    let data;
    try {
      data = await response.json();
    } catch {
      data = { error: { message: 'Invalid server response' } };
    }

    if (!response.ok || data.error) {
      const err = data.error || {};
      notify('error', err.message || 'Something went wrong', NOTIFY_TIME);
      debugEl.textContent = 'Try again. If the issue persists, contact support.';
      keyEl.className = 'empty';
      keyEl.textContent = 'Key will appear here';
      return;
    }

    const result = data.data || {};
    notify('success', 'Key generated successfully', NOTIFY_TIME);
    keyEl.className = 'standalone';
    keyEl.textContent = result.key;
    debugEl.textContent = `Expires: ${new Date(result.expires_at).toLocaleString()}`;
    copyBtn.style.display = 'flex';

    await navigator.clipboard.writeText(result.key).catch(() => {});
  } catch (error) {
    notify('error', 'Network error, check your connection', NOTIFY_TIME);
    keyEl.className = 'empty';
    keyEl.textContent = 'Key will appear here';
    debugEl.textContent = error.message;
  } finally {
    notify.close(loadingNotify);
    generateBtn.disabled = false;
  }
});

copyBtn.addEventListener('click', async () => {
  await navigator.clipboard.writeText(keyEl.textContent).catch(() => {});
  notify('success', 'Key copied to clipboard', NOTIFY_TIME);
});

// Auto-generate if hash is already present in URL
if (hash && hash.length === 64) {
  setTimeout(() => generateBtn.click(), 1200);
}
