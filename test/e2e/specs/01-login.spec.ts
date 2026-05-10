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
  await page.goto('/api/v1/oidc/login')
  await page.waitForURL(new RegExp(`^https://auth\\.${fullDomain.replace(/\./g, '\\.')}/`), { timeout: 30_000 })
  await page.locator('#username-textfield').fill(deviceUser)
  await page.locator('#password-textfield').fill(devicePassword)
  await page.locator('#sign-in-button').click()
  await page.waitForURL(/\/library\/(?!login)/, { timeout: 30_000 })
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

    const tokenResp = await page.request.post('/api/v1/oauth/token', {
      headers: { 'Content-Type': 'application/json' },
      data: {
        grant_type: 'session',
        client_name: 'e2e webdav',
        scope: 'webdav',
        expires_in: 0,
        username: deviceUser,
      },
    })
    expect(tokenResp.status()).toBe(200)
    const token = (await tokenResp.json()).access_token as string
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
