import { StatsCard } from '@/components/dashboard/stats-card'
import { SalesChart } from '@/components/dashboard/sales-chart'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { DollarSign, ShoppingCart, Package, FileText } from 'lucide-react'

export default async function DashboardPage() {
  // TODO: 从Supabase获取真实数据
  const stats = {
    todaySales: '¥1,234,560',
    todayOrders: 48,
    pendingProducts: 5,
    pendingInvoices: 12,
  }

  const chartData = [
    { date: '4/1', amount: 800000 },
    { date: '4/2', amount: 950000 },
    { date: '4/3', amount: 850000 },
    { date: '4/4', amount: 1100000 },
    { date: '4/5', amount: 980000 },
    { date: '4/6', amount: 1200000 },
    { date: '4/7', amount: 1050000 },
  ]

  const recentOrders = [
    { id: 'ORD-20260403-001', customer: 'ABC株式会社', amount: '¥45,600', status: '待确认', time: '10:23' },
    { id: 'ORD-20260403-002', customer: 'XYZ商事', amount: '¥123,400', status: '已确认', time: '09:45' },
    { id: 'ORD-20260403-003', customer: '千代田精肉店', amount: '¥78,900', status: '已打印', time: '09:12' },
  ]

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">仪表盘</h1>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="今日销售额"
          value={stats.todaySales}
          change="+12.5%"
          changeType="increase"
          icon={<DollarSign className="h-6 w-6" />}
          iconColor="text-green-600"
        />
        <StatsCard
          title="今日订单"
          value={stats.todayOrders}
          change="+8件"
          changeType="increase"
          icon={<ShoppingCart className="h-6 w-6" />}
          iconColor="text-blue-600"
        />
        <StatsCard
          title="待审核商品"
          value={stats.pendingProducts}
          change="需要处理"
          icon={<Package className="h-6 w-6" />}
          iconColor="text-orange-600"
        />
        <StatsCard
          title="待收款请求书"
          value={stats.pendingInvoices}
          change="¥2,345,000"
          icon={<FileText className="h-6 w-6" />}
          iconColor="text-red-600"
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <SalesChart data={chartData} className="lg:col-span-2" />

        {/* Top Products */}
        <Card>
          <CardHeader>
            <CardTitle>销量TOP5</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {[
                { name: 'ほうれん草', qty: '234個' },
                { name: '大根', qty: '198本' },
                { name: '白菜', qty: '156個' },
                { name: 'にんじん', qty: '145本' },
                { name: 'じゃがいも', qty: '132kg' },
              ].map((item, i) => (
                <div key={i} className="flex justify-between text-sm">
                  <span className="text-gray-600">{i + 1}. {item.name}</span>
                  <span className="font-bold">{item.qty}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Orders */}
      <Card>
        <CardHeader>
          <CardTitle>最近订单</CardTitle>
        </CardHeader>
        <CardContent>
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50">
                <th className="text-left p-3 font-medium">订单号</th>
                <th className="text-left p-3 font-medium">客户</th>
                <th className="text-right p-3 font-medium">金额</th>
                <th className="text-center p-3 font-medium">状态</th>
                <th className="text-left p-3 font-medium">时间</th>
              </tr>
            </thead>
            <tbody>
              {recentOrders.map((order, i) => (
                <tr key={i} className="border-t">
                  <td className="p-3 font-mono text-sm">{order.id}</td>
                  <td className="p-3">{order.customer}</td>
                  <td className="p-3 text-right font-bold font-mono">{order.amount}</td>
                  <td className="p-3 text-center">
                    <span className={`
                      px-2 py-1 rounded text-xs
                      ${order.status === '待确认' ? 'bg-blue-100 text-blue-700' : ''}
                      ${order.status === '已确认' ? 'bg-orange-100 text-orange-700' : ''}
                      ${order.status === '已打印' ? 'bg-green-100 text-green-700' : ''}
                    `}>
                      {order.status}
                    </span>
                  </td>
                  <td className="p-3 text-gray-500">{order.time}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  )
}
