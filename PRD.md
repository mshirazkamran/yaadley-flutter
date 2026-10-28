# Yaadly: Product Requirements Document (PRD)

**Tagline:** Say it in Roman Urdu. Yaadly remembers.
**Version:** 1.6 (MVP)  ·  **Date:** 2026-10-28  ·  **Status:** Approved for build
**Owner:** Muhammad Shiraz Kamran (FA23-BSE-077, BSE-7B), solo developer
**Senior dev / reviewer:** Claude
**Design:** Figma Make, https://www.figma.com/make/SL2R1QOmwmnljpRE0CGxV2/Design-mobile-app-UI-screens (published at https://ardent-quirky-31020635.figma.site). Follow it ~70–80%; the other 20–30% are changes listed in §9.
**Repos:** two separate GitHub repos, `yaadley-backend` and `yaadley-flutter`. Each holds an identical copy of this PRD and context.md, so **when you update one, copy it to the other**.
**Related:** [context.md](context.md) (running decisions log), original docs in `~/Downloads/TRA-peoject-ideas/`

---

## 1. Summary

Yaadly is a WhatsApp assistant. It turns Urdu, Roman Urdu and English voice notes, text and photos into calendar events and list items. Users talk to it on WhatsApp. An Android app (Flutter) shows and edits everything. Events sync two-way with Google Calendar.

This is a **semester project**. The goal is a **working, high-quality MVP built today**, which I (the solo developer) will then self-test. Pricing, plans and payments are **out of scope** until testing is done.

## 2. Problem and goals

| Problem | Goal |
|---|---|
| Plans get buried in voice notes and chats | One voice note → a saved event or list item in < 10 s |
| Calendar and to-do apps need slow typing | Zero typing. Voice, text, or a forwarded photo |
| Assistants don't understand Roman Urdu | ≥ 90% correct parses on a Roman Urdu test set |
| Double-booking | Clash detection across *all* of the user's Google calendars |

**Non-goals (this build):** monetization, iOS, web pages, admin dashboard, push notifications (FCM), shared lists, recurring events, Outlook.

**Platform-policy guardrail:** Meta banned *general-purpose* AI chatbots on the WhatsApp Business API from 15 Jan 2026. Yaadly must stay a **task-specific** assistant for events and lists. Off-topic questions get a short "Main sirf events aur lists sambhalta hoon" (I only handle events and lists) response.

## 3. Personas

- **Ayesha (21, student):** sends lots of voice notes. Needs to remember classes, deadlines and meetups.
- **Bilal (34, shopkeeper/freelancer):** hates typing. Needs quick tasks, grocery lists and client meetings.
- **Sara (28, professional):** uses Google Calendar and online meetings. Needs meeting links saved and no double-booking.

## 4. Key concepts

| Term | Meaning |
|---|---|
| **Reaction** | An emoji the bot puts on the user's WhatsApp message to show status |
| **Reply** | A real WhatsApp message from the bot (cards, buttons, questions) |
| **Delivery mode** | Per-user setting: **Chat replies** (bot sends replies) or **App only** (bot only reacts, and details wait in the app Inbox) |
| **Testing mode** | Dev setting: in App-only mode the bot *also* sends a reply, so every output is visible in chat |
| **Pending item** | A parsed event or change waiting for the user to confirm (in chat or the app Inbox) |
| **Auto-save** | **ON by default.** High-confidence, complete, clash-free parses are saved straight away with ✅ and can be undone |
| **List purpose** | A short description set when a list is created ("office ke kaam", i.e. office work). Used to route new items |

### Reaction legend

👀 processing · ✅ saved · 📅 command result · ⚠️ clash · ❓ needs your input · 🛒 list updated · ↩️ undone · ❌ not understood · 👋 welcome

## 5. Functional requirements

Priority: **P0** must ship today · **P1** ship today if time allows, otherwise next session.

### Epic A: Onboarding and account

| ID | Requirement | Pri |
|---|---|---|
| A-1 | Sending "Hi" (or anything) from a new number creates the account. The bot reacts 👋 and sends one welcome reply with an "App download" button. | P0 |
| A-2 | The app shows a **6-digit pairing code** (valid 10 min, single use) with a countdown. The user sends it to the bot. The bot reacts ✅ and the app (polling `/auth/pair/status`) shows "WhatsApp linked". The app receives a session token (JWT plus refresh token) and stores it in secure storage. | P0 |
| A-3 | Re-login after a reinstall or on a new phone uses a new pairing code. **Max 2 devices.** Linking a third device signs out the oldest. | P0 |
| A-4 | **Connect Google Calendar**: `/connect` on WhatsApp sends a one-time link (15 min) that opens Google consent in the browser. The app reuses the same flow in M5. OAuth opens in a **Custom Tab** in the app (Google blocks WebViews). The backend handles the callback and stores encrypted tokens, then redirects to `yaadly://calendar-connected`. Disconnect is available at any time. | P0 |
| A-5 | **Delete account:** a confirmation dialog, then all data is erased and Google tokens are revoked. | P1 |

### Epic B: Understanding input

| ID | Requirement | Pri |
|---|---|---|
| B-1 | **Voice notes** up to 60 s. Spoken **Urdu, Roman Urdu, English or a mix** are all understood. | P0 |
| B-2 | **Text** in Roman Urdu, English or a mix. Spelling variants are handled ("bajay/baje/bjy"). | P0 |
| B-3 | The **transcript is shown** in Roman Urdu (in the reply card or the app item). Audio is **deleted** after transcription. | P0 |
| B-4 | **Clarification:** if the time, AM/PM or date is missing, the bot asks one short question with quick-reply buttons (chat) or shows a ❓ card (app). | P0 |
| B-5 | **Parsing rules:** aaj (today), kal (tomorrow), parson (day after), agle hafte (next week), weekday names. "N bajay" with no AM/PM means **PM for 1–6, AM for 7–11, and ask for 12**. "kal" between 00:00 and 04:00 triggers a confirmation question. Default duration is 60 min. Timezone is fixed to Asia/Karachi. | P0 |
| B-6 | **Off-topic / unknown input:** react ❌ and send a short help tip. | P0 |
| B-7 | **Idempotency:** each `wa_message_id` is processed once. Webhook retries never create duplicates. | P0 |

### Epic C: Slash commands (no LLM; fast and cheap)

| ID | Requirement | Pri |
|---|---|---|
| C-1 | `/today` and `/tomorrow` return the events and due tasks for that day. | P0 |
| C-2 | `/calendar` returns the next 7 days. | P1 |
| C-3 | `/list` returns all lists with item counts. `/list <name>` returns one list. `/tasks` returns items with due dates. | P0 |
| C-4 | `/help` returns the commands and 4 example phrases. | P0 |
| C-5 | `/undo` reverses the last action (see G-2). | P0 |

In Chat-replies mode, commands get a text reply. In App-only mode they get a 📅 reaction, and the result is in the app (plus a reply in Testing mode).

### Epic D: Events

| ID | Requirement | Pri |
|---|---|---|
| D-1 | Create an event from voice, text or the app's + button: title, date, time, duration, optional location and meeting link. | P0 |
| D-2 | **Auto-save ON:** if confidence ≥ 0.85, all fields are present and there is no clash, save it, write it to the main Google calendar, react ✅ and send a confirmation that has an **Undo** button. Otherwise create a **Pending** item with **Confirm / Edit / Cancel** (chat buttons or the app). | P0 |
| D-3 | **Clash detection** against Yaadly events and **all visible Google calendars** (freebusy). On a clash: react ⚠️ and show both events with **Dono rakho** (keep both) / **Time badlo** (change time, suggesting up to 3 free slots) / **Naya cancel karo** (cancel the new one). | P0 |
| D-4 | **Edit, reschedule and cancel by message**, e.g. "kal wali meeting 4 bajay kar do" (move tomorrow's meeting to 4) or "Ali wala plan cancel karo" (cancel the plan with Ali). Find matching events first. One match: confirm. Several: the user picks. None: "Nahi mila" (not found). Also possible in the app. | P0 |
| D-5 | **Meeting links:** detect Zoom, Google Meet or Teams URLs in text or forwarded messages. Store the link on the event and put it in the Google event description. If the time is missing, clarify (B-4). | P0 |
| D-6 | **Reminders** are sent on **WhatsApp** (FCM is dropped for now), 30 min before by default (configurable). Inside the 24 h customer-service window this is a free-form message. Outside it, an approved **utility template** `event_reminder` is used. Buttons: "Theek hai" (OK) and "10 min baad" (snooze). | P1 |
| D-7 | Google is the source of truth for events that live there. If a Yaadly event is changed or deleted in Google, Yaadly picks that up the next time it reads (on every view, command or clash check). | P0 |

### Epic E: Lists

| ID | Requirement | Pri |
|---|---|---|
| E-1 | **Create lists** by voice, text or the app, each with a **purpose**: "ek list banao office ke kaam ke liye" (make a list for office work). An icon kind (grocery / tasks / general) is chosen automatically. | P0 |
| E-2 | **Smart routing:** new items go to the list whose purpose best matches the item (the LLM is given the list names and purposes). If nothing matches clearly, they go to the **default list** (the first list created, changeable later). Naming a list explicitly always wins: "office list mein X add karo" (add X to the office list). | P0 |
| E-3 | Multi-item dictation is split and de-duplicated: "doodh, anday, chawal, cheeni aur chai" (milk, eggs, rice, sugar and tea) becomes 5 items. Reaction 🛒. | P0 |
| E-4 | Tick off ("doodh le liya", i.e. got the milk), remove, rename and move items by message or in the app. Changes show in both places. | P0 |
| E-5 | **One item model:** text, done flag, optional **due date**, optional note. Overdue items show in red. | P0 |
| E-6 | Rename or delete a list. Set the default list. | P1 |

### Epic F: Android app (Flutter)

Follows Figma ~70–80%. Screen changes are listed in §9.

| ID | Screen | Pri |
|---|---|---|
| F-1 | Splash / Welcome | P0 |
| F-2 | Link WhatsApp (code, countdown, waiting, linked and expired states) | P0 |
| F-3 | Connect Calendar (connect / later, connecting, connected showing the email, error) | P0 |
| F-4 | **Today** with an Aaj/Kal toggle: events (tan cards), due tasks, alert banners, empty state | P0 |
| F-5 | **Inbox**: *Needs action* (pending, clarification, clash) and *Updates* (saved, undone, reminders). Unread dots. Pull to refresh, plus polling every 15 s while open | P0 |
| F-6 | Pending event detail: original message / transcript, editable fields, Confirm / Edit / Cancel, low-confidence hint | P0 |
| F-7 | Clarification card (AM/PM, day picker, duration) | P0 |
| F-8 | Clash screen (new vs. existing, free-slot chips) | P0 |
| F-9 | **Calendar**: month grid with dots, plus a day list; week view is P1. "+" adds an event manually | P0 |
| F-10 | **Lists**: all lists → list detail (checkbox rows, add field, due-date chip). Create-list sheet with purpose | P0 |
| F-11 | Help: commands, voice examples, reaction legend | P1 |
| F-12 | **Settings**: language (**EN / Roman Urdu toggle**), delivery mode, testing mode, auto-save (on), reminder minutes, quiet hours, main calendar picker, Google connection, WhatsApp link status, delete my data | P0 (language, delivery, testing, auto-save, Google, WhatsApp) / P1 (rest) |

App data refresh (no FCM): fetch on screen open, pull to refresh, poll the Inbox every 15 s while the app is in the foreground, and show a badge count on the Inbox tab.

### Epic G: New MVP features (added in Round 3)

| ID | Feature | Why it earns its place | Pri |
|---|---|---|---|
| G-1 | **📸 Photo → Event ("Card se event").** Forward a photo of a wedding or event card, a poster, or a screenshot of a chat or invite. **Qwen3.8-27B vision on Groq** (max 3 images, 20 MB) reads the date, time, venue and title, then the normal flow runs (auto-save / pending / clash). | Very common in Pakistan: shaadi cards and WhatsApp-forwarded invites. Strong demo moment. It reuses the whole event pipeline. | P0 |
| G-2 | **↩️ Undo.** `/undo`, "wapas karo" (take it back), or the Undo button reverses the last create, edit, cancel or list change made in the last **15 min**, including in Google. Reaction ↩️. | Auto-save is ON, so one-tap undo is the safety net. It keeps users trusting the bot. | P0 |
| G-3 | **🕒 "Kab free hoon?" (free-time finder).** For example, "kal kab free hoon?" (when am I free tomorrow?) or "jumma ko 1 ghante ka slot batao" (give me a 1-hour slot on Friday) returns up to 3 free slots across all calendars between 9:00 and 22:00. Tapping a slot starts an event for it. | It reuses the clash/freebusy engine, answers a question people really ask, and is perfect for Sara. | P1 |

Candidates for later: daily morning agenda on WhatsApp (needs an approved template), recurring events, shared lists.

## 6. Delivery mode decision

| Incoming | User setting | Result |
|---|---|---|
| Slash command | Chat replies | Reaction 📅 + text reply |
| Slash command | App only | Reaction 📅 (plus a reply if Testing mode is on) |
| Voice / text / photo | Chat replies | Reaction + interactive reply card |
| Voice / text / photo | App only | Reaction + Inbox item (plus a reply if Testing mode is on) |
| Reminder | any | WhatsApp message (free-form in-window / template out of window) |

No limits or counters are enforced in this build. The `UsageCounter` table still records commands and replies so we have real data for pricing later.

## 7. Key user flows

1. **Onboarding:** "Hi" on WhatsApp → 👋 + welcome → install the app → Link WhatsApp code → send the code → ✅ → Connect Calendar (or later) → Today.
2. **Voice → Event (core):**
   1. The voice note arrives at the webhook. The bot reacts 👀.
   2. The job is queued, the audio is downloaded and transcribed, then deleted.
   3. gpt-oss-120b (with Qwen as fallback) extracts the intent as JSON. The validator applies the parsing rules.
   4. If info is missing, go to the clarification flow. Otherwise run a freebusy clash check; on a clash, go to the clash flow.
   5. If confident, auto-save and react ✅ with an Undo option. Otherwise create a Pending item and react ❓.
3. **Photo → Event:** the image arrives → 👀 → Qwen3.8-27B vision → the same pipeline from the clash check onwards.
4. **List dictation:** voice → intent `add_list_items` → route each item to a list by purpose, or to the default list → split and de-duplicate → 🛒 (+ list card).
5. **Edit/cancel by message:** intent `edit_event` / `cancel_event` → match candidates → confirm or choose → update Google + DB → ✅ (with Undo).
6. **Reminder:** pg-boss job at start − N min → WhatsApp message with a join link if there is one → "Theek hai" / "10 min baad".
7. **Undo:** look up the last `ActionLog` entry within 15 min → apply its inverse → ↩️.

## 8. Non-functional requirements

| Area | Target |
|---|---|
| Latency | Reaction ≤ 2 s (webhook acks immediately and the job is queued). Text → result ≤ 5 s. Voice/photo → result ≤ 10 s |
| Accuracy | ≥ 90% correct intent and fields on a **Roman Urdu test set** (60+ phrases, built on day 1 and run as an automated eval) |
| Security | Verify `X-Hub-Signature-256` on every webhook. Google tokens encrypted at rest (AES-256-GCM). HTTPS only. Short-lived JWT plus refresh token. Secrets in `.env` (never committed) |
| Privacy | Audio and images deleted after processing. Full account deletion. Data is only used to run the service |
| Reliability | Idempotent by `wa_message_id`. Retries for jobs (pg-boss). Failed parses logged with the reason |
| Observability | Structured logs (pino). `MessageLog` table holds the transcript, parsed JSON and latency for every message |
| i18n | All app strings in ARB files (en and Roman Urdu). Bot replies are templated in both languages |

## 9. Design: Figma vs. changes

**Keep (~75%)**
- Visual language (from the Make export's `index.css`): cream `#FBF6EA` background, paper `#FFFDF6` cards, sun `#F7C948` primary, butter `#FFF1AD` and sand `#ECDCC0` surfaces, ink `#2D2113` text, outlines and **hard offset shadows** (4px/2px), clay `#7A6650` muted text, rust `#B83D26` errors. Fonts: **Space Grotesk** (display) + **Geist** (body). Ported to `lib/core/theme/`.
- Voice-note pill, the overall screen layouts, and the bottom tabs: Today, Inbox, Calendar, Lists, More.

**Change (~25%)**
1. **Remove the** Usage & Plan, Payment and Plans screens and the usage chip (pricing is deferred).
2. **Lists screen redesign:** from the fixed Grocery | Tasks tabs to *all lists* (grid of cards with icon, name, purpose, count) → list detail. Add a "New list" sheet with a purpose field.
3. **Settings additions:** language toggle, Testing mode, main-calendar picker, auto-save (on).
4. **New UI:** Photo → Event (a pending card shows the image thumbnail and the extracted fields), an Undo snackbar/row, and free-slot chips (shared by the Clash screen and the free-time finder).
5. **Inbox:** add a refresh affordance and unread badge (no push).
6. **Help:** the reaction legend gains ↩️, and examples gain a photo example.

**How we consume Figma:** the design is a **Figma Make** project, i.e. a React/Vite prototype (`src/App.tsx`, `screensCore.tsx`, `screensMore.tsx`, `ui.tsx`, `index.css`, plus 2 images). The Figma connector is connected and lists these files. The most reliable input is the **exported Make code**, placed in `yaadley-flutter/design/figma-make/`. Colors, spacing and typography tokens in `index.css`/`ui.tsx` are ported to a Flutter `ThemeData` plus a small widget kit (OutlinedCard with hard shadow, VoicePill, EventCard, ListCard).

## 10. Architecture

```
WhatsApp user ─► Meta Cloud API ─► POST /webhooks/whatsapp (Fastify)
                                     │ verify signature, dedupe, react 👀, ack 200
                                     ▼
                                 pg-boss queue (Postgres) ──► worker
                                     │  ├─ command router (no LLM)
                                     │  ├─ STT: Groq whisper-large-v3-turbo → whisper-large-v3 (fallback)
                                     │  ├─ NLU: Groq gpt-oss-120b (strict JSON) → qwen3.8-27b (fallback)
                                     │  ├─ Vision (photos): Groq qwen3.8-27b
                                     │  ├─ validator + parsing rules (luxon, Asia/Karachi)
                                     │  ├─ clash/free-slot engine (Google freebusy + DB)
                                     │  ├─ action executor + ActionLog (for Undo)
                                     │  └─ delivery selector ─► WhatsApp sender (react / reply / template)
                                     ▼
                                 PostgreSQL ◄──── REST API (JWT) ◄──── Flutter Android app
                                     ▲
                       Google Calendar API (OAuth, events, freebusy, calendarList)
```

One Node process runs in two roles (API + worker), so there is no Redis. pg-boss also schedules reminders and cleanup.

### Data model (Drizzle, PostgreSQL)

`users`(id, wa_number, display_name, language, timezone, delivery_mode, testing_mode, auto_save, reminder_min, quiet_start, quiet_end, default_list_id, main_calendar_id, last_inbound_at, created_at)
`devices`(id, user_id, platform, name, refresh_token_hash, last_seen, created_at)
`pairing_codes`(code, device_nonce, user_id?, expires_at, used_at)
`calendar_connections`(user_id, provider, google_email, enc_access_token, enc_refresh_token, expires_at, status)
`events`(id, user_id, title, start_at, end_at, location, meeting_link, meeting_platform, google_calendar_id, google_event_id, source, status[pending|confirmed|cancelled], overlaps, created_at, updated_at)
`pending_actions`(id, user_id, type[create_event|edit_event|cancel_event|clarify|clash|add_items], payload_json, question_json, status, wa_context_message_id, expires_at, created_at)
`lists`(id, user_id, name, purpose, kind, is_default, created_at)
`list_items`(id, list_id, text, is_done, due_at, note, created_at, done_at)
`action_log`(id, user_id, action, before_json, after_json, created_at, undone_at) (for Undo)
`inbox_items`(id, user_id, type, title, body, deep_link, reaction, pending_action_id, read_at, created_at)
`message_log`(id, user_id, wa_message_id UNIQUE, kind[text|audio|image|command|button], transcript, parsed_json, delivery_mode, latency_ms, status, error, created_at)
`usage_counters`(user_id, date, commands, replies) (recorded only, not enforced)
`reminders` are pg-boss scheduled jobs keyed by event id.

### REST API (v1)

| Method | Path | Purpose |
|---|---|---|
| POST | `/v1/auth/pair/start` | Create a pairing code for this device |
| GET | `/v1/auth/pair/status` (header `x-poll-token`) | Poll; returns tokens once linked (once) |
| POST | `/v1/auth/refresh` · `/v1/auth/logout` | Session |
| GET | `/v1/me` · PATCH `/v1/me/settings` | Profile and settings |
| POST | `/v1/google/link` → one-time URL opened in a Custom Tab · GET `/v1/google/connect` · GET `/v1/google/callback` · DELETE `/v1/google` | Google OAuth |
| GET | `/v1/day?date=` · `/v1/calendar?from=&to=` | Merged Yaadly + Google events, plus due items |
| POST/PATCH/DELETE | `/v1/events[/:id]` | Manual event CRUD |
| GET | `/v1/inbox` · POST `/v1/inbox/seen` | Inbox (pending + updates, unread count) |
| POST | `/v1/pending/:id/action` `{action, arg}` · `/v1/pending/:id/answer` `{text}` | Pending actions (same actions as the WhatsApp buttons) |
| GET | `/v1/free-slots?date=&duration=` | Free-time finder |
| CRUD | `/v1/lists[/:id]`, POST `/v1/lists/:id/items`, PATCH/DELETE `/v1/items/:id` | Lists and items (rename, default, move, tick, due date) |
| POST | `/v1/undo` | Undo last action |
| DELETE | `/v1/me` | Delete account |
| GET/POST | `/webhooks/whatsapp` | Meta verify + inbound |

### Intent schema (Groq structured output, `json_schema` with `strict: true` on gpt-oss-120b)

Intents: `create_event`, `edit_event`, `cancel_event`, `show_schedule`, `find_free_time`, `connect_calendar`, `create_list`, `add_list_items`, `complete_list_items`, `remove_list_items`, `show_list`, `undo`, `help`, `smalltalk`, `unknown`. The output is flat (strict-mode friendly): event fields (`title, date, time_hour, time_minute, meridiem, duration_minutes, location`), edit fields (`target_query, target_date, new_*`), `schedule_date`, list fields (`list_name, list_purpose, list_kind, items[{text, list, due_date}]`) and `confidence`. The model only extracts; code applies the rules (see `src/modules/nlu/draft.ts`, `src/modules/lists/routing.ts`).

## 11. Tech stack (versions checked 2026-10-28)

### Backend (Node + Fastify, TypeScript)

| Concern | Choice | Version |
|---|---|---|
| Runtime | Node.js LTS (installed: 24.21.0 ✔) | 24.x LTS "Krypton" (latest 24.22.1) |
| Framework | fastify | 5.12.7 |
| Plugins | @fastify/cors 11.3.1 · @fastify/helmet 13.2.0 · @fastify/rate-limit 11.2.1 · @fastify/sensible 6.0.7 · @fastify/jwt 10.2.5 · @fastify/swagger 9.9.2 · fastify-plugin 6.0.1 · fastify-raw-body 6.0.3 (for webhook signatures) | — |
| Validation | zod 4.6.7 + fastify-type-provider-zod 7.0.0 | — |
| DB / ORM | PostgreSQL **18.6** (Docker) · drizzle-orm 0.45.4 · drizzle-kit 0.31.11 · postgres (postgres.js) 3.4.9 | — |
| Jobs / scheduler | pg-boss 12.38.0 (queue, retries, reminders, no Redis) | — |
| AI provider | **Groq only**, via groq-sdk | 1.6.0 |
| NLU (intent JSON) | **1st: `openai/gpt-oss-120b`** (production; strict `json_schema` structured outputs; `reasoning_effort: low`) → **fallback: `qwen/qwen3.8-27b`** (preview; JSON-schema mode, best-effort, so we re-validate with zod) | — |
| Vision (Photo → Event) | **`qwen/qwen3.8-27b`** (text + image in; max 3 images, 20 MB, 2,048 tokens per image; $0.80 / $4.00 per 1M tokens) | — |
| Roman Urdu normalization | `qwen/qwen3.8-27b` (`reasoning_effort: none`) turns Urdu-script Whisper output into a Roman Urdu transcript. Falls back to gpt-oss-120b | — |
| Speech-to-text | **1st: `whisper-large-v3-turbo`** ($0.04/h) → **fallback: `whisper-large-v3`** ($0.111/h), used when turbo errors, is rate-limited or unavailable, or when the confidence check fails (`avg_logprob` < −0.5 or `no_speech_prob` > 0.6 on `verbose_json`). `language: "ur"` hint. WhatsApp `.ogg` is accepted as-is. Min billed length is 10 s | — |
| Google | googleapis 188.0.0 (Calendar v3: events, freeBusy, calendarList; OAuth2) | — |
| WhatsApp | Graph API **v26.0** through built-in `fetch` (no SDK needed) | — |
| Dates | luxon 3.7.2 (timezone math) · chrono-node 2.10.3 (English fallback parser) | — |
| Logs | pino 10.4.0 · pino-pretty 13.2.0 | — |
| Tooling | typescript 7.0.2 · tsx 4.23.15 · vitest 5.0.5 · @types/node 26.6.5 · dotenv 18.0.9 | — |
| Hosting | Own **VPS** + **Docker Compose** (`api` + `db`, postgres:18.6) behind host **Caddy** (automatic HTTPS) on `yaadley-api.mshiraz.com` (see §11a). **One process** runs API + workers | — |

### Mobile (Flutter, Android first)

| Concern | Choice | Version |
|---|---|---|
| SDK | Flutter stable / Dart | 3.47.8 / 3.13.7 |
| State | flutter_riverpod 3.4.3 · riverpod_annotation 4.0.7 · riverpod_generator 4.0.9 | — |
| Routing + deep links | go_router 18.1.1 · app_links 7.2.2 (`yaadly://`) | — |
| HTTP | dio 5.11.1 | — |
| Models | freezed 4.0.3 · freezed_annotation 3.1.0 · json_serializable 6.15.2 · json_annotation 4.12.0 · build_runner 2.17.1 | — |
| Storage | flutter_secure_storage 11.2.0 (tokens) · shared_preferences 2.5.6 (cache) | — |
| Calendar UI | table_calendar 3.3.0 (month) · calendar_view 2.0.0 (day/week, P1) | — |
| OAuth / links | url_launcher 6.3.3 (`LaunchMode.inAppBrowserView` = Custom Tabs) | — |
| UI | google_fonts 8.2.1 (Space Grotesk + Geist; 9.x clashes with flutter/material via the decoupled `material_ui` package) · flutter_svg 2.3.0 · gap 3.0.1 · shimmer 4.0.0 | — |
| i18n | flutter_localizations + intl 0.20.3 (ARB: `en`, `ur` written in Roman letters) | — |
| Lint | flutter_lints 6.0.0 | — |

### Repo layout (two GitHub repos)

```
yaadely/                      (local parent folder only, not a git repo)
├─ yaadley-backend/           ← GitHub repo #1
│   PRD.md  context.md
│   src/{routes,whatsapp,nlu,google,jobs,db,domain}
│   eval/roman-urdu-testset.jsonl + runner
│   docker-compose.yml        (postgres:18.6 for local dev)
│   compose.yaml · Dockerfile · .env.example
│   deploy/Caddyfile.example
└─ yaadley-flutter/           ← GitHub repo #2
    PRD.md  context.md
    codemagic.yaml            (repo root, so no working_directory needed)
    lib/{core,features/*,l10n}
    design/figma-make/        (exported Make code, for reference)
```

### 11a. Deployment and CI

**Backend → VPS**
- Caddy reverse-proxies `yaadley-api.mshiraz.com` → `localhost:3000`. HTTPS certificates are automatic, which satisfies Meta's TLS requirement for webhooks. This URL is used for the Meta webhook (`/webhooks/whatsapp`) and the Google OAuth redirect (`/v1/google/callback`).
- Docker Compose runs `api` (one Node process: Fastify HTTP + pg-boss workers; restart policy replaces pm2) and `db` (PostgreSQL 18.6). Both ports are bound to 127.0.0.1, so they're only reachable through Caddy. The container is non-root and read-only, with all capabilities dropped.
- PostgreSQL 18 runs on the VPS, bound to localhost only.
- Deploy: `./deploy/deploy.sh` runs `git reset --hard origin/main` → `docker compose up -d --build` → waits for `/health/ready`. Migrations run on boot (`RUN_MIGRATIONS=true`).

**Flutter → Codemagic**
- `codemagic.yaml` sits at the root of the `yaadley-flutter` repo. Workflow `android-release` runs on `mac_mini_m2` (the only machine on the free plan), with `flutter: stable` (3.47.x) and `java: 17`.
- Trigger: push to `main` (and manual runs).
- Steps:
  1. `flutter pub get`
  2. `dart run build_runner build --delete-conflicting-outputs`
  3. `flutter analyze`
  4. `flutter test`
  5. `flutter build apk --release --build-number=$BUILD_NUMBER --dart-define=API_BASE_URL=$API_BASE_URL`
- Signing: a keystore uploaded in Team settings → Code signing identities, referenced with `android_signing: [yaadly_keystore]`. `android/app/build.gradle.kts` reads `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS` and `CM_KEY_PASSWORD` when `CI` is set.
- Env group `yaadly_prod` holds `API_BASE_URL=https://yaadley-api.mshiraz.com`.
- Artifacts: `build/**/outputs/**/*.apk`, emailed to the owner. You install the APK on your phone from the link.

**Android application ID:** `com.mshiraz.yaadley`. It's the app's permanent unique identity on Android and Google Play. See context.md D33.

## 12. Setup checklist (what you need to do)

**Laptop**
1. **Flutter 3.47.8** stable (includes Dart 3.13.7). Used to run `flutter create`, codegen and `flutter analyze` locally. **No Android Studio needed**, because Codemagic builds the APK.
2. Already installed ✔: Node 24, Docker (local Postgres), git, Java 25 (provides `keytool` for the signing keystore).
3. Optional: Chrome, for quick UI previews with `flutter run -d chrome`.

**VPS**
1. Docker Engine + Compose plugin · Caddy (already installed) · git. Node/Postgres are **not** needed on the host (they run in containers).
2. DNS: an **A record** for `yaadley-api.mshiraz.com` pointing to the VPS IP.

**Accounts and keys** (into `yaadley-backend/.env` on the VPS; never commit them or paste them in chat)
1. **GitHub:** two repos, `yaadley-backend` and `yaadley-flutter` (private).
2. **Codemagic:** sign in with GitHub and add the `yaadley-flutter` repo. Upload the keystore (`keytool -genkey -v -keystore yaadly.keystore -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias yaadly`) and **back it up**: losing it means you can't update the app.
3. **Groq:** an API key from console.groq.com.
4. **Meta:** developers.facebook.com → create an app (type *Business*) → add the **WhatsApp** product. Note the **phone number ID**, **WABA ID**, a **System User permanent token** and the **App Secret**. Add your WhatsApp number as a test recipient (max 5). Webhook URL: `https://yaadley-api.mshiraz.com/webhooks/whatsapp`.
5. **Google Cloud:** create a project → enable the **Google Calendar API** → set up the OAuth consent screen (External, *Testing*) → add your Gmail as a **test user** → create an OAuth client of type **Web application** with redirect `https://yaadley-api.mshiraz.com/v1/google/callback`. Scopes: `calendar.events`, `calendar.readonly`, `openid email`.
6. **Figma:** export the Make code (zip) into `yaadley-flutter/design/figma-make/`.

## 13. Build plan for today (solo + senior-dev pairing)

| # | Milestone | Done when |
|---|---|---|
| M0 ✅ code | Scaffold both repos: Fastify skeleton, Drizzle schema + migrations, Docker Compose, Caddy config, deploy script. Flutter shell with the Figma theme, plus `codemagic.yaml` and signing | `https://yaadley-api.mshiraz.com/health` is green. The first Codemagic APK installs on the phone |
| M1 ✅ code | WhatsApp in/out: webhook verify, signature check, dedupe, reactions, text reply, interactive buttons, media download | Bot reacts 👀/✅ to my message |
| M2 ✅ code | NLU: Whisper turbo/v3 chain → gpt-oss-120b intent extraction (qwen fallback) → Roman Urdu normalization → validator + parsing rules → eval set (60 phrases) running in vitest | ≥ 85% on day-1 eval |
| M3 ✅ code | Events + Google: OAuth, create in the main calendar, freebusy clash check, auto-save / pending / clarify / clash flows, edit/cancel/reschedule, Undo | Voice note → event visible in Google Calendar |
| M4 ✅ code | Lists: create with purpose, routing, add/tick/remove, slash commands | "doodh, anday…" → 5 items in the right list |
| M5 ✅ code | App: pairing, Today, Inbox + pending/clarify/clash, Lists, Calendar month, Settings (language, delivery, testing) | End-to-end demo on the phone |
| M6 ✅ code | Photo → Event, meeting links, NLU eval set | Forwarded shaadi card → pending event |
| M7 (P1) | Reminders (pg-boss + template), free-time finder, Help, week view, delete account | — |

Quality gates: TypeScript strict mode, vitest unit tests for the parsing rules, delivery selector and routing, the eval runner, and `flutter analyze` clean.

## 14. Risks

| Risk | Mitigation |
|---|---|
| Roman Urdu STT quality | Turbo → large-v3 fallback on low confidence. Qwen post-normalizes to Roman Urdu. The transcript is always shown, and clarification happens when unsure |
| `qwen/qwen3.8-27b` is a **Preview** model (Groq can change or remove it) | Model IDs live in config/env. NLU degrades to gpt-oss-120b only. If Qwen disappears, Photo → Event is switched off behind a feature flag |
| Groq rate limits on the free/dev tier | Retries with backoff in pg-boss. Rule-based slash commands need no LLM |
| Codemagic free plan minutes | Build only on push to `main`. Cache the pub and Gradle caches |
| Meta test number only messages 5 recipients, temporary tokens expire in 24 h | Use a System User token. Register a real number for wider testing |
| Templates need approval (reminders outside the 24 h window) | Submit `event_reminder` on day 1. Until it's approved, reminders only go out while the window is open |
| Google OAuth "unverified app" screen, 100-user cap | Fine for testing (add test users). Verification only before a public launch |
| Meta pricing changes (Oct 2026 reports conflict) | No pricing decisions now. `usage_counters` collects real volumes |
| "Today" scope is tight for solo work | P0/P1 split, and milestones ordered so each one is demoable on its own |

## 15. Deferred / later

Plans, limits, payments (Play Billing vs. web checkout), landing page, admin dashboard, FCM push, iOS, recurring events, shared lists, Outlook, Urdu-script text input, timezone setting, morning agenda, in-app mic.
