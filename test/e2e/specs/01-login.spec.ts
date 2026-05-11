import { test, expect, Page } from '@playwright/test'
import { shoot } from '../helpers/screenshot'

const deviceUser = required('PLAYWRIGHT_DEVICE_USER')
const devicePassword = required('PLAYWRIGHT_DEVICE_PASSWORD')
const appDomain = required('PLAYWRIGHT_APP_DOMAIN')
const regularUser = 'regularuser'
const regularPassword = 'regularpass123'

function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`${name} is required`)
  return v
}

async function signIn(page: Page, user: string, password: string) {
  await page.goto('/')
  await page.locator('input[name="username"]').fill(user)
  await page.locator('input[name="password"]').fill(password)
  await page.locator('.action-confirm').click()
  await expect(page.locator('.nav-sidebar')).toBeVisible({ timeout: 30_000 })
}

test.describe('photoprism', () => {
  test('admin signs in with syncloud password', async ({ page }, testInfo) => {
    await signIn(page, deviceUser, devicePassword)
    await expect(page.locator('.nav-library').first()).toBeVisible()
    await shoot(page, testInfo, 'admin-logged-in')
  })

  test('webdav accepts syncloud password basic auth', async ({ request }) => {
    const auth = 'Basic ' + Buffer.from(`${deviceUser}:${devicePassword}`).toString('base64')
    const resp = await request.fetch(`https://${appDomain}/originals/`, {
      method: 'PROPFIND',
      headers: { Authorization: auth, Depth: '0' },
      ignoreHTTPSErrors: true,
    })
    expect(resp.status()).toBe(207)
  })

  test('non-admin syncloud user cannot sign in', async ({ page }, testInfo) => {
    // photoprism CE treats non-admin LDAP users as Visitor role (the
    // share-link role), and Visitor.IsRegistered() is false so web login
    // is gated off. The credentials bind successfully against slapd and
    // a user row is created, but the sign-in click does not navigate.
    await page.goto('/')
    await page.locator('input[name="username"]').fill(regularUser)
    await page.locator('input[name="password"]').fill(regularPassword)
    await page.locator('.action-confirm').click()
    await expect(page.locator('input[name="username"]')).toBeVisible({ timeout: 5_000 })
    await expect(page.locator('.nav-sidebar')).toHaveCount(0)
    await shoot(page, testInfo, 'regular-rejected')
  })
})
