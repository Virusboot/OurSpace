export interface LogContext {
  timestamp?: string;
  requestId?: string;
  userId?: string;
  conversationId?: string;
  callId?: string;
  socketId?: string;
  eventName?: string;
  connectionState?: string;
  iceConnectionState?: string;
  [key: string]: any;
}

export class Logger {
  private static sanitize(obj: any): any {
    if (!obj || typeof obj !== 'object') return obj;
    const sanitized = { ...obj };
    const sensitiveKeys = ['password', 'password_hash', 'encryptedPayload', 'token', 'privateKey', 'pin'];
    for (const key of Object.keys(sanitized)) {
      if (sensitiveKeys.includes(key)) {
        sanitized[key] = '[REDACTED]';
      }
    }
    return sanitized;
  }

  static info(message: string, context: LogContext = {}) {
    const entry = {
      level: 'INFO',
      timestamp: context.timestamp || new Date().toISOString(),
      message,
      context: Logger.sanitize(context)
    };
    console.log(JSON.stringify(entry));
  }

  static warn(message: string, context: LogContext = {}) {
    const entry = {
      level: 'WARN',
      timestamp: context.timestamp || new Date().toISOString(),
      message,
      context: Logger.sanitize(context)
    };
    console.warn(JSON.stringify(entry));
  }

  static error(message: string, error?: any, context: LogContext = {}) {
    const entry = {
      level: 'ERROR',
      timestamp: context.timestamp || new Date().toISOString(),
      message,
      error: error?.message || String(error),
      stack: error?.stack,
      context: Logger.sanitize(context)
    };
    console.error(JSON.stringify(entry));
  }
}
