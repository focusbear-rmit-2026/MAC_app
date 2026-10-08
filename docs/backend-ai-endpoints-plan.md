# Plan: Move client-side OpenAI calls to shared backend endpoints

**Status:** Proposed · **Owners:** Backend, Mac, Windows · **Shared via:** cross-agent coordination board

> **Update 2026-09-28: voice endpoints implemented** (backend PR #2470, Mac-App #2732). `POST /voice/intent` matches
> Endpoint 2 below exactly. **Transcription shipped as one synchronous `POST /voice/transcribe` multipart upload**
> (part `file`, audio MIME type, ≤ 10 MB, returns `{ "text": "…" }`), not the async R2 + job flow in Endpoint 1.
> A voice command is a few seconds of audio the user is waiting on, so one request with no Pusher event or polling
> is simpler for every client. The final wire contract is in the "Client contract" section of backend PR #2470.
> The committed `sk-proj-…` key is already revoked.

## Why

Two AI features currently call `https://api.openai.com` **directly from the client** with an OpenAI
API key that ships inside (or alongside) the app. This exposes the key to anyone who inspects the
binary and gives us no server-side control over prompts, models, cost, or abuse. This plan moves both
features behind authenticated **backend endpoints** so:

- the OpenAI key lives only on the server (env/secret), never in any client;
- prompts + model choice can be tuned without a client release;
- all three clients (Mac, Windows, and any future one) implement against **one contract**.

The backend already proxies OpenAI for several features (e.g. `POST /user/is-url-safe-to-use`,
`POST /user/generate-occupation-specific-relevant-sites`, `POST /ai/chat`). This plan mirrors those
conventions exactly. **A shared `libs/openai` service already exists and already has the primitives we
need** (`transcribeAudioToText`, `createChatCompletion`), so most of the backend work is wiring +
prompts, not new infrastructure.

---

## Current client implementation (what we are replacing)

### Feature 1 — Microphone / voice input (Mac)

Two chained direct OpenAI calls, both with a **hardcoded `sk-proj-…` key**:

**1a. Transcription** — `AllApi.transcribeAudio(fileURL:completion:)`
`FocusBear/AllApi.swift:6886`
- `POST https://api.openai.com/v1/audio/transcriptions`
- `Authorization: Bearer sk-proj-…` (hardcoded, `AllApi.swift:6887`)
- `multipart/form-data` body with parts:
  - `model` = `whisper-1`
  - `language` = `en`
  - `file` = the recording, filename from the temp URL, `Content-Type: audio/wav`
- Response used: OpenAI returns `{ "text": "<transcript>" }`; the client reads only `json["text"]`.
- Caller: `audioRecorder.swift:257` (after recording stops), which then feeds the transcript into 1b.

**1b. Intent classification** — `AllApi.getIntentFromOpenAI(userMessage:habits:completion:)`
`FocusBear/AllApi.swift:6953`
- `POST https://api.openai.com/v1/chat/completions`
- `Authorization: Bearer sk-proj-…` (hardcoded, `AllApi.swift:6954`)
- Request body:
  - `model` = `gpt-4o-mini`
  - `temperature` = `0.1`
  - `response_format` = `{ "type": "json_object" }`
  - `messages` = `[ {role: system, content: <classifier prompt>}, {role: user, content: <transcript>} ]`
- The **system prompt** (`AllApi.swift:6963`–`7092`) is a voice-command classifier. Key inputs baked
  into the prompt at request time:
  - current local datetime (`yyyy-MM-dd HH:mm:ss`) for resolving relative times ("tomorrow 9am");
  - the user's **habit list** (`habits`, newline-bulleted) so `start_habit` matches a real habit name.
  - Actions it can emit: `create_task`, `start_focus`, `pause_focus`, `resume_focus`, `stop_focus`,
    `start_habit`, `pause_habit`, `resume_habit`, `get_focus_stats`.
- Response decoded into `IntentResponse` (`AllApi.swift:7328`):
  ```
  IntentResponse {
    action: String
    parameters: {                      // all optional
      task: String?, time: String?, repeat: String?,
      duration_minutes: Int?, goal: String?, habit_name: String?
    }
    confidence: String                 // "high" | "medium" | "low"
    clarification_needed: String?
    additional_actions: [{ action: String, parameters: [String:String]? }]?
  }
  ```
  Caller: `audioRecorder.swift:314` (`getIntentFromOpenAIAndPerformTask`).

### Feature 2 — AI accountability buddy (Mac)

`AllApi.evaluateAccountabilityConversation(messages:longTermGoals:completion:)`
`FocusBear/AccountabilityBuddy/aiAccountabilityBuddy.swift:184`
- `POST https://api.openai.com/v1/chat/completions`
- Key read at runtime from `FOCUSBEAR_OPENAI_KEY` env or `~/.focusbear-openai-key`
  (`aiAccountabilityBuddy.swift:25`) — a POC key, **not** currently bundled but must still be retired.
- Request body:
  - `model` = `gpt-4.1-mini`
  - `temperature` = `0.2`
  - `response_format` = `{ "type": "json_object" }`
  - `messages` = `[ {role: system, content: <buddy prompt with goals block>} ] + conversation`
    where conversation entries are `{role: "user"|"assistant", content: text}` — the running chat as
    the user argues their case across turns.
- The **system prompt** (`aiAccountabilityBuddy.swift:205`–`248`) makes the model a firm-but-caring
  gatekeeper deciding whether postponing a healthy habit for a stated computer task is justified
  **against the user's long-term goals**. The goals are injected into the prompt as a bullet block.
- Long-term goals are fetched client-side today via `AllApi.getuserLongTermGoals` →
  `GET /user/long-term-goals` (`AllApi.swift:1071`), returning `[String]`, then passed into the call
  (`aiAccountabilityBuddy.swift:391`). **Server-side we fetch these directly** and stop trusting the
  client to supply them.
- Response decoded into `AccountabilityVerdict` (`aiAccountabilityBuddy.swift:49`):
  ```
  {
    "approved": true | false,
    "message": "<1-3 sentence reply shown to the user>",
    "allowed_apps": ["Outlook", ...],          // decoded to allowedApps
    "allowed_urls": ["github.com", ...],        // decoded to allowedUrls
    "allowed_duration_minutes": <int>           // decoded to durationMinutes
  }
  ```
  The client clamps duration to 5–180 (default 25) after decoding (`aiAccountabilityBuddy.swift:69`).

---

## Backend conventions to mirror

Taken from the existing OpenAI-proxy endpoints so the new code looks native:

- **Controller:** `@Controller('<module>')`, `@ApiTags(...)`, class-level `@UseGuards(IsAuth)` +
  `@ApiSecurity('Auth0AccessToken')`. Handlers take `@AuthContext() { user }: Passport` for the
  authenticated user id. (See `ai.controller.ts`, `user.controller.ts:302`.)
- **Auth:** JWT Bearer via the `IsAuth` guard — same as every other endpoint. No endpoint is anonymous.
- **DTO validation:** `class-validator` decorators (`@IsString`, `@IsOptional`, `@IsNotEmpty`,
  `@MaxLength`, `@IsArray`, `@IsInt`, `@ValidateNested` + `@Type`). See `is-url-safe.dto.ts`,
  `generate-occupation-sites.dto.ts`.
- **Rate limiting:** `@Throttle({ default: { limit: N, ttl: 60000 } })` per handler
  (`user.controller.ts:317` uses 10/min for the occupation-sites generator).
- **OpenAI key config:** `apps/api-server/src/config/openai.config.ts` — `registerAs('openai', …)`
  with one sub-key per feature, each `process.env.OPENAI_<FEATURE>_API_KEY || process.env.OPENAI_API_KEY`.
  Read in services via `configService.get('openai.<feature>.apiKey')`. **Add new sub-keys here** (see below).
- **Shared LLM service:** `libs/openai/src/openai.service.ts` already exposes:
  - `transcribeAudioToText(file: File): Promise<string>` — uses `gpt-4o-transcribe` (`openai.service.ts:1719`).
  - `createChatCompletion(messages, …)` (`openai.service.ts:1295`) and JSON-mode helpers.
  - Prompts live in `libs/openai/src/openai.constants.ts` / the `prompt-cache.service.ts`, **not** in
    controllers. New prompts go there so they are tunable without a client release.

---

## Proposed endpoints

New module: **`apps/api-server/src/modules/voice`** for the two voice endpoints, and a new route on
the existing **`ai`** module (or a small `accountability` addition) for the buddy. All under JWT auth.

> Naming note: the existing human-buddy invitation feature already owns `@Controller('accountability-buddy')`.
> To avoid colliding with that (unrelated) module, the AI buddy endpoint lives under the `ai` module as
> `POST /ai/accountability-buddy/evaluate`. Backend may instead put it on a dedicated controller if
> preferred — the **path and contract below are what all clients code against**, so keep them stable.

### Endpoint 1 — Transcription: async, R2-backed, 3 endpoints

Audio is **never posted to a synchronous endpoint.** The client uploads the recording to R2, hands the
backend the **object key**, and transcription runs as an **async queue job**; the client is notified
over the existing Pusher `private-<userId>` channel and fetches the transcript by job id. This mirrors
the backend's existing to-do audio flow **exactly** — that flow already does presigned-R2 upload → async
Bull job → `transcribeAudioToText` — so this is a near copy, not new infrastructure.

**Pattern being mirrored (cite):**
- Presigned-upload endpoint returning `{ uploadUrl, <key> }`:
  `apps/api-server/src/modules/to-do/controllers/to-do.controller.ts:163` (`generate-upload-audio-url` →
  `r2Service.getPresignedUploadUrl(S3_BUCKET_TODO_AUDIOS, audioKey, 'audio/mpeg')`), DTO
  `generate-upload-audio-url.dto.ts` (`fileExtension` in `['mp3','m4a','wav','mp4']`).
- "Uploaded" endpoint that creates an async task + enqueues a Bull job and returns `{ asyncTaskId }`:
  `to-do.controller.ts:174` (`todo-audio-uploaded` → `asyncTaskService.createAsyncTask(...)` +
  `todoAudioQueue.add(BullWorkers.PROCESS_TODO_AUDIO, …)`).
- Consumer that pulls the object from R2 and transcribes:
  `apps/api-server/src/modules/to-do/consumers/todo-audio.consumer.ts:38` (`r2Service.getPresignedUrl` →
  `axios.get(arraybuffer)` → `toFile` → `openAiService.transcribeAudioToText(file)` →
  `asyncTaskService.updateStatusWithMetadata(asyncTaskId, AsyncTaskStatus.COMPLETED, …, { aiResponse })`).
- Async status lifecycle `pending → processing → completed → failed`:
  `apps/api-server/src/modules/async-task/domain/async-task-status.enum.ts`.
- Pusher completion push on the per-user channel:
  `apps/api-server/src/modules/activity-template/consumers/routine-suggestions.consumer.ts:80`
  (`this.pusher.trigger(\`private-${userId}\`, 'routine-suggestions.completed', { asyncTaskId, status })`
  via `PusherService` from `@app/pusher`).
- Client already subscribes to that exact channel and binds dot/kebab event names:
  `FocusBear/pusherEvents.swift:70` (`channelName = "private-"+userId`), `:75` onward
  (`channel.bind(eventName: "focus-mode-started", …)`, `"settings-updated"`, etc., each parsing
  `event.data` JSON).

All three endpoints below are JWT Bearer (`IsAuth`) + `@ApiSecurity('Auth0AccessToken')`, in a new
`voice` module.

#### 1a. `POST /voice/generate-upload-url` → presigned R2 target

Mirror of `to-do`'s `generate-upload-audio-url`.
- **Rate limit:** `@Throttle({ default: { limit: 30, ttl: 60000 } })`.
- **Request DTO:**
  ```ts
  export class GenerateVoiceUploadUrlDto {
    @IsString() @IsIn(['wav', 'm4a', 'mp3', 'mp4'])
    fileExtension: string;              // Mac records wav today; others allowed for Windows
  }
  ```
- **Response:**
  ```json
  { "uploadUrl": "https://<r2-presigned-PUT-url>", "audioKey": "<userId>-<ts>-voice-command.wav" }
  ```
  Server builds `audioKey = \`${user.id}-${Date.now()}-voice-command.${fileExtension}\`` and calls
  `r2Service.getPresignedUploadUrl(S3_BUCKET_VOICE_COMMANDS, audioKey, contentType)`. Add a
  `S3_BUCKET_VOICE_COMMANDS` bucket constant (or reuse the existing audio bucket with a `voice/` prefix —
  backend's call, but the **key must be user-scoped**).

#### 1b. Client PUTs the audio bytes to `uploadUrl` (R2)

The client uploads the recording directly to R2 with an HTTP `PUT` to the presigned `uploadUrl` (no auth
header — the presigned URL carries its own auth), `Content-Type` matching the extension. No backend
involvement. This is the only step that moves the audio bytes.

#### 1c. `POST /voice/transcribe` → enqueue job, return job id

Mirror of `todo-audio-uploaded`.
- **Rate limit:** `@Throttle({ default: { limit: 20, ttl: 60000 } })`.
- **Request DTO:**
  ```ts
  export class TranscribeVoiceDto {
    @IsString() @IsNotEmpty()
    audioKey: string;                   // the R2 object key returned by 1a (NOT bytes, NOT a public URL)

    @IsOptional() @IsString()
    language?: string;                  // ISO-639-1, default 'en'
  }
  ```
  > The client sends the **R2 object key**, not the audio and not an arbitrary URL. The backend resolves
  > the key against its own bucket, so a client can't point the server at an attacker URL.
- **Response DTO** — returns a **job id immediately** (no blocking on OpenAI):
  ```json
  { "jobId": "<uuid>" }
  ```
  ```ts
  export class TranscribeJobDto { jobId: string; }   // jobId === the AsyncTask id
  ```
- **Server internals:** `asyncTaskService.createAsyncTask({ metadata: { taskType: 'voice-transcription',
  userId, audioKey } })`, then `voiceTranscribeQueue.add(BullWorkers.PROCESS_VOICE_TRANSCRIPTION,
  { userId, audioKey, asyncTaskId }, { attempts: 3, backoff: exponential })`. Return `{ jobId: asyncTaskId }`.

#### 1d. Async consumer (queue worker) + Pusher notification

New `VoiceTranscriptionConsumer` (copy `TodoAudioConsumer`):
1. `updateStatusWithMetadata(asyncTaskId, PROCESSING, …)`.
2. `r2Service.getPresignedUrl(S3_BUCKET_VOICE_COMMANDS, audioKey)` → `axios.get` arraybuffer → `toFile`.
3. `openAiService.transcribeAudioToText(file)` (uses `gpt-4o-transcribe` server-side — an upgrade over
   the client's `whisper-1`; the client only consumes the text, so it's transparent). Key:
   `voiceTranscription` in `openai.config.ts`.
4. `updateStatusWithMetadata(asyncTaskId, COMPLETED, …, { text: transcript })` (store transcript under a
   `text` metadata key).
5. **Notify the client** over the existing channel:
   ```ts
   await this.pusher.trigger(`private-${userId}`, 'voice-transcription.completed', { jobId: asyncTaskId, status: 'completed' });
   ```
   On failure: `updateStatusWithMetadata(… FAILED …)` then
   `trigger('private-'+userId, 'voice-transcription.completed', { jobId, status: 'failed', errorMessage })`
   (same shape the routine-suggestions consumer uses).
   > Event name `voice-transcription.completed` follows the backend's `routine-suggestions.completed` /
   > `habit-creation.completed` convention. Channel is the same `private-<userId>` the Mac app already
   > subscribes to (`pusherEvents.swift:70`); Windows uses its equivalent per-user channel. The push is a
   > lightweight `{ jobId, status }` — the transcript itself is fetched via 1e (keeps the event small and
   > lets a client that missed the event still recover).

#### 1e. `GET /voice/transcribe/:jobId` → retrieve the transcript

The result-retrieval endpoint. Backed by the AsyncTask store (thin wrapper over the existing
`GET /async-task/:id`, but returning the voice-specific `{ status, text }` shape the client wants).
- **Response DTO:**
  ```ts
  export class VoiceTranscriptResultDto {
    status: 'pending' | 'processing' | 'completed' | 'failed';   // AsyncTaskStatus
    text: string | null;                 // the transcript when status === 'completed', else null
    errorMessage?: string;               // present when status === 'failed'
  }
  ```
  ```json
  { "status": "completed", "text": "start a focus session for 25 minutes" }
  ```
- **Server internals:** `asyncTaskService.findTaskById(jobId)`, map `task.status` → `status` and
  `task.metadata.text` → `text`. `404` if the job id is unknown; enforce that the job's
  `metadata.userId` matches the caller so users can't read each other's transcripts.

**Client sequencing (all clients):** call 1a → PUT to R2 (1b) → 1c to get `jobId` → **wait for the
`voice-transcription.completed` Pusher event** for that `jobId`, then call 1e to fetch `{ status, text }`.
Fallback: if the event is missed, **poll 1e** a few times (e.g. every ~1.5 s, ~20 s cap) — the event is
an optimisation, 1e is the source of truth. On `status: 'completed'`, feed `text` into
`POST /voice/intent` (Endpoint 2) exactly as the transcript is fed to intent classification today.

- **Errors/timeouts:** 1a/1c `400` bad ext/key, `401`, `429`; 1e `404` unknown/forbidden job. The R2 PUT
  (1b) is between client and R2. The OpenAI call lives in the worker (bounded ≤ ~120 s per the to-do
  consumer's `axios` timeout), not in any request the client waits on synchronously.

### Endpoint 2 — `POST /voice/intent`

Classify a transcript into a structured voice-command intent.

- **Auth:** JWT Bearer. **Rate limit:** `@Throttle({ default: { limit: 30, ttl: 60000 } })`.
- **Request DTO:**
  ```ts
  export class VoiceIntentDto {
    @IsString() @IsNotEmpty() @MaxLength(1000)
    transcript: string;                 // the spoken command text

    @IsOptional() @IsArray() @IsString({ each: true })
    habits?: string[];                  // candidate habit names for start_habit matching

    @IsOptional() @IsString()
    clientDatetime?: string;            // client local "yyyy-MM-dd HH:mm:ss" for relative-time resolution

    @IsOptional() @IsString()
    timezone?: string;                  // IANA tz (e.g. "Australia/Melbourne"); preferred over clientDatetime
  }
  ```
  > `habits` is passed as an **array** (backend joins it into the prompt) rather than a pre-joined
  > string, so the prompt formatting lives server-side. `clientDatetime`/`timezone` replace the
  > datetime the client used to bake into the prompt — the client still knows "now" in the user's local
  > zone, so it passes it; backend falls back to server time if absent.
- **Response DTO** — **byte-for-byte the JSON `IntentResponse` decodes today** (snake_case keys, all
  `parameters` optional):
  ```ts
  export class VoiceIntentResponseDto {
    action: string;                     // create_task | start_focus | pause_focus | resume_focus |
                                        // stop_focus | start_habit | pause_habit | resume_habit | get_focus_stats
    parameters: {
      task?: string; time?: string; repeat?: string;
      duration_minutes?: number; goal?: string; habit_name?: string;
    };
    confidence: string;                 // high | medium | low
    clarification_needed: string | null;
    additional_actions?: { action: string; parameters?: Record<string, string> }[];
  }
  ```
- **Server internals:** the classifier system prompt (currently `AllApi.swift:6963`–`7092`) moves into
  `libs/openai` (constants/prompt-cache). Backend injects datetime + habit list, calls
  `createChatCompletion` with `gpt-4o-mini`, `temperature 0.1`, `response_format json_object`, parses
  and validates the JSON against the response shape before returning. Key: add `voiceIntent` to `openai.config.ts`.
- **Errors/timeout:** as Endpoint 1.

### Endpoint 3 — `POST /ai/accountability-buddy/evaluate`

Judge the accountability conversation and return a verdict.

- **Auth:** JWT Bearer. **Rate limit:** `@Throttle({ default: { limit: 20, ttl: 60000 } })`.
- **Request DTO:**
  ```ts
  class BuddyMessageDto {
    @IsIn(['user', 'assistant']) role: 'user' | 'assistant';
    @IsString() @IsNotEmpty() @MaxLength(2000) content: string;
  }

  export class EvaluateAccountabilityDto {
    @IsArray() @ValidateNested({ each: true }) @Type(() => BuddyMessageDto)
    @ArrayMinSize(1)
    messages: BuddyMessageDto[];        // running chat (user's case + buddy replies), oldest first
  }
  ```
  > **Long-term goals are NOT in the request.** The backend fetches them for the authenticated user
  > (same source that backs `GET /user/long-term-goals`) and injects them into the system prompt. This
  > removes the client round-trip AND stops the client from being able to spoof the goals it is judged
  > against. This is the one behavioural change vs. today (goals now come from the server).
- **Response DTO** — identical to `AccountabilityVerdict` today (snake_case):
  ```ts
  export class AccountabilityVerdictDto {
    approved: boolean;
    message: string;                    // 1-3 sentences shown to the user
    allowed_apps: string[];             // [] when denied
    allowed_urls: string[];             // [] when denied
    allowed_duration_minutes: number;   // client still clamps 5..180 (default 25)
  }
  ```
- **Server internals:** the buddy system prompt (`aiAccountabilityBuddy.swift:205`–`248`) moves into
  `libs/openai`. Backend builds the goals block from the user's stored long-term goals, prepends the
  system message, appends `messages`, calls `createChatCompletion` with `gpt-4.1-mini`,
  `temperature 0.2`, `response_format json_object`, validates the parsed JSON. Key: add
  `accountabilityBuddy` to `openai.config.ts`.
- **Errors/timeout:** as above; `422` if the model returns unparseable JSON after retries.

### `openai.config.ts` additions

```ts
voiceTranscription:   { apiKey: process.env.OPENAI_VOICE_TRANSCRIPTION_API_KEY   || process.env.OPENAI_API_KEY },
voiceIntent:          { apiKey: process.env.OPENAI_VOICE_INTENT_API_KEY          || process.env.OPENAI_API_KEY },
accountabilityBuddy:  { apiKey: process.env.OPENAI_ACCOUNTABILITY_BUDDY_API_KEY  || process.env.OPENAI_API_KEY },
```
Per-feature env vars (falling back to the shared key) let ops rotate/limit each feature independently,
matching the existing pattern.

### Cross-cutting: abuse & cost

- Every endpoint is behind `IsAuth` (no anonymous access) and per-route `@Throttle`.
- Cap input sizes in the DTOs (`@MaxLength`, `ArrayMaxSize`, audio size/duration limits).
- Log usage per user (the openai service already logs operations) so we can spot abuse.
- Consider a per-user daily budget for the buddy + intent endpoints if cost becomes a concern (future).

---

## Client migration

### Shared contract summary (all clients)

| Feature | Old direct call | New backend call |
|---------|-----------------|------------------|
| Voice transcription | `POST api.openai.com/v1/audio/transcriptions` (whisper-1) | **as shipped:** `POST {baseUrl}/voice/transcribe` (multipart, part `file`) → `{ text }` |
| Voice intent | `POST api.openai.com/v1/chat/completions` (gpt-4o-mini) | `POST {baseUrl}/voice/intent` (JSON) |
| Accountability buddy | `POST api.openai.com/v1/chat/completions` (gpt-4.1-mini) | `POST {baseUrl}/ai/accountability-buddy/evaluate` (JSON) |

All new calls: **JWT Bearer**, standard app headers, response shapes **unchanged** from what clients
already decode.

### Mac changes

Use the existing authenticated-request helper rather than building a raw `URLRequest`:

- **`makeRequest(responsePathUrl:)`** (`AllApi.swift:7146`) already attaches
  `Authorization: Bearer <accessToken>`, `platform`, `app-version`, `x-focus-bear-user-id`, `device-id`.
  Every migrated call should be built from it (see `getuserLongTermGoals`, `AllApi.swift:1085`, as the
  reference pattern: `makeRequest` → set `httpMethod` → `URLSession.shared.dataTask`). `baseUrl` +
  `allApiObject` are the existing globals.

1. **`transcribeAudio`** (`AllApi.swift:6886`): replace the direct OpenAI multipart call with the
   **async R2 flow** (Endpoint 1). **Delete the `Authorization: Bearer sk-proj-…` line and the whole
   direct-OpenAI request.** New sequence, all `makeRequest`-based except the R2 PUT:
   (a) `POST \(baseUrl)/voice/generate-upload-url` `{ fileExtension: "wav" }` → `{ uploadUrl, audioKey }`;
   (b) `PUT` the recorded bytes to `uploadUrl` (plain `URLSession` PUT, `Content-Type: audio/wav`, **no**
   auth header — the presigned URL is self-authorising); (c) `POST \(baseUrl)/voice/transcribe`
   `{ audioKey }` → `{ jobId }`. Then **bind a new Pusher event** `voice-transcription.completed` on the
   already-subscribed `private-<userId>` channel in `pusherEvents.swift` (add alongside the existing
   `channel.bind(eventName:…)` calls at `pusherEvents.swift:75`+); when it fires for this `jobId`, call
   `GET \(baseUrl)/voice/transcribe/\(jobId)` → `{ status, text }` and, on `completed`, feed `text` into
   step 2 exactly as today (`audioRecorder.swift:257`→`267`). Add a **poll fallback** on 1e (every ~1.5 s,
   ~20 s cap) in case the event is missed. The `transcribeAudio` completion still ultimately yields the
   transcript `String`, so `audioRecorder.swift`'s downstream `getIntentFromOpenAIAndPerformTask` is
   unchanged — only the mechanism to obtain the transcript changes.
2. **`getIntentFromOpenAI`** (`AllApi.swift:6953`): replace the entire OpenAI request with a
   `makeRequest`-based `POST \(baseUrl)/voice/intent`, JSON body `{ transcript, habits, clientDatetime,
   timezone }`. **Delete the hardcoded key and the whole embedded system prompt** — it now lives on the
   server. Decode the response straight into the existing `IntentResponse` (unchanged). The `habits`
   string currently built by `getHabitsString` (`audioRecorder.swift:310`) becomes a `[String]` array
   sent as `habits`.
3. **`evaluateAccountabilityConversation`** (`aiAccountabilityBuddy.swift:184`): replace with a
   `makeRequest`-based `POST \(baseUrl)/ai/accountability-buddy/evaluate`, body
   `{ messages: [{role, content}] }`. **Delete `accountabilityBuddyOpenAIKey()` (`:25`), the
   `~/.focusbear-openai-key` read, the embedded system prompt, and the `longTermGoals` parameter** — the
   server injects goals. Decode into the existing `AccountabilityVerdict` (unchanged; keep the client
   `clampedDurationMinutes` clamp). The `getuserLongTermGoals` fetch in
   `AccountabilityBuddyChatViewController` (`aiAccountabilityBuddy.swift:391`) can be removed once the
   server owns goals.

Constants hygiene while touching these files: the three new paths (`/voice/transcribe`,
`/voice/intent`, `/ai/accountability-buddy/evaluate`) should be named constants alongside the other
endpoint strings, not inline literals.

### Windows changes

Windows (`windows-app-v2`) must perform the **same swap against the same contract**: replace its
direct OpenAI calls for these two features with authenticated `POST`s to the three endpoints above,
using its existing JWT-authenticated HTTP client (the equivalent of Mac's `makeRequest`). Request and
response DTOs are identical. If Windows does not yet implement the accountability buddy, it simply
adopts the endpoint when it does. Windows team: track under the Windows board.

---

## Rollout & backward-compat

1. **Backend ships first** behind the new routes; verify with authenticated calls in staging.
2. **Feature flag on each client:** gate the new code path behind a flag (server-config / remote flag)
   `useBackendVoiceAi` / `useBackendAccountabilityBuddy`. Default OFF until the backend is live in prod,
   then flip ON. This lets us roll back to the old path without a client release if the endpoints regress.
3. **Keep the old direct-call path only until the backend is confirmed in prod**, then **delete it and
   the bundled/local key** from the client in the following release. Do not leave the dead OpenAI code
   (or the key) behind — remove `transcribeAudio`'s hardcoded key, `getIntentFromOpenAI`'s key + prompt,
   and `accountabilityBuddyOpenAIKey()` entirely.
4. **Prompt/model tuning** now happens server-side (in `libs/openai`) with no client release.

## Security follow-up — revoke compromised keys (do this regardless)

These keys are compromised the moment they ship in a client and MUST be revoked in the OpenAI
dashboard once the backend endpoints are live:

- The **hardcoded `sk-proj-…` key** in `AllApi.swift:6887` and `:6954` (it is in the committed Mac
  source — treat as fully public).
- Any key checked into / referenced by the **public `accountability-buddy-poc` repo**.
- The POC key used via `~/.focusbear-openai-key` / `FOCUSBEAR_OPENAI_KEY` should be retired for
  production use (the buddy no longer needs a client-side key at all).

Revoke **after** the migrated clients are on the backend path (or at least after the feature flag can
be turned on), so we don't break the current app before the replacement is live. The server key is a
**new** key stored only as a backend secret/env var.

---

## Implementation checklist

**Backend**
- [ ] Add `voiceTranscription`, `voiceIntent`, `accountabilityBuddy` sub-keys to `openai.config.ts`.
- [ ] Move the three prompts (voice classifier, buddy) into `libs/openai` constants/prompt-cache.
- [ ] Add `S3_BUCKET_VOICE_COMMANDS` + Bull queue/worker constants (`PROCESS_VOICE_TRANSCRIPTION`).
- [ ] `POST /voice/generate-upload-url` → `r2Service.getPresignedUploadUrl` (mirror `generate-upload-audio-url`).
- [ ] `POST /voice/transcribe` `{ audioKey }` → `createAsyncTask` + enqueue Bull job → `{ jobId }`
      (mirror `todo-audio-uploaded`).
- [ ] `VoiceTranscriptionConsumer` (copy `TodoAudioConsumer`): R2 fetch → `transcribeAudioToText` →
      `updateStatusWithMetadata(COMPLETED, { text })` → `pusher.trigger('private-'+userId,
      'voice-transcription.completed', { jobId, status })`.
- [ ] `GET /voice/transcribe/:jobId` → `{ status, text }` from the AsyncTask (enforce owner match).
- [ ] `POST /voice/intent` (JSON) → `createChatCompletion` (gpt-4o-mini, json_object), validate output.
- [ ] `POST /ai/accountability-buddy/evaluate` (JSON) → fetch user goals server-side → buddy prompt →
      `createChatCompletion` (gpt-4.1-mini, json_object), validate output.
- [ ] DTOs with class-validator; per-route `@Throttle`; `IsAuth` guard; Swagger tags.

**Mac**
- [ ] Rework `transcribeAudio` into the async R2 flow (generate-upload-url → R2 PUT → `POST /voice/transcribe`
      → `{ jobId }`); bind `voice-transcription.completed` in `pusherEvents.swift`; fetch via
      `GET /voice/transcribe/:jobId` with a poll fallback.
- [ ] Repoint `getIntentFromOpenAI`, `evaluateAccountabilityConversation` at the backend via `makeRequest`;
      delete hardcoded/local keys + embedded prompts.
- [ ] Feature flags; remove old path + keys after backend is prod-verified.

**Windows**
- [ ] Same client swaps against the same contract (incl. the async transcribe sequence + per-user channel
      event `voice-transcription.completed`); feature-flagged; remove any bundled key.

**Ops/Security**
- [ ] Provision server-side OpenAI key(s) as backend secrets.
- [ ] Revoke the committed `sk-proj-…` key and the poc-repo key after cutover.
