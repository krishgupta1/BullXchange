import admin from "firebase-admin";
import axios from "axios";
import moment from "moment-timezone"; // We will use this for date sorting
import fs from "fs";
import "dotenv/config"; // Loads your .env file

// 1. FIREBASE INITIALIZATION
const serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json"));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://bullxchange-94945-default-rtdb.firebaseio.com/"
});
const db = admin.firestore();
const rtdb = admin.database();
console.log("✅ Firebase initialized (Firestore & RTDB)");

// 2. ANGEL ONE CONFIG
const ANGEL_BASE_URL =
  "https://apiconnect.angelone.in/rest/secure/angelbroking/market/v1/quote/";
const ANGEL_JWT = process.env.ANGEL_JWT; // MAKE SURE THIS IS A FRESH TOKEN
const ANGEL_API_KEY = process.env.ANGEL_API_KEY;
const CLIENT_IP = process.env.CLIENT_IP;
let RATE_LIMIT_BLOCKED = false;

// 3. MARKET HOURS CHECK
function isMarketOpen() {
  const now = moment().tz("Asia/Kolkata");
  const day = now.isoWeekday();
  if (day >= 6) return false;
  const open = moment.tz("09:15", "HH:mm", "Asia/Kolkata");
  const close = moment.tz("15:30", "HH:mm", "Asia/Kolkata");
  return now.isBetween(open, close);
}

function isMarketCloseTime() {
  const now = moment().tz("Asia/Kolkata");
  return now.hour() === 15 && now.minute() >= 30;
}

// 4. FETCH LIVE PRICES (Upgraded to handle batches, all data, and multiple exchanges)
async function getLivePrices(tokensByExchange) {
  if (RATE_LIMIT_BLOCKED) {
    console.log("⏸️ Skipping fetch (rate-limited)");
    return {};
  }
  
  const allPrices = {};
  const CHUNK_SIZE = 40; // Angel One limit is often 50, 40 is safe

  try {
    // Loop over each exchange (e.g., "NSE", "BSE")
    for (const exchange of Object.keys(tokensByExchange)) {
      const validTokens = tokensByExchange[exchange].filter(t => t);
      if (validTokens.length === 0) continue;

      console.log(`...fetching for ${exchange} exchange...`);

      // Loop through the tokens for that exchange in chunks
      for (let i = 0; i < validTokens.length; i += CHUNK_SIZE) {
        const chunk = validTokens.slice(i, i + CHUNK_SIZE);
        
        const requestBody = { 
          mode: "FULL", 
          exchangeTokens: { [exchange]: chunk } 
        };
        
        console.log(`...fetching price data for ${chunk.length} tokens (batch ${Math.floor(i/CHUNK_SIZE) + 1})`);
        
        const response = await axios.post(
          ANGEL_BASE_URL,
          requestBody,
          { headers: {
              Authorization: `Bearer ${ANGEL_JWT}`,
              "Content-Type": "application/json",
              Accept: "application/json",
              "X-UserType": "USER",
              "X-SourceID": "WEB",
              "X-ClientLocalIP": CLIENT_IP,
              "X-ClientPublicIP": CLIENT_IP,
              "X-MACAddress": "00:00:00:00:00:00",
              "X-PrivateKey": ANGEL_API_KEY,
          }}
        );

        if (response.data?.status !== true) {
          console.error(`❌ Angel One API Error (${exchange}):`, response.data?.message || "Received non-true status");
          if (response.data?.message?.includes("Token")) {
            console.error("   (This might be an EXPIRED JWT TOKEN or a 'Tokens max limit' error)");
          }
          continue; 
        }

        const fetched = response.data?.data?.fetched;
        if (Array.isArray(fetched)) {
          fetched.forEach((item) => {
            const token = item.symbolToken || item.symboltoken || item.token;
            if (token) {
              allPrices[token] = {
                ltp: parseFloat(item.ltp) || 0,
                openInterest: parseInt(item.openInterest) || 0,
                volume: parseInt(item.totalTradedVolume) || 0,
                change: parseFloat(item.change) || 0,
                percentChange: parseFloat(item.percentChange) || 0,
                iv: parseFloat(item.iv) || 0,
                symbol: item.symbol,
                currency: item.symbol?.includes('USD') ? '$' : '₹',
              };
            }
          });
        }
      } // End of chunk loop
    } // End of exchange loop
    
    return allPrices; // Return the combined results

  } catch (err) {
    if (err.response?.status === 403) {
      console.error("❌ FATAL: Request failed with status code 403 (Forbidden).");
      console.error("   >>> YOUR ANGEL_JWT TOKEN IS EXPIRED OR INVALID. PLEASE UPDATE .env FILE. <<<");
    } else if (err.response?.data?.message?.includes("exceeding access rate")) {
      console.error("🚫 Rate limit reached — pausing for 1 min");
      RATE_LIMIT_BLOCKED = true;
      setTimeout(() => (RATE_LIMIT_BLOCKED = false), 60000);
    } else {
      console.error("❌ Error fetching prices:", err.response?.data?.message || err.message);
    }
    return {};
  }
}


// 5. YOUR ORIGINAL LIMIT ORDER LOGIC (with fixes)
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

  // ✨ FIX 1: Pass tokens as an object, assuming NSE for orders
  const livePrices = await getLivePrices({ NSE: [...tokens] });
  
  if (Object.keys(livePrices).length === 0) {
    console.warn("⚠️ No LTPs received for orders — skipping this cycle.");
    return;
  }

  for (const order of orders) {
    // ✨ FIX 2: Get the .ltp property from the price object
    const ltp = livePrices[order.instrumentToken]?.ltp;
    
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

    const charges =
      order.charges?.total ?? 0.0; 

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

// 6. YOUR ORIGINAL INTRADAY CLOSE LOGIC (No changes)
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


// 8. F&O OPTION CHAIN LOGIC
const SCRIP_MASTER_URL = "https://margincalculator.angelone.in/OpenAPI_File/files/OpenAPIScripMaster.json";
let scripMasterCache = [];

// ✨ 1. MASTER WATCHLIST (All 6 symbols from your Flutter code)
const BASE_SYMBOLS_TO_TRACK = [
  { symbol: 'Nifty 50',         scripName: 'NIFTY',        indexToken: '26000', exch: 'NSE' },
  { symbol: 'Nifty Bank',       scripName: 'BANKNIFTY',    indexToken: '26009', exch: 'NSE' },
  { symbol: 'Nifty Fin Service',  scripName: 'FINNIFTY',     indexToken: '26037', exch: 'NSE' },
  { symbol: 'NIFTY MID SELECT', scripName: 'MIDCPNIFTY',   indexToken: '26074', exch: 'NSE' },
  { symbol: 'SENSEX',           scripName: 'SENSEX',       indexToken: '1',     exch: 'BSE' },
  { symbol: 'BANKEX',           scripName: 'BANKEX',       indexToken: '11',    exch: 'BSE' },
];
let dynamicWatchlist = [];

const CACHE_FILE_PATH = './scripMaster.json';

// Caching function
async function getScripMaster() {
  if (scripMasterCache.length > 0) {
    return scripMasterCache;
  }
  try {
    if (fs.existsSync(CACHE_FILE_PATH)) {
      console.log("Loading Scrip Master from local cache...");
      const fileData = fs.readFileSync(CACHE_FILE_PATH, 'utf8');
      scripMasterCache = JSON.parse(fileData);
      console.log(`✅ Scrip Master loaded from cache. ${scripMasterCache.length} instruments found.`);
      return scripMasterCache;
    }
  } catch (err) {
    console.error("Corrupt scripMaster.json file. Deleting and re-downloading...", err.message);
    try { fs.unlinkSync(CACHE_FILE_PATH); } catch (delErr) { /* ignore */ }
  }
  try {
    console.log("Downloading Scrip Master (10MB+)... This will happen only once.");
    const response = await axios.get(SCRIP_MASTER_URL);
    scripMasterCache = response.data;
    fs.writeFileSync(CACHE_FILE_PATH, JSON.stringify(scripMasterCache));
    console.log(`✅ Scrip Master downloaded and cached. ${scripMasterCache.length} instruments found.`);
    return scripMasterCache;
  } catch (err) {
    console.error("❌ FATAL: Could not download Scrip Master.", err.message);
    return [];
  }
}

// Dynamic Expiry finder
async function buildDynamicWatchlist() {
  console.log("Building dynamic F&O watchlist...");
  const allInstruments = await getScripMaster();
  if (allInstruments.length === 0) {
    console.error("Cannot build watchlist, Scrip Master is empty.");
    return;
  }
  
  const today = moment().tz("Asia/Kolkata").startOf('day');
  let newList = [];

  for (const item of BASE_SYMBOLS_TO_TRACK) {
    const scripName = item.scripName;
    const options = allInstruments.filter(inst =>
      inst.name === scripName &&
      inst.instrumenttype === 'OPTIDX'
    );
    
    if (options.length === 0) {
      console.warn(`⚠️ No options found for ${item.symbol} (scripName: ${scripName}).`);
      continue;
    }

    const uniqueExpiries = [...new Set(options.map(inst => inst.expiry))];
    
    const futureExpiries = uniqueExpiries
      .map(expiryStr => ({
          str: expiryStr,
          date: moment(expiryStr, 'DDMMMYYYY')
      }))
      .filter(exp => exp.date.isSameOrAfter(today))
      .sort((a, b) => a.date - b.date); 

    if (futureExpiries.length > 0) {
      const nearestExpiryString = futureExpiries[0].str;
      console.log(`✅ Found nearest expiry for ${item.symbol}: ${nearestExpiryString}`);
      newList.push({
        ...item,
        expiry: nearestExpiryString,
      });
    } else {
      console.warn(`⚠️ No *future* expiries found for ${item.symbol}.`);
    }
  }
  
  dynamicWatchlist = newList;
  console.log("✅ Dynamic watchlist built successfully.");
}


function getSafeToken(inst) {
  if (!inst) return null;
  return inst.symbolToken || inst.symboltoken || inst.token || null;
}

// Main F&O fetching function
async function fetchAndStreamOptionChain(watchlistItem) {
  
  const { symbol, scripName, expiry, indexToken, exch } = watchlistItem;

  if (!isMarketOpen() || RATE_LIMIT_BLOCKED) {
    // return; // PRODUCTION
    console.log(`🚀 FORCING ${symbol} FETCH (TESTING MODE) 🚀`); // TESTING
  }
  if (RATE_LIMIT_BLOCKED) {
    console.log(`⏸️ Skipping ${symbol} fetch (rate-limited)`);
    return;
  }
  
  console.log(`📈 Fetching F&O Option Chain for ${symbol} (${expiry})...`);

  try {
    const allInstruments = await getScripMaster();
    if (allInstruments.length === 0) return;

    const optionInstruments = allInstruments.filter(inst => 
      inst.name === scripName &&
      inst.instrumenttype === 'OPTIDX' &&
      inst.expiry === expiry
    );

    if (optionInstruments.length === 0) {
      console.warn(`⚠️ No instruments found for ${symbol} with expiry ${expiry}. Skipping.`);
      return;
    }

    const strikes = {}; 
    const tokensByExchange = {}; 

    const addToken = (token, exch) => {
      if (!token || !exch) return;
      if (!tokensByExchange[exch]) {
        tokensByExchange[exch] = []; 
      }
      tokensByExchange[exch].push(token);
    };

    addToken(indexToken, exch); 

    for (const inst of optionInstruments) {
      const strike = parseFloat(inst.strike) / 100; 
      if (!strikes[strike]) {
        strikes[strike] = {};
      }
      if (inst.symbol.endsWith("CE")) {
        strikes[strike].ce = inst;
      } else if (inst.symbol.endsWith("PE")) {
        strikes[strike].pe = inst;
      }
      addToken(getSafeToken(inst), inst.exch_seg);
    }

    const livePrices = await getLivePrices(tokensByExchange);

    const finalRows = [];
    for (const strike in strikes) {
      const ceInst = strikes[strike].ce;
      const peInst = strikes[strike].pe;
      
      const ceToken = getSafeToken(ceInst);
      const peToken = getSafeToken(peInst);
      
      const ceData = livePrices[ceToken];
      const peData = livePrices[peToken];

      finalRows.push({
        strikePrice: parseFloat(strike),
        ce: ceInst ? {
          symbol: ceInst.symbol,
          token: ceToken,
          lastPrice: ceData?.ltp || 0,
          openInterest: ceData?.openInterest || 0,
          priceChangePercent: ceData?.percentChange || 0,
          iv: ceData?.iv || 0,
          currency: ceData?.currency || '₹',
        } : null,
        pe: peInst ? {
          symbol: peInst.symbol,
          token: peToken,
          lastPrice: peData?.ltp || 0,
          openInterest: peData?.openInterest || 0,
          priceChangePercent: peData?.percentChange || 0,
          iv: peData?.iv || 0,
          currency: peData?.currency || '₹',
        } : null,
      });
    }
    finalRows.sort((a, b) => a.strikePrice - b.strikePrice);

    const indexData = livePrices[indexToken];
    
    const formattedExpiry = moment(expiry, 'DDMMMYYYY').format('D MMM');

    const finalData = {
      underlyingLtp: indexData?.ltp || null,
      underlyingLtpChange: indexData?.change || 0,
      underlyingLtpPercent: indexData?.percentChange || 0,
      expiry: formattedExpiry,
      currency: indexData?.currency || '₹',
      rows: finalRows,
      lastUpdatedAt: admin.database.ServerValue.TIMESTAMP,
    };

    await rtdb.ref(`option_chain/${symbol}`).set(finalData);
    
    const success = finalData.underlyingLtp > 0 || finalRows.some(r => r.ce?.openInterest > 0 || r.pe?.openInterest > 0);
    if (success) {
      console.log(`✅ ${symbol} Option Chain streamed to RTDB. (${finalRows.length} strikes)`);
    } else {
      console.warn(`⚠️ ${symbol} Chain streamed, but all data was 0. (Check JWT)`);
    }

  } catch (err) {
    console.error(`❌ Error fetching F&O chain for ${symbol}:`, err.message);
  }
}


// 10. MAIN LOOP
async function mainLoop() {
  console.log("⚡ BullXchange Executor running...");
  
  await getScripMaster(); 
  await buildDynamicWatchlist();
  console.log("Dynamic watchlist is:", dynamicWatchlist);

  // Order executor
  setInterval(async () => {
    try {
      await checkAndExecuteOrders();
      await closeAllIntradayPositions();
    } catch (err) {
      console.error("🔥 Error in main loop:", err.message);
    }
  }, 60000);

  // F&O Loop
  setInterval(async () => {
    console.log("--- Starting F&O Update Cycle ---");
    try {
      for (const item of dynamicWatchlist) {
        await fetchAndStreamOptionChain(item);
      }
    } catch (err) {
      console.error("🔥 Error in F&O loop:", err.message);
    }
    console.log("--- F&O Update Cycle Finished ---");
  }, 10000); 
}

mainLoop();