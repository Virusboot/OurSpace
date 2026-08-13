# OURSPACE - SECURE PRIVATE CHAT & CALL PLATFORM

> **Core Philosophy**: CHAT. CALL. DISAPPEAR.

A production-ready, zero-knowledge, privacy-focused communication platform consisting of a cross-platform Flutter mobile app, a lightweight Web guest calling client, and a single shared Node.js/TypeScript backend.

---

## 🏗️ Repository Architecture

```
/ourspace
├── backend/          # Unified Node.js + TypeScript REST & WebSocket Server
├── web/              # Lightweight Web Guest Call Client (Vite + React)
├── mobile_flutter/   # Production Mobile App (Flutter for Android & iOS)
├── mobile/           # Original React Native / Expo Mobile App
├── .gitignore
└── README.md
```

---

## 🔒 Key Privacy & Security Features

- **No Phone Number or Email Required**: Authenticates using client-generated Private IDs (`USER-XXXXXX`), unique usernames (`@username`), local PIN, and 256-bit Account Recovery Key phrases.
- **End-to-End Encryption (E2EE)**: Messages and media attachments are encrypted client-side using `AES-256-GCM` + `ECDH` prior to transmission. Server holds zero plaintext content.
- **Disappearing Messages**: Timers (`10s`, `30s`, `1m`, `5m`, `1h`, `24h`, `Off`). Dual-layer expiration with automated background server TTL cleanup worker.
- **Protected Media & View-Once**: Encrypted temporary media blobs with no save, download, share, or forward buttons. View-Once images are purged from server immediately after 1 view.
- **WebRTC Audio & Video Calling**: Real-time peer-to-peer encrypted media streams with zero server-side recording or cloud media storage.
- **Shareable Call Links**: 32-character random tokens (`/c/<token>`) with optional PIN, expiration, host revocation, and deep-linking to native app or web guest client.
- **OS Security Protections**: `FLAG_SECURE` on Android sensitive activities; screen recording/mirroring detection and background privacy blur overlays on iOS.
- **Ghost Mode**: Enforces 30s disappearing timers, view-once media, hidden notification previews, and aggressive cache wiping.

---

## 🚦 Quick Start Guide

### 1. Start Shared Backend Server
```bash
cd backend
npm install
npm run dev
```
- Server running at: `http://localhost:4000`
- WebSocket endpoint: `ws://localhost:4000/ws`
- Health check: `http://localhost:4000/health`

### 2. Start Web Guest App
```bash
cd web
npm install
npm run dev
```
- Web App running at: `http://localhost:3000`

### 3. Start Flutter Mobile App
```bash
cd mobile_flutter
flutter pub get
flutter run
```

---

## 🧪 Testing

### Backend Security Test Suite
```bash
cd backend
npm test
```

### Web App Production Build Verification
```bash
cd web
npm run build
```
