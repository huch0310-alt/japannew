import { createBrowserClient } from '@supabase/ssr'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''

export function isConfigured() {
  return Boolean(supabaseUrl && supabaseAnonKey && supabaseUrl !== 'YOUR_SUPABASE_URL')
}

export function createClient() {
  if (!isConfigured()) {
    throw new Error('Supabase is not configured. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in .env.local')
  }
  return createBrowserClient(supabaseUrl, supabaseAnonKey)
}
