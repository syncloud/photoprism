import * as fs from 'node:fs'
import * as dns from 'node:dns/promises'

export async function addHostAlias(alias: string, deviceHost: string, baseDomain: string): Promise<void> {
  const fqdn = `${alias}.${baseDomain}`
  const { address } = await dns.lookup(deviceHost)
  const line = `${address} ${fqdn}\n`
  if (!fs.readFileSync('/etc/hosts', 'utf8').includes(line)) {
    fs.appendFileSync('/etc/hosts', line)
  }
}
