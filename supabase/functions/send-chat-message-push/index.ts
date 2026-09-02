// Notify other chat participants via FCM (HTTP v1). Skips users with this chat open recently.
// Secrets: SUPABASE_* (auto), FIREBASE_SERVICE_ACCOUNT_JSON (Firebase service account JSON string).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { GoogleAuth } from "npm:google-auth-library@9.15.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const ACTIVE_WINDOW_MS = 90_000;

type Body = { chat_id?: string; message_id?: string };

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? "";

  if (!supabaseUrl || !serviceKey || !anonKey) {
    return new Response(JSON.stringify({ error: "Missing Supabase env" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!saJson) {
    return new Response(
      JSON.stringify({
        error: "FIREBASE_SERVICE_ACCOUNT_JSON not configured",
        skipped: true,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: Body;
  try {
    body = (await req.json()) as Body;
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const chatId = body.chat_id?.trim();
  if (!chatId) {
    return new Response(JSON.stringify({ error: "chat_id required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const jwt = authHeader.replace(/^Bearer\s+/i, "");
  const admin = createClient(supabaseUrl, serviceKey);

  const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
  const senderId = userData.user?.id;
  if (userErr || !senderId) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { data: isParticipant, error: partErr } = await admin.rpc(
    "is_chat_participant",
    { p_chat_id: chatId, p_uid: senderId },
  );
  if (partErr || isParticipant !== true) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { data: chatRow, error: chatErr } = await admin
    .from("chats")
    .select("request_id")
    .eq("id", chatId)
    .maybeSingle();
  if (chatErr || !chatRow?.request_id) {
    return new Response(JSON.stringify({ error: "Chat not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const requestId = chatRow.request_id as string;

  const { data: reqRow, error: reqErr } = await admin
    .from("requests")
    .select("user_id")
    .eq("id", requestId)
    .maybeSingle();
  if (reqErr || !reqRow?.user_id) {
    return new Response(JSON.stringify({ error: "Request not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const requesterId = reqRow.user_id as string;

  const { data: responses, error: rrErr } = await admin
    .from("request_responses")
    .select("driver_id")
    .eq("request_id", requestId)
    .in("status", ["pending", "accepted"]);
  if (rrErr) {
    return new Response(JSON.stringify({ error: rrErr.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const participantIds = new Set<string>([requesterId]);
  for (const row of responses ?? []) {
    const d = row.driver_id as string | undefined;
    if (d) participantIds.add(d);
  }

  if (!participantIds.has(senderId)) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const messageId = body.message_id?.trim();
  let lastMsg: {
    message: string | null;
    image_url: string | null;
    sender_id: string;
  } | null = null;

  if (messageId) {
    const { data: row, error: midErr } = await admin
      .from("messages")
      .select("message, image_url, sender_id, created_at")
      .eq("id", messageId)
      .eq("chat_id", chatId)
      .maybeSingle();
    if (midErr || !row || String(row.sender_id) !== String(senderId)) {
      return new Response(JSON.stringify({ error: "Invalid message_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    lastMsg = row as typeof lastMsg;
  } else {
    const { data: row, error: msgErr } = await admin
      .from("messages")
      .select("message, image_url, sender_id, created_at")
      .eq("chat_id", chatId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (msgErr || !row || String(row.sender_id) !== String(senderId)) {
      return new Response(JSON.stringify({ error: "No recent message from caller" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    lastMsg = row as typeof lastMsg;
  }

  const preview = (lastMsg!.image_url as string | null)?.trim()
    ? "Photo"
    : (((lastMsg!.message as string | null) ?? "").trim() || "New message");

  const { data: senderProfile } = await admin
    .from("profiles")
    .select("name")
    .eq("id", senderId)
    .maybeSingle();
  const senderName = ((senderProfile?.name as string | null) ?? "").trim() ||
    "Someone";

  let serviceAccount: { project_id: string; client_email?: string };
  try {
    serviceAccount = JSON.parse(saJson);
  } catch {
    return new Response(JSON.stringify({ error: "Invalid service account JSON" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: [FCM_SCOPE],
  });
  const client = await auth.getClient();
  const access = await client.getAccessToken();
  const token = access.token;
  if (!token) {
    return new Response(JSON.stringify({ error: "No OAuth token for FCM" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const projectId = serviceAccount.project_id;
  const fcmUrl =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const recipients = [...participantIds].filter((id) => id !== senderId);
  let sent = 0;
  const now = Date.now();

  for (const recipientId of recipients) {
    const { data: profile } = await admin
      .from("profiles")
      .select("fcm_token, active_chat_id, active_chat_at")
      .eq("id", recipientId)
      .maybeSingle();

    const fcmToken = (profile?.fcm_token as string | null)?.trim();
    if (!fcmToken) continue;

    const activeId = profile?.active_chat_id as string | null | undefined;
    const activeAt = profile?.active_chat_at as string | null | undefined;
    if (
      activeId === chatId && activeAt &&
      now - new Date(activeAt).getTime() < ACTIVE_WINDOW_MS
    ) {
      continue;
    }

    const res = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: senderName,
            body: preview.length > 120 ? preview.slice(0, 117) + "…" : preview,
          },
          data: {
            chatId,
            requestId,
          },
          android: { priority: "HIGH" },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        },
      }),
    });

    if (res.ok) {
      sent++;
    } else {
      const t = await res.text();
      console.error("FCM error", recipientId, res.status, t);
    }
  }

  return new Response(JSON.stringify({ ok: true, sent, recipients: recipients.length }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
