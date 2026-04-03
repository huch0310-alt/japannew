import { createBrowserClient } from '@supabase/ssr'

// Browser client singleton - lazy initialization
let browserClient: ReturnType<typeof createBrowserClient> | null = null

export function isSupabaseConfigured(): boolean {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
  return Boolean(url && key && url !== 'YOUR_SUPABASE_URL' && url.startsWith('http'))
}

export function getSupabaseBrowserClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''

  if (!url || !key || url === 'YOUR_SUPABASE_URL') {
    throw new Error('Supabase is not configured. Please set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in .env.local')
  }

  // Validate URL format
  try {
    new URL(url)
  } catch {
    throw new Error(`Invalid Supabase URL: ${url}`)
  }

  if (!browserClient) {
    browserClient = createBrowserClient(url, key)
  }
  return browserClient
}

// Types matching Supabase schema
export interface DbUser {
  id: string
  email: string | null
  phone: string | null
  role: 'super_admin' | 'sales_manager' | 'purchaser' | 'customer'
  name: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface DbCustomer {
  id: string
  company_name: string
  company_name_zh: string | null
  tax_id: string | null
  postal_code: string | null
  address: string | null
  address_zh: string | null
  contact_name: string | null
  discount_rate: number
  payment_term_days: number
  created_at: string
  updated_at: string
}

export interface DbCategory {
  id: string
  name_ja: string
  name_zh: string | null
  parent_id: string | null
  sort_order: number
  created_at: string
}

export interface DbProduct {
  id: string
  code: string
  name_ja: string
  name_zh: string | null
  category_id: string | null
  unit: string
  purchase_price: number
  sale_price_ex_tax: number
  stock: number
  stock_warning: number
  status: 'pending' | 'approved' | 'rejected'
  submitted_by: string | null
  reject_reason: string | null
  images: string[] | null
  description_ja: string | null
  description_zh: string | null
  created_at: string
  updated_at: string
}

export interface DbOrder {
  id: string
  order_number: string
  customer_id: string
  status: 'pending' | 'confirmed' | 'printed' | 'invoiced' | 'paid' | 'cancelled'
  total_ex_tax: number
  tax_amount: number
  total_in_tax: number
  customer_note: string | null
  printed_by: string | null
  printed_at: string | null
  invoice_id: string | null
  created_at: string
  updated_at: string
}

export interface DbOrderItem {
  id: string
  order_id: string
  product_id: string
  product_name: string | null
  quantity: number
  unit_price_ex_tax: number
  discounted_price: number
  line_total_ex_tax: number
  note: string | null
}

// API functions
export const supabaseApi = {
  // ============ Products ============
  async getProducts(): Promise<DbProduct[]> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data || []
  },

  async getProductById(id: string): Promise<DbProduct | null> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async createProduct(product: Partial<DbProduct>): Promise<DbProduct> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('products')
      .insert(product)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async updateProduct(id: string, product: Partial<DbProduct>): Promise<DbProduct> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('products')
      .update(product)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async deleteProduct(id: string): Promise<void> {
    const supabase = getSupabaseBrowserClient()
    const { error } = await supabase.from('products').delete().eq('id', id)
    if (error) throw error
  },

  async approveProduct(id: string): Promise<void> {
    const supabase = getSupabaseBrowserClient()
    const { error } = await supabase
      .from('products')
      .update({ status: 'approved' })
      .eq('id', id)
    if (error) throw error
  },

  async rejectProduct(id: string, reason: string): Promise<void> {
    const supabase = getSupabaseBrowserClient()
    const { error } = await supabase
      .from('products')
      .update({ status: 'rejected', reject_reason: reason })
      .eq('id', id)
    if (error) throw error
  },

  // ============ Categories ============
  async getCategories(): Promise<DbCategory[]> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('sort_order', { ascending: true })
    if (error) throw error
    return data || []
  },

  // ============ Orders ============
  async getOrders(): Promise<(DbOrder & { order_items: DbOrderItem[] })[]> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*)')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data || []
  },

  async getOrderById(id: string): Promise<(DbOrder & { order_items: DbOrderItem[] }) | null> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async updateOrderStatus(id: string, status: DbOrder['status']): Promise<void> {
    const supabase = getSupabaseBrowserClient()
    const { error } = await supabase
      .from('orders')
      .update({ status })
      .eq('id', id)
    if (error) throw error
  },

  // ============ Users ============
  async getUsers(): Promise<DbUser[]> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data || []
  },

  async getUserById(id: string): Promise<DbUser | null> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async createUser(user: Partial<DbUser>): Promise<DbUser> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('users')
      .insert(user)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async updateUser(id: string, user: Partial<DbUser>): Promise<DbUser> {
    const supabase = getSupabaseBrowserClient()
    const { data, error } = await supabase
      .from('users')
      .update(user)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  // ============ Dashboard Stats ============
  async getDashboardStats() {
    const supabase = getSupabaseBrowserClient()

    const [productsCount, ordersCount, usersCount, recentOrders] = await Promise.all([
      supabase.from('products').select('id', { count: 'exact', head: true }),
      supabase.from('orders').select('id', { count: 'exact', head: true }),
      supabase.from('users').select('id', { count: 'exact', head: true }),
      supabase.from('orders')
        .select('total_in_tax, created_at')
        .order('created_at', { ascending: false })
        .limit(7)
    ])

    return {
      productsCount: productsCount.count || 0,
      ordersCount: ordersCount.count || 0,
      usersCount: usersCount.count || 0,
      recentOrders: recentOrders.data || []
    }
  }
}
