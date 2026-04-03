'use client'

import { useState, useEffect } from 'react'
import { StatsCard } from '@/components/dashboard/stats-card'
import { SalesChart } from '@/components/dashboard/sales-chart'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { DollarSign, ShoppingCart, Package, FileText } from 'lucide-react'

interface DashboardData {
  todaySales: string
  todayOrders: number
  pendingProducts: number
  pendingInvoices: number
  chartData: { date: string; amount: number }[]
  recentOrders: any[]
}

export function DashboardClient({ initialData }: { initialData: DashboardData }) {
  const [stats, setStats] = useState(initialData)
  const [chartData, setChartData] = useState(initialData.chartData)
  const [recentOrders, setRecentOrders] = useState(initialData.recentOrders)
  const [isLoading, setIsLoading] = useState(false)

  const statusLabels: Record<string, { label: string; className: string }> = {
    pending: { label: '未確認', className: 'bg-blue-100 text-blue-700' },
    confirmed: { label: '確認済', className: 'bg-orange-100 text-orange-700' },
    printed: { label: '印刷済', className: 'bg-green-100 text-green-700' },
    invoiced: { label: '請求書済', className: 'bg-purple-100 text-purple-700' },
    paid: { label: '支払済', className: 'bg-gray-100 text-gray-700' },
    cancelled: { label: 'キャンセル', className: 'bg-red-100 text-red-700' },
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">ダッシュボード</h1>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="本日の売上"
          value={stats.todaySales}
          change="+12.5%"
          changeType="increase"
          icon={<DollarSign className="h-6 w-6" />}
          iconColor="text-green-600"
        />
        <StatsCard
          title="本日の注文"
          value={stats.todayOrders.toString()}
          change="+8件"
          changeType="increase"
          icon={<ShoppingCart className="h-6 w-6" />}
          iconColor="text-blue-600"
        />
        <StatsCard
          title="審査待ち商品"
          value={stats.pendingProducts.toString()}
          change="要処理"
          icon={<Package className="h-6 w-6" />}
          iconColor="text-orange-600"
        />
        <StatsCard
          title="未回収請求書"
          value={stats.pendingInvoices.toString()}
          change="¥0"
          icon={<FileText className="h-6 w-6" />}
          iconColor="text-red-600"
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <SalesChart data={chartData} className="lg:col-span-2" />

        {/* Top Products - Placeholder */}
        <Card>
          <CardHeader>
            <CardTitle>销量TOP5</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3 text-gray-500">
              {isLoading ? (
                <div className="text-center py-4">読み込み中...</div>
              ) : (
                <div className="text-center py-4">データがありません</div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Orders */}
      <Card>
        <CardHeader>
          <CardTitle>最近注文</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="p-8 text-center text-gray-500">読み込み中...</div>
          ) : recentOrders.length === 0 ? (
            <div className="p-8 text-center text-gray-500">注文がありません</div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50">
                  <th className="text-left p-3 font-medium">注文番号</th>
                  <th className="text-right p-3 font-medium">金額</th>
                  <th className="text-center p-3 font-medium">状態</th>
                  <th className="text-left p-3 font-medium">時間</th>
                </tr>
              </thead>
              <tbody>
                {recentOrders.map((order, i) => (
                  <tr key={i} className="border-t">
                    <td className="p-3 font-mono text-sm">{order.order_number}</td>
                    <td className="p-3 text-right font-bold font-mono">¥{order.total_in_tax?.toLocaleString()}</td>
                    <td className="p-3 text-center">
                      <span className={statusLabels[order.status]?.className || 'bg-gray-100 text-gray-700'}>
                        {statusLabels[order.status]?.label || order.status}
                      </span>
                    </td>
                    <td className="p-3 text-gray-500">
                      {new Date(order.created_at).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
