// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Replace newline characters in private key if they were escaped
function formatPrivateKey(key: string) {
  return key.replace(/\\n/g, '\n');
}

async function getFCMToken(clientEmail: string, privateKey: string) {
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };

  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;

  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp,
    iat,
  };

  const formattedKey = formatPrivateKey(privateKey);
  const keyObj = await importPKCS8(formattedKey, 'RS256');

  const jwt = await new SignJWT(payload)
    .setProtectedHeader(header)
    .sign(keyObj);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const data = await response.json();
  return data.access_token;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { title, body, fcm_token, tag, channel_id, silent, sender_id, type, payload } = await req.json();

    if (!fcm_token) {
      throw new Error("Missing fcm_token in request payload");
    }

    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKey = Deno.env.get('FCM_PRIVATE_KEY');
    const projectId = Deno.env.get('FCM_PROJECT_ID');

    if (!clientEmail || !privateKey || !projectId) {
      throw new Error("Server configuration error: Missing FCM Secrets");
    }

    const accessToken = await getFCMToken(clientEmail, privateKey);

    const dataPayload: Record<string, string> = {
      title: title || '',
      body: body || '',
      type: type || (channel_id === 'pigeon_messages' ? 'message' : 'activity'),
      channel_id: channel_id || '',
      sender_id: sender_id || '',
      tag: tag || '',
      payload: payload || (sender_id ? (type === 'message' ? `message:${sender_id}` : `profile:${sender_id}`) : ''),
    };

    const message = {
      message: {
        token: fcm_token,
        notification: {
          title,
          body,
        },
        data: dataPayload,
        android: {
          priority: silent ? 'normal' : 'high',
          notification: { 
            ...(silent ? {} : { sound: 'default' }),
            ...(channel_id && { channel_id }),
            ...(tag && { tag })
          }
        },
        apns: {
          ...(tag && { headers: { "apns-collapse-id": tag } }),
          payload: { 
            aps: { 
              ...(silent ? {} : { sound: 'default' }) 
            } 
          }
        }
      }
    };

    const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    });

    if (!fcmResponse.ok) {
      const errorText = await fcmResponse.text();
      throw new Error(`FCM API Error: ${errorText}`);
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
