import { test, expect, Page } from '@playwright/test'
import * as path from 'node:path'
import { shoot } from '../helpers/screenshot'
import { ssh } from '../helpers/ssh'

const regularPassword = 'regularpass123'
const uploadImage = path.resolve(process.cwd(), '../images/user1-upload.jpg')

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
  await expect(page.locator('.photo-results .media.result')).toHaveCount(expectedThumbs, { timeout: 60_000 })
}

test.describe('photoprism upload', () => {
  test('regularuser1 uploads via UI into own per-user library', async ({ page }, testInfo) => {
    await signIn(page, 'regularuser1', regularPassword)
    await openBrowse(page, 2)

    await page.locator('.p-page-photos .action-menu__btn').click()
    await page.locator('.action-menu__item.action-upload').click()
    await expect(page.locator('.p-upload-dialog')).toBeVisible({ timeout: 10_000 })

    await page.locator('.p-upload-dialog .input-upload').setInputFiles(uploadImage)
    await expect(page.locator('.p-upload-dialog')).toBeHidden({ timeout: 120_000 })

    await page.reload()
    await openBrowse(page, 3)
    await shoot(page, testInfo, 'regularuser1-after-upload')

    const listing = ssh('find /data/photoprism/photos/originals/users/regularuser1 -type f')
    const files = listing.trim().split('\n').filter(Boolean)
    expect(files.length, `expected >=3 files under regularuser1 originals, got:\n${listing}`).toBeGreaterThanOrEqual(3)
  })
})
