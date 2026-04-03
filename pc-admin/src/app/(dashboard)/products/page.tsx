export const dynamic = 'force-dynamic'

'use client'

import { useState, useEffect, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ProductDialog } from '@/components/product-dialog'
import { supabaseApi, DbProduct, DbCategory } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

interface ProductWithCategory extends DbProduct {
  category_name?: string
}

export default function ProductsPage() {
  const router = useRouter()
  const [products, setProducts] = useState<ProductWithCategory[]>([])
  const [categories, setCategories] = useState<DbCategory[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [dialogOpen, setDialogOpen] = useState(false)
  const [selectedProduct, setSelectedProduct] = useState<ProductWithCategory | null>(null)

  const loadData = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const [productsData, categoriesData] = await Promise.all([
        supabaseApi.getProducts(),
        supabaseApi.getCategories()
      ])

      // Map category names to products
      const categoryMap = new Map(categoriesData.map(c => [c.id, c.name_ja]))
      const productsWithCategory: ProductWithCategory[] = productsData.map(p => ({
        ...p,
        category_name: p.category_id ? categoryMap.get(p.category_id) : undefined
      }))

      setProducts(productsWithCategory)
      setCategories(categoriesData)
    } catch (err) {
      console.error('Failed to load products:', err)
      setError('商品的読み込みに失敗しました')
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData()
  }, [loadData])

  const statusLabels: Record<string, { label: string; color: string }> = {
    pending: { label: '審査中', color: 'bg-yellow-100 text-yellow-700' },
    approved: { label: '上架中', color: 'bg-green-100 text-green-700' },
    rejected: { label: '拒否', color: 'bg-red-100 text-red-700' },
  }

  const handleEdit = (product: ProductWithCategory) => {
    setSelectedProduct(product)
    setDialogOpen(true)
  }

  const handleCreate = () => {
    setSelectedProduct(null)
    setDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('この商品を削除しますか？')) return
    try {
      await supabaseApi.deleteProduct(id)
      await loadData()
    } catch (err) {
      console.error('Failed to delete product:', err)
      alert('削除に失敗しました')
    }
  }

  const handleApprove = async (id: string) => {
    try {
      await supabaseApi.approveProduct(id)
      await loadData()
    } catch (err) {
      console.error('Failed to approve product:', err)
      alert('承認に失敗しました')
    }
  }

  const handleReject = async (id: string, reason: string) => {
    try {
      await supabaseApi.rejectProduct(id, reason)
      await loadData()
    } catch (err) {
      console.error('Failed to reject product:', err)
      alert('拒否に失敗しました')
    }
  }

  const handleDialogClose = (open: boolean) => {
    setDialogOpen(open)
    if (!open) {
      setSelectedProduct(null)
      loadData()
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">商品管理</h1>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => loadData()}>
            更新
          </Button>
          <Button onClick={handleCreate}>新規作成</Button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-8 text-center text-gray-500">読み込み中...</div>
          ) : products.length === 0 ? (
            <div className="p-8 text-center text-gray-500">商品がありません</div>
          ) : (
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
                {products.map((product) => (
                  <tr key={product.id} className="border-t hover:bg-gray-50">
                    <td className="p-3 font-mono">{product.code}</td>
                    <td className="p-3 font-medium">{product.name_ja}</td>
                    <td className="p-3 text-gray-600">{product.category_name || '-'}</td>
                    <td className="p-3 text-right font-mono">¥{product.purchase_price.toLocaleString()}</td>
                    <td className="p-3 text-right font-mono">¥{product.sale_price_ex_tax.toLocaleString()}</td>
                    <td className="p-3 text-right font-mono">
                      {product.stock <= (product.stock_warning || 10) && product.stock > 0 && (
                        <span className="text-orange-500 mr-1">⚠️</span>
                      )}
                      {product.stock === 0 && <span className="text-red-500 mr-1">在庫切れ</span>}
                      {product.stock}個
                    </td>
                    <td className="p-3 text-center">
                      <Badge className={statusLabels[product.status]?.color || 'bg-gray-100 text-gray-700'}>
                        {statusLabels[product.status]?.label || product.status}
                      </Badge>
                    </td>
                    <td className="p-3 text-right">
                      <div className="flex justify-end gap-2">
                        {product.status === 'pending' && (
                          <>
                            <Button
                              variant="ghost"
                              size="sm"
                              className="text-green-600"
                              onClick={() => handleApprove(product.id)}
                            >
                              承認
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              className="text-red-600"
                              onClick={() => {
                                const reason = prompt('拒否理由を入力:')
                                if (reason) handleReject(product.id, reason)
                              }}
                            >
                              拒否
                            </Button>
                          </>
                        )}
                        <Button variant="ghost" size="sm" onClick={() => handleEdit(product)}>
                          編集
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-red-600"
                          onClick={() => handleDelete(product.id)}
                        >
                          削除
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </CardContent>
      </Card>

      <ProductDialog
        open={dialogOpen}
        onOpenChange={handleDialogClose}
        product={selectedProduct}
        categories={categories}
      />
    </div>
  )
}
