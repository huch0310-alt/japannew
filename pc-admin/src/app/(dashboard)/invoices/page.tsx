// pc-admin/src/app/(dashboard)/invoices/page.tsx
'use client'

import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Download, Eye, CheckCircle } from 'lucide-react'

interface Invoice {
  id: string
  invoiceNumber: string
  customer: string
  totalInTax: number
  status: 'unpaid' | 'paid' | 'overdue'
  issueDate: string
  dueDate: string
}

const mockInvoices: Invoice[] = [
  { id: '1', invoiceNumber: 'Q20260403001', customer: 'ABC株式会社', totalInTax: 2862, status: 'unpaid', issueDate: '2026-04-03', dueDate: '2026-04-30' },
  { id: '2', invoiceNumber: 'Q20260402001', customer: 'XYZ商事', totalInTax: 123400, status: 'paid', issueDate: '2026-04-02', dueDate: '2026-04-30' },
  { id: '3', invoiceNumber: 'Q20260401001', customer: '千代田精肉店', totalInTax: 78900, status: 'overdue', issueDate: '2026-04-01', dueDate: '2026-04-15' },
]

export default function InvoicesPage() {
  const statusLabels: Record<string, { label: string; color: string }> = {
    unpaid: { label: '未払い', color: 'bg-red-100 text-red-700' },
    paid: { label: '支払済', color: 'bg-green-100 text-green-700' },
    overdue: { label: '期限超過', color: 'bg-orange-100 text-orange-700' },
  }

  const defaultStatus = { label: '不明', color: 'bg-gray-100 text-gray-700' }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">請求書管理</h1>
        <Button>新規請求書作成</Button>
      </div>

      <Card>
        <CardContent className="p-0">
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
              {mockInvoices.map((invoice) => (
                <tr key={invoice.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono font-bold">{invoice.invoiceNumber}</td>
                  <td className="p-3">{invoice.customer}</td>
                  <td className="p-3 text-right font-bold font-mono">¥{invoice.totalInTax.toLocaleString()}</td>
                  <td className="p-3 text-center">
                    <Badge className={statusLabels[invoice.status]?.color ?? defaultStatus.color}>
                      {statusLabels[invoice.status]?.label ?? defaultStatus.label}
                    </Badge>
                  </td>
                  <td className="p-3 text-gray-600">{invoice.issueDate}</td>
                  <td className="p-3 text-gray-600">{invoice.dueDate}</td>
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
                        <Button variant="outline" size="sm" className="text-green-600">
                          <CheckCircle className="h-4 w-4 mr-1" />
                          支払確認
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
    </div>
  )
}