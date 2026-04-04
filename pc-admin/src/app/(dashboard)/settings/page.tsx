'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { supabaseApi, DbSystemSettings } from '@/lib/supabase'
import { toast } from 'sonner'

export default function SettingsPage() {
  const [settings, setSettings] = useState<DbSystemSettings | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)

  const [companyInfo, setCompanyInfo] = useState({
    companyName: '',
    address: '',
    phone: '',
    taxId: '',
    bankName: '',
    bankBranch: '',
    bankAccountType: '普通',
    bankAccountNumber: '',
  })

  const [taxSettings, setTaxSettings] = useState({
    taxRate: '8',
    paymentTermDays: '30',
  })

  const loadSettings = useCallback(async () => {
    setIsLoading(true)
    try {
      const data = await supabaseApi.getSystemSettings()
      if (data) {
        setSettings(data)
        setCompanyInfo({
          companyName: data.company_name || '',
          address: data.company_address || '',
          phone: data.company_phone || '',
          taxId: data.tax_id || '',
          bankName: data.bank_name || '',
          bankBranch: data.bank_branch || '',
          bankAccountType: data.bank_account_type || '普通',
          bankAccountNumber: data.bank_account_number || '',
        })
        setTaxSettings({
          taxRate: (data.tax_rate * 100).toString(),
          paymentTermDays: data.default_payment_term_days.toString(),
        })
      }
    } catch (err) {
      console.error('Failed to load settings:', err)
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    loadSettings()
  }, [loadSettings])

  const handleSaveCompany = async () => {
    setIsSaving(true)
    try {
      await supabaseApi.updateSystemSettings({
        company_name: companyInfo.companyName,
        company_address: companyInfo.address,
        company_phone: companyInfo.phone,
        tax_id: companyInfo.taxId,
        bank_name: companyInfo.bankName,
        bank_branch: companyInfo.bankBranch,
        bank_account_type: companyInfo.bankAccountType,
        bank_account_number: companyInfo.bankAccountNumber,
      })
      toast.success('保存しました')
    } catch (err) {
      console.error('Failed to save company settings:', err)
      toast.error('保存に失敗しました')
    } finally {
      setIsSaving(false)
    }
  }

  const handleSaveTax = async () => {
    setIsSaving(true)
    try {
      await supabaseApi.updateSystemSettings({
        tax_rate: parseFloat(taxSettings.taxRate) / 100,
        default_payment_term_days: parseInt(taxSettings.paymentTermDays),
      })
      toast.success('保存しました')
    } catch (err) {
      console.error('Failed to save tax settings:', err)
      toast.error('保存に失敗しました')
    } finally {
      setIsSaving(false)
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">読み込み中...</div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">システム設定</h1>

      <Tabs defaultValue="company">
        <TabsList>
          <TabsTrigger value="company">会社情報</TabsTrigger>
          <TabsTrigger value="tax">全局設定</TabsTrigger>
          <TabsTrigger value="print">印刷設定</TabsTrigger>
        </TabsList>

        <TabsContent value="company" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>会社情報</CardTitle>
              <CardDescription>請求書に表示される会社情報を設定します</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>会社名</Label>
                  <Input
                    value={companyInfo.companyName}
                    onChange={(e) => setCompanyInfo({ ...companyInfo, companyName: e.target.value })}
                    placeholder="FreshBiz株式会社"
                  />
                </div>
                <div className="space-y-2">
                  <Label>電話番号</Label>
                  <Input
                    value={companyInfo.phone}
                    onChange={(e) => setCompanyInfo({ ...companyInfo, phone: e.target.value })}
                    placeholder="06-1234-5678"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label>住所</Label>
                <Input
                  value={companyInfo.address}
                  onChange={(e) => setCompanyInfo({ ...companyInfo, address: e.target.value })}
                  placeholder="大阪府大阪市北区梅田1-1-1"
                />
              </div>
              <div className="space-y-2">
                <Label>税号</Label>
                <Input
                  value={companyInfo.taxId}
                  onChange={(e) => setCompanyInfo({ ...companyInfo, taxId: e.target.value })}
                  placeholder="6123456789012"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>銀行名</Label>
                  <Input
                    value={companyInfo.bankName}
                    onChange={(e) => setCompanyInfo({ ...companyInfo, bankName: e.target.value })}
                    placeholder="大阪銀行"
                  />
                </div>
                <div className="space-y-2">
                  <Label>支店名</Label>
                  <Input
                    value={companyInfo.bankBranch}
                    onChange={(e) => setCompanyInfo({ ...companyInfo, bankBranch: e.target.value })}
                    placeholder="本店"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>口座種別</Label>
                  <Input
                    value={companyInfo.bankAccountType}
                    onChange={(e) => setCompanyInfo({ ...companyInfo, bankAccountType: e.target.value })}
                    placeholder="普通"
                  />
                </div>
                <div className="space-y-2">
                  <Label>口座番号</Label>
                  <Input
                    value={companyInfo.bankAccountNumber}
                    onChange={(e) => setCompanyInfo({ ...companyInfo, bankAccountNumber: e.target.value })}
                    placeholder="1234567"
                  />
                </div>
              </div>
              <div className="flex justify-end">
                <Button onClick={handleSaveCompany} disabled={isSaving}>
                  {isSaving ? '保存中...' : '保存'}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="tax" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>全局設定</CardTitle>
              <CardDescription>消費税率等の全局設定を行います</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>消費税率 (%)</Label>
                  <Input
                    type="number"
                    value={taxSettings.taxRate}
                    onChange={(e) => setTaxSettings({ ...taxSettings, taxRate: e.target.value })}
                    placeholder="8"
                  />
                </div>
                <div className="space-y-2">
                  <Label>デフォルト支払期限 (日)</Label>
                  <Input
                    type="number"
                    value={taxSettings.paymentTermDays}
                    onChange={(e) => setTaxSettings({ ...taxSettings, paymentTermDays: e.target.value })}
                    placeholder="30"
                  />
                </div>
              </div>
              <div className="flex justify-end">
                <Button onClick={handleSaveTax} disabled={isSaving}>
                  {isSaving ? '保存中...' : '保存'}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="print" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>印刷設定</CardTitle>
              <CardDescription>請求書・分拣单の印刷設定を行います</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-gray-500">印刷テンプレートのカスタマイズ機能は開発予定</p>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}