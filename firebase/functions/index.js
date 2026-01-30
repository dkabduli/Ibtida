/**
 * Ibtida Firebase Functions
 * - health: verification endpoint
 * - createPaymentIntent: Stripe PaymentIntent; validates intakeId, writes Firestore
 * - stripeWebhook: Stripe webhook → organizationIntakes + payments (event idempotency)
 *
 * Stripe secrets (never hardcode):
 * - firebase functions:secrets:set STRIPE_SECRET_KEY
 * - firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
 */

if (process.env.FUNCTIONS_EMULATOR === "true" || !process.env.GCLOUD_PROJECT) {
  try {
    require("dotenv").config();
  } catch (e) {
    // dotenv optional for production
  }
}

const {onRequest} = require("firebase-functions/https");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {setGlobalOptions} = require("firebase-functions");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

const stripeSecretRef = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecretRef = defineSecret("STRIPE_WEBHOOK_SECRET");

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

setGlobalOptions({maxInstances: 10});

const MIN_AMOUNT_CENTS = 50;
const MAX_AMOUNT_CENTS = 99999999;
/** Currency enforced as CAD everywhere (Canadian charities). */
const CURRENCY_CAD = "cad";
const INTAKES_COLLECTION = "organizationIntakes";
const PAYMENTS_COLLECTION = "payments";
const USERS_COLLECTION = "users";
const USER_DONATIONS_SUBCOLLECTION = "donations";

function getStripeSecret(secretRef) {
  if (process.env.STRIPE_SECRET_KEY) {
    return process.env.STRIPE_SECRET_KEY;
  }
  try {
    if (secretRef && typeof secretRef.value === "function") {
      const v = secretRef.value();
      if (v) return v;
    }
  } catch (e) {
    // Secret not set
  }
  const config = functions.config();
  const secret = config.stripe && config.stripe.secret;
  if (!secret) {
    throw new Error("Stripe secret not configured");
  }
  return secret;
}

function getStripeWebhookSecret(secretRef) {
  if (process.env.STRIPE_WEBHOOK_SECRET) {
    return process.env.STRIPE_WEBHOOK_SECRET;
  }
  try {
    if (secretRef && typeof secretRef.value === "function") {
      const v = secretRef.value();
      if (v) return v;
    }
  } catch (e) {
    // Secret not set
  }
  const config = functions.config();
  const secret = config.stripe && config.stripe.webhook_secret;
  if (!secret) {
    throw new Error("Stripe webhook secret not configured");
  }
  return secret;
}

function corsHeaders(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

async function getUidFromRequest(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null;
  const idToken = authHeader.split("Bearer ")[1];
  if (!idToken) return null;
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    return decoded.uid || null;
  } catch (e) {
    return null;
  }
}

// ----- Health -----

exports.health = onRequest((req, res) => {
  corsHeaders(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  res.status(200).json({
    ok: true,
    timestamp: new Date().toISOString(),
  });
});

// ----- createPaymentIntent -----

exports.createPaymentIntent = onRequest(
  {secrets: [stripeSecretRef]},
  async (req, res) => {
    corsHeaders(res);
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    try {
      const body = req.body || {};
      const intakeId = body.intakeId;
      if (!intakeId || typeof intakeId !== "string" || intakeId.length === 0) {
        res.status(400).json({error: "intakeId is required"});
        return;
      }

      let amount = body.amount ?? body.amountCents;
      if (amount == null) {
        res.status(400).json({error: "amount must be a positive integer (minimum 50 cents)"});
        return;
      }
      if (typeof amount === "string") {
        amount = parseInt(amount, 10);
      }
      if (typeof amount === "number" && !Number.isInteger(amount)) {
        amount = Math.round(amount);
      }
      if (!Number.isInteger(amount) || isNaN(amount) || amount < MIN_AMOUNT_CENTS || amount > MAX_AMOUNT_CENTS) {
        res.status(400).json({
          error: "amount must be a positive integer (minimum 50 cents)",
        });
        return;
      }
      amount = Number(amount);

      const intakeRef = db.collection(INTAKES_COLLECTION).doc(intakeId);
      const intakeSnap = await intakeRef.get();
      if (!intakeSnap.exists) {
        res.status(404).json({error: "Intake not found"});
        return;
      }

      const intake = intakeSnap.data();
      const status = intake.status;
      if (status !== "draft" && status !== "requires_payment") {
        res.status(400).json({error: "Intake cannot be paid; status is " + status});
        return;
      }

      const existingPi = intake.paymentIntentId || null;
      const existingAmount = intake.amountCents;
      if (existingPi && existingAmount === amount) {
        const secret = getStripeSecret(stripeSecretRef);
        const stripe = require("stripe")(secret);
        const existing = await stripe.paymentIntents.retrieve(existingPi);
        if (existing && existing.status !== "canceled" && (existing.currency || "").toLowerCase() === CURRENCY_CAD) {
          logger.info("createPaymentIntent idempotent", {intakeId, paymentIntentId: existingPi, currencyEnforced: "cad"});
          res.status(200).json({
            clientSecret: existing.client_secret,
            paymentIntentId: existingPi,
          });
          return;
        }
      }

      const orgId = (intake.orgId || "").toString();
      const orgName = (intake.orgName || "").toString();
      const uid = (intake.userId || "").toString() || null;
      const env = process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT.includes("prod") ? "live" : "test";

      const secret = getStripeSecret(stripeSecretRef);
      const stripeKeyMode = (secret && secret.startsWith && secret.startsWith("sk_test_")) ? "TEST" : "LIVE";
      logger.info("createPaymentIntent", {intakeId, amountCents: amount, currency: CURRENCY_CAD, stripeKeyMode});
      const stripe = require("stripe")(secret);
      const metadata = {
        intakeId,
        orgId,
        orgName: orgName.substring(0, 500),
        environment: env,
      };
      if (uid) metadata.uid = uid;
      metadata.organizationId = orgId;
      const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency: CURRENCY_CAD,
        automatic_payment_methods: {enabled: true},
        metadata,
      });

      await intakeRef.update({
        paymentIntentId: paymentIntent.id,
        status: "requires_payment",
        amountCents: amount,
        currency: CURRENCY_CAD,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("createPaymentIntent created", {intakeId, paymentIntentId: paymentIntent.id, amountCents: amount, currencyEnforced: "cad"});

      res.status(200).json({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      });
    } catch (err) {
      const msg = err && err.message ? String(err.message) : "Unknown error";
      if (msg.includes("not configured")) {
        logger.warn("createPaymentIntent: Stripe not configured");
        res.status(503).json({error: "Payment service not configured"});
        return;
      }
      logger.error("createPaymentIntent error", {message: msg});
      res.status(500).json({error: "Internal error"});
    }
  },
);

// ----- stripeWebhook -----

async function isEventProcessed(paymentIntentId, eventId) {
  const ref = db.collection(PAYMENTS_COLLECTION).doc(paymentIntentId)
    .collection("events").doc(eventId);
  const snap = await ref.get();
  return snap.exists;
}

async function markEventProcessed(paymentIntentId, eventId) {
  const ref = db.collection(PAYMENTS_COLLECTION).doc(paymentIntentId)
    .collection("events").doc(eventId);
  await ref.set({
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
    eventId,
  });
}

exports.stripeWebhook = onRequest(
  {secrets: [stripeWebhookSecretRef, stripeSecretRef]},
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    const sig = req.headers["stripe-signature"];
    if (!sig) {
      res.status(400).send("Missing stripe-signature");
      return;
    }

    let rawBody = null;
    if (req.rawBody) {
      rawBody = Buffer.isBuffer(req.rawBody) ?
        req.rawBody.toString("utf8") : String(req.rawBody);
    }
    if (!rawBody) {
      logger.error("Webhook missing rawBody");
      res.status(400).send("Missing raw body");
      return;
    }

    let event;
    try {
      const webhookSecret = getStripeWebhookSecret(stripeWebhookSecretRef);
      const stripe = require("stripe")(getStripeSecret(stripeSecretRef));
      event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
    } catch (err) {
      const msg = err && err.message ? String(err.message) : "Unknown";
      logger.error("Webhook signature verification failed", {message: msg});
      res.status(400).send("Webhook Error");
      return;
    }

    const eventId = event.id;
    const paymentIntentId = event.data && event.data.object && event.data.object.id;
    logger.info("stripeWebhook received", {
      type: event.type,
      eventId,
      paymentIntentId: paymentIntentId || null,
    });
    if (!paymentIntentId) {
      res.status(200).json({received: true});
      return;
    }

    const alreadyProcessed = await isEventProcessed(paymentIntentId, eventId);
    if (alreadyProcessed) {
      logger.info("Webhook event already processed", {eventId, paymentIntentId});
      res.status(200).json({received: true});
      return;
    }

    const pi = event.data.object;
    const intakeId = (pi.metadata && pi.metadata.intakeId) || null;
    const amountCents = pi.amount;
    const now = admin.firestore.FieldValue.serverTimestamp();

    const paymentRef = db.collection(PAYMENTS_COLLECTION).doc(paymentIntentId);
    const paymentPayload = {
      paymentIntentId,
      intakeId: intakeId || null,
      amountCents,
      currency: CURRENCY_CAD,
      status: pi.status,
      updatedAt: now,
      lastEventId: eventId,
      lastEventType: event.type,
    };

    if (event.type === "payment_intent.succeeded") {
      await paymentRef.set({...paymentPayload, createdAt: now}, {merge: true});
      await markEventProcessed(paymentIntentId, eventId);

      const uid = (pi.metadata && pi.metadata.uid) || null;
      const organizationId = (pi.metadata && pi.metadata.organizationId) || (pi.metadata && pi.metadata.orgId) || null;
      const organizationName = (pi.metadata && pi.metadata.orgName) || null;
      const environment = (pi.metadata && pi.metadata.environment) || "test";

      if (intakeId) {
        const intakeRef = db.collection(INTAKES_COLLECTION).doc(intakeId);
        await intakeRef.update({
          status: "succeeded",
          updatedAt: now,
          latestEventId: eventId,
        });
      }

      // Optional: receipt_url from Stripe Charge
      let receiptUrl = null;
      let stripeChargeId = null;
      if (pi.latest_charge) {
        try {
          const stripe = require("stripe")(getStripeSecret(stripeSecretRef));
          const charge = await stripe.charges.retrieve(pi.latest_charge);
          if (charge && charge.receipt_url) receiptUrl = charge.receipt_url;
          if (charge && charge.id) stripeChargeId = charge.id;
        } catch (e) {
          logger.warn("stripeWebhook: could not retrieve charge for receipt_url", {paymentIntentId});
        }
      }

      if (uid) {
        const userDonationRef = db.collection(USERS_COLLECTION).doc(uid)
          .collection(USER_DONATIONS_SUBCOLLECTION).doc(intakeId);
        const donationPayload = {
          uid,
          intakeId,
          organizationId: organizationId || null,
          organizationName: organizationName || null,
          amountCents,
          currency: CURRENCY_CAD,
          stripePaymentIntentId: paymentIntentId,
          stripeChargeId: stripeChargeId || null,
          receiptUrl: receiptUrl || null,
          status: "succeeded",
          createdAt: now,
          environment: environment || "test",
          platform: "ios",
        };
        await userDonationRef.set(donationPayload, {merge: true});

        const userRef = db.collection(USERS_COLLECTION).doc(uid);
        await db.runTransaction(async (tx) => {
          const userSnap = await tx.get(userRef);
          const currentTotal = (userSnap.exists && userSnap.data().totalDonatedCents) ? userSnap.data().totalDonatedCents : 0;
          tx.set(userRef, {
            lastDonationAt: now,
            totalDonatedCents: currentTotal + amountCents,
          }, {merge: true});
        });
        logger.info("payment_intent.succeeded: user receipt written", {intakeId, paymentIntentId, uid, amountCents});
      } else {
        logger.info("payment_intent.succeeded", {intakeId, paymentIntentId, amountCents});
      }
    } else if (event.type === "payment_intent.payment_failed") {
      await paymentRef.set({...paymentPayload, createdAt: now}, {merge: true});
      await markEventProcessed(paymentIntentId, eventId);

      if (intakeId) {
        const intakeRef = db.collection(INTAKES_COLLECTION).doc(intakeId);
        await intakeRef.update({
          status: "failed",
          updatedAt: now,
          latestEventId: eventId,
        });
        const uid = (pi.metadata && pi.metadata.uid) || null;
        const organizationId = (pi.metadata && pi.metadata.organizationId) || (pi.metadata && pi.metadata.orgId) || null;
        const organizationName = (pi.metadata && pi.metadata.orgName) || null;
        const environment = (pi.metadata && pi.metadata.environment) || "test";
        if (uid) {
          const userDonationRef = db.collection(USERS_COLLECTION).doc(uid)
            .collection(USER_DONATIONS_SUBCOLLECTION).doc(intakeId);
          await userDonationRef.set({
            uid,
            intakeId,
            organizationId: organizationId || null,
            organizationName: organizationName || null,
            amountCents: pi.amount,
            currency: CURRENCY_CAD,
            stripePaymentIntentId: paymentIntentId,
            stripeChargeId: null,
            receiptUrl: null,
            status: "failed",
            createdAt: now,
            environment: environment || "test",
            platform: "ios",
          }, {merge: true});
        }
      }
      logger.info("payment_intent.payment_failed", {intakeId, paymentIntentId});
    } else if (event.type === "payment_intent.canceled") {
      await paymentRef.set({...paymentPayload, createdAt: now}, {merge: true});
      await markEventProcessed(paymentIntentId, eventId);

      if (intakeId) {
        const intakeRef = db.collection(INTAKES_COLLECTION).doc(intakeId);
        await intakeRef.update({
          status: "canceled",
          updatedAt: now,
          latestEventId: eventId,
        });
      }
      logger.info("payment_intent.canceled", {intakeId, paymentIntentId});
    } else {
      await markEventProcessed(paymentIntentId, eventId);
    }

    res.status(200).json({received: true});
  },
);

// ----- setAdminRole (callable v2; admin-only) -----
// Caller must have custom claim admin === true. Sets { admin: true } for the user identified by email.
// Prefer setting admin once via the local script (scripts/set-admin-claims.js); use this to add more admins.
exports.setAdminRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const callerAdmin = request.auth.token.admin === true;
  if (!callerAdmin) {
    throw new HttpsError("permission-denied", "Only an existing admin can set admin role.");
  }
  const email = request.data && typeof request.data.email === "string" ? request.data.email.trim() : null;
  if (!email || email.length === 0) {
    throw new HttpsError("invalid-argument", "email (string) is required.");
  }
  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (e) {
    logger.warn("setAdminRole: getUserByEmail failed", {email, message: e && e.message});
    throw new HttpsError("not-found", "No user found with that email.");
  }
  await admin.auth().setCustomUserClaims(userRecord.uid, {admin: true});
  logger.info("setAdminRole: admin claim set", {uid: userRecord.uid, email: userRecord.email});
  return {success: true, uid: userRecord.uid, email: userRecord.email};
});

// ----- finalizeDonation (HTTP, auth required) -----
// Client calls after PaymentSheet .completed. Verifies PI with Stripe, writes user receipt (idempotent with webhook).
exports.finalizeDonation = onRequest(
  {secrets: [stripeSecretRef]},
  async (req, res) => {
    corsHeaders(res);
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    const uid = await getUidFromRequest(req);
    if (!uid) {
      logger.warn("finalizeDonation: unauthenticated");
      res.status(401).json({error: "Unauthorized"});
      return;
    }

    try {
      const body = req.body || {};
      const paymentIntentId = body.paymentIntentId;
      const intakeId = body.intakeId;
      if (!paymentIntentId || !intakeId) {
        res.status(400).json({error: "paymentIntentId and intakeId required"});
        return;
      }

      const secret = getStripeSecret(stripeSecretRef);
      const stripe = require("stripe")(secret);
      const pi = await stripe.paymentIntents.retrieve(paymentIntentId);
      if (!pi || pi.status !== "succeeded") {
        logger.warn("finalizeDonation: PI not succeeded", {paymentIntentId, status: pi && pi.status});
        res.status(400).json({error: "Payment not succeeded"});
        return;
      }

      const intakeRef = db.collection(INTAKES_COLLECTION).doc(intakeId);
      const intakeSnap = await intakeRef.get();
      if (!intakeSnap.exists) {
        res.status(404).json({error: "Intake not found"});
        return;
      }
      const intake = intakeSnap.data();
      if (intake.userId !== uid) {
        res.status(403).json({error: "Forbidden"});
        return;
      }
      if (intake.amountCents !== pi.amount || (pi.currency || "").toLowerCase() !== CURRENCY_CAD) {
        res.status(400).json({error: "Amount or currency mismatch (expected CAD)"});
        return;
      }

      let receiptUrl = null;
      let stripeChargeId = null;
      if (pi.latest_charge) {
        try {
          const charge = await stripe.charges.retrieve(pi.latest_charge);
          if (charge && charge.receipt_url) receiptUrl = charge.receipt_url;
          if (charge && charge.id) stripeChargeId = charge.id;
        } catch (e) {
          // optional
        }
      }

      const now = admin.firestore.FieldValue.serverTimestamp();
      const organizationId = (pi.metadata && pi.metadata.organizationId) || (pi.metadata && pi.metadata.orgId) || null;
      const organizationName = (pi.metadata && pi.metadata.orgName) || null;
      const environment = (pi.metadata && pi.metadata.environment) || "test";

      const userDonationRef = db.collection(USERS_COLLECTION).doc(uid)
        .collection(USER_DONATIONS_SUBCOLLECTION).doc(intakeId);
      await userDonationRef.set({
        uid,
        intakeId,
        organizationId: organizationId || null,
        organizationName: organizationName || null,
        amountCents: pi.amount,
        currency: CURRENCY_CAD,
        stripePaymentIntentId: paymentIntentId,
        stripeChargeId: stripeChargeId || null,
        receiptUrl: receiptUrl || null,
        status: "succeeded",
        createdAt: now,
        environment: environment || "test",
        platform: "ios",
      }, {merge: true});

      const userRef = db.collection(USERS_COLLECTION).doc(uid);
      await db.runTransaction(async (tx) => {
        const userSnap = await tx.get(userRef);
        const currentTotal = (userSnap.exists && userSnap.data().totalDonatedCents) ? userSnap.data().totalDonatedCents : 0;
        tx.set(userRef, {
          lastDonationAt: now,
          totalDonatedCents: currentTotal + pi.amount,
        }, {merge: true});
      });

      logger.info("finalizeDonation: receipt written", {intakeId, paymentIntentId, uid, currencyEnforced: "cad"});
      res.status(200).json({success: true});
    } catch (err) {
      const msg = err && err.message ? String(err.message) : "Unknown error";
      logger.error("finalizeDonation error", {message: msg});
      res.status(500).json({error: "Internal error"});
    }
  },
);
