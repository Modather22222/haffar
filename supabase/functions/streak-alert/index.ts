// streak-alert — daily "streak in danger" push via FCM HTTP v1.
//
// Triggered by pg_cron at 18:00 UTC (see migration). For every profile with
// streak > 0 that has NOT completed anything today (UTC), sends a no-title
// notification whose body is:
//   "يا بطل streak بتاعك في خطر! ما قريت اليوم ادخل هسي قبل ما تخسر [x] يوم!"
// once per day per user (dedup via push_log). Stale FCM tokens are pruned.
//
// Secrets: FCM_SERVICE_ACCOUNT_JSON, STREAK_ALERT_SECRET (caller auth).

import { createClient } from "npm:@supabase/supabase-js@2";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const CHANNEL_ID = "streak_alerts";
// Publicly hosted flame icon shown as the notification's large image.
const STREAK_IMAGE_URL =
  "https://qfngbhrlqyojfwoadher.supabase.co/storage/v1/object/public/assets/icons/streak.png";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

function b64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
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
    // Light auth: cron (or we, manually) must present the shared secret.
    const secret = Deno.env.get("STREAK_ALERT_SECRET") ?? "";
    if (!secret || req.headers.get("authorization") !== `Bearer ${secret}`) {
      return new Response("forbidden", { status: 401 });
    }

    const saRaw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!saRaw) return new Response("missing FCM secret", { status: 500 });
    const sa = JSON.parse(saRaw) as ServiceAccount;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Day boundary matches the streak RPCs: UTC date.
    // Only "yesterday" qualifies: completed today → already safe; 2+ days
    // stale → refresh_streak will zero it anyway, so the alert is moot.
    const now = new Date();
    const today = now.toISOString().slice(0, 10);
    const lastCall = new Date(now.getTime());
    lastCall.setUTCDate(lastCall.getUTCDate() - 1);
    const yesterday = lastCall.toISOString().slice(0, 10);

    const { data: users, error } = await supabase
      .from("profiles")
      .select("id, streak, push_tokens(token)")
      .gt("streak", 0)
      .eq("last_streak_date", yesterday);
    if (error) throw error;

    let sent = 0;
    let deduped = 0;
    let dropped = 0;

    if (users && users.length > 0) {
      const bearer = await accessToken(sa);
      const fcmUrl =
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

      for (const u of users as Array<{
        id: string;
        streak: number;
        push_tokens: Array<{ token: string }> | null;
      }>) {
        const tokens = u.push_tokens ?? [];
        if (tokens.length === 0) continue;

        // One alert per user per day — insert wins, conflict skips the send.
        const { data: inserted } = await supabase
          .from("push_log")
          .insert({ user_id: u.id, kind: "streak", day: today })
          .select("user_id");
        if (!inserted || inserted.length === 0) {
          deduped++;
          continue;
        }

        for (const t of tokens) {
          const res = await fetch(fcmUrl, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${bearer}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token: t.token,
                notification: {
                  body:
                    `يا بطل streak 🔥 بتاعك في خطر! ما قريت اليوم ادخل هسي قبل ما تخسر ${u.streak} يوم!`,
                },
                android: {
                  priority: "high",
                  notification: {
                    channel_id: CHANNEL_ID,
                    image: STREAK_IMAGE_URL,
                  },
                },
                data: { type: "streak_alert" },
              },
            }),
          });

          if (res.status === 404) {
            // UNREGISTERED / token gone — prune it permanently.
            await supabase.from("push_tokens").delete().eq("token", t.token);
            dropped++;
          } else if (!res.ok) {
            console.error(`FCM send failed ${res.status}: ${await res.text()}`);
          } else {
            sent++;
          }
        }
      }
    }

    return Response.json({ sent, deduped, dropped, candidates: users?.length ?? 0 });
  } catch (e) {
    console.error("streak-alert failed", e);
    return new Response("internal error", { status: 500 });
  }
});
