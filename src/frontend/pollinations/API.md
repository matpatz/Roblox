# Pollinations API — Understanding

Base URL: `https://gen.pollinations.ai`

Auth: `Authorization: Bearer <pk_ or sk_ key>` header, or `?key=` query param.
Keys from [enter.pollinations.ai](https://enter.pollinations.ai/keys).

## The endpoint I care about

`GET /text/{prompt}` — Simple Text Generation.
Simplified alternative to the OpenAI-compatible `/v1/chat/completions`. Returns **plain text**. Good for quick prototyping.

### Path params

| param | type | notes |
|-------|------|-------|
| `prompt` | string, min 1 | URL-encoded text prompt. e.g. `Write%20a%20haiku` |

### Query params (all optional)

| param | type | default | notes |
|-------|------|---------|-------|
| `model` | string | — | e.g. `openai`, `openai-fast`, `deepseek`, `gemini-flash-lite-3.5`, etc. Full list via `/v1/models` or `/text/models` |
| `system` | string | — | system prompt / context set before the user prompt |
| `json` | boolean | false | when `true`, model returns valid JSON |
| `seed` | integer (-1 … max) | -1 | reproducibility; `-1` = stable compat seed |
| `temperature` | number (0.0–2.0) | — | 0.2 focused, 1.5 creative |
| `top_p` | number | — | nucleus sampling |
| `presence_penalty` | number | — | -2 … 2 |
| `frequency_penalty` | number | — | -2 … 2 |
| `repetition_penalty` | number | — | |
| `max_tokens` | integer | — | cap output length |
| `max_completion_tokens` | integer | — | alt cap |
| `reasoning_effort` | string | — | e.g. `none` / `low` / `medium` / `high` on reasoning models |
| `voice` | string | — | for audio output models |
| `stream` | boolean | false | SSE streaming, each chunk = partial text |
| `safe` | string\|boolean | off | comma list: `privacy,secrets,sexual,violence,shield,true,nsfw`. `true` = `privacy,secrets`; `nsfw` = `sexual,violence`. Also via `Pollinations-Safe` header |

### Example

```bash
curl "https://gen.pollinations.ai/text/Write%20a%20haiku?model=openai" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Response

- `200` — generated text, `text/plain`
- `400` — bad input
- `401` — missing/invalid API key
- `402` — insufficient pollen balance / key budget exhausted
- `403` — no permission for that resource/model
- `429` — rate limited
- `500` — server error

## Related text endpoints (OpenAI-compatible)

| endpoint | use when |
|----------|----------|
| `POST /v1/chat/completions` | need full OpenAI-compatible JSON: streaming, tools, vision, structured outputs |
| `POST /v1/responses` | stateless OpenAI Responses: input/output items, semantic SSE events, function tools |
| `POST /text` | generate from an OpenAI `messages` array, return just the assistant content |
| `GET /text/{prompt}` | quickest — plain GET, plain text out |

Any OpenAI SDK works by just changing the base URL to `https://gen.pollinations.ai`.

## Gotchas / rules of thumb

- **Auth is now required** (bearer key). No anonymous free tier on these docs.
- Error `402` specifically = billing/pollen, not a code bug.
- `stream=true` returns SSE; the non-stream `200` is `text/plain`.
- For JSON output, use `json=true` (GET) or `response_format: { "type": "json_object" }` (POST) — not just `"output JSON"` in the prompt.
- Models are prefixed/mixed vendors — some names collide, so check `/text/models` for exact advertised names + capabilities (reasoning, responses, audio, vision).
