'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ProductDialog } from '@/components/product-dialog'

interface Product {
  id: string
  code: string
  name: string
  category: string
  purchasePrice: number
  salePrice: number
  stock: number
  stockWarning?: number
  status?: 'pending' | 'approved' | 'rejected'
}

const mockProducts: Product[] = [
  { id: '1', code: 'P001', name: 'ほうれん草', category: '野菜', purchasePrice: 100, salePrice: 180, stock: 50, stockWarning: 10, status: 'approved' },
  { id: '2', code: 'P002', name: '和牛カルビ', category: '精肉', purchasePrice: 600, salePrice: 850, stock: 20, stockWarning: 10, status: 'pending' },
  { id: '3', code: 'P003', name: '白菜', category: '野菜', purchasePrice: 200, salePrice: 300, stock: 0, stockWarning: 10, status: 'approved' },
]

export default function ProductsPage() {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null)

  const statusLabels: Record<string, { label: string; color: string }> = {
    pending: { label: '審査中', color: 'bg-yellow-100 text-yellow-700' },
    approved: { label: '上架中', color: 'bg-green-100 text-green-700' },
    rejected: { label: '拒否', color: 'bg-red-100 text-red-700' },
  }

  const handleEdit = (product: Product) => {
    setSelectedProduct(product)
    setDialogOpen(true)
  }

  const handleCreate = () => {
    setSelectedProduct(null)
    setDialogOpen(true)
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">商品管理</h1>
        <div className="flex gap-2">
          <Button variant="outline">批量上架</Button>
          <Button variant="outline">批量価格変更</Button>
          <Button onClick={handleCreate}>新規作成</Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50 border-b">
                <th className="text-left p-3 font-medium">商品コード</th>
                <th className="text-left p-3 font-medium">商品名</th>
                <th className="text-left p-3 font-medium">分類</th>
                <th className="text-right p-3 font-medium">仕入価格</th>
                <th className="text-right p-3 font-medium">販売価格</th>
                <th className="text-right p-3 font-medium">在庫</th>
                <th className="text-center p-3 font-medium">状態</th>
                <th className="text-right p-3 font-medium">操作</th>
              </tr>
            </thead>
            <tbody>
              {mockProducts.map((product) => (
                <tr key={product.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono">{product.code}</td>
                  <td className="p-3 font-medium">{product.name}</td>
                  <td className="p-3 text-gray-600">{product.category}</td>
                  <td className="p-3 text-right font-mono">¥{product.purchasePrice.toLocaleString()}</td>
                  <td className="p-3 text-right font-mono">¥{product.salePrice.toLocaleString()}</td>
                  <td className="p-3 text-right font-mono">
                    {product.stock <= (product.stockWarning ?? 10) && product.stock > 0 && (
                      <span className="text-orange-500">⚠️</span>
                    )}
                    {product.stock === 0 && <span className="text-red-500">在庫切れ</span>}
                    {product.stock}個
                  </td>
                  <td className="p-3 text-center">
                    <Badge className={statusLabels[product.status].color}>
                      {statusLabels[product.status].label}
                    </Badge>
                  </td>
                  <td className="p-3 text-right">
                    <Button variant="ghost" size="sm" onClick={() => handleEdit(product)}>
                      編集
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <ProductDialog open={dialogOpen} onOpenChange={setDialogOpen} product={selectedProduct} />
    </div>
  )
}
