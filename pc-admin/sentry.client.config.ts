import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN || '',
  environment: process.env.NODE_ENV || 'development',
  tracesSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  // Disable console logging in production to reduce noise
  beforeSend: (event) => {
    // Filter out known non-critical errors
    if (event.exception) {
      return event
    }
    return null
  },
})
