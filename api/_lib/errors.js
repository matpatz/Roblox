export class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function errorResponse(res, status, message) {
  return res.status(status).json({ error: { status, message } });
}

export function handleApiError(res, err) {
  if (err instanceof ApiError) {
    return errorResponse(res, err.status, err.message);
  }
  console.error('Unhandled:', err.message || err);
  return errorResponse(res, 500, 'Internal error');
}
