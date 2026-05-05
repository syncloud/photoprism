import { test, expect } from '@playwright/test'
import { shoot } from '../helpers/screenshot'

test.describe('login page', () => {
  test('renders login form', async ({ page }, testInfo) => {
    await page.goto('/')
    await expect(page.locator('input[name="username"]')).toBeVisible({ timeout: 60_000 })
    await expect(page.locator('input[name="password"]')).toBeVisible()
    await shoot(page, testInfo, 'login')
  })
})
