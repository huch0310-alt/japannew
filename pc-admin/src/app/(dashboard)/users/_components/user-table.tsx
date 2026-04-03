'use client'

import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { DbUser } from '@/lib/supabase'

interface UserTableProps {
  users: DbUser[]
  onEdit: (user: DbUser) => void
}

export function UserTable({ users, onEdit }: UserTableProps) {
  const roleLabels: Record<string, string> = {
    super_admin: '超級管理者',
    sales_manager: '営業マネージャー',
    purchaser: '仕入担当者',
    customer: '顧客',
  }

  if (users.length === 0) {
    return <div className="p-8 text-center text-gray-500">ユーザーがありません</div>
  }

  return (
    <table className="w-full text-sm">
      <thead>
        <tr className="bg-gray-50">
          <th className="text-left p-3 font-medium">名前</th>
          <th className="text-left p-3 font-medium">メール/電話</th>
          <th className="text-left p-3 font-medium">役割</th>
          <th className="text-center p-3 font-medium">状態</th>
          <th className="text-right p-3 font-medium">操作</th>
        </tr>
      </thead>
      <tbody>
        {users.map((user) => (
          <tr key={user.id} className="border-t hover:bg-gray-50">
            <td className="p-3 font-medium">{user.name}</td>
            <td className="p-3 text-gray-600">{user.email || user.phone || '-'}</td>
            <td className="p-3">
              <Badge variant="outline">{roleLabels[user.role] || user.role}</Badge>
            </td>
            <td className="p-3 text-center">
              <Badge variant={user.is_active ? 'default' : 'secondary'}>
                {user.is_active ? '有効' : '無効'}
              </Badge>
            </td>
            <td className="p-3 text-right">
              <Button variant="ghost" size="sm" onClick={() => onEdit(user)}>
                編集
              </Button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
