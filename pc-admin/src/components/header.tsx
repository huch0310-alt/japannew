'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

export function Header() {
  const router = useRouter()
  const supabase = createClient()
  const [language, setLanguage] = useState('ja')

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <header className="h-14 bg-primary text-white px-6 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <span className="text-lg font-bold">🛒 FreshBiz</span>
        <span className="text-sm opacity-80">管理后台</span>
      </div>

      <div className="flex items-center gap-4">
        <Select value={language} onValueChange={(v) => setLanguage(v || 'ja')}>
          <SelectTrigger className="w-24 bg-transparent border-white/30 text-white">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ja">日本語</SelectItem>
            <SelectItem value="zh">中文</SelectItem>
          </SelectContent>
        </Select>

        <Button
          variant="ghost"
          className="text-white hover:bg-white/20"
          onClick={handleLogout}
        >
          退出
        </Button>
      </div>
    </header>
  )
}
