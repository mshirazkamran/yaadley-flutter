# Yaadly: Setup checklist

> What you (the owner) need to set up so every part of Yaadly works. Identical copy in `yaadley-backend/` and `yaadley-flutter/`.
> Secrets go into `yaadley-backend/.env` on the VPS only. Never commit them or paste them in chat.
> **Last updated:** 2026-10-29

## Status

| Area | Status |
|---|---|
| VPS + Docker + Caddy, `yaadley-api.mshiraz.com` | ✅ Live |
| WhatsApp (Meta app `shiraz`, new portfolio, app Live, WABA subscribed) | ✅ Working |
| Privacy / terms / data-deletion pages | ✅ Live |
| Groq | ✅ |
| Google Calendar | ⬜ Section 1 |
| `JWT_SECRET` (app login, M5) | ⬜ Section 2 |
| Codemagic signing | ⬜ Section 3 |
| WhatsApp reminder template (M7) | ⬜ Section 4. Submit early, approval takes time |
| Backups, log rotation, monitoring | ⬜ Section 5 |

---

## 1. Google Calendar (~15 min)

**A. Project** (console.cloud.google.com)
1. Project picker → **New project** `yaadly` → select it.
2. **APIs & Services → Library → Google Calendar API → Enable**.

**B. Consent screen** (**Google Auth Platform** / OAuth consent screen → Get started)
1. App name `Yaadly`, support email = your Gmail, audience **External**, contact email = your Gmail.
2. **Branding:**
   - Home page and privacy policy: `https://yaadley-api.mshiraz.com/privacy`
   - Terms: `https://yaadley-api.mshiraz.com/terms`
   - Authorized domain: `mshiraz.com`
3. **Data access → Add scopes:**
   - `openid`
   - `.../auth/userinfo.email`
   - `.../auth/calendar.events`
   - `.../auth/calendar.calendarlist.readonly`
4. **Audience → Test users:** add every Gmail that will test (max 100). Stay in **Testing**. The "unverified app" warning is normal; click **Continue**.

**C. OAuth client** (Clients / Credentials → Create OAuth client ID)
1. Type **Web application**, name `yaadly-backend`.
2. Authorized redirect URI: `https://yaadley-api.mshiraz.com/v1/google/callback`
3. Copy the client ID and secret.

**D. VPS `.env`**
```
GOOGLE_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=...
TOKEN_ENCRYPTION_KEY=   # openssl rand -hex 32  (back it up: losing it = everyone reconnects)
```
Then run `docker compose up -d --force-recreate api`. The "Google Calendar is not configured" warning should disappear.

**E. Test**
1. Send `/connect` on WhatsApp, open the link and click **Allow**. You should get "connected ✅".
2. Send "kal 3 bajay dentist". It should appear in Google Calendar.

## 2. App login secret (M5)

```
JWT_SECRET=   # openssl rand -hex 32
```
Add it to the VPS `.env` before deploying M5. Changing it later logs every app user out (no data is lost).

## 3. Codemagic signing (release APK)

1. **Back up** `yaadly.keystore` and both passwords in two safe places (password manager + cloud drive). Without them you can never update the app.
2. Move the file out of the repo:
   ```bash
   mkdir -p ~/secure && mv yaadly.keystore ~/secure/
   ```
3. Codemagic → **Team settings → codemagic.yaml settings → Code signing identities → Android keystores → Add**:
   - File: `yaadly.keystore`
   - Keystore password
   - Alias: `yaadly`
   - Key password
   - **Reference name: `yaadly_keystore`**
4. `codemagic.yaml` already references `yaadly_keystore`. Replace the email under `publishing.email.recipients` with yours.
5. Push to `main`. The signed APK is emailed. Install it on the phone (allow "install unknown apps").

## 4. WhatsApp reminder template (M7)

Reminders outside the 24-hour chat window need an approved template. Until it's approved, reminders are only sent while the window is open.

WhatsApp Manager → **Message templates → Create template**:
- Category: **Utility**
- Name: `event_reminder`
- Language: **English**
- Body: `Reminder: {{1}} at {{2}}.` (samples: `Doctor appointment`, `4:30 PM`)
- Buttons: **Quick reply** `OK` and `Snooze 10 min`

## 5. Operations

**Nightly database backup (VPS):**
```bash
mkdir -p ~/backups && crontab -e
```
Add this line:
```
0 3 * * * cd ~/yaadley-backend && docker compose exec -T db pg_dump -U yaadly yaadly | gzip > ~/backups/yaadly-$(date +\%F).sql.gz && find ~/backups -name 'yaadly-*.sql.gz' -mtime +14 -delete
```
Every few weeks, copy a backup off the server.

**Monitoring (optional):** set up a free UptimeRobot check on `https://yaadley-api.mshiraz.com/health/ready`.

**Security hygiene:**
- Revoke any token that was ever pasted in chat, and generate a new one.
- AWS Security Group: only 80 and 443 open to the world. Port 22 only from your IP.
- `LEGAL_CONTACT_EMAIL` set in `.env`.

**Deploy routine:**
1. On the laptop, commit and push.
2. On the VPS:
   ```bash
   cd ~/yaadley-backend && git pull && ./deploy/deploy.sh
   ```
3. Check with `docker compose logs -f api`.

## 6. Later (not needed for testing)

- A real phone number for the WhatsApp Business account. The test number only messages 5 recipients.
- Google OAuth verification. Only before a public launch with more than 100 users.
- Meta business verification. Only for higher messaging limits.

## 7. What's still missing for a complete project

| Item | Where |
|---|---|
| App API + Flutter screens with real data | M5 |
| Run the NLU eval once: `GROQ_API_KEY=... npm run eval:nlu` (target ≥ 85%) | You, after M6 |
| WhatsApp reminders, delete account, free-time finder in the app, week view, Help | M7 |
| Google resync of failed writes (F23) and Google → Yaadly change detection (D-7) | M7 |
| App icon + splash | M5 |
| Flutter widget/API tests | M5–M7 |
