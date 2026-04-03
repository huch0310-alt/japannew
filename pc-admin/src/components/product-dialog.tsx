'use client'

import { useState, useEffect } from 'react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { supabaseApi, DbProduct, DbCategory } from '@/lib/supabase'

interface ProductWithCategory extends Partial<DbProduct> {
  category_name?: string
}

interface ProductDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  product?: ProductWithCategory | null
  categories?: DbCategory[]
}

export function ProductDialog({ open, onOpenChange, product, categories = [] }: ProductDialogProps) {
  const [formData, setFormData] = useState({
    code: '',
    nameJa: '',
    nameZh: '',
    categoryId: '',
    unit: '個',
    purchasePrice: '',
    salePriceExTax: '',
    stock: '',
    stockWarning: '10',
  })
  const [isLoading, setIsLoading] = useState(false)

  useEffect(() => {
    if (product) {
      setFormData({
        code: product.code || '',
        nameJa: product.name_ja || '',
        nameZh: product.name_zh || '',
        categoryId: product.category_id || '',
        unit: product.unit || '個',
        purchasePrice: product.purchase_price?.toString() || '',
        salePriceExTax: product.sale_price_ex_tax?.toString() || '',
        stock: product.stock?.toString() || '',
        stockWarning: (product.stock_warning || 10).toString(),
      })
    } else {
      setFormData({
        code: '',
        nameJa: '',
        nameZh: '',
        categoryId: '',
        unit: '個',
        purchasePrice: '',
        salePriceExTax: '',
        stock: '',
        stockWarning: '10',
      })
    }
  }, [product])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)

    try {
      const productData = {
        code: formData.code,
        name_ja: formData.nameJa,
        name_zh: formData.nameZh || null,
        category_id: formData.categoryId || null,
        unit: formData.unit,
        purchase_price: parseInt(formData.purchasePrice) || 0,
        sale_price_ex_tax: parseInt(formData.salePriceExTax) || 0,
        stock: parseInt(formData.stock) || 0,
        stock_warning: parseInt(formData.stockWarning) || 10,
        status: 'pending' as const,
      }

      if (product?.id) {
        // Update existing product
        await supabaseApi.updateProduct(product.id, productData)
      } else {
        // Create new product
        await supabaseApi.createProduct(productData)
      }

      onOpenChange(false)
    } catch (err) {
      console.error('Failed to save product:', err)
      alert('保存に失敗しました')
    } finally {
      setIsLoading(false)
    }
  }

  const categoryOptions = [
    { value: '', label: '未選択' },
    ...categories.map(c => ({ value: c.id, label: c.name_ja }))
  ]

  const unitOptions = ['個', 'kg', 'g', '袋', '箱', '束', '本']

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>{product?.id ? '商品を編集' : '新規商品を作成'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="code">商品コード *</Label>
              <Input
                id="code"
                value={formData.code}
                onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="category">分類</Label>
              <Select value={formData.categoryId} onValueChange={(v) => setFormData({ ...formData, categoryId: v || '' })}>
                <SelectTrigger>
                  <SelectValue placeholder="選択" />
                </SelectTrigger>
                <SelectContent>
                  {categoryOptions.map(opt => (
                    <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="nameJa">商品名(日) *</Label>
              <Input
                id="nameJa"
                value={formData.nameJa}
                onChange={(e) => setFormData({ ...formData, nameJa: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="nameZh">商品名(中)</Label>
              <Input
                id="nameZh"
                value={formData.nameZh}
                onChange={(e) => setFormData({ ...formData, nameZh: e.target.value })}
              />
            </div>
          </div>

          <div className="grid grid-cols-5 gap-4">
            <div className="space-y-2">
              <Label htmlFor="unit">単位</Label>
              <Select value={formData.unit} onValueChange={(v) => setFormData({ ...formData, unit: v || '個' })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {unitOptions.map(u => (
                    <SelectItem key={u} value={u}>{u}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="purchasePrice">仕入価格</Label>
              <Input
                id="purchasePrice"
                type="number"
                value={formData.purchasePrice}
                onChange={(e) => setFormData({ ...formData, purchasePrice: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="salePrice">販売価格</Label>
              <Input
                id="salePrice"
                type="number"
                value={formData.salePriceExTax}
                onChange={(e) => setFormData({ ...formData, salePriceExTax: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="stock">在庫</Label>
              <Input
                id="stock"
                type="number"
                value={formData.stock}
                onChange={(e) => setFormData({ ...formData, stock: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="stockWarning">警告在庫</Label>
              <Input
                id="stockWarning"
                type="number"
                value={formData.stockWarning}
                onChange={(e) => setFormData({ ...formData, stockWarning: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              キャンセル
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading ? '保存中...' : '保存'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
