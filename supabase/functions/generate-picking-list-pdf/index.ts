import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseKey)

  const { orderId, printedBy, printedAt } = await req.json()

  // Fetch order
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .select('*')
    .eq('id', orderId)
    .single()

  if (orderError || !order) {
    return new Response(JSON.stringify({ error: 'Order not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Fetch customer with company info
  const { data: customer, error: customerError } = await supabase
    .from('users')
    .select(`
      id,
      name,
      phone,
      customers (
        company_name,
        postal_code,
        address,
        contact_name,
        discount_rate
      )
    `)
    .eq('id', order.customer_id)
    .single()

  if (customerError || !customer) {
    return new Response(JSON.stringify({ error: 'Customer not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Fetch order items with product info
  const { data: orderItems, error: itemsError } = await supabase
    .from('order_items')
    .select(`
      quantity,
      unit_price_ex_tax,
      discounted_price,
      line_total_ex_tax,
      order_date,
      note,
      products (
        name_ja,
        unit
      )
    `)
    .eq('order_id', orderId)
    .order('order_date', { ascending: true })

  if (itemsError) {
    return new Response(JSON.stringify({ error: 'Order items not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Try to fetch printer info (user who printed)
  let printerName = printedBy || ''
  if (printedBy) {
    const { data: printerUser } = await supabase
      .from('users')
      .select('name')
      .eq('id', printedBy)
      .single()
    if (printerUser) {
      printerName = printerUser.name
    }
  }

  // Fetch system settings for tax rate
  const { data: settings } = await supabase
    .from('system_settings')
    .select('*')
    .single()

  const taxRate = settings?.tax_rate || 0.08

  const customerData = customer.customers
  const companyName = customerData?.company_name || customer.name
  const contactName = customerData?.contact_name || ''
  const phone = customer.phone || ''
  const postalCode = customerData?.postal_code || ''
  const address = customerData?.address || ''
  const discountRate = customerData?.discount_rate || 0

  // Format date
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return `${date.getFullYear()}年${String(date.getMonth() + 1).padStart(2, '0')}月${String(date.getDate()).padStart(2, '0')}日`
  }

  const formatShortDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return `${date.getMonth() + 1}/${date.getDate()}`
  }

  // Format datetime for printing
  const formatDateTime = (dateStr: string) => {
    const date = new Date(dateStr)
    return `${date.getFullYear()}年${String(date.getMonth() + 1).padStart(2, '0')}月${String(date.getDate()).padStart(2, '0')}日 ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
  }

  // Format currency
  const formatYen = (amount: number) => {
    return `¥${amount.toLocaleString('ja-JP')}`
  }

  // Calculate totals
  const totalQuantity = orderItems.reduce((sum: number, item: any) => sum + Number(item.quantity), 0)
  const orderDate = formatDate(order.created_at)
  const printDateTime = printedAt ? formatDateTime(printedAt) : formatDateTime(new Date().toISOString())

  // Build items rows HTML
  const itemsRows = orderItems.map((item: any, index: number) => {
    const bgStyle = index % 2 === 1 ? 'background:#f8f9fa;' : ''
    const productName = item.products?.name_ja || '不明'
    const unit = item.products?.unit || '個'
    return `
    <tr>
      <td style="padding:8px; border:1px solid #ddd; text-align:center; ${bgStyle}">${item.quantity}</td>
      <td style="padding:8px; border:1px solid #ddd; text-align:center; ${bgStyle}">${unit}</td>
      <td style="padding:8px; border:1px solid #ddd; ${bgStyle}">${productName}</td>
      <td style="padding:8px; border:1px solid #ddd; text-align:right; font-family:monospace; ${bgStyle}">${formatYen(item.unit_price_ex_tax)}</td>
      <td style="padding:8px; border:1px solid #ddd; text-align:right; font-family:monospace; ${bgStyle}">${formatYen(item.discounted_price)}</td>
      <td style="padding:8px; border:1px solid #ddd; text-align:right; font-family:monospace; ${bgStyle}">${formatYen(item.line_total_ex_tax)}</td>
    </tr>`
  }).join('')

  const html = `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>分拣单 - ${order.order_number}</title>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Noto Sans JP', sans-serif; font-size: 12px; line-height: 1.6; }
    .picking-container { background: white; padding: 40px; }
    .header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; border-bottom: 2px solid #333; padding-bottom: 15px; }
    .header-left h1 { font-size: 24px; font-weight: bold; letter-spacing: 4px; }
    .header-right { text-align: right; }
    .header-right .order-number { font-size: 16px; font-weight: bold; }
    .header-right .order-date { font-size: 12px; color: #666; }
    .customer-box { background: #f8f9fa; padding: 15px; border-radius: 4px; margin-bottom: 20px; border: 1px solid #ddd; }
    .customer-box .company-name { font-weight: bold; font-size: 14px; margin-bottom: 8px; }
    .customer-box .info-row { display: flex; gap: 20px; font-size: 11px; color: #333; }
    .customer-box .info-row span { color: #666; }
    .customer-box .notes { margin-top: 8px; font-size: 11px; color: #666; font-style: italic; }
    .items-table { width: 100%; border-collapse: collapse; font-size: 11px; margin-bottom: 20px; }
    .items-table th { padding: 10px 8px; background: #2c5282; color: white; text-align: center; border: 1px solid #2c5282; }
    .items-table th:nth-child(1) { width: 10%; }
    .items-table th:nth-child(2) { width: 8%; }
    .items-table th:nth-child(3) { width: 32%; text-align: left; }
    .items-table th:nth-child(4) { width: 15%; }
    .items-table th:nth-child(5) { width: 15%; }
    .items-table th:nth-child(6) { width: 20%; }
    .summary-section { display: flex; justify-content: space-between; align-items: flex-start; }
    .summary-info { font-size: 11px; color: #666; }
    .summary-info div { margin-bottom: 4px; }
    .summary-table { width: 250px; border-collapse: collapse; font-size: 11px; }
    .summary-table td { padding: 8px; border: 1px solid #ddd; }
    .summary-table td:first-child { background: #f8f9fa; width: 50%; }
    .summary-table td:last-child { text-align: right; font-family: monospace; width: 50%; }
    .summary-table tr:last-child td { background: #2c5282; color: white; font-weight: bold; padding: 10px; }
  </style>
</head>
<body>
  <div class="picking-container">
    <!-- Header -->
    <div class="header">
      <div class="header-left">
        <h1>分 拣 单</h1>
      </div>
      <div class="header-right">
        <div class="order-number">${order.order_number}</div>
        <div class="order-date">${orderDate}</div>
      </div>
    </div>

    <!-- Customer Info Box -->
    <div class="customer-box">
      <div class="company-name">${companyName}</div>
      <div class="info-row">
        <div>担当者: <span>${contactName}</span></div>
        <div>電話: <span>${phone}</span></div>
      </div>
      <div class="info-row">
        <div>住所: <span>${postalCode} ${address}</span></div>
      </div>
      ${order.customer_note ? `<div class="notes">備考: ${order.customer_note}</div>` : ''}
    </div>

    <!-- Items Table -->
    <table class="items-table">
      <thead>
        <tr>
          <th>数量</th>
          <th>単位</th>
          <th>商品名</th>
          <th>単価</th>
          <th>割引後単価</th>
          <th>金額</th>
        </tr>
      </thead>
      <tbody>
        ${itemsRows}
      </tbody>
    </table>

    <!-- Summary Section -->
    <div class="summary-section">
      <div class="summary-info">
        <div>合計商品数: ${totalQuantity}</div>
        <div>打印时间: ${printDateTime}</div>
        <div>打印人: ${printerName}</div>
      </div>
      <table class="summary-table">
        <tr>
          <td>割引率</td>
          <td>${discountRate}%</td>
        </tr>
        <tr>
          <td>税抜合計</td>
          <td>${formatYen(order.total_ex_tax)}</td>
        </tr>
        <tr>
          <td>消費税(8%)</td>
          <td>${formatYen(order.tax_amount)}</td>
        </tr>
        <tr>
          <td>税込合計</td>
          <td>${formatYen(order.total_in_tax)}</td>
        </tr>
      </table>
    </div>
  </div>
</body>
</html>`

  return new Response(JSON.stringify({ html }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
