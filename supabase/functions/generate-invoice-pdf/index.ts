import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseKey)

  const { invoiceId, settings } = await req.json()

  // Fetch invoice
  const { data: invoice, error: invoiceError } = await supabase
    .from('invoices')
    .select('*')
    .eq('id', invoiceId)
    .single()

  if (invoiceError || !invoice) {
    return new Response(JSON.stringify({ error: 'Invoice not found' }), {
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
      customers (
        company_name,
        postal_code,
        address,
        contact_name
      )
    `)
    .eq('id', invoice.customer_id)
    .single()

  if (customerError || !customer) {
    return new Response(JSON.stringify({ error: 'Customer not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Fetch orders linked to this invoice
  const { data: orders, error: ordersError } = await supabase
    .from('orders')
    .select('id, order_number')
    .eq('invoice_id', invoice.id)

  if (ordersError) {
    return new Response(JSON.stringify({ error: 'Orders not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const orderIds = orders.map(o => o.id)

  // Fetch order items with product info
  const { data: orderItems, error: itemsError } = await supabase
    .from('order_items')
    .select(`
      quantity,
      unit_price_ex_tax,
      discounted_price,
      line_total_ex_tax,
      order_date,
      products (
        name_ja,
        unit
      )
    `)
    .in('order_id', orderIds)
    .order('order_date', { ascending: true })

  if (itemsError) {
    return new Response(JSON.stringify({ error: 'Order items not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Use settings from argument or defaults
  const companyName = settings?.company_name || 'FreshBiz株式会社'
  const companyAddress = settings?.company_address || ''
  const companyPhone = settings?.company_phone || ''
  const bankName = settings?.bank_name || ''
  const bankBranch = settings?.bank_branch || ''
  const bankAccountType = settings?.bank_account_type || ''
  const bankAccountNumber = settings?.bank_account_number || ''
  const taxRate = settings?.tax_rate || 0.08

  const customerData = customer.customers
  const companyNameDisplay = customerData?.company_name || customer.name
  const contactName = customerData?.contact_name || ''
  const postalCode = customerData?.postal_code || ''
  const address = customerData?.address || ''

  // Format date
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return `${date.getFullYear()}年${String(date.getMonth() + 1).padStart(2, '0')}月${String(date.getDate()).padStart(2, '0')}日`
  }

  const formatShortDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return `${date.getMonth() + 1}/${date.getDate()}`
  }

  // Format currency
  const formatYen = (amount: number) => {
    return `¥${amount.toLocaleString()}`
  }

  // Issue date and due date
  const issueDate = formatDate(invoice.issue_date)
  const dueDate = formatDate(invoice.due_date)

  // Build items rows HTML
  const itemsRows = orderItems.map((item: any, index: number) => {
    const bgStyle = index % 2 === 1 ? 'background:#f8f9fa;' : ''
    const productName = item.products?.name_ja || '不明'
    const unit = item.products?.unit || '個'
    return `
    <tr>
      <td style="padding:8px; border:1px solid #ddd; ${bgStyle}">${formatShortDate(item.order_date)}</td>
      <td style="padding:8px; border:1px solid #ddd; ${bgStyle}">${productName}</td>
      <td style="padding:8px; border:1px solid #ddd; text-align:center; ${bgStyle}">${item.quantity}</td>
      <td style="padding:8px; border:1px solid #ddd; text-align:center; ${bgStyle}">${unit}</td>
      <td style="padding:8px; border:1px solid #ddd; text-align:right; font-family:monospace; ${bgStyle}">${formatYen(item.unit_price_ex_tax)}</td>
      <td style="padding:8px; border:1px solid #ddd; text-align:right; font-family:monospace; ${bgStyle}">${formatYen(item.line_total_ex_tax)}</td>
    </tr>`
  }).join('')

  const html = `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>請求書 - ${invoice.invoice_number}</title>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Noto Sans JP', sans-serif; font-size: 12px; line-height: 1.6; }
    .invoice-container { background: white; padding: 40px; }
    .header-note { text-align: right; margin-bottom: 20px; color: #666; font-size: 11px; }
    .title { text-align: center; margin-bottom: 30px; }
    .title h1 { font-size: 32px; font-weight: bold; letter-spacing: 8px; border-bottom: 3px double #333; padding-bottom: 15px; display: inline-block; }
    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 30px; }
    .info-grid .recipient { }
    .info-grid .issuer { text-align: right; }
    .info-label { font-size: 10px; color: #666; margin-bottom: 4px; }
    .company-name { font-weight: bold; font-size: 14px; }
    .info-item { font-size: 11px; }
    .info-item strong { font-weight: bold; }
    .bank-info { background: #f8f9fa; padding: 12px; border-radius: 4px; margin-bottom: 20px; font-size: 11px; }
    .bank-info .bank-title { font-weight: bold; margin-bottom: 4px; }
    .invoice-amount-table { width: 100%; border-collapse: collapse; font-size: 11px; margin-bottom: 0; }
    .invoice-amount-table td:first-child { padding: 10px 8px; border: 1px solid #0F4C81; background: #e8f4fd; font-weight: bold; color: #0F4C81; width: 16.5%; }
    .invoice-amount-table td:last-child { padding: 10px 8px; border: 1px solid #0F4C81; background: #e8f4fd; text-align: right; font-weight: bold; font-family: monospace; font-size: 14px; color: #0F4C81; }
    .items-table { width: 100%; border-collapse: collapse; font-size: 11px; }
    .items-table th { padding: 10px 8px; background: #0F4C81; color: white; text-align: left; border: 1px solid #0F4C81; }
    .items-table th:nth-child(3) { text-align: center; }
    .items-table th:nth-child(4) { text-align: center; }
    .items-table th:nth-child(5) { text-align: right; }
    .items-table th:nth-child(6) { text-align: right; }
    .items-table th { width: 16.5%; }
    .items-table th:nth-child(2) { width: 40%; }
    .items-table th:nth-child(3) { width: 12%; }
    .items-table th:nth-child(4) { width: 8%; }
    .items-table th:nth-child(5) { width: 12%; }
    .items-table th:nth-child(6) { width: 11.5%; }
    .summary { display: flex; justify-content: flex-end; margin-top: 16px; }
    .summary-table { width: 250px; border-collapse: collapse; font-size: 11px; }
    .summary-table td { padding: 8px; border: 1px solid #ddd; }
    .summary-table td:first-child { background: #f8f9fa; }
    .summary-table td:last-child { text-align: right; font-family: monospace; }
    .summary-table tr:last-child td { background: #0F4C81; color: white; font-weight: bold; padding: 10px; }
  </style>
</head>
<body>
  <div class="invoice-container">
    <!-- Header -->
    <div class="header-note">
      毎度ありがとうございます。<br/>
      下記のとおりご請求申し上げます。
    </div>

    <!-- Title -->
    <div class="title">
      <h1>請 求 書</h1>
    </div>

    <!-- Info Grid -->
    <div class="info-grid">
      <div class="recipient">
        <div class="info-label">宛先</div>
        <div class="company-name">${companyNameDisplay} 御中</div>
        <div class="info-item">${postalCode}</div>
        <div class="info-item">${address}</div>
        ${contactName ? `<div class="info-item">担当者：${contactName} 様</div>` : ''}
      </div>
      <div class="issuer">
        <div class="info-label">発行元</div>
        <div class="company-name">${companyName}</div>
        <div class="info-item">${companyAddress}</div>
        <div class="info-item">Tel: ${companyPhone}</div>
        <div class="info-item">invoice: <strong>${invoice.invoice_number}</strong></div>
        <div class="info-item">請求日: ${issueDate}</div>
        <div class="info-item">支払期限: ${dueDate}</div>
      </div>
    </div>

    <!-- Bank Info -->
    ${bankName ? `
    <div class="bank-info">
      <div class="bank-title">【銀行振込先】</div>
      <div>${bankName} ${bankBranch} ${bankAccountType} ${bankAccountNumber}</div>
    </div>` : ''}

    <!-- 請求金額 Row -->
    <table class="invoice-amount-table">
      <tbody>
        <tr>
          <td>請求金額</td>
          <td>${formatYen(invoice.total_in_tax)}</td>
        </tr>
      </tbody>
    </table>

    <!-- Items Table -->
    <table class="items-table">
      <thead>
        <tr>
          <th>日付</th>
          <th>商品名</th>
          <th>数量</th>
          <th>単位</th>
          <th>単価</th>
          <th>金額</th>
        </tr>
      </thead>
      <tbody>
        ${itemsRows}
      </tbody>
    </table>

    <!-- Summary -->
    <div class="summary">
      <table class="summary-table">
        <tr>
          <td>税抜合計</td>
          <td>${formatYen(invoice.total_ex_tax)}</td>
        </tr>
        <tr>
          <td>消費税額 (${Math.round(taxRate * 100)}%)</td>
          <td>${formatYen(invoice.tax_amount)}</td>
        </tr>
        <tr>
          <td>税込合計</td>
          <td>${formatYen(invoice.total_in_tax)}</td>
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
