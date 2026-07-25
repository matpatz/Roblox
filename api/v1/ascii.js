import sharp from 'sharp';
import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { ApiError } from '../_lib/errors.js';

const CHARS = ' .\'`^",:;Il!i><~+_-?][}{1)(|/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$';

function toHex(r, g, b) {
  return '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('');
}

function pixelsToRichText(data, width, height, cols) {
  const cellW = width / cols;
  const cellH = cellW * 2.2;
  const rows = Math.floor(height / cellH);
  const lines = [];

  for (let row = 0; row < rows; row++) {
    let line = '';
    let lastHex = null;

    for (let col = 0; col < cols; col++) {
      const px = Math.floor((col + 0.5) * cellW);
      const py = Math.floor((row + 0.5) * cellH);
      const idx = (py * width + px) * 4;
      const r = data[idx];
      const g = data[idx + 1];
      const b = data[idx + 2];
      const a = data[idx + 3] / 255;
      const lum = (0.299 * r + 0.587 * g + 0.114 * b) * a;
      const char = CHARS[Math.floor((lum / 255) * (CHARS.length - 1))];
      const hex = toHex(Math.round(r * a), Math.round(g * a), Math.round(b * a));

      if (hex !== lastHex) {
        if (lastHex !== null) line += '</font>';
        line += `<font color="${hex}">`;
        lastHex = hex;
      }

      if (char === '&') line += '&amp;';
      else if (char === '<') line += '&lt;';
      else if (char === '>') line += '&gt;';
      else if (char === '"') line += '&quot;';
      else line += char;
    }

    if (lastHex !== null) line += '</font>';
    lines.push(line);
  }

  return lines.join('\n');
}

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');

  const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request body');

  const { image, columns } = body;
  if (!image) throw new ApiError(400, 'Missing "image" field');

  const cols = Math.min(Math.max(parseInt(columns) || 80, 10), 200);
  const b64data = image.includes(',') ? image.split(',')[1] : image;
  const buffer = Buffer.from(b64data, 'base64');

  let raw, width, height;
  try {
    const img = sharp(buffer).ensureAlpha();
    const meta = await img.metadata();
    width = meta.width;
    height = meta.height;
    raw = await img.raw().toBuffer();
  } catch (err) {
    throw new ApiError(400, 'Could not decode image');
  }

  const ascii = pixelsToRichText(raw, width, height, cols);
  return successResponse(res, req, { ascii });
}

export { handler_fn as handler };
