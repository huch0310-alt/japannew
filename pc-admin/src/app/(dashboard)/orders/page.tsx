// pc-admin/src/app/(dashboard)/orders/page.tsx
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Printer, Eye } from 'lucide-react'

const mockOrders = [
  { id: '1', orderNumber: 'ORD-20260403-001', customer: 'ABC株式会社', totalInTax: 45600, status: 'pending', createdAt: '10:23' },
  { id: '2', orderNumber: 'ORD-20260403-002', customer: 'XYZ商事', totalInTax: 123400, status: 'confirmed', createdAt: '09:45' },
  { id: '3', orderNumber: 'ORD-20260403-003', customer: '千代田精肉店', totalInTax: 78900, status: 'printed', createdAt: '09:12' },
]

export default function OrdersPage() {
  const [tab, setTab] = useState('all')

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
    ? mockOrders
    : mockOrders.filter((o) => o.status === tab)

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">注文管理</h1>

      <Tabs defaultValue="all" onValueChange={setTab}>
        <TabsList>
          <TabsTrigger value="all">すべて</TabsTrigger>
          <TabsTrigger value="pending">未確認</TabsTrigger>
          <TabsTrigger value="confirmed">確認済</TabsTrigger>
          <TabsTrigger value="printed">印刷済</TabsTrigger>
        </TabsList>

        {['all', 'pending', 'confirmed', 'printed'].map((t) => (
          <TabsContent key={t} value={t} className="mt-4">
            <Card>
              <CardContent className="p-0">
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
                        <td className="p-3 font-mono">{order.orderNumber}</td>
                        <td className="p-3">{order.customer}</td>
                        <td className="p-3 text-right font-bold font-mono">¥{order.totalInTax.toLocaleString()}</td>
                        <td className="p-3 text-center">
                          <Badge className={(statusLabels[order.status] ?? defaultStatus).color}>
                            {(statusLabels[order.status] ?? defaultStatus).label}
                          </Badge>
                        </td>
                        <td className="p-3 text-gray-500">{order.createdAt}</td>
                        <td className="p-3 text-right">
                          <div className="flex justify-end gap-2">
                            <Button variant="ghost" size="sm">
                              <Eye className="h-4 w-4 mr-1" />
                              詳細
                            </Button>
                            {order.status === 'pending' && (
                              <Button variant="outline" size="sm">確認</Button>
                            )}
                            {(order.status === 'confirmed' || order.status === 'pending') && (
                              <Button variant="outline" size="sm">
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
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  )
}
