const https = require('https');

const url = 'https://ourspace-backend.onrender.com/health';

console.log(`[Keep-Alive] Starting ping loop to ${url} every 10 minutes...`);

function ping() {
  https.get(url, (res) => {
    console.log(`[Keep-Alive] Ping sent. Status: ${res.statusCode} at ${new Date().toISOString()}`);
  }).on('error', (err) => {
    console.error(`[Keep-Alive] Ping error: ${err.message}`);
  });
}

// Ping immediately
ping();

// Ping every 10 minutes (600000 ms)
setInterval(ping, 600000);
