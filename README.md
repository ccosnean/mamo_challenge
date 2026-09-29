# Payment approval flow

A Flutter take-home for Mamo. Payees send you payment requests. You approve or reject them.

**Live demo:** _link added after the Firebase deploy_. Nothing to install.

- Spec: [`docs/CHALLENGE.md`](docs/CHALLENGE.md)
- Domain model and ISO 20022 mapping: [`docs/DOMAIN.md`](docs/DOMAIN.md)

## TL;DR

- **The app is production code.** It talks to a JSON API over HTTP, and asks for biometric confirmation through a small interface. It knows nothing about mocks.
- **The showcase is a web page around the app.** It shows the app in an iPhone frame, with a mock bank, a biometrics simulation and a live log console next to it.
- **Why:** a link is the easiest thing to share. Reviewers try it in a browser, with no install and no build.
- **How:** the app takes everything from outside through one object, `AppConfig`. The showcase passes mocks and simulations. Production would pass the real API and the `local_auth` package.
- **Design came first.** Every screen was drawn before any code. Money is monospaced, so amounts compare at a glance.

## Try it in one minute

1. Tap **Sign in**. The demo account is filled in.
2. In the **Bank** panel, tap **Send payment request**. Within 5 s, a sheet opens over whatever screen you are on.
3. Tap **Review with Face ID**. The **Biometrics** panel decides whether the simulated scan passes or fails.
4. **Approve** takes you to Payments. **Reject** leaves you where you were.

Also try:

- Send 3 requests: one sheet, 3 pages, swipe between them, one Face ID for all.
- Pay a bigger request from **Savings** (AED 150): not enough funds, and the request stays open.
- Turn the bank **offline**, or add **latency**.
- **Expire session**: the app returns to login on its next call.
- Watch the **Console**: tokens, IBANs and amounts are masked.

## How I worked

1. **Designed first.** I read the spec, then drew every screen and state on a design canvas before writing code. See [Design](#design).
2. **Planned the handover early.** "Reviewers shouldn't need to compile" made a hosted demo part of the job from day one.
3. **Modelled the domain** on a real standard (ISO 20022 Request-to-Pay), not on the wireframe.
4. **Built the app against a fake backend,** then moved that backend out. It became a JSON API behind dio, so the app's data layer is the real one.
5. **Split the code into 3 packages,** so mock code can never reach the production app.
6. **Built the showcase around the app:** device frame, bank controls, simulated Face ID, console.
7. **Used it, then fixed what felt wrong:** one sheet for many requests, nothing truncated where money is approved, pinned buttons, the Face ID animation at the Dynamic Island.

## Design

Before any code, I drew every screen and state on a design canvas: Home, Payments, Accounts, Details, and each step of the approval sheet. The code followed it. The spec says the wireframe's look is a placeholder, so I designed my own.

**Look**

- **Calm banking style,** inspired by Revolut: a light grey background, white cards, one blue accent.
- **Two typefaces.** Manrope for text. DM Mono for money, references and IBANs.

**Money**

- **Monospaced and right-aligned.** Every digit has the same width, so decimal points line up down a list. You compare amounts at a glance.
- **The currency code is smaller and muted.** The number is what you read.
- **Amounts never wrap or get cut.** In a row, the name gives way, not the amount.
- **Rejected amounts are muted and struck through,** with a "Rejected" label. That money didn't move.
- **Balances count up** to their new value after a payment, so you see the change.

**Privacy**

- **Masks have a fixed shape.** `A•••• K.` and `AED ••,•••.••` never reveal the length of a name or the size of an amount.
- **The pending list is masked like the sheet.** It never shows what the sheet hides.
- **Tap the total balance to hide it,** for when you use the app in public.

**Clarity**

- **The top bar says who you act for:** your name, your company, and the total balance.
- **Home says what counts.** "Spent in September" is only money that moved. Rejections sit next to it, marked "not counted".
- **Waiting requests come first** on Payments, with a bar for the time left. History is grouped by day.
- **A badge on the Payments tab** shows how many requests are waiting.
- **Status is never colour alone.** Every status has a text label, and the colours also differ in lightness.
- **Avatars are initials** on a colour taken from the payee's id. The same payee always looks the same. No network images.
- **Low balances are flagged** on Accounts, before a payment fails.

**The approval sheet**

- **Nothing is truncated once revealed.** This is where money leaves. Full payee name, full amount, and each account with its balance before and after.
- **The header and buttons are pinned.** Only the details scroll. The buttons stay clear of the home indicator.
- **Approve is the big button.** Reject sits next to it, neutral.
- **Problems are explained in place:** not enough funds, bank unreachable, Face ID failed. The request stays open.

**Motion and accessibility**

- **Short animations** (150 to 450 ms). All of them turn off when the system asks for reduced motion.
- **New items slide in. The first load doesn't.** Motion always means "this just changed".
- **Screen readers get real labels.** A masked amount reads "Amount hidden", not dots. Errors are announced.
- **Muted text keeps a contrast above 6:1** on white.

## Architecture

```
showcase (web page)
├── iPhone frame ── payments_app (unchanged production app)
│                     └── dio ─► auth ─► logging ─► MockBankInterceptor ─► MockBankServer
├── Bank panel ─────────────────────────────────────────────────────────► MockBankServer controls
├── Biometrics panel ─► BiometricsSimulator (a DeviceAuthenticator) ─► animation over the frame
└── Console ◄── LogSink ◄── the app's logger (masked)
```

### Packages

| Package | What it is | Depends on |
|---|---|---|
| [`payments_app`](packages/payments_app) | The production app. No mock imports. | dio, flutter_bloc, go_router, get_it, freezed, local_auth |
| [`mock_bank`](packages/mock_bank) | An in-memory bank that speaks JSON. | dio, faker, crypto |
| [`showcase`](packages/showcase) | The web page. Wires the app to the fakes. | payments_app, mock_bank, device_frame |

- `mock_bank` is a **dev dependency** of the app, for tests only. It is never in the app's runtime code.
- The packages form a **pub workspace**: one lockfile, one `pub get`.

### What the app takes from outside (`AppConfig`)

| Plug-in point | Production | Showcase |
|---|---|---|
| `apiBaseUrl` + transport interceptors | the real API | `MockBankInterceptor` |
| `DeviceAuthenticator` | `local_auth` package | `BiometricsSimulator` (simulation) |
| `LogSink`s | debug console | debug console + the Console panel |
| `demoAccount` | none | shown on login for one-tap sign-in |

The app never checks which one it got.

## The mock bank

- **A real API shape.** JSON over HTTP, snake_case, amounts as decimal strings (`"1200.00"`), UTC timestamps.
- **It answers inside a dio interceptor,** added last. The app's own interceptors (auth header, logging) run first, exactly as they would against a real server. To go live, you remove one interceptor.
- **Endpoints:** `POST /oauth/token`, `POST /oauth/revoke`, `GET /me`, `GET /accounts`, `GET /payment-requests`, `GET /payments`, `POST /payment-requests/{id}/approve`, `POST /payment-requests/{id}/reject`.
- **Real errors:** 401 bad token, 404 unknown, 409 already decided, 410 expired, 422 insufficient funds (ISO reason `AM04`).
- **Real rules:** balances are debited on approval. Requests expire after 24 h. Tokens expire after 1 h. Passwords are stored salted and hashed.
- **Fake data** comes from `faker`: repeat payees, UAE businesses, valid UAE IBANs, realistic amounts and notes.
- **Controls for the showcase:** send a request, top up, go offline, set latency, expire sessions, reset.
- **No tests, on purpose.** It is test tooling, not product.

## Biometrics (simulated)

- **It's a simulation.** There is no real Face ID here. A browser has none, and more would be overkill for a demo.
- **The app sees one small interface,** `DeviceAuthenticator`, modelled on the `local_auth` package: an `authenticate(reason)` call, and the outcomes `local_auth` can end with (`success`, `failed`, `cancelled`, `unavailable`).
- **In the showcase:** `BiometricsSimulator` implements it. Pick **Pass** or **Fail**. A short Face ID-style animation plays at the Dynamic Island, then the app gets the answer.
- **For a real phone:** `LocalAuthDeviceAuthenticator` implements the same interface with `local_auth`. The demo only runs the simulation.

## The showcase

- **Why a phone in a browser?** A link needs no TestFlight, no APK, no emulator. And a browser has no Face ID, so the showcase simulates it from outside.
- **The app in the frame is the production app.** It runs unchanged. Only `AppConfig` differs.
- **A real phone screen:** `device_frame` draws an iPhone 15 Pro with its safe areas, so the layout behaves as on a device.
- **Always the full workbench:** phone on the left, Bank and Biometrics on the right, and a collapsible Console below them. A narrow window scrolls sideways.
- **Logs are always masked here,** even in debug, so reviewers see what production logs look like.

## Inside the app

### File structure

Feature-first. Each feature has three layers.

```
packages/payments_app/lib/
├── payments_app.dart   public API: configurePaymentsApp(), PaymentsApp, AppConfig
├── main.dart           production entry point
├── app/                composition root: config, DI, router, shell
├── core/               shared code, no feature logic
│   ├── api/            API errors, HTTP logging, JSON list parsing
│   ├── money/          Money, Currency
│   ├── banking/        Iban
│   ├── device_auth/    DeviceAuthenticator + local_auth version
│   ├── logging/        sinks, redactor, bloc observer, error hooks
│   ├── format/         money, dates, masking
│   └── ui/             theme, motion, shared widgets
└── features/
    ├── auth/           login, session, token interceptor
    ├── account/        accounts and balances
    ├── payments/       requests, history, list, details
    ├── approval/       the approval sheet
    └── home/           monthly summary, recent payments

features/<feature>/
├── domain/        models, repository interfaces, exceptions (pure Dart)
├── data/          RepositoryImpl, DTOs, mappers (dio)
└── presentation/  pages, widgets, blocs
```

### Domain

- **Request-to-Pay, following ISO 20022.** The user is always the payer. The details are in [`docs/DOMAIN.md`](docs/DOMAIN.md).
- **Two types, on purpose.** `PaymentRequest` is pending. `Payment` is decided. Lists and details only take a `Payment`, and details look it up in the decided history. A pending request can't open there.
- **The decision and the money are separate.** Status is `rejected`, `processing`, `completed` or `failed`. Only `completed` counts in totals.
- **Money is exact.** An integer count of fils, never a `double`. Mixing currencies throws.
- **IBANs are validated** with the mod-97 checksum.
- **Personal data stays out of logs.** `toString()` never prints names or full IBANs.
- **Pure Dart.** No Flutter, no dio.

### Repositories

- **Interfaces in `domain/`, implementations in `data/`** (`AuthRepositoryImpl`, `AccountRepositoryImpl`, `PaymentsRepositoryImpl`).
- **One in-memory cache per repository,** exposed as streams. Every screen reads the same data, so a decision shows up everywhere at once.
- **Polling every 5 s** for pending requests and balances, while signed in. Plus an instant refresh when the app comes back to the foreground.
- **Optimistic, then confirmed.** A decision updates the cache at once, then reloads from the server.
- **DTOs are separate from domain models** (freezed + json_serializable). Mappers validate on the way in. A bad item is dropped and logged, not shown wrong.
- **Typed errors.** HTTP status → a sealed exception (`InsufficientFundsException`, `PaymentRequestExpiredException`, …). The UI must handle every case.

### State and navigation

- **flutter_bloc.** App-wide cubits sit above the router (session, accounts, history, pending), so every screen opens with data. Each request in the approval sheet has its own `ApprovalBloc`.
- **go_router.** A redirect guard sends signed-out users to login. Tabs keep their state. Details open above the tabs, so back returns to where you came from.
- **The approval sheet** is shown from `MaterialApp.builder`, so it opens over any screen.

### Dependency injection

- **get_it, in one place:** `app/di.dart`. It is the only code that picks implementations.
- **Only `PaymentsApp` reads from get_it.** Below it: plain constructors and `BlocProvider`. Blocs and screens never call get_it, so they are easy to test.
- **A host calls `configurePaymentsApp(config)` once,** then shows `PaymentsApp()`. Calling it again replaces everything.

### Networking

- **One dio client.** Timeouts of 10 s to connect and 15 s to receive.
- **Interceptors, in order:** auth header → one-line HTTP log → transport (only the mock, in the showcase and tests).
- **Failures keep the last known data.** The next poll retries.
- **No data leaks between sessions.** If the user changed while a request was in flight, the response is dropped.

### Authorisation and token validity

- **OAuth 2 password grant.** Sign-in gets an opaque bearer token, then loads the user from `/me`.
- **The token never leaves the data layer.** `AuthRepositoryImpl` holds it, in memory only. `AuthTokenInterceptor` adds it to every call except `/oauth/*`.
- **Validity is the server's call.** The app does not guess expiry. A `401` on a call that carried the current token ends the session, and the router goes to login.
- **A late 401 from an old token is ignored,** so it can't end a newer session.
- **Sign-out is local first.** The app leaves protected screens at once, then revokes the token on the server (RFC 7009). If the revoke fails, it's logged, and you're still signed out.
- **In production I would add** a refresh token in the Keychain/Keystore, and one silent refresh on 401 before signing out.

### Logging

- **`package:logging`,** one named logger per class, routed to pluggable `LogSink`s.
- **Masking before any sink sees a line.** `LogRedactor` masks tokens (`at_•••`), IBANs (country and last 4), card numbers, emails, phones and amounts (`AED •••`).
- **Masked by default outside debug builds.** Unmasked in local debug, so developers can read everything. The showcase forces masking on.
- **Names and notes are never logged,** masked or not.
- **Bloc events** are logged as type names only, never their data.
- **Uncaught errors** (Flutter and async) go to the same log.

### Approval UX

- **Masked until Face ID.** Only the reference is shown in full.
- **One sheet for all pending requests,** as pages. Swipe, arrows or dots. One Face ID unlocks them all, including ones that arrive later.
- **Locks again** when the app goes to the background.
- **Reject needs no Face ID.** Approve does.
- **Double taps can't send two decisions.**
- **Edge cases handled:** not enough funds, expired, decided on another device, offline, session ended.

## Tooling

- **Flutter 3.47.5, pinned with fvm** (`.fvmrc`).
- **Melos scripts**, configured in the root `pubspec.yaml`, always on the fvm SDK.
- **Lints:** `very_good_analysis`, strict casts, strict raw types. Any lint fails the build.
- **Tests (95):** money, IBAN, formats, masking, DTO mapping, repositories over real dio + the mock bank, blocs, and full widget flows from sign-in to approval.
- `freezed` is pinned to `3.2.6-dev.1`, the only version that works with the Dart 3.12 SDK constraint.

```sh
fvm flutter pub get                       # the whole workspace
fvm dart run melos run verify             # format + analyze + test
fvm dart run melos run build:showcase     # release web build (what gets deployed)
fvm dart run melos run deploy:showcase    # build + publish to Firebase Hosting
fvm dart run melos run codegen            # after changing a DTO
cd packages/showcase && fvm flutter run -d chrome   # the showcase, locally
```

`packages/payments_app/lib/main.dart` is the production entry point. It needs `--dart-define=API_BASE_URL=…` and a real backend.

## Deviations from the spec

- **No debug FAB.** New requests come from the showcase's Bank panel, outside the app, the way a real payee's request would arrive. The app picks them up on its next 5 s poll.
- **Three tabs, not two.** I added Accounts, because approving means choosing which account pays.

## What I would do next

**Product**

- **Multi-currency accounts.** Hold AED, USD, EUR. Show the FX rate and fee before approving. Show the total in one home currency.
- **Send requests, not only receive them.** Request money from other companies, and share a payment link or QR code.
- **Approval rules for teams.** Above a set amount, a second person must approve (maker-checker). Rules per payee or per account.
- **Safer payments.** Confirm the payee's name against the IBAN before paying. Warn on a first-time payee or an unusual amount. Show a verified badge for known businesses.
- **Invoices attached to requests.** Show the PDF in the sheet, and keep the receipt with the payment.
- **Accounting export.** Send decided payments to Xero or QuickBooks, matched by reference.
- **Approve from a notification.** Push when a request arrives, then Face ID and done.
- **Schedule instead of paying now.** Pay on a chosen date, before the request expires.

**Engineering**

- **Real-time updates** (WebSocket or push) instead of polling.
- **Idempotency keys** on approve and reject, so a retry can never pay twice.
- **Refresh tokens** in secure storage, plus certificate pinning.
- **Hide revealed details** in the app switcher and from screenshots.
- **Arabic and right-to-left layouts,** and dark mode.
- **Crash reporting** as another `LogSink` (Sentry or Crashlytics). It already gets masked lines.
- **CI:** `melos run verify` on every PR, and a Firebase deploy of the showcase on merge.
