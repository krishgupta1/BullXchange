import admin from "firebase-admin";
import axios from "axios";
import moment from "moment-timezone";
import fs from "fs";

// ------------------------------------------------------------
// 1. FIREBASE INITIALIZATION
// ------------------------------------------------------------
const serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json"));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
console.log("✅ Firebase initialized");

// ------------------------------------------------------------
// 2. ANGEL ONE CONFIG
// ------------------------------------------------------------
const ANGEL_BASE_URL =
  "https://apiconnect.angelone.in/rest/secure/angelbroking/market/v1/quote/";
const ANGEL_JWT = "YOUR_VALID_JWT"; // Replace manually
const ANGEL_API_KEY = "YOUR_API_KEY";
const CLIENT_IP = "152.59.183.251";

let RATE_LIMIT_BLOCKED = false;

// ------------------------------------------------------------
// 3. MARKET HOURS CHECK
// ------------------------------------------------------------
function isMarketOpen() {
  const now = moment().tz("Asia/Kolkata");
  const day = now.isoWeekday(); // 1 = Monday, 7 = Sunday
  if (day >= 6) return false; // weekend
  const open = moment.tz("09:15", "HH:mm", "Asia/Kolkata");
  const close = moment.tz("15:30", "HH:mm", "Asia/Kolkata");
  return now.isBetween(open, close);
}

function isMarketCloseTime() {
  const now = moment().tz("Asia/Kolkata");
  return now.hour() === 15 && now.minute() >= 30;
}

// ------------------------------------------------------------
// 4. FETCH LIVE PRICES
// ------------------------------------------------------------
async function getLivePrices(symbolTokens) {
  if (RATE_LIMIT_BLOCKED) {
    console.log("⏸️ Skipping fetch (rate-limited)");
    return {};
  }

  try {
    const tokensByExchange = { NSE: symbolTokens };
    const response = await axios.post(
      ANGEL_BASE_URL,
      { mode: "FULL", exchangeTokens: tokensByExchange },
      {
        headers: {
          Authorization: `Bearer ${ANGEL_JWT}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-UserType": "USER",
          "X-SourceID": "WEB",
          "X-ClientLocalIP": CLIENT_IP,
          "X-ClientPublicIP": CLIENT_IP,
          "X-MACAddress": "00:00:00:00:00:00",
          "X-PrivateKey": ANGEL_API_KEY,
        },
      }
    );

    const fetched = response.data?.data?.fetched;
    const prices = {};
    if (Array.isArray(fetched)) {
      fetched.forEach((item) => {
        const token =
          item.symbolToken ||
          item.symboltoken ||
          item.symbol_token ||
          item.token;
        if (token && item.ltp) prices[token] = parseFloat(item.ltp);
      });
    }
    return prices;
  } catch (err) {
    if (err.response?.data?.message?.includes("exceeding access rate")) {
      console.error("🚫 Rate limit reached — pausing for 1 min");
      RATE_LIMIT_BLOCKED = true;
      setTimeout(() => (RATE_LIMIT_BLOCKED = false), 60000);
    } else {
      console.error("❌ Error fetching prices:", err.message);
    }
    return {};
  }
}

// ------------------------------------------------------------
// 5. EXECUTE LIMIT ORDERS (during market hours)
// ------------------------------------------------------------
async function checkAndExecuteOrders() {
  if (!isMarketOpen()) {
    console.log("🕒 Market closed, skipping order execution...");
    return;
  }

  console.log("🔍 Checking pending orders...");
  const snapshot = await db
    .collection("orders")
    .where("orderStatus", "==", "PENDING")
    .get();

  if (snapshot.empty) {
    console.log("✅ No pending orders found.");
    return;
  }

  const orders = [];
  const tokens = new Set();
  snapshot.forEach((doc) => {
    const data = doc.data();
    data.id = doc.id;
    orders.push(data);
    if (data.instrumentToken) tokens.add(data.instrumentToken);
  });

  const livePrices = await getLivePrices([...tokens]);
  if (Object.keys(livePrices).length === 0) {
    console.warn("⚠️ No LTPs received — skipping this cycle.");
    return;
  }

  for (const order of orders) {
    const ltp = livePrices[order.instrumentToken];
    if (!ltp) continue;

    let shouldExecute = false;
    if (order.transactionType === "BUY" && ltp <= order.limitPrice)
      shouldExecute = true;
    if (order.transactionType === "SELL" && ltp >= order.limitPrice)
      shouldExecute = true;
    if (!shouldExecute) continue;

    console.log(
      `🚀 Executing ${order.transactionType} ${order.symbol} @ ₹${ltp.toFixed(2)}`
    );

    const userRef = db.collection("users").doc(order.userId);
    const userSnap = await userRef.get();
    if (!userSnap.exists) continue;
    const userData = userSnap.data();

    // ⚡ Use charges passed from your app (not calculated here)
    const charges =
      order.charges?.total ?? 0.0; // Use total charge if saved from Flutter

    const totalAmount = ltp * order.quantity;
    const netAmount =
      order.transactionType === "BUY"
        ? totalAmount + charges
        : totalAmount - charges;

    // 🧾 Record transaction
    const transactionDoc = {
      userId: order.userId,
      symbol: order.symbol,
      companyName: order.companyName,
      price: ltp,
      quantity: order.quantity,
      exchange: order.exchange,
      productType: order.productType,
      transactionType: order.transactionType,
      orderStatus: "EXECUTED",
      executedAt: admin.firestore.Timestamp.now(),
      totalAmount,
      charges,
    };
    await db.collection("transactions").add(transactionDoc);

    // 💰 Portfolio + funds update
    if (order.productType === "DELIVERY" && order.transactionType === "BUY") {
      const newStock = {
        stockName: order.companyName,
        stockSymbol: order.symbol,
        exchange: order.exchange,
        quantity: order.quantity,
        transactionType: "DELIVERY",
        transactionPrice: ltp,
        totalAmount: netAmount,
        charges,
        buyingTime: admin.firestore.Timestamp.now(),
      };

      await userRef.update({
        stocks: admin.firestore.FieldValue.arrayUnion(newStock),
        availableFunds: (userData.availableFunds || 0) - netAmount,
      });
    }

    if (order.productType === "DELIVERY" && order.transactionType === "SELL") {
      await userRef.update({
        availableFunds: (userData.availableFunds || 0) + netAmount,
      });
    }

    if (order.productType === "INTRADAY") {
      const newPosition = {
        stockName: order.companyName,
        stockSymbol: order.symbol,
        exchange: order.exchange,
        quantity: order.quantity,
        transactionType: "INTRADAY",
        transactionPrice: ltp,
        totalAmount: netAmount,
        charges,
        buyingTime: admin.firestore.Timestamp.now(),
      };

      await userRef.update({
        positions: admin.firestore.FieldValue.arrayUnion(newPosition),
      });
    }

    await db.collection("orders").doc(order.id).update({
      orderStatus: "EXECUTED",
      executedPrice: ltp,
      executedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`✅ Order ${order.symbol} executed successfully`);
  }
}

// ------------------------------------------------------------
// 6. AUTO CLOSE INTRADAY POSITIONS AT 3:30 PM
// ------------------------------------------------------------
async function closeAllIntradayPositions() {
  if (!isMarketCloseTime()) return;

  console.log("🔚 Market closing — auto-closing all intraday positions...");
  const usersSnapshot = await db.collection("users").get();

  for (const userDoc of usersSnapshot.docs) {
    const userRef = userDoc.ref;
    const userData = userDoc.data();

    if (!userData.positions || userData.positions.length === 0) continue;

    for (const pos of userData.positions) {
      const totalAmount = pos.transactionPrice * pos.quantity;
      const charges = pos.charges ?? 0;

      const transactionDoc = {
        userId: userDoc.id,
        symbol: pos.stockSymbol,
        companyName: pos.stockName,
        price: pos.transactionPrice,
        quantity: pos.quantity,
        exchange: pos.exchange,
        productType: "INTRADAY",
        transactionType: "SELL (AUTO-CLOSE)",
        orderStatus: "EXECUTED",
        executedAt: admin.firestore.Timestamp.now(),
        totalAmount,
        charges,
      };
      await db.collection("transactions").add(transactionDoc);

      await userRef.update({
        availableFunds:
          (userData.availableFunds || 0) + (totalAmount - charges),
        positions: [],
      });
    }

    console.log(`💰 Closed all intraday positions for user ${userDoc.id}`);
  }
}

// ------------------------------------------------------------
// 7. MAIN LOOP
// ------------------------------------------------------------
async function mainLoop() {
  console.log("⚡ BullXchange Order Executor running...");
  setInterval(async () => {
    try {
      await checkAndExecuteOrders();
      await closeAllIntradayPositions();
    } catch (err) {
      console.error("🔥 Error in main loop:", err.message);
    }
  }, 60000); // run every 1 minute
}

mainLoop();
