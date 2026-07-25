export class ApiError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

export function errorResponse(res, status, message, details) {
  const body = { error: { status, message } };
  if (details) body.error.details = details;
  return res.status(status).json(body);
}

export function handleApiError(res, err) {
  if (err instanceof ApiError) {
    return errorResponse(res, err.status, err.message, err.details);
  }
  console.error('Unhandled error:', err);
  return errorResponse(res, 500, 'Internal server error');
}
