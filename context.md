# Yaadly: Working Context

> Quick overview of everything we've discussed. The full spec is in [PRD.md](PRD.md).
> **There are two identical copies**, one in `yaadley-backend/` and one in `yaadley-flutter/`. Update both together.

**Status:** PRD v1.6. **M0–M6 code done.** Backend: 117 unit + 29 integration tests ✅. Flutter: analyze clean, 6 tests ✅. NLU eval set (60 cases) ready: `npm run eval:nlu` (needs a Groq key, not yet run). Next: you deploy + test M5/M6 and run the eval; then M7 (reminders, delete account, resync).
**Last updated:** 2026-10-29

---

## 1. One-paragraph product

Yaadly is a WhatsApp assistant for Pakistani users. It turns Urdu, Roman Urdu and English voice notes, text and **photos** into calendar events and items on smart-routed lists. It syncs two-way with Google Calendar and has a Flutter Android companion app. This is a semester project. Solo developer (Shiraz) with Claude as senior developer. Goal: **a high-quality MVP built today**, then self-testing. Pricing comes later.

## 2. Decisions log

| # | Decision | Round |
|---|---|---|
| D1 | Semester project. Build a working app first, then self-test. | R1 |
| D2 | Pricing, plans and payments are deferred. Usage is recorded but not enforced. | R1 |
| D4 | Clarifications and clash alerts count as replies (for future limits). | R1 |
| D5 | Re-login via a new 6-digit WhatsApp pairing code. Max 2 devices. | R1 |
| D6 | Google Calendar is two-way: write Yaadly events, read existing events. | R1 |
| D7 | Many named lists. | R1 |
| D8 | Android only. iOS later. | R1 |
| D10 | MVP today, high quality. | R2 |
| D11 | Smart list routing by **list purpose**. Fallback to the default list. Naming a list explicitly wins. | R2 |
| D12 | Delivery modes: Chat replies / App only, plus **Testing mode** (also send replies). | R2 |
| D13 | One list-item model: text, done flag, optional due date, optional note. | R2 |
| D14 | Meeting links, edit, cancel and reschedule are in the MVP. | R2 |
| D15 | Input: spoken Urdu, Roman Urdu, English and mixed. Text in Roman Urdu or English. | R2 |
| D16/17 | Bot replies and app UI in **English / Roman Urdu with a toggle**. | R2 |
| D18 | In-app add and edit is allowed. | R2 |
| D19 | Read **all visible calendars**, write to **one main calendar**. | R2 |
| D21 | **Auto-save ON** (confidence ≥ 0.85, complete, no clash), with Undo. | R3 |
| D22 | **No FCM for now.** The app polls and refreshes. **Reminders are sent on WhatsApp** (template outside the 24 h window). | R3 |
| D23 | WhatsApp and Google integrations done today. | R3 |
| D24 | Solo developer. Claude acts as senior developer. | R3 |
| D25 | New MVP features: 📸 Photo → Event · ↩️ Undo · 🕒 "Kab free hoon?" (P1). | R3 |
| D26 | Follow Figma 70–80%. Changes: no pricing screens, Lists redesigned for many lists, Settings toggles, Photo/Undo/free-slot UI. | R3 |
| D27 | **Stack:** Flutter (Android) + Fastify 5 (TypeScript) + PostgreSQL 18 (Drizzle) + pg-boss (no Redis) + googleapis + WhatsApp Graph API v26.0. | R3 |
| D29 | **AI = Groq only** (groq-sdk 1.6.0). Claude/Anthropic is removed. | R4 |
| D30 | **NLU:** `openai/gpt-oss-120b` first (strict JSON schema), then `qwen/qwen3.8-27b` as fallback. **Vision and Roman Urdu normalization:** `qwen/qwen3.8-27b`. | R4 |
| D31 | **STT:** `whisper-large-v3-turbo` first, then `whisper-large-v3` if turbo is unavailable, errors, or returns low confidence. | R4 |
| D32 | **Photo → Event stays.** Confirmed: Qwen3.8-27B on Groq accepts image input (max 3 images, 20 MB). It is a Preview model, so it sits behind a feature flag. | R4 |
| D33 | **Android application ID: `com.mshiraz.yaadley`.** It's the app's permanent unique identity on Android and Google Play. Display name: "Yaadly". | R4 |
| D34 | **Two GitHub repos:** `yaadley-backend` and `yaadley-flutter`. No root repo. PRD and context are copied into both. | R4 |
| D35 | **Hosting:** own VPS + host Caddy (auto HTTPS) on **`yaadley-api.mshiraz.com`** → **Docker Compose** (`api` + `db` postgres:18.6). **One process** (API + pg-boss workers), no pm2. No dev tunnel for now. | R5 |
| D36 | **Mobile CI:** Codemagic. `codemagic.yaml` sits at the root of `yaadley-flutter`. Runs on `mac_mini_m2` (free plan). Signed release APK emailed. Flutter is installed locally for codegen and analysis only. No Android Studio. | R4 |
| D38 | **Design tokens come from the Make export** (cream/paper/sun/butter/sand/tan/ink/clay/rust, Space Grotesk + Geist, 2px outline + hard shadow), not the PDF's beige/lavender. | R5 |
| D39 | **google_fonts pinned to 8.2.1.** 9.x depends on Flutter's new decoupled `material_ui` package, whose `TextTheme` clashes with `flutter/material` (still used by go_router). Revisit when the ecosystem migrates. | R5 |
| D40 | Roman Urdu UI is our own string table (`lib/core/l10n/strings.dart`), not a Flutter locale: `ur` would flip the app to RTL and Urdu script. | R5 |
| D41 | Ask before running heavy commands (> ~3 min, e.g. Gradle/APK builds, Docker image builds). | R5 |
| D42 | **M2 and M3 were built together** (events need understanding first). | R6 |
| D43 | **The LLM only extracts; code decides.** AM/PM defaults, "kal" after midnight, durations and links live in `draft.ts` (unit-tested), not in the prompt. | R6 |
| D44 | **Google connect via a WhatsApp one-time link** (`/connect`, 15 min, PKCE, single-use state). Scopes: `calendar.events` + `calendar.calendarlist.readonly` (least privilege). The app will reuse it in M5. | R6 |
| D45 | **Google writes are best-effort.** Postgres is the source of truth for Yaadly events. If a Google write fails, the user is told (`sync_failed` / `disconnected`), and the request never fails. | R6 |
| D46 | **Pending actions + buttons:** button ids `p:<pending>:<action>[:arg]` / `u:<action>`. Claims are atomic, so double taps are safe. Typed or spoken answers merge with the open question for 30 min. | R6 |
| D47 | **Undo window 15 min** via `/undo`, "wapas karo" or the Undo button. Exact restore from before/after snapshots. | R6 |
| D48 | Google Calendar is optional at boot (blank `GOOGLE_*` = disabled; events stay in Yaadly). | R6 |
| D49 | **Lists (M4):** the model suggests a list per item from `<lists>` (name: purpose); code decides: explicitly named list → valid suggestion → default list. First list = default (one per user, partial unique index). No lists yet → "Meri List" is created on the fly. Names unique per user, case-insensitive. | R8 |
| D50 | **List undo** shares the action log and the 15-min window with events. One `/undo` covers both (newest first). Remove is a soft delete so it can be undone. Writes + their undo entry are one transaction. | R8 |
| D51 | **List writes are retry-safe** per WhatsApp message (`sourceKey` in the action log / on the list), so a retried job returns the first result instead of "already on the list". | R8 |
| D52 | Items carry an optional due date ("kal tak"). `/today` shows due + overdue tasks, `/tomorrow` shows tomorrow's, `/tasks` shows the next 7 days + overdue. | R8 |
| D53 | **App sign-in = WhatsApp pairing code.** App shows a 6-digit code (10 min); the user sends it to the bot, which proves the number. App polls with a secret poll token (stored hashed). Then JWT access (15 min, HS256 via `jose`) + opaque refresh token (60 days, SHA-256 hashed, rotated on every use). Logout revokes the session. | R9 |
| D54 | **App API is optional at boot** (no `JWT_SECRET` = disabled, like Google). Every query is scoped to the session's user. | R9 |
| D55 | **One undo/history service** (`HistoryService`) for WhatsApp and the app: one atomic claim across events and lists; the Inbox "Updates" feed is the action log. | R9 |
| D56 | App writes are explicit: manual create skips auto-save/confidence prompts but still asks on a clash; edits/cancels from the app apply at once (undoable). `Idempotency-Key` header on creates. | R9 |
| D57 | Flutter: hand-written JSON models (no codegen), Dio with a queued 401→refresh interceptor, Riverpod providers, Inbox polls every 15 s while foregrounded and drives the tab badge. | R9 |
| D58 | **Photo → Event (M6):** WhatsApp image → in-memory download (≤ 4 MB, Groq's base64 limit) → Qwen3.8-27B vision into the same intent contract → normal event flow, **always confirm** (`from_photo`). A photographed list adds items. `PHOTO_EVENTS=false` turns it off. | R10 |
| D59 | **NLU eval** lives in `eval/` (60 Roman Urdu/English cases, fixed "today"), run on demand with `npm run eval:nlu`; exits non-zero below 85% (all fields correct). Not part of CI because it costs API calls. | R10 |
| D37 | **Design source:** Figma Make file `SL2R1QOmwmnljpRE0CGxV2` (React prototype). The connector is connected and lists its files. Use the exported code in `yaadley-flutter/design/figma-make/`. | R4 |

## 3. Scope at a glance

**P0 today:** onboarding + pairing · Google connect · voice/text/photo understanding · clarification · events with auto-save/pending/clash · edit/cancel/reschedule · meeting links · Undo · lists with purpose routing · slash commands · app (Pairing, Today, Inbox, Pending, Clarify, Clash, Calendar month, Lists, Settings core).
**P1:** WhatsApp reminders · free-time finder · Help · week view · delete account · remaining Settings.
**Deferred:** pricing/payments, FCM, iOS, web, admin, recurring, shared lists, Outlook, Urdu-script text.

## 4. Open items / waiting on you

- [x] GitHub repos created (code not pushed yet).
- [x] Figma Make code exported. Sources extracted to `yaadley-flutter/design/figma-make/src/`.
- [x] Flutter 3.47.8 installed (`~/development/flutter`).
- [ ] VPS: Docker + Compose plugin, git (Caddy already installed). DNS A record for `yaadley-api.mshiraz.com` ✅ added.
- [ ] Keys: **Groq** (required now), **Meta** (phone number ID, WABA ID, System User token, app secret), **Google** OAuth client (redirect `https://yaadley-api.mshiraz.com/v1/google/callback`).
- [x] Codemagic set up (keystore still pending).
- [ ] Replace the email placeholder in `yaadley-flutter/codemagic.yaml`.
- [ ] After the Codemagic app exists: keystore guide (Claude), then uncomment `android_signing`.

## 5. Expert findings (status)

| # | Finding | Status |
|---|---|---|
| F1 | Meta pricing premise may be wrong | Deferred. Collecting usage data |
| F2 | Meta ban on general-purpose AI chatbots | Guardrail in PRD §2 |
| F3 | Google OAuth needs Custom Tabs, 100-user cap while unverified | Designed in |
| F6 | Roman Urdu STT quality | Turbo → v3 fallback + Qwen normalization + eval set |
| F10 | Test number: 5 recipients | Use a System User token |
| F14 | WhatsApp reminders outside the 24 h window need a template | Submit on day 1 |
| F15 | Qwen3.8-27B is **Preview** on Groq | Model IDs in env, Photo → Event behind a flag |
| F16 | Only gpt-oss supports *strict* JSON on Groq | Qwen output re-validated with zod |
| F17 | Two repos with duplicated PRD/context can drift | Update both together (or symlink locally) |
| F18 | The Make file's source can't be read through the connector in this session | Resolved: zip exported |
| F19 | Real DB integration (migrations, upserts, pg-boss) | Verified manually on 2026-10-28 against Docker Postgres. An automated integration test suite is a later nice-to-have |
| F21 | Retried jobs re-evaluated already-saved events, which clashed with themselves | **Fixed** (idempotency-key check first). Caught by an integration test |
| F22 | `overlaps` is an SQL keyword | Column renamed to `allow_overlap` |
| F23 | Failed Google writes are not retried automatically | Follow-up: background resync job for `google_event_id IS NULL` events |
| F24 | Meta locked the WABA (131031) for an unverified business | Appeal + verification (FBR NTN) in progress. Fallback: Twilio sandbox adapter |
| F25 | Rename/delete list, set default, move items | ✅ In the app (M5). Not by WhatsApp message |
| F20 | Release APK signing | Keystore created; upload to Codemagic as `yaadly_keystore` (SETUP.md §3). `android_signing` enabled |
| F26 | App answers to a clarify question go through the NLU merge (same as WhatsApp); a bare "4" may not parse | Acceptable; options are buttons where possible |

## 6. Round log

- **R1:** Expert review. Semester project, pricing deferred, two-way calendar, many lists, Android only.
- **R2:** MVP today, list purpose routing, Testing mode, meeting links + edit/cancel, EN/Roman Urdu, all-calendars read.
- **R3:** +3 features, auto-save ON, FCM dropped, solo + Claude, Flutter + Fastify. PRD v1.0.
- **R4:** Groq only (gpt-oss → Qwen, Whisper turbo → v3). Qwen vision confirmed, so Photo → Event kept. Two GitHub repos. VPS + Caddy + pm2 on `yaadley-api.mshiraz.com`. Codemagic for the APK. App ID `com.mshiraz.yaadley`. Figma Make linked. PRD v1.1.
- **R5:** Domain `yaadley-api.mshiraz.com`, no dev server. Docker Compose with one process (no pm2). M0 + M1 written: Fastify webhook (HMAC, idempotent enqueue), pg-boss worker (👀/👋/✅ + replies, media download), Graph API client, Drizzle schema/migration, Docker/Caddy/deploy. Flutter shell: Make-accurate theme + widget kit, Welcome screen, 5-tab shell, More (server health + language), codemagic.yaml, Gradle signing via CM_* vars. PRD v1.2.
- **R6:** M2 + M3 built. Groq STT (turbo→v3 on low confidence) + Qwen romanization + gpt-oss strict-JSON NLU (Qwen fallback). Deterministic time rules. EventService: auto-save, clarify (buttons + text follow-up), clash with free-slot suggestions, confirm, edit/cancel/reschedule by message, pick-target, undo, /today /tomorrow /calendar /free /connect. Google OAuth (PKCE, encrypted tokens), calendar gateway (all visible calendars read, main calendar write). 97 unit + 14 integration tests. PRD v1.3.
- **R7:** Meta app `yaadley` created (WhatsApp use case, unpublished/dev mode). DNS, GitHub repos and Codemagic set up. Next: collect Meta values → push code → deploy → verify webhook → subscribe `messages` → test.
- **R8:** M4 built: lists with purpose, per-item routing, split + de-dup, tick/remove (fuzzy match), due dates, `/list`, `/list <name>`, `/tasks`, due tasks in `/today`, unified undo. Migration `0002_m4_lists`. 109 unit + 22 integration tests. Meta WABA locked (131031): appeal + verification started.
- **R9:** WhatsApp live (new portfolio, app published, WABA subscribed via Graph Explorer). Keystore generated. M5 built: pairing + JWT sessions, app REST API (`/v1/me`, day/calendar, events CRUD, inbox/pending/answer, undo, lists/items CRUD incl. rename/default/move), Flutter screens (Link, Connect, Today, Inbox, Pending/Clarify/Clash, Calendar month, Lists + detail, Settings, Help). SETUP.md added to both repos.
- **R10:** M6 built: Photo → Event (Qwen vision, confirm-first, list photos too, 4 MB cap), eval set + runner. 117 unit + 29 integration tests.
