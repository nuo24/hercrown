// ES256 JSON Web Tokens signed with an Apple .p8 key (App Store Server API, APNs).

const b64url = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const b64urlJson = (value: unknown) => b64url(new TextEncoder().encode(JSON.stringify(value)));

/** Signs `header.payload` with a PKCS#8 P-256 key in PEM form (newlines may be written as \n). */
export async function es256Jwt(pem: string, header: Record<string, unknown>, payload: Record<string, unknown>): Promise<string> {
  const der = Uint8Array.from(atob(pem.replace(/\\n/g, "\n").replace(/-----[^-]+-----/g, "").replace(/\s+/g, "")), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const signingInput = `${b64urlJson({ alg: "ES256", typ: "JWT", ...header })}.${b64urlJson(payload)}`;
  // WebCrypto returns the raw r||s signature that JWS ES256 expects.
  const signature = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(signingInput));
  return `${signingInput}.${b64url(new Uint8Array(signature))}`;
}
