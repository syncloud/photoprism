import { test, expect } from '@playwright/test'
import { shoot } from '../helpers/screenshot'

const deviceUser = required('PLAYWRIGHT_DEVICE_USER')
const devicePassword = required('PLAYWRIGHT_DEVICE_PASSWORD')

function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`${name} is required`)
  return v
}

test.describe('login page', () => {
  test('renders login form', async ({ page }, testInfo) => {
    await page.goto('/')
    await expect(page.locator('input[name="username"]')).toBeVisible({ timeout: 60_000 })
    await expect(page.locator('input[name="password"]')).toBeVisible()
    await shoot(page, testInfo, 'login')
  })

  test('logs in with syncloud user', async ({ page }, testInfo) => {
    await page.goto('/')
    await page.locator('input[name="username"]').fill(deviceUser)
    await page.locator('input[name="password"]').fill(devicePassword)
    await shoot(page, testInfo, 'login-filled')
    await page.locator('.action-confirm').click()
    await expect(page.locator('#p-navigation')).toBeVisible({ timeout: 30_000 })
    await expect(page).toHaveURL(/\/library\/(?!login)/)
    await shoot(page, testInfo, 'logged-in')
  })
})
