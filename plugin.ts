import { cp, mkdir, writeFile, stat } from "node:fs/promises"
import { join, dirname } from "node:path"
import { homedir } from "node:os"
import type { Plugin } from "@opencode-ai/plugin"

const MARKER = ".taches-plugin-installed"

async function exists(path: string): Promise<boolean> {
  try {
    await stat(path)
    return true
  } catch {
    return false
  }
}

async function installResources(targetDir: string, resourcesDir: string): Promise<void> {
  const markerPath = join(targetDir, MARKER)
  if (await exists(markerPath)) return

  await mkdir(join(targetDir, "commands"), { recursive: true })
  await mkdir(join(targetDir, "skills"), { recursive: true })
  await mkdir(join(targetDir, "agents"), { recursive: true })

  await cp(join(resourcesDir, "commands"), join(targetDir, "commands"), { recursive: true, force: false, errorOnExist: false })
  await cp(join(resourcesDir, "skills"), join(targetDir, "skills"), { recursive: true, force: false, errorOnExist: false })
  await cp(join(resourcesDir, "agents"), join(targetDir, "agents"), { recursive: true, force: false, errorOnExist: false })

  await writeFile(markerPath, new Date().toISOString())
}

export const TachesPlugin: Plugin = async ({ directory, client }) => {
  const resourcesDir = join(import.meta.dir, "resources")
  const pluginDir = import.meta.dir
  const globalPluginsDir = join(homedir(), ".config", "opencode", "plugins")
  const isGlobal = pluginDir.startsWith(globalPluginsDir)

  const installDir = isGlobal
    ? join(homedir(), ".config", "opencode")
    : join(directory, ".opencode")

  try {
    await installResources(installDir, resourcesDir)
    await client.app.log({
      body: {
        service: "taches-plugin",
        level: "info",
        message: `Resources installed to ${installDir}`,
      },
    })
  } catch (err: any) {
    await client.app.log({
      body: {
        service: "taches-plugin",
        level: "error",
        message: `Failed to install resources: ${err.message}`,
      },
    })
  }

  return {}
}
