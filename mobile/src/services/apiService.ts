import { getSecureItem } from '../crypto/e2eeCrypto';

const API_BASE_URL = 'http://localhost:4000/api';
const WS_BASE_URL = 'ws://localhost:4000/ws';

export async function fetchWithAuth(endpoint: string, options: RequestInit = {}) {
  const token = await getSecureItem('auth_token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>)
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.error || 'API Request failed');
  }
  return data;
}

export class MobileSocketClient {
  private ws: WebSocket | null = null;
  public onMessage?: (data: any) => void;
  public onConnected?: () => void;

  public async connect() {
    const token = await getSecureItem('auth_token');
    if (!token) return;

    this.ws = new WebSocket(WS_BASE_URL);

    this.ws.onopen = () => {
      this.ws?.send(JSON.stringify({ type: 'auth', token }));
      if (this.onConnected) this.onConnected();
    };

    this.ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (this.onMessage) this.onMessage(data);
      } catch (e) {}
    };

    this.ws.onclose = () => {
      // Reconnect automatically after 3s
      setTimeout(() => this.connect(), 3000);
    };
  }

  public send(payload: any) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(payload));
    }
  }

  public disconnect() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}

export const socketClient = new MobileSocketClient();
