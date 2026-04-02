describe('Price Calculator', () => {
  it('calculates discounted price correctly', () => {
    const unitPrice = 1000
    const discountRate = 10
    const discountedPrice = Math.round(unitPrice * (100 - discountRate) / 100)
    expect(discountedPrice).toBe(900)
  })

  it('calculates tax correctly', () => {
    const totalExTax = 10000
    const taxRate = 0.08
    const taxAmount = Math.round(totalExTax * taxRate)
    expect(taxAmount).toBe(800)
  })

  it('handles zero discount rate', () => {
    const unitPrice = 1000
    const discountRate = 0
    const discountedPrice = Math.round(unitPrice * (100 - discountRate) / 100)
    expect(discountedPrice).toBe(1000)
  })
})
