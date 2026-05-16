import { test, expect, Page } from '@playwright/test'
import { shoot } from '../helpers/screenshot'

const deviceUser = required('PLAYWRIGHT_DEVICE_USER')
const devicePassword = required('PLAYWRIGHT_DEVICE_PASSWORD')
const appDomain = required('PLAYWRIGHT_APP_DOMAIN')
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

async function openBrowse(page: Page, expectedThumbs: number) {
  await page.locator('.nav-browse').first().click()
  await expect(page.locator('.p-page-photos')).toBeVisible({ timeout: 30_000 })
  await expect(page.locator('.photo-results .media.result')).toHaveCount(expectedThumbs, { timeout: 30_000 })
}

test.describe('photoprism', () => {
  test('admin signs in and sees every user library', async ({ page }, testInfo) => {
    await signIn(page, deviceUser, devicePassword)
    await openBrowse(page, 6)
    await shoot(page, testInfo, 'admin-library')
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

  test('regularuser1 only sees their own pictures', async ({ page }, testInfo) => {
    await signIn(page, 'regularuser1', regularPassword)
    await openBrowse(page, 2)
    await shoot(page, testInfo, 'regularuser1-library')
  })

  test('regularuser2 only sees their own pictures', async ({ page }, testInfo) => {
    await signIn(page, 'regularuser2', regularPassword)
    await openBrowse(page, 2)
    await shoot(page, testInfo, 'regularuser2-library')
  })
})
