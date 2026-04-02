import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

serve(async (req) => {
  const { items, customerDiscountRate, taxRate } = await req.json()

  let totalExTax = 0
  const calculatedItems = items.map((item: any) => {
    // 使用整数计算避免浮点精度问题
    const discountRate = customerDiscountRate || 0
    const discountedPrice = Math.round(item.unitPriceExTax * (100 - discountRate) / 100)
    const lineTotal = Math.round(item.quantity * discountedPrice)
    totalExTax += lineTotal
    return { ...item, discountedPrice, lineTotal }
  })

  const taxAmount = Math.round(totalExTax * (taxRate || 0.08))
  const totalInTax = totalExTax + taxAmount

  return new Response(JSON.stringify({
    items: calculatedItems,
    totalExTax,
    taxAmount,
    totalInTax
  }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
