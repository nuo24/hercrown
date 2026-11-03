// Small HTTP helpers shared by every route.

export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message?: string,
  ) {
    super(message ?? code);
  }
}

export const badRequest = (message: string) => new HttpError(400, "invalid_request", message);
export const notFound = (message = "Not found") => new HttpError(404, "not_found", message);

export function errorResponse(err: HttpError): Response {
  return Response.json({ error: err.code, message: err.message }, { status: err.status });
}

const MAX_JSON_BYTES = 256 * 1024;

/** Parses a JSON object body; anything else is a 400. */
export async function readJson(request: Request): Promise<Record<string, unknown>> {
  const text = await request.text();
  if (text.length > MAX_JSON_BYTES) throw new HttpError(413, "too_large", "Request body is too large");
  let body: unknown;
  try {
    body = JSON.parse(text || "{}");
  } catch {
    throw badRequest("Body must be valid JSON");
  }
  if (!body || typeof body !== "object" || Array.isArray(body)) throw badRequest("Body must be a JSON object");
  return body as Record<string, unknown>;
}

/** Optional trimmed string with a maximum length. `null` clears the value; `undefined` leaves it unchanged. */
export function optionalText(body: Record<string, unknown>, key: string, max: number): string | null | undefined {
  const value = body[key];
  if (value === undefined || value === null) return value;
  if (typeof value !== "string") throw badRequest(`${key} must be a string`);
  const trimmed = value.trim();
  if (trimmed.length > max) throw badRequest(`${key} must be at most ${max} characters`);
  return trimmed || null;
}

export function oneOf<T extends string>(body: Record<string, unknown>, key: string, allowed: readonly T[]): T | null | undefined {
  const value = body[key];
  if (value === undefined || value === null) return value;
  if (typeof value !== "string" || !allowed.includes(value as T)) {
    throw badRequest(`${key} must be one of: ${allowed.join(", ")}`);
  }
  return value as T;
}
