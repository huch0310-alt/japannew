'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { UserTable } from './_components/user-table'
import { UserDialog } from '@/components/user-dialog'
import { Plus } from 'lucide-react'
import type { User } from './_components/user-table'

// Mock数据
const mockUsers = [
  { id: '1', name: '山田太郎', email: 'yamada@abc.co.jp', role: 'purchaser', isActive: true },
  { id: '2', name: '佐藤花子', email: 'sato@freshbiz.jp', role: 'sales_manager', isActive: true },
  { id: '3', name: 'ABC株式会社', email: 'order@abc.co.jp', role: 'customer', isActive: true, companyName: 'ABC株式会社' },
]

export default function UsersPage() {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [selectedUser, setSelectedUser] = useState<User | null>(null)

  const handleEdit = (user: User) => {
    setSelectedUser(user)
    setDialogOpen(true)
  }

  const handleCreate = () => {
    setSelectedUser(null)
    setDialogOpen(true)
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">ユーザー管理</h1>
        <Button onClick={handleCreate}>
          <Plus className="h-4 w-4 mr-2" />
          新規作成
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>ユーザーリスト</CardTitle>
        </CardHeader>
        <CardContent>
          <UserTable users={mockUsers} onEdit={handleEdit} />
        </CardContent>
      </Card>

      <UserDialog open={dialogOpen} onOpenChange={setDialogOpen} user={selectedUser} />
    </div>
  )
}