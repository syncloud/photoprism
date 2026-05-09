import { test, expect } from '@playwright/test'
import { addHostAlias } from '../helpers/hosts'
import { deviceHost } from '../helpers/ssh'
import { shoot } from '../helpers/screenshot'

const deviceUser = required('PLAYWRIGHT_DEVICE_USER')
const devicePassword = required('PLAYWRIGHT_DEVICE_PASSWORD')
const fullDomain = required('PLAYWRIGHT_FULL_DOMAIN')

function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`${name} is required`)
  return v
}

test.beforeAll(async () => {
  await addHostAlias('auth', deviceHost, fullDomain)
})

test.describe('login', () => {
  test('photoprism redirects to authelia and signs in', async ({ page }, testInfo) => {
    await page.goto('/')
    await expect(page).toHaveURL(new RegExp(`^https://auth\\.${fullDomain.replace(/\./g, '\\.')}/`), { timeout: 30_000 })
    await page.locator('#username-textfield').fill(deviceUser)
    await page.locator('#password-textfield').fill(devicePassword)
    await shoot(page, testInfo, 'authelia-filled')
    await page.locator('#sign-in-button').click()
    await expect(page.locator('#p-navigation')).toBeVisible({ timeout: 30_000 })
    await shoot(page, testInfo, 'logged-in')
  })
})
