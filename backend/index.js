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
const ANGEL_JWT = "eyJhbGciOiJIUzUxMiJ9.eyJ1c2VybmFtZSI6IkFBQU83ODQzOTMiLCJyb2xlcyI6MCwidXNlcnR5cGUiOiJVU0VSIiwidG9rZW4iOiJleUpoYkdjaU9pSlNVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKMWMyVnlYM1I1Y0dVaU9pSmpiR2xsYm5RaUxDSjBiMnRsYmw5MGVYQmxJam9pZEhKaFpHVmZZV05qWlhOelgzUnZhMlZ1SWl3aVoyMWZhV1FpT2pNc0luTnZkWEpqWlNJNklqTWlMQ0prWlhacFkyVmZhV1FpT2lJNE16a3paVEl5T0MweE1ESXhMVE0zTmpJdE9URmtZUzAwWlRNNU1HRTVOVE0yTWpRaUxDSnJhV1FpT2lKMGNtRmtaVjlyWlhsZmRqSWlMQ0p2Ylc1bGJXRnVZV2RsY21sa0lqb3pMQ0p3Y205a2RXTjBjeUk2ZXlKa1pXMWhkQ0k2ZXlKemRHRjBkWE1pT2lKaFkzUnBkbVVpZlN3aWJXWWlPbnNpYzNSaGRIVnpJam9pWVdOMGFYWmxJbjE5TENKcGMzTWlPaUowY21Ga1pWOXNiMmRwYmw5elpYSjJhV05sSWl3aWMzVmlJam9pUVVGQlR6YzRORE01TXlJc0ltVjRjQ0k2TVRjM05UY3hNemd5TWl3aWJtSm1Jam94TnpjMU5qSTNNalF5TENKcFlYUWlPakUzTnpVMk1qY3lORElzSW1wMGFTSTZJalkyWm1ZeVlqSTBMV1ZoWlRrdE5HTTBOQzFpWmpabExXWTRZakEyTlRRM1pUaG1OU0lzSWxSdmEyVnVJam9pSW4wLmJJV19xY01ub0daTjNsd0VFV1Vmb0FiMGlLTW1CM0VVSEFpanpnNmRHdVQwbURKMUk1TFhObXNmRmVPNmFEdUdiZmdpMjVYNUpqWjJfcU5uVXExX2R4YTJ0LVEySm5ZaUUtX0ZVcHdGbFhDa214V0lWZlNhZjMzYWVqWjNsaWJuc3BjTFphd2t0SUExWG91OXZfZkR2RjJTWXpaNEIzb2RNaFh4amhLOHBkOCIsIkFQSS1LRVkiOiJOZGNvUFhCSyIsIlgtT0xELUFQSS1LRVkiOmZhbHNlLCJpYXQiOjE3NzU2Mjc0MjIsImV4cCI6MTc3NTY3MzAwMH0.DXkXFQMTmb1QwzAd_YlPjIs1rSu8aFqPAdYd4JjR3LgvmnWx8f8yRuJLuuyz5ArbTlioYdRyoXRnFLEAFFbkWw"
; // Replace manually
const ANGEL_API_KEY = "NdcoPXBK";
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

    // Fix: Add zero-division check for percentage calculations
    let percentChange = 0;
    if (order.previousPrice && order.previousPrice > 0) {
      percentChange = ((ltp - order.previousPrice) / order.previousPrice) * 100;
    }

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
