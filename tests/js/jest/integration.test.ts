describe('jest integration', () => {
  it('test 1', () => {
    expect(4).toBe(4)
  })

  it('test 2', () => {
    const a = 1
    const b = 2

    console.log(a)
    console.log(b)

    expect(a).toBe(b)
  })
})
