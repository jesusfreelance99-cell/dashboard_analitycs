import * as jwt from 'jsonwebtoken';

const ISSUER_ID = 'b95f788d-d6ca-4e73-8971-f29396be38bf';
const KEY_ID = 'M42Q63YUM4';

export function generateAppleJWT(privateKey: string): string {
  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    { iss: ISSUER_ID, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' },
    privateKey,
    { algorithm: 'ES256', header: { alg: 'ES256', kid: KEY_ID, typ: 'JWT' } }
  );
}

export async function appleGet(url: string, token: string): Promise<Response> {
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  return res;
}
