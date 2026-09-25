// admin-push — admin-triggered notification via FCM HTTP v1.
//
// verify_jwt is ON: the gateway validates the caller's access token before
// this code runs, so we can trust the token payload; we still re-check
// profiles.is_admin server-side (the in-app button flag is UX only).
//
// Body: { body: string, user_id?: string, segment?: "dormant_7d" |
// "active_7d" } — omit user_id/segment to broadcast to every registered
// token; user_id wins over segment (target one user's devices).
// Sends a no-title notification on the same Android channel as streak
// alerts so it always displays.
//
// Secret: FCM_SERVICE_ACCOUNT_JSON (shared with streak-alert).

import { createClient } from "npm:@supabase/supabase-js@2";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const CHANNEL_ID = "streak_alerts";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

function decodeSub(jwt: string): string | null {
  try {
    const payload = jwt.split(".")[1];
    if (!payload) return null;
    const b64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const padded = b64 + "=".repeat((4 - (b64.length % 4)) % 4);
    const json = new TextDecoder().decode(
      Uint8Array.from(atob(padded), (c) => c.charCodeAt(0)),
    );
    const sub = JSON.parse(json).sub;
    return typeof sub === "string" && sub.length > 0 ? sub : null;
  } catch {
    return null;
  }
}

function b64url(bytes: Uint8Array | ArrayBuffer): string {
  // crypto.subtle.sign resolves to ArrayBuffer on some runtimes, which is
  // not iterable — normalize before the byte loop.
  const view = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let bin = "";
  for (const b of view) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function signJwt(
  header: Record<string, unknown>,
  payload: Record<string, unknown>,
  pem: string,
): Promise<string> {
  const enc = (o: Record<string, unknown>) =>
    b64url(new TextEncoder().encode(JSON.stringify(o)));
  const unsigned = `${enc(header)}.${enc(payload)}`;
  const der = pem
    .replace(/-----BEGIN [A-Z ]+-----/g, "")
    .replace(/-----END [A-Z ]+-----/g, "")
    .replace(/\s+/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(der), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${b64url(new Uint8Array(sig))}`;
}

/// Mint a 1h OAuth2 access token for FCM from the service account.
async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const jwt = await signJwt(
    { alg: "RS256", typ: "JWT" },
    {
      iss: sa.client_email,
      scope: FCM_SCOPE,
      aud: TOKEN_URL,
      iat: now,
      exp: now + 3600,
    },
    sa.private_key,
  );
  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=${encodeURIComponent(
        "urn:ietf:params:oauth:grant-type:jwt-bearer",
      )}&assertion=${encodeURIComponent(jwt)}`,
  });
  if (!res.ok) {
    throw new Error(`token exchange failed: ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  return data.access_token as string;
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("method not allowed", { status: 405 });
    }

    // Gateway already validated the token (verify_jwt) — read its subject.
    const auth = req.headers.get("authorization") ?? "";
    const jwt = auth.startsWith("Bearer ") ? auth.slice(7) : "";
    const sub = decodeSub(jwt);
    if (!sub) return new Response("unauthorized", { status: 401 });

    let payload: { body?: unknown; user_id?: unknown; segment?: unknown };
    try {
      payload = await req.json();
    } catch {
      return new Response("invalid json", { status: 400 });
    }
    const text = typeof payload.body === "string" ? payload.body.trim() : "";
    if (!text) return new Response("missing body", { status: 400 });
    const targetUserId =
      typeof payload.user_id === "string" && payload.user_id.length > 0
        ? payload.user_id
        : null;
    const segmentRaw = payload.segment;
    if (
      segmentRaw !== undefined &&
      segmentRaw !== null &&
      segmentRaw !== "dormant_7d" &&
      segmentRaw !== "active_7d"
    ) {
      return new Response("invalid segment", { status: 400 });
    }
    const segment =
      segmentRaw === "dormant_7d" || segmentRaw === "active_7d"
        ? segmentRaw
        : null;

    const saRaw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!saRaw) return new Response("missing FCM secret", { status: 500 });
    const sa = JSON.parse(saRaw) as ServiceAccount;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Server-side admin gate — never trust the client's is_admin flag.
    const { data: caller, error: callerErr } = await supabase
      .from("profiles")
      .select("is_admin")
      .eq("id", sub)
      .maybeSingle();
    if (callerErr) throw callerErr;
    if (!caller?.is_admin) {
      return new Response("forbidden", { status: 403 });
    }

    // Resolve audience: user_id > segment > all tokens.
    let tokenQuery = supabase.from("push_tokens").select("token, user_id");
    if (targetUserId) {
      tokenQuery = tokenQuery.eq("user_id", targetUserId);
    } else if (segment) {
      const cutoff = new Date(Date.now() - 7 * 86_400_000).toISOString();
      const profileIds: string[] = [];
      if (segment === "dormant_7d") {
        // Never engaged OR last engaged before the 7-day cutoff. Two simple
        // queries instead of .or() so ISO timestamps need no value quoting.
        const [never, stale] = await Promise.all([
          supabase.from("profiles").select("id").is("last_active_at", null),
          supabase.from("profiles").select("id").lt("last_active_at", cutoff),
        ]);
        if (never.error) throw never.error;
        if (stale.error) throw stale.error;
        profileIds.push(
          ...(never.data ?? []).map((r) => r.id),
          ...(stale.data ?? []).map((r) => r.id),
        );
      } else {
        const recent = await supabase
          .from("profiles")
          .select("id")
          .gte("last_active_at", cutoff);
        if (recent.error) throw recent.error;
        profileIds.push(...(recent.data ?? []).map((r) => r.id));
      }
      if (profileIds.length === 0) {
        return Response.json({
          sent: 0,
          dropped: 0,
          targets: 0,
          segment,
        });
      }
      tokenQuery = tokenQuery.in("user_id", profileIds);
    }
    const { data: tokens, error: tokenErr } = await tokenQuery;
    if (tokenErr) throw tokenErr;
    const rows = tokens ?? [];
    if (rows.length === 0) {
      return Response.json({ sent: 0, dropped: 0, targets: 0 });
    }

    const bearer = await accessToken(sa);
    const fcmUrl =
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    let sent = 0;
    let dropped = 0;
    for (const row of rows as Array<{ token: string }>) {
      const res = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${bearer}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: row.token,
            notification: { body: text },
            android: {
              priority: "high",
              notification: { channel_id: CHANNEL_ID },
            },
            data: { type: "admin_message" },
          },
        }),
      });

      if (res.status === 404) {
        // UNREGISTERED / token gone — prune it permanently.
        await supabase.from("push_tokens").delete().eq("token", row.token);
        dropped++;
      } else if (!res.ok) {
        console.error(`FCM send failed ${res.status}: ${await res.text()}`);
      } else {
        sent++;
      }
    }

    return Response.json({
      sent,
      dropped,
      targets: rows.length,
      ...(segment ? { segment } : {}),
    });
  } catch (e) {
    console.error("admin-push failed", e);
    return new Response("internal error", { status: 500 });
  }
});
