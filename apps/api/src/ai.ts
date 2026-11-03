// Model calls: OpenRouter (DeepSeek by default), optionally through Cloudflare AI Gateway (ai-app-playbook chapter 05).
// Streams tokens, falls back to a second model, times out, and logs every call with its cost (usage_ledger + ai_call).
import type { Tracker } from "./events";
import { HttpError } from "./http";

export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface AiUsage {
  model: string;
  promptTokens: number;
  completionTokens: number;
  costUsd: number;
  latencyMs: number;
}

const FIRST_TOKEN_TIMEOUT_MS = 25_000;
const TOTAL_TIMEOUT_MS = 90_000;

export function aiConfigured(env: Env) {
  return Boolean(env.OPENROUTER_API_KEY);
}

/** OpenRouter's chat endpoint, through AI Gateway when AI_GATEWAY_URL is set (…/v1/{account}/{gateway}/openrouter). */
function endpoint(env: Env) {
  return `${(env.AI_GATEWAY_URL || "https://openrouter.ai/api").replace(/\/$/, "")}/v1/chat/completions`;
}

const unavailable = () => new HttpError(503, "study_unavailable", "Study tools are busy right now. Try again in a moment.");

/**
 * Streams a completion. Yields text deltas; returns usage when done. Throws `study_unavailable` (503) if the model can't
 * be reached or stops sending.
 */
export async function* streamChat(
  env: Env,
  messages: ChatMessage[],
  opts: { maxTokens: number; temperature?: number },
): AsyncGenerator<string, AiUsage> {
  if (!aiConfigured(env)) throw new HttpError(503, "study_unavailable", "Study tools aren't configured on this server yet.");
  const started = Date.now();
  const abort = new AbortController();
  let timer = setTimeout(() => abort.abort(), FIRST_TOKEN_TIMEOUT_MS);
  const total = setTimeout(() => abort.abort(), TOTAL_TIMEOUT_MS);
  const models = [env.STUDY_MODEL, env.STUDY_FALLBACK_MODEL].filter(Boolean);

  try {
    let res: Response;
    try {
      res = await fetch(endpoint(env), {
        method: "POST",
        headers: {
          authorization: `Bearer ${env.OPENROUTER_API_KEY}`,
          "content-type": "application/json",
          "x-title": "Bible Scroll",
        },
        body: JSON.stringify({
          model: models[0], models, messages, stream: true, max_tokens: opts.maxTokens,
          temperature: opts.temperature ?? 0.3, usage: { include: true },
          // Reasoning models spend tokens "thinking" first. STUDY_REASONING: off (default) | low | medium | high.
          reasoning: !env.STUDY_REASONING || env.STUDY_REASONING === "off" ? { enabled: false } : { effort: env.STUDY_REASONING, exclude: true },
        }),
        signal: abort.signal,
      });
    } catch (err) {
      console.error("ai: request failed", err);
      throw unavailable();
    }
    if (!res.ok || !res.body) {
      console.error(`ai: OpenRouter ${res.status}`, (await res.text().catch(() => "")).slice(0, 300));
      throw unavailable();
    }

    const usage: AiUsage = { model: models[0]!, promptTokens: 0, completionTokens: 0, costUsd: 0, latencyMs: 0 };
    const reader = res.body.pipeThrough(new TextDecoderStream()).getReader();
    let buffer = "";
    let finished = false;
    for (;;) {
      let chunk: ReadableStreamReadResult<string>;
      try {
        chunk = await reader.read();
      } catch (err) {
        console.error("ai: stream broke", err);
        throw unavailable();
      }
      if (chunk.done) break;
      buffer += chunk.value;
      let newline: number;
      while ((newline = buffer.indexOf("\n")) >= 0) {
        const line = buffer.slice(0, newline).trim();
        buffer = buffer.slice(newline + 1);
        if (!line.startsWith("data:")) continue; // ": OPENROUTER PROCESSING" keep-alives
        const data = line.slice(5).trim();
        if (data === "[DONE]") { finished = true; continue; }
        let json: any;
        try { json = JSON.parse(data); } catch { continue; }
        if (json.error) {
          console.error("ai: provider error", JSON.stringify(json.error).slice(0, 300));
          throw unavailable();
        }
        if (typeof json.model === "string") usage.model = json.model;
        if (json.usage) {
          usage.promptTokens = json.usage.prompt_tokens ?? 0;
          usage.completionTokens = json.usage.completion_tokens ?? 0;
          usage.costUsd = typeof json.usage.cost === "number" ? json.usage.cost : 0;
        }
        const delta = json.choices?.[0]?.delta?.content;
        if (json.choices?.[0]?.delta?.reasoning) { // still thinking: alive, nothing to show
          clearTimeout(timer);
          timer = setTimeout(() => abort.abort(), FIRST_TOKEN_TIMEOUT_MS);
        }
        if (typeof delta === "string" && delta) {
          clearTimeout(timer);
          timer = setTimeout(() => abort.abort(), FIRST_TOKEN_TIMEOUT_MS); // also the longest silence allowed
          yield delta;
        }
      }
    }
    if (!finished && usage.completionTokens === 0) throw unavailable();
    usage.latencyMs = Date.now() - started;
    return usage;
  } finally {
    clearTimeout(timer);
    clearTimeout(total);
  }
}

/** Records an AI call: usage_ledger (quota + cost per person) and an `ai_call` analytics event. */
export async function logAiCall(env: Env, tracker: Tracker | undefined, userId: string, feature: string, usage: AiUsage | null, ok: boolean) {
  const cost = usage?.costUsd ?? 0;
  await env.DB.prepare(
    "INSERT INTO usage_ledger (id, user_id, feature, units, cost_micros, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
  ).bind(crypto.randomUUID(), userId, feature, (usage?.promptTokens ?? 0) + (usage?.completionTokens ?? 0),
    Math.round(cost * 1_000_000), Date.now()).run();
  tracker?.track("ai_call", {
    feature, model: usage?.model ?? env.STUDY_MODEL, tokens_in: usage?.promptTokens ?? 0, tokens_out: usage?.completionTokens ?? 0,
    latency_ms: usage?.latencyMs ?? 0, cost_usd: cost, ok,
  });
}
