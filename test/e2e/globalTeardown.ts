import { ssh, scpFrom } from './helpers/ssh'
import * as path from 'node:path'
import * as fs from 'node:fs'
import { execSync } from 'node:child_process'

const TMP_DIR = '/tmp/syncloud/photoprism-ui'
const artifactRoot = process.env.PLAYWRIGHT_ARTIFACT_DIR ?? 'artifact'

export default async function () {
  const project = process.env.PLAYWRIGHT_PROJECT ?? 'desktop'
  const out = path.join(artifactRoot, 'playwright', project)
  fs.mkdirSync(out, { recursive: true })

  ssh(`mkdir -p ${TMP_DIR}`, { throw: false })
  ssh(`journalctl > ${TMP_DIR}/journalctl.log`, { throw: false })
  ssh(`ls -la /var/snap/photoprism/current/config > ${TMP_DIR}/config.ls.log`, { throw: false })
  ssh(`cat /var/snap/photoprism/current/config/photoprism.env > ${TMP_DIR}/photoprism.env`, { throw: false })
  ssh(`cat /var/snap/photoprism/current/config/options.yml > ${TMP_DIR}/options.yml`, { throw: false })
  ssh(`cat /proc/$(pgrep -of '/snap/photoprism/.*photoprism --config-path')/environ | tr '\\0' '\\n' > ${TMP_DIR}/photoprism.web.environ`, { throw: false })
  ssh(`snap run photoprism.cli users ls > ${TMP_DIR}/photoprism-users.txt 2>&1`, { throw: false })
  ssh(`ls -la /data/photoprism > ${TMP_DIR}/data.ls.log`, { throw: false })
  scpFrom(`${TMP_DIR}/*`, out, { throw: false })
  try { execSync(`chmod -R a+r ${out}`) } catch {}
}
