import { test, expect, Page } from '@playwright/test'
import * as path from 'node:path'
import { shoot } from '../helpers/screenshot'
import { ssh } from '../helpers/ssh'
import { signIn } from '../helpers/auth'

const regularPassword = 'regularpass123'
const uploadImage = path.resolve(process.cwd(), '../images/user1-upload.jpg')

function originals(): string[] {
  return ssh('find /data/photoprism/photos/originals/users/regularuser1 -type f').trim().split('\n').filter(Boolean)
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
    await shoot(page, testInfo, 'regularuser1-upload-dialog')

    await page.locator('.p-upload-dialog .input-file-upload input[type="file"]').setInputFiles(uploadImage)
    await page.locator('.p-upload-dialog .action-upload').click()
    await expect.poll(() => originals().length, { timeout: 120_000 }).toBeGreaterThanOrEqual(3)
    await expect(page.locator('.p-upload-dialog')).toBeHidden({ timeout: 120_000 })

    await page.reload()
    await openBrowse(page, 3)
    await shoot(page, testInfo, 'regularuser1-after-upload')

    expect(originals().length).toBeGreaterThanOrEqual(3)
  })
})
