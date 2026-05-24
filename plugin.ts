import { cp, mkdir, readFile, writeFile, stat } from "node:fs/promises"
import { join } from "node:path"
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

  const commandsTarget = join(targetDir, "commands")
  const skillsTarget = join(targetDir, "skills")
  const agentsTarget = join(targetDir, "agents")

  await mkdir(commandsTarget, { recursive: true })
  await mkdir(skillsTarget, { recursive: true })
  await mkdir(agentsTarget, { recursive: true })

  await cp(join(resourcesDir, "commands"), commandsTarget, {
    recursive: true,
    force: false,
    errorOnExist: false,
  })

  await cp(join(resourcesDir, "skills"), skillsTarget, {
    recursive: true,
    force: false,
    errorOnExist: false,
  })

  await cp(join(resourcesDir, "agents"), agentsTarget, {
    recursive: true,
    force: false,
    errorOnExist: false,
  })

  await writeFile(markerPath, new Date().toISOString())
}

export const TachesPlugin: Plugin = async ({ directory, client }) => {
  const resourcesDir = join(import.meta.dir, "resources")
  const opencodeDir = join(directory, ".opencode")

  try {
    await installResources(opencodeDir, resourcesDir)
    await client.app.log({
      body: {
        service: "taches-plugin",
        level: "info",
        message: "Resources installed successfully",
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
