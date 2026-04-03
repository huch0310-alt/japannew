import { createBrowserClient } from '@supabase/ssr'

// Lazy initialization - only create client in browser
let supabaseClient: ReturnType<typeof createBrowserClient> | null = null

function getSupabaseUrl() {
  // During build/SSR, return empty to avoid evaluation issues
  if (typeof window === 'undefined') {
    return ''
  }
  return process.env.NEXT_PUBLIC_SUPABASE_URL || ''
}

function getSupabaseKey() {
  if (typeof window === 'undefined') {
    return ''
  }
  return process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
}

export function isConfigured() {
  const url = getSupabaseUrl()
  const key = getSupabaseKey()
  return Boolean(url && key && url !== 'YOUR_SUPABASE_URL')
}

export function createClient() {
  // During build/SSR, return null
  if (typeof window === 'undefined') {
    return null as any
  }

  const url = getSupabaseUrl()
  const key = getSupabaseKey()

  if (!url || !key || url === 'YOUR_SUPABASE_URL') {
    throw new Error('Supabase is not configured. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in .env.local')
  }

  if (!supabaseClient) {
    supabaseClient = createBrowserClient(url, key)
  }
  return supabaseClient
}
