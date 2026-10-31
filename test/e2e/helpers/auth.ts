import { Page, expect } from '@playwright/test'
import { ssh } from './ssh'

export async function signIn(page: Page, user: string, password: string) {
  await page.goto('/')
  await expect(page.locator('#username-textfield')).toBeVisible({ timeout: 30_000 })
  await page.locator('#username-textfield').fill(user)
  await page.locator('#password-textfield').fill(password)
  await page.locator('#sign-in-button').click()
  await expect(page.locator('.nav-sidebar')).toBeVisible({ timeout: 30_000 })
}

export function createAppPassword(user: string): string {
  const output = ssh(`snap run photoprism.cli auth add --name gallery --scope '*' --expires -1 ${user}`)
  const match = output.match(/[0-9A-Za-z]{6}-[0-9A-Za-z]{6}-[0-9A-Za-z]{6}-[0-9A-Za-z]{6}/)
  if (!match) throw new Error(`no app password in:\n${output}`)
  return match[0]
}
