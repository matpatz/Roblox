const statusEl = document.getElementById('status');
const keyEl = document.getElementById('key');
const generateBtn = document.getElementById('generateBtn');
const copyBtn = document.getElementById('copyBtn');
const debugEl = document.getElementById('debug');

const API_URL = '/api/v1/key-system/generate-key';

const urlParams = new URLSearchParams(window.location.search);
const hash = urlParams.get('hash');

function setStatus(type, message) {
  statusEl.className = type;
  statusEl.textContent = message;
}

if (hash && hash.length === 64) {
  setStatus(
    'success',
    'Hash verified, click to generate your key'
  );
  generateBtn.disabled = false;
  debugEl.textContent = `Hash: ${hash.slice(0, 12)}...${hash.slice(-12)}`;
} else {
  setStatus(
    'error',
    'No valid hash found. Complete the Linkvertise ad first.'
  );
  debugEl.textContent = 'URL should contain: ?hash=64charhashhere';
}

generateBtn.addEventListener('click', async () => {
  if (!hash || hash.length !== 64) return;

  generateBtn.disabled = true;
  setStatus(
    'loading',
    'Verifying ad and generating key...'
  );
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
      if (response.status === 429 || err.status === 429) {
        setStatus(
          'error',
          err.message || 'Daily limit reached'
        );
        debugEl.textContent = 'You can generate up to 2 keys per day per IP.';
      } else {
        setStatus(
          'error',
          err.message || 'Something went wrong'
        );
        debugEl.textContent = 'Try again. If the issue persists, contact support.';
      }
      keyEl.className = 'empty';
      keyEl.textContent = 'Key will appear here';
      return;
    }

    const result = data.data || {};
    setStatus(
      'success',
      'Key generated successfully'
    );
    keyEl.className = '';
    keyEl.textContent = result.key;
    debugEl.textContent = `Expires: ${new Date(result.expires_at).toLocaleString()} | ${result.keys_remaining} key${result.keys_remaining !== 1 ? 's' : ''} remaining today`;
    copyBtn.style.display = 'flex';
    generateBtn.style.display = 'none';

    await navigator.clipboard.writeText(result.key).catch(() => {});
  } catch (error) {
    setStatus(
      'error',
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
  const original = copyBtn.textContent;
  copyBtn.textContent = 'Copied!';
  setTimeout(() => { copyBtn.textContent = original; }, 2000);
});

// Auto-generate if hash is already present in URL
if (hash && hash.length === 64) {
  setTimeout(() => generateBtn.click(), 1200);
}
