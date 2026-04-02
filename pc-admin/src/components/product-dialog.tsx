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

interface Product {
  id?: string
  code: string
  name: string
  category: string
  purchasePrice: number
  salePrice: number
  stock: number
  stockWarning?: number
  status?: 'pending' | 'approved' | 'rejected'
  unit?: string
}

interface ProductDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  product?: Product | null
}

export function ProductDialog({ open, onOpenChange, product }: ProductDialogProps) {
  const [formData, setFormData] = useState({
    code: '',
    nameJa: '',
    category: '',
    unit: '個',
    purchasePrice: '',
    salePrice: '',
    stock: '',
    stockWarning: '10',
  })

  useEffect(() => {
    setFormData({
      code: product?.code || '',
      nameJa: product?.name || '',
      category: product?.category || '',
      unit: product?.unit || '個',
      purchasePrice: product?.purchasePrice?.toString() || '',
      salePrice: product?.salePrice?.toString() || '',
      stock: product?.stock?.toString() || '',
      stockWarning: product?.stockWarning?.toString() || '10',
    })
  }, [product])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log('Save product:', formData)
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>{product ? '商品を編集' : '新規商品を作成'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="code">商品コード *</Label>
              <Input id="code" value={formData.code} onChange={(e) => setFormData({ ...formData, code: e.target.value })} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="category">分類 *</Label>
              <Select value={formData.category} onValueChange={(v) => setFormData({ ...formData, category: v })}>
                <SelectTrigger>
                  <SelectValue placeholder="選択" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="野菜">野菜</SelectItem>
                  <SelectItem value="精肉">精肉</SelectItem>
                  <SelectItem value="鮮魚">鮮魚</SelectItem>
                  <SelectItem value="果物">果物</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="nameJa">商品名 *</Label>
            <Input id="nameJa" value={formData.nameJa} onChange={(e) => setFormData({ ...formData, nameJa: e.target.value })} required />
          </div>

          <div className="grid grid-cols-4 gap-4">
            <div className="space-y-2">
              <Label htmlFor="unit">単位</Label>
              <Select value={formData.unit} onValueChange={(v) => setFormData({ ...formData, unit: v })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="個">個</SelectItem>
                  <SelectItem value="kg">kg</SelectItem>
                  <SelectItem value="g">g</SelectItem>
                  <SelectItem value="袋">袋</SelectItem>
                  <SelectItem value="箱">箱</SelectItem>
                  <SelectItem value="束">束</SelectItem>
                  <SelectItem value="本">本</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="purchasePrice">仕入価格</Label>
              <Input id="purchasePrice" type="number" value={formData.purchasePrice} onChange={(e) => setFormData({ ...formData, purchasePrice: e.target.value })} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="salePrice">販売価格</Label>
              <Input id="salePrice" type="number" value={formData.salePrice} onChange={(e) => setFormData({ ...formData, salePrice: e.target.value })} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="stock">在庫</Label>
              <Input id="stock" type="number" value={formData.stock} onChange={(e) => setFormData({ ...formData, stock: e.target.value })} />
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>キャンセル</Button>
            <Button type="submit">保存</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
