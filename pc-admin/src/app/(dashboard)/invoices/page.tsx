// pc-admin/src/app/(dashboard)/invoices/page.tsx
'use client'

import { useState, useEffect, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Download, Eye, CheckCircle } from 'lucide-react'
import { supabaseApi, DbInvoice } from '@/lib/supabase'

export default function InvoicesPage() {
  const [invoices, setInvoices] = useState<DbInvoice[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [tab, setTab] = useState('all')

  const loadInvoices = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await supabaseApi.getInvoices()
      setInvoices(data)
    } catch (err) {
      console.error('Failed to load invoices:', err)
      setError('請求書の読み込みに失敗しました')
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    loadInvoices()
  }, [loadInvoices])

  const statusLabels: Record<string, { label: string; color: string }> = {
    unpaid: { label: '未払い', color: 'bg-red-100 text-red-700' },
    paid: { label: '支払済', color: 'bg-green-100 text-green-700' },
    overdue: { label: '期限超過', color: 'bg-orange-100 text-orange-700' },
  }
  const defaultStatus = { label: '不明', color: 'bg-gray-100 text-gray-700' }

  const filteredInvoices = tab === 'all'
    ? invoices
    : tab === 'overdue'
      ? invoices.filter((i) => i.status === 'overdue' || (i.status === 'unpaid' && new Date(i.due_date) < new Date()))
      : invoices.filter((i) => i.status === tab)

  const handleMarkPaid = async (invoiceId: string) => {
    try {
      await supabaseApi.updateInvoiceStatus(invoiceId, 'paid')
      await loadInvoices()
    } catch (err) {
      console.error('Failed to update invoice:', err)
      alert('更新に失敗しました')
    }
  }

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return date.toLocaleDateString('ja-JP', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    })
  }

  const counts = {
    all: invoices.length,
    unpaid: invoices.filter(i => i.status === 'unpaid').length,
    paid: invoices.filter(i => i.status === 'paid').length,
    overdue: invoices.filter(i => i.status === 'overdue' || (i.status === 'unpaid' && new Date(i.due_date) < new Date())).length,
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">請求書管理</h1>
        <Button>新規請求書作成</Button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="flex gap-2">
        <Button
          variant={tab === 'all' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setTab('all')}
        >
          すべて({counts.all})
        </Button>
        <Button
          variant={tab === 'unpaid' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setTab('unpaid')}
        >
          未払い({counts.unpaid})
        </Button>
        <Button
          variant={tab === 'overdue' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setTab('overdue')}
        >
          期限超過({counts.overdue})
        </Button>
        <Button
          variant={tab === 'paid' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setTab('paid')}
        >
          支払済({counts.paid})
        </Button>
      </div>

      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-8 text-center text-gray-500">読み込み中...</div>
          ) : filteredInvoices.length === 0 ? (
            <div className="p-8 text-center text-gray-500">請求書がありません</div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50 border-b">
                  <th className="text-left p-3 font-medium">請求書番号</th>
                  <th className="text-left p-3 font-medium">お客様</th>
                  <th className="text-right p-3 font-medium">請求金額</th>
                  <th className="text-center p-3 font-medium">状態</th>
                  <th className="text-left p-3 font-medium">発行日</th>
                  <th className="text-left p-3 font-medium">支払期限</th>
                  <th className="text-right p-3 font-medium">操作</th>
                </tr>
              </thead>
              <tbody>
                {filteredInvoices.map((invoice) => {
                  const isOverdue = invoice.status === 'unpaid' && new Date(invoice.due_date) < new Date()
                  const displayStatus = isOverdue && invoice.status !== 'overdue' ? 'overdue' : invoice.status
                  return (
                    <tr key={invoice.id} className="border-t hover:bg-gray-50">
                      <td className="p-3 font-mono font-bold">{invoice.invoice_number}</td>
                      <td className="p-3">{invoice.customer_name || invoice.customer_id}</td>
                      <td className="p-3 text-right font-bold font-mono">¥{invoice.total_in_tax.toLocaleString()}</td>
                      <td className="p-3 text-center">
                        <Badge className={statusLabels[displayStatus]?.color ?? defaultStatus.color}>
                          {statusLabels[displayStatus]?.label ?? defaultStatus.label}
                        </Badge>
                      </td>
                      <td className="p-3 text-gray-600">{formatDate(invoice.issue_date)}</td>
                      <td className="p-3 text-gray-600">{formatDate(invoice.due_date)}</td>
                      <td className="p-3 text-right">
                        <div className="flex justify-end gap-2">
                          <Button variant="ghost" size="sm">
                            <Eye className="h-4 w-4 mr-1" />
                            詳細
                          </Button>
                          <Button variant="ghost" size="sm">
                            <Download className="h-4 w-4 mr-1" />
                            PDF
                          </Button>
                          {invoice.status !== 'paid' && (
                            <Button
                              variant="outline"
                              size="sm"
                              className="text-green-600"
                              onClick={() => handleMarkPaid(invoice.id)}
                            >
                              <CheckCircle className="h-4 w-4 mr-1" />
                              支払確認
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </CardContent>
      </Card>
    </div>
  )
}