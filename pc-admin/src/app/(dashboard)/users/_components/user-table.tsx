'use client'

import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { UserDialog } from '@/components/user-dialog'

interface User {
  id: string
  email: string
  phone?: string
  name: string
  role: string
  isActive: boolean
  companyName?: string
}

interface UserTableProps {
  users: User[]
  onEdit: (user: User) => void
}

export function UserTable({ users, onEdit }: UserTableProps) {
  const roleLabels: Record<string, string> = {
    super_admin: '超级管理员',
    sales_manager: '销售主管',
    purchaser: '采购人员',
    customer: '客户',
  }

  return (
    <table className="w-full text-sm">
      <thead>
        <tr className="bg-gray-50">
          <th className="text-left p-3 font-medium">名前</th>
          <th className="text-left p-3 font-medium">メール/電話</th>
          <th className="text-left p-3 font-medium">役割</th>
          <th className="text-left p-3 font-medium">会社</th>
          <th className="text-center p-3 font-medium">状態</th>
          <th className="text-right p-3 font-medium">操作</th>
        </tr>
      </thead>
      <tbody>
        {users.map((user) => (
          <tr key={user.id} className="border-t hover:bg-gray-50">
            <td className="p-3 font-medium">{user.name}</td>
            <td className="p-3 text-gray-600">{user.email || user.phone}</td>
            <td className="p-3">
              <Badge variant="outline">{roleLabels[user.role] || user.role}</Badge>
            </td>
            <td className="p-3 text-gray-600">{user.companyName || '-'}</td>
            <td className="p-3 text-center">
              <Badge variant={user.isActive ? 'default' : 'secondary'}>
                {user.isActive ? '有効' : '無効'}
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