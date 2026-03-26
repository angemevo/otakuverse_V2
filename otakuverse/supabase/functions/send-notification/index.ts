import { serve }        from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ─── Types ───────────────────────────────────────────────────────────
interface NotificationPayload {
  userId: string
  title:  string
  body:   string
  data?:  Record<string, string>
}

interface ServiceAccount {
  client_email: string
  private_key:  string
}

// ─── Handler principal ───────────────────────────────────────────────
serve(async (req: Request): Promise<Response> => {
  try {
    const { userId, title, body, data }:
        NotificationPayload = await req.json()

    // ✅ Validation basique
    if (!userId || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'userId, title et body requis' }),
        { status: 400,
          headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')    ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // ✅ Récupérer le token FCM
    const { data: tokenData, error } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', userId)
      .single()

    if (error || !tokenData?.token) {
      return new Response(
        JSON.stringify({ error: 'Token FCM introuvable' }),
        { status: 404,
          headers: { 'Content-Type': 'application/json' } }
      )
    }

    // ✅ Obtenir le token OAuth2
    const accessToken = await _getAccessToken()
    const projectId   = Deno.env.get('FIREBASE_PROJECT_ID') ?? ''

    // ✅ Envoyer via FCM v1
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type':  'application/json',
        },
        body: JSON.stringify({
          message: {
            token:        tokenData.token,
            notification: { title, body },
            data:         data ?? {},
            android: {
              priority: 'high',
            },
            apns: {
              payload: {
                aps: { sound: 'default' },
              },
            },
          },
        }),
      }
    )

    const result = await fcmResponse.json()

    return new Response(
      JSON.stringify(result),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (e: unknown) {
    // ✅ Fix — e est de type unknown
    const message = e instanceof Error
        ? e.message
        : 'Erreur inconnue'

    return new Response(
      JSON.stringify({ error: message }),
      { status: 500,
        headers: { 'Content-Type': 'application/json' } }
    )
  }
})

// ─── Générer token OAuth2 ─────────────────────────────────────────────
async function _getAccessToken(): Promise<string> {
  const raw            = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}'
  const serviceAccount = JSON.parse(raw) as ServiceAccount

  const now     = Math.floor(Date.now() / 1000)
  const payload = {
    iss:   serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud:   'https://oauth2.googleapis.com/token',
    iat:   now,
    exp:   now + 3600,
  }

  // ✅ Encoder header + payload en base64url
  const header  = _toBase64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const body    = _toBase64Url(JSON.stringify(payload))
  const signing = `${header}.${body}`

  // ✅ Importer la clé privée
  const keyData = await crypto.subtle.importKey(
    'pkcs8',
    _pemToArrayBuffer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  // ✅ Signer
  const signature  = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    keyData,
    new TextEncoder().encode(signing)
  )

  const jwt = `${signing}.${_toBase64Url(
    String.fromCharCode(...new Uint8Array(signature))
  )}`

  // ✅ Échanger contre un access token
  const tokenRes = await fetch(
    'https://oauth2.googleapis.com/token',
    {
      method:  'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion:  jwt,
      }),
    }
  )

  const tokenData = await tokenRes.json() as { access_token: string }
  return tokenData.access_token
}

// ─── Helpers ─────────────────────────────────────────────────────────
function _toBase64Url(str: string): string {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g,  '')
}

function _pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g,   '')
    .replace(/\n/g, '')
    .trim()

  const binary = atob(base64)
  const buffer = new ArrayBuffer(binary.length)
  const view   = new Uint8Array(buffer)

  for (let i = 0; i < binary.length; i++) {
    view[i] = binary.charCodeAt(i)
  }

  return buffer
}