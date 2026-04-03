import { getSupabaseBrowserClient } from '@/lib/supabase'
import { DashboardClient } from '@/components/dashboard/dashboard-client'

// Force dynamic rendering to avoid SSG issues with Supabase
export const dynamic = 'force-dynamic'

async function getDashboardData() {
  try {
    const supabase = getSupabaseBrowserClient()
    if (!supabase) {
      return {
        todaySales: '¥0',
        todayOrders: 0,
        pendingProducts: 0,
        pendingInvoices: 0,
        chartData: [],
        recentOrders: []
      }
    }

    const { data: productsData } = await supabase.from('products').select('id', { count: 'exact', head: true })
    const { data: ordersData } = await supabase.from('orders').select('id', { count: 'exact', head: true })
    const { data: recentOrdersData } = await supabase
      .from('orders')
      .select('total_in_tax, created_at, order_number, status')
      .order('created_at', { ascending: false })
      .limit(7)

    const ordersTotal = recentOrdersData?.reduce((sum: number, o: any) => sum + (o.total_in_tax || 0), 0) || 0

    return {
      todaySales: `¥${ordersTotal.toLocaleString()}`,
      todayOrders: ordersData?.count || 0,
      pendingProducts: productsData?.count || 0,
      pendingInvoices: 0,
      chartData: recentOrdersData?.map((o: any) => ({
        date: new Date(o.created_at).toLocaleDateString('ja-JP', { month: 'numeric', day: 'numeric' }),
        amount: o.total_in_tax || 0
      })) || [],
      recentOrders: recentOrdersData?.slice(0, 5) || []
    }
  } catch (err) {
    console.error('Failed to load dashboard data:', err)
    return {
      todaySales: '¥0',
      todayOrders: 0,
      pendingProducts: 0,
      pendingInvoices: 0,
      chartData: [],
      recentOrders: []
    }
  }
}

export default async function DashboardPage() {
  const initialData = await getDashboardData()

  return <DashboardClient initialData={initialData} />
}
