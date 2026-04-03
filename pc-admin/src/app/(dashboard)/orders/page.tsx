'use client'

import { useState, useEffect, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Printer, Eye } from 'lucide-react'
import { supabaseApi, DbOrder, DbOrderItem } from '@/lib/supabase'

interface OrderWithItems extends DbOrder {
  order_items: DbOrderItem[]
}

export default function OrdersPage() {
  const [orders, setOrders] = useState<OrderWithItems[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [tab, setTab] = useState('all')

  const loadOrders = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await supabaseApi.getOrders()
      setOrders(data)
    } catch (err) {
      console.error('Failed to load orders:', err)
      setError('注文の読み込みに失敗しました')
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    loadOrders()
  }, [loadOrders])

  const statusLabels: Record<string, { label: string; color: string }> = {
    pending: { label: '未確認', color: 'bg-blue-100 text-blue-700' },
    confirmed: { label: '確認済', color: 'bg-orange-100 text-orange-700' },
    printed: { label: '印刷済', color: 'bg-green-100 text-green-700' },
    invoiced: { label: '請求書済', color: 'bg-purple-100 text-purple-700' },
    paid: { label: '支払済', color: 'bg-gray-100 text-gray-700' },
    cancelled: { label: 'キャンセル', color: 'bg-red-100 text-red-700' },
  }
  const defaultStatus = { label: '不明', color: 'bg-gray-100 text-gray-700' }

  const filteredOrders = tab === 'all'
    ? orders
    : orders.filter((o) => o.status === tab)

  const handleUpdateStatus = async (orderId: string, newStatus: DbOrder['status']) => {
    try {
      await supabaseApi.updateOrderStatus(orderId, newStatus)
      await loadOrders()
    } catch (err) {
      console.error('Failed to update order:', err)
      alert('状态的更新に失敗しました')
    }
  }

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return date.toLocaleString('ja-JP', {
      month: 'numeric',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const counts = {
    all: orders.length,
    pending: orders.filter(o => o.status === 'pending').length,
    confirmed: orders.filter(o => o.status === 'confirmed').length,
    printed: orders.filter(o => o.status === 'printed').length,
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">注文管理</h1>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <Tabs defaultValue="all" onValueChange={setTab}>
        <TabsList>
          <TabsTrigger value="all">すべて({counts.all})</TabsTrigger>
          <TabsTrigger value="pending">未確認({counts.pending})</TabsTrigger>
          <TabsTrigger value="confirmed">確認済({counts.confirmed})</TabsTrigger>
          <TabsTrigger value="printed">印刷済({counts.printed})</TabsTrigger>
        </TabsList>

        {['all', 'pending', 'confirmed', 'printed'].map((t) => (
          <TabsContent key={t} value={t} className="mt-4">
            <Card>
              <CardContent className="p-0">
                {isLoading ? (
                  <div className="p-8 text-center text-gray-500">読み込み中...</div>
                ) : filteredOrders.length === 0 ? (
                  <div className="p-8 text-center text-gray-500">注文がありません</div>
                ) : (
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-gray-50 border-b">
                        <th className="text-left p-3 font-medium">注文番号</th>
                        <th className="text-left p-3 font-medium">お客様</th>
                        <th className="text-right p-3 font-medium">税込金額</th>
                        <th className="text-center p-3 font-medium">状態</th>
                        <th className="text-left p-3 font-medium">注文時間</th>
                        <th className="text-right p-3 font-medium">操作</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredOrders.map((order) => (
                        <tr key={order.id} className="border-t hover:bg-gray-50">
                          <td className="p-3 font-mono">{order.order_number}</td>
                          <td className="p-3">{order.customer_id}</td>
                          <td className="p-3 text-right font-bold font-mono">¥{order.total_in_tax.toLocaleString()}</td>
                          <td className="p-3 text-center">
                            <Badge className={(statusLabels[order.status] ?? defaultStatus).color}>
                              {(statusLabels[order.status] ?? defaultStatus).label}
                            </Badge>
                          </td>
                          <td className="p-3 text-gray-500">{formatDate(order.created_at)}</td>
                          <td className="p-3 text-right">
                            <div className="flex justify-end gap-2">
                              <Button variant="ghost" size="sm">
                                <Eye className="h-4 w-4 mr-1" />
                                詳細
                              </Button>
                              {order.status === 'pending' && (
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => handleUpdateStatus(order.id, 'confirmed')}
                                >
                                  確認
                                </Button>
                              )}
                              {order.status === 'confirmed' && (
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => handleUpdateStatus(order.id, 'printed')}
                                >
                                  <Printer className="h-4 w-4 mr-1" />
                                  印刷
                                </Button>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  )
}
