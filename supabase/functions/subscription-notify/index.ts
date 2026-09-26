// subscription-notify — push notifications for manual bank-transfer
// subscription orders (حفار برو).
//
// verify_jwt is ON: the gateway validates the caller's access token before
// this code runs. Authorization is re-checked server-side per action.
//
// Body: { order_id: string, action: "created" | "approved" }
//
//   created  — caller must be the order's owner. Pushes
//              "أرسل {display_name} طلب اشتراك" to every admin device.
//   approved — caller must be an admin. Pushes the approval message to the
//              order owner's devices.
//
// Push markers are written to push_log best-effort AFTER the send (the
// (user_id, kind, day) unique key means a same-day resubmit/renewal just
// skips logging — it never blocks the send).
//
// Secret: FCM_SERVICE_ACCOUNT_JSON (shared with admin-push / streak-alert).

import { createClient } from "npm:@supabase/supabase-js@2";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const CHANNEL_ID = "streak_alerts";

const APPROVAL_BODY =
  "تمت الموافقة على اشتراك حفار برو! استمتع بالقلوب غير المحدودة 🎉";

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

    let payload: { order_id?: unknown; action?: unknown };
    try {
      payload = await req.json();
    } catch {
      return new Response("invalid json", { status: 400 });
    }
    const orderId =
      typeof payload.order_id === "string" && payload.order_id.length > 0
        ? payload.order_id
        : null;
    const action = payload.action;
    if (!orderId || (action !== "created" && action !== "approved")) {
      return new Response("invalid payload", { status: 400 });
    }

    const saRaw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!saRaw) return new Response("missing FCM secret", { status: 500 });
    const sa = JSON.parse(saRaw) as ServiceAccount;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: order, error: orderErr } = await supabase
      .from("subscription_orders")
      .select("id, user_id, status")
      .eq("id", orderId)
      .maybeSingle();
    if (orderErr) throw orderErr;
    if (!order) return new Response("order not found", { status: 404 });

    let title: string;
    let body: string;
    let targets: string[];
    let logKind: string;

    if (action === "created") {
      // Only the order's own owner may announce it — never trust the client.
      if (order.user_id !== sub) {
        return new Response("forbidden", { status: 403 });
      }
      if (order.status !== "pending") {
        return new Response("order not pending", { status: 409 });
      }
      const { data: caller, error: callerErr } = await supabase
        .from("profiles")
        .select("display_name")
        .eq("id", sub)
        .maybeSingle();
      if (callerErr) throw callerErr;
      const { data: admins, error: adminErr } = await supabase
        .from("profiles")
        .select("id")
        .eq("is_admin", true);
      if (adminErr) throw adminErr;
      targets = (admins ?? []).map((a) => a.id as string);
      if (targets.length === 0) {
        return Response.json({ sent: 0, dropped: 0, targets: 0 });
      }
      const name = caller?.display_name?.trim() || "مستخدم";
      title = "طلب اشتراك جديد";
      body = `أرسل ${name} طلب اشتراك`;
      logKind = "subscription_created";
    } else {
      // Approval is an admin decision — re-check server-side.
      const { data: caller, error: callerErr } = await supabase
        .from("profiles")
        .select("is_admin")
        .eq("id", sub)
        .maybeSingle();
      if (callerErr) throw callerErr;
      if (!caller?.is_admin) {
        return new Response("forbidden", { status: 403 });
      }
      if (order.status !== "approved") {
        return new Response("order not approved", { status: 409 });
      }
      targets = [order.user_id];
      title = "حفار برو";
      body = APPROVAL_BODY;
      logKind = "subscription_approved";
    }

    const { data: tokens, error: tokenErr } = await supabase
      .from("push_tokens")
      .select("token, user_id")
      .in("user_id", targets);
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
            notification: { title, body },
            android: {
              priority: "high",
              notification: { channel_id: CHANNEL_ID },
            },
            data: { type: "subscription" },
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

    // Best-effort send markers (unique (user_id, kind, day) — conflicts on a
    // same-day resubmit/renewal are expected and ignored).
    const day = new Date().toISOString().slice(0, 10);
    await supabase
      .from("push_log")
      .upsert(
        targets.map((user_id) => ({ user_id, kind: logKind, day })),
        { onConflict: "user_id,kind,day", ignoreDuplicates: true },
      );

    return Response.json({ sent, dropped, targets: rows.length });
  } catch (e) {
    console.error("subscription-notify failed", e);
    return new Response("internal error", { status: 500 });
  }
});
