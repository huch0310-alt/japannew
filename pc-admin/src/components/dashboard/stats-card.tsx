import { Card, CardContent } from '@/components/ui/card'
import { cn } from '@/lib/utils'

interface StatsCardProps {
  title: string
  value: string | number
  change?: string
  changeType?: 'increase' | 'decrease'
  icon: React.ReactNode
  iconColor?: string
}

export function StatsCard({
  title,
  value,
  change,
  changeType,
  icon,
  iconColor = 'text-primary',
}: StatsCardProps) {
  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm text-gray-500">{title}</p>
            <p className="text-2xl font-bold mt-1 font-mono">{value}</p>
            {change && (
              <p className={cn(
                'text-xs mt-1',
                changeType === 'increase' ? 'text-green-600' : 'text-red-600'
              )}>
                {changeType === 'increase' ? '▲' : '▼'} {change}
              </p>
            )}
          </div>
          <div className={cn('p-3 rounded-lg bg-gray-100', iconColor)}>
            {icon}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
