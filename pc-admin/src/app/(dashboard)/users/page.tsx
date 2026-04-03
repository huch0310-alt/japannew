export const dynamic = 'force-dynamic'

'use client'

import { useState, useEffect, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { UserTable } from './_components/user-table'
import { UserDialog } from '@/components/user-dialog'
import { Plus } from 'lucide-react'
import { supabaseApi, DbUser } from '@/lib/supabase'

export default function UsersPage() {
  const [users, setUsers] = useState<DbUser[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [dialogOpen, setDialogOpen] = useState(false)
  const [selectedUser, setSelectedUser] = useState<DbUser | null>(null)

  const loadUsers = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await supabaseApi.getUsers()
      setUsers(data)
    } catch (err) {
      console.error('Failed to load users:', err)
      setError('ユーザーの読み込みに失敗しました')
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    loadUsers()
  }, [loadUsers])

  const handleEdit = (user: DbUser) => {
    setSelectedUser(user)
    setDialogOpen(true)
  }

  const handleCreate = () => {
    setSelectedUser(null)
    setDialogOpen(true)
  }

  const handleDialogClose = (open: boolean) => {
    setDialogOpen(open)
    if (!open) {
      setSelectedUser(null)
      loadUsers()
    }
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

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle>ユーザーリスト</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="p-8 text-center text-gray-500">読み込み中...</div>
          ) : (
            <UserTable users={users} onEdit={handleEdit} />
          )}
        </CardContent>
      </Card>

      <UserDialog open={dialogOpen} onOpenChange={handleDialogClose} user={selectedUser} />
    </div>
  )
}
