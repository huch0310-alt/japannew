'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface SalesChartProps {
  data: { date: string; amount: number }[]
  className?: string
}

export function SalesChart({ data, className }: SalesChartProps) {
  const maxAmount = Math.max(...data.map((d) => d.amount))

  return (
    <Card className={className}>
      <CardHeader>
        <CardTitle>销售额趋势（近7日）</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-40 flex items-end justify-around gap-2">
          {data.map((item, index) => (
            <div key={index} className="flex flex-col items-center gap-2">
              <div
                className="w-10 bg-primary rounded-t transition-all"
                style={{
                  height: `${(item.amount / maxAmount) * 100}%`,
                  minHeight: '10px',
                }}
              />
              <span className="text-xs text-gray-500">{item.date}</span>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
