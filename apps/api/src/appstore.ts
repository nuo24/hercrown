// App Store Server API client (developer.apple.com/documentation/appstoreserverapi).
// Requests are authorized with a short-lived ES256 JWT signed by the app's In-App Purchase key.
// Responses come straight from Apple over TLS with that authorization, so their signed payloads are
// decoded without re-verifying Apple's certificate chain (hardening option: verify x5c against Apple Root CA G3).
import { HttpError } from "./http";

const BASE = { production: "https://api.storekit.apple.com", sandbox: "https://api.storekit-sandbox.apple.com" } as const;
export type AppleEnvironment = keyof typeof BASE;

/** Subscription status values from Apple's `status` type. */
export const APPLE_STATUS = { ACTIVE: 1, EXPIRED: 2, BILLING_RETRY: 3, GRACE: 4, REVOKED: 5 } as const;

export interface AppleTransaction {
  transactionId: string;
  originalTransactionId: string;
  bundleId: string;
  productId: string;
  type?: string;
  expiresDate?: number;
  revocationDate?: number;
  offerType?: number;
  offerDiscountType?: string;
  environment?: "Sandbox" | "Production";
  appAccountToken?: string;
}

export interface AppleRenewalInfo {
  autoRenewStatus?: 0 | 1;
  gracePeriodExpiresDate?: number;
  isInBillingRetryPeriod?: boolean;
}

export interface AppleSubscription {
  status: number;
  transaction: AppleTransaction;
  renewal: AppleRenewalInfo | null;
}

export interface AppleStatusResult {
  environment: AppleEnvironment;
  bundleId: string;
  subscriptions: AppleSubscription[];
}

const unavailable = (message: string) => new HttpError(503, "restore_unavailable", message);

const b64url = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const b64urlJson = (value: unknown) => b64url(new TextEncoder().encode(JSON.stringify(value)));

export function appStoreConfigured(env: Env) {
  return Boolean(env.APP_STORE_ISSUER_ID && env.APP_STORE_KEY_ID && env.APP_STORE_PRIVATE_KEY);
}

/** ES256 JWT for the App Store Server API: kid, iss, aud "appstoreconnect-v1", bid, ≤ 60 min lifetime. */
export async function appStoreJwt(env: Env, now = Date.now()): Promise<string> {
  const pem = env.APP_STORE_PRIVATE_KEY.replace(/\\n/g, "\n");
  const der = Uint8Array.from(atob(pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "")), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const iat = Math.floor(now / 1000);
  const header = b64urlJson({ alg: "ES256", kid: env.APP_STORE_KEY_ID, typ: "JWT" });
  const payload = b64urlJson({ iss: env.APP_STORE_ISSUER_ID, iat, exp: iat + 20 * 60, aud: "appstoreconnect-v1", bid: env.APPLE_APP_BUNDLE_IDENTIFIER });
  // WebCrypto returns the raw r||s signature that JWS ES256 expects.
  const signature = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(`${header}.${payload}`));
  return `${header}.${payload}.${b64url(new Uint8Array(signature))}`;
}

/** Decodes the payload of a JWS returned by Apple (see note at the top of this file). */
export function decodeJws<T>(jws: string): T {
  const part = jws.split(".")[1];
  if (!part) throw new Error("Malformed JWS");
  const json = atob(part.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(part.length / 4) * 4, "="));
  return JSON.parse(new TextDecoder().decode(Uint8Array.from(json, (c) => c.charCodeAt(0)))) as T;
}

interface StatusResponse {
  environment?: string;
  bundleId?: string;
  data?: { lastTransactions?: { originalTransactionId: string; status: number; signedTransactionInfo: string; signedRenewalInfo?: string }[] }[];
}

/** One call to "Get All Subscription Statuses" in one environment. `null` = Apple doesn't know this transaction there. */
async function statusesIn(env: Env, environment: AppleEnvironment, transactionId: string): Promise<AppleStatusResult | null> {
  if (!appStoreConfigured(env)) throw unavailable("Purchase restore isn't configured on this server yet");
  let res: Response;
  try {
    res = await fetch(`${BASE[environment]}/inApps/v1/subscriptions/${encodeURIComponent(transactionId)}`, {
      headers: { authorization: `Bearer ${await appStoreJwt(env)}` },
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw unavailable("The App Store didn't respond. Please try again.");
  }
  if (res.status === 404) return null; // TransactionIdNotFound / AccountNotFound / AppNotFound
  if (res.status === 400) throw new HttpError(400, "invalid_request", "The App Store didn't accept this transaction id");
  if (res.status === 401) {
    console.error("App Store Server API rejected our credentials (401)");
    throw unavailable("Purchase restore is misconfigured on this server");
  }
  if (!res.ok) {
    console.error("App Store Server API", res.status, await res.text().catch(() => ""));
    throw unavailable("The App Store is busy. Please try again shortly.");
  }

  const body = await res.json<StatusResponse>();
  const subscriptions = (body.data ?? []).flatMap((group) => group.lastTransactions ?? []).map((item) => ({
    status: item.status,
    transaction: decodeJws<AppleTransaction>(item.signedTransactionInfo),
    renewal: item.signedRenewalInfo ? decodeJws<AppleRenewalInfo>(item.signedRenewalInfo) : null,
  }));
  return { environment, bundleId: body.bundleId ?? "", subscriptions };
}

/**
 * Looks a transaction up in production, then (if allowed) in the sandbox, as Apple recommends:
 * App Review and TestFlight purchases are sandbox transactions even against a production server.
 */
export async function subscriptionStatuses(env: Env, transactionId: string): Promise<AppleStatusResult | null> {
  return (await statusesIn(env, "production", transactionId))
    ?? (env.APP_STORE_ALLOW_SANDBOX === "true" ? await statusesIn(env, "sandbox", transactionId) : null);
}
