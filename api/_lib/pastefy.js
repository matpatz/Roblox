import { ApiError } from './errors.js';

const PASTEFY_BASE = 'https://pastefy.app/api/v2/paste';

function getToken() {
  const token = process.env.PASTEFY_API_KEY;
  if (!token) throw new ApiError(500, 'Server config missing');
  return token;
}

async function pastefyFetch(path, options = {}) {
  let response;
  try {
    response = await fetch(PASTEFY_BASE + path, {
      ...options,
      headers: {
        Authorization: `Token ${getToken()}`,
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      },
    });
  } catch (err) {
    console.error('Pastefy fetch error:', err);
    throw new ApiError(502, 'Pastefy is unreachable, try again');
  }

  let data = null;
  try { data = await response.json(); } catch (_) { /* non-JSON body */ }

  if (!response.ok) {
    const message =
      (data &&
        (data.message ||
          (data.error && data.error.message) ||
          (typeof data.error === 'string' && data.error))) ||
      `Pastefy error (${response.status})`;
    console.error('Pastefy rejected:', response.status, message);
    throw new ApiError(response.status >= 500 ? 502 : 400, message);
  }
  return data;
}

export async function createPaste(paste) {
  const data = await pastefyFetch('', {
    method: 'POST',
    body: JSON.stringify(paste),
  });
  const created = data && data.paste;
  if (!created || !created.id) throw new ApiError(502, 'Unexpected Pastefy response');
  return created;
}

export async function getPaste(id) {
  return pastefyFetch('/' + encodeURIComponent(id));
}
