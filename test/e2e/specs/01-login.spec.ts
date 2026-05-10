import { test, expect, Page } from '@playwright/test'
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

async function signInViaOidc(page: Page) {
  await page.goto('/')
  await page.locator('#username-textfield').fill(deviceUser)
  await page.locator('#password-textfield').fill(devicePassword)
  await page.locator('#sign-in-button').click()
  await expect(page.locator('.action-search')).toBeVisible({ timeout: 30_000 })
}

test.beforeAll(async () => {
  await addHostAlias('auth', deviceHost, fullDomain)
})

test.describe('photoprism', () => {
  test('signs in via authelia oidc', async ({ page }, testInfo) => {
    await signInViaOidc(page)
    await shoot(page, testInfo, 'logged-in')
  })

  test('generated app password authenticates webdav', async ({ page, request }, testInfo) => {
    await signInViaOidc(page)

    await page.locator('.nav-settings').first().click()
    await page.locator('.action-apps-dialog').click()
    await page.locator('.action-add').click()
    await page.locator('input[name="client_name"]').fill('e2e webdav')
    await page.locator('.input-scope').click()
    await page.getByRole('option', { name: 'WebDAV' }).click()
    await page.locator('.action-generate').click()
    const token = await page.locator('.input-app-password input').inputValue()
    await shoot(page, testInfo, 'app-password-generated')
    expect(token).toBeTruthy()

    const auth = 'Basic ' + Buffer.from(`${deviceUser}:${token}`).toString('base64')
    const propfind = await request.fetch(`https://${process.env.PLAYWRIGHT_APP_DOMAIN}/originals/`, {
      method: 'PROPFIND',
      headers: { Authorization: auth, Depth: '0' },
      ignoreHTTPSErrors: true,
    })
    expect(propfind.status()).toBe(207)
  })
})
