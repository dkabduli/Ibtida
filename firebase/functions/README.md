# Ibtida Firebase Functions

Cloud Functions for the Ibtida app (payments, webhooks, health).

## Node version

- **Required:** Node.js **22** (see `engines` in `package.json`).
- Use Node 22 locally (e.g. `nvm use 22` or install from [nodejs.org](https://nodejs.org)).
- The Firebase runtime uses the same version when you deploy.

## Setup

```bash
npm install
```

## Local emulator

```bash
npm run serve
```

## Deploy

```bash
npm run deploy
```

## Stripe config (no secrets in repo)

- **Local:** Create `firebase/functions/.env` (git-ignored):
  ```
  STRIPE_SECRET_KEY=sk_test_...
  STRIPE_WEBHOOK_SECRET=whsec_...
  ```
- **Production:** Set config (run from repo root):
  ```bash
  firebase functions:config:set stripe.secret="sk_live_..." stripe.webhook_secret="whsec_..."
  ```
  Then redeploy: `npm run deploy`

## Endpoints

- `health` – GET/POST returns `{ ok: true, timestamp }`.
- `createPaymentIntent` – POST JSON `{ amount, currency?, metadata? }`; returns `{ clientSecret }`.
- `stripeWebhook` – POST from Stripe (webhook); verifies signature and writes to Firestore `donations`.
