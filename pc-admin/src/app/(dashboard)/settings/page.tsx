'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export default function SettingsPage() {
  const [companyInfo, setCompanyInfo] = useState({
    companyName: 'FreshBiz株式会社',
    address: '大阪府大阪市北区梅田1-1-1',
    phone: '06-1234-5678',
    taxId: '6123456789012',
    bankName: '大阪銀行',
    bankBranch: '本店',
    bankAccountType: '普通',
    bankAccountNumber: '1234567',
  })

  const [taxSettings, setTaxSettings] = useState({
    taxRate: '8',
    paymentTermDays: '30',
  })

  const handleSave = () => {
    // TODO: 設定を保存
    console.log('Save settings')
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
                  <Input value={companyInfo.companyName} onChange={(e) => setCompanyInfo({ ...companyInfo, companyName: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>電話番号</Label>
                  <Input value={companyInfo.phone} onChange={(e) => setCompanyInfo({ ...companyInfo, phone: e.target.value })} />
                </div>
              </div>
              <div className="space-y-2">
                <Label>住所</Label>
                <Input value={companyInfo.address} onChange={(e) => setCompanyInfo({ ...companyInfo, address: e.target.value })} />
              </div>
              <div className="space-y-2">
                <Label>税号</Label>
                <Input value={companyInfo.taxId} onChange={(e) => setCompanyInfo({ ...companyInfo, taxId: e.target.value })} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>銀行名</Label>
                  <Input value={companyInfo.bankName} onChange={(e) => setCompanyInfo({ ...companyInfo, bankName: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>支店名</Label>
                  <Input value={companyInfo.bankBranch} onChange={(e) => setCompanyInfo({ ...companyInfo, bankBranch: e.target.value })} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>口座種別</Label>
                  <Input value={companyInfo.bankAccountType} onChange={(e) => setCompanyInfo({ ...companyInfo, bankAccountType: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>口座番号</Label>
                  <Input value={companyInfo.bankAccountNumber} onChange={(e) => setCompanyInfo({ ...companyInfo, bankAccountNumber: e.target.value })} />
                </div>
              </div>
              <div className="flex justify-end">
                <Button onClick={handleSave}>保存</Button>
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
                  <Input type="number" value={taxSettings.taxRate} onChange={(e) => setTaxSettings({ ...taxSettings, taxRate: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>デフォルト支払期限 (日)</Label>
                  <Input type="number" value={taxSettings.paymentTermDays} onChange={(e) => setTaxSettings({ ...taxSettings, paymentTermDays: e.target.value })} />
                </div>
              </div>
              <div className="flex justify-end">
                <Button onClick={handleSave}>保存</Button>
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
              <div className="flex justify-end mt-4">
                <Button onClick={handleSave}>保存</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}