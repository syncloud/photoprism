import { test, expect, Page } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import { signIn, createAppPassword } from '../helpers/auth'

const deviceUser = required('PLAYWRIGHT_DEVICE_USER')
const devicePassword = required('PLAYWRIGHT_DEVICE_PASSWORD')
const appDomain = required('PLAYWRIGHT_APP_DOMAIN')
const regularPassword = 'regularpass123'
const spacePassword = ' space pass123 '

function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`${name} is required`)
  return v
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

  test('gallery app signs in with an app password', async ({ request }) => {
    const appPassword = createAppPassword(deviceUser)
    const session = await request.post(`https://${appDomain}/api/v1/session`, {
      data: { username: deviceUser, password: appPassword },
      ignoreHTTPSErrors: true,
    })
    expect(session.status()).toBe(200)

    const auth = 'Basic ' + Buffer.from(`${deviceUser}:${appPassword}`).toString('base64')
    const webdav = await request.fetch(`https://${appDomain}/originals/`, {
      method: 'PROPFIND',
      headers: { Authorization: auth, Depth: '0' },
      ignoreHTTPSErrors: true,
    })
    expect(webdav.status()).toBe(207)
  })

  test('gallery app signs in with the syncloud password', async ({ request }) => {
    const withAppPassword = await request.post(`https://${appDomain}/api/v1/session`, {
      data: { username: deviceUser, password: createAppPassword(deviceUser) },
      ignoreHTTPSErrors: true,
    })
    expect(withAppPassword.status()).toBe(200)

    const session = await request.post(`https://${appDomain}/api/v1/session`, {
      data: { username: deviceUser, password: devicePassword },
      ignoreHTTPSErrors: true,
    })
    expect(session.status()).toBe(200)
    expect((await session.json()).user.UID).toBe((await withAppPassword.json()).user.UID)

    const auth = 'Basic ' + Buffer.from(`${deviceUser}:${devicePassword}`).toString('base64')
    const webdav = await request.fetch(`https://${appDomain}/originals/`, {
      method: 'PROPFIND',
      headers: { Authorization: auth, Depth: '0' },
      ignoreHTTPSErrors: true,
    })
    expect(webdav.status()).toBe(207)
  })

  test('a password with leading and trailing spaces signs in through the api', async ({ request }) => {
    const session = await request.post(`https://${appDomain}/api/v1/session`, {
      data: { username: 'spaceuser', password: spacePassword },
      ignoreHTTPSErrors: true,
    })
    expect(session.status()).toBe(200)
  })

  test('a wrong syncloud password does not sign in through the api', async ({ request }) => {
    const session = await request.post(`https://${appDomain}/api/v1/session`, {
      data: { username: deviceUser, password: devicePassword + 'x' },
      ignoreHTTPSErrors: true,
    })
    expect(session.status()).toBe(401)
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

  test('a password with leading and trailing spaces signs in', async ({ page }) => {
    await signIn(page, 'spaceuser', spacePassword)
  })

  test('regularuser1 sees favorites + places nav and routes load', async ({ page }, testInfo) => {
    await signIn(page, 'regularuser1', regularPassword)
    await expect(page.locator('.nav-favorites').first()).toBeVisible()
    await expect(page.locator('.nav-places').first()).toBeVisible()

    await page.locator('.nav-favorites').first().click()
    await expect(page).toHaveURL(/\/favorites/, { timeout: 30_000 })
    await expect(page.locator('.photo-results .media.result')).toHaveCount(0)
    await shoot(page, testInfo, 'regularuser1-favorites-empty')

    await page.locator('.nav-places').first().click()
    await expect(page).toHaveURL(/\/places/, { timeout: 30_000 })
    await shoot(page, testInfo, 'regularuser1-places')
  })
})
