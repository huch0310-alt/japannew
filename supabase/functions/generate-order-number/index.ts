import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseKey)

  const today = new Date().toISOString().split('T')[0].replace(/-/g, '')
  const prefix = `ORD-${today}-`

  // 查询当天最大订单号
  const { data, error } = await supabase
    .from('orders')
    .select('order_number')
    .like('order_number', `${prefix}%`)
    .order('order_number', { ascending: false })
    .limit(1)

  let sequence = 1
  if (data && data.length > 0) {
    const lastNumber = data[0].order_number
    const lastSeq = parseInt(lastNumber.split('-')[2])
    sequence = lastSeq + 1
  }

  const orderNumber = `${prefix}${String(sequence).padStart(3, '0')}`

  return new Response(JSON.stringify({ orderNumber }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
