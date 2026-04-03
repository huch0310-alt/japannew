'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient, isConfigured } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { toast } from 'sonner'

export function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [configured, setConfigured] = useState(true)
  const router = useRouter()

  useEffect(() => {
    setConfigured(isConfigured())
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!configured) {
      toast.error('Supabaseが設定されていません', {
        description: '.env.localにNEXT_PUBLIC_SUPABASE_URLとNEXT_PUBLIC_SUPABASE_ANON_KEYを設定してください',
      })
      return
    }

    setLoading(true)

    try {
      const supabase = createClient()
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) {
        toast.error('エラー', {
          description: error.message,
        })
      } else {
        toast.success('ログインしました')
        router.push('/dashboard')
      }
    } catch (err) {
      toast.error('エラー', {
        description: 'Supabase接続に失敗しました',
      })
    } finally {
      setLoading(false)
    }
  }

  if (!configured) {
    return (
      <div className="space-y-4">
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-md text-sm text-yellow-800">
          <p className="font-medium">⚠️ Supabaseが設定されていません</p>
          <p className="mt-1">.env.localに環境変数を設定してください：</p>
          <ul className="mt-2 ml-4 list-disc text-xs">
            <li>NEXT_PUBLIC_SUPABASE_URL</li>
            <li>NEXT_PUBLIC_SUPABASE_ANON_KEY</li>
          </ul>
        </div>
        <Button disabled className="w-full">
          ログイン
        </Button>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Input
        type="email"
        placeholder="メールアドレス"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <Input
        type="password"
        placeholder="パスワード"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      <Button type="submit" className="w-full" disabled={loading}>
        {loading ? 'ログイン中...' : 'ログイン'}
      </Button>
    </form>
  )
}
