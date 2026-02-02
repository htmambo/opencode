const run = (cwd: string, cmd: string[]) => Bun.spawn(cmd, { cwd, stdout: "inherit", stderr: "inherit" })

const backend = run("packages/opencode", [
  "bun",
  "run",
  "--conditions=browser",
  "./src/index.ts",
  "serve",
  "--port",
  "4096",
])

const app = run("packages/app", ["bun", "dev"])

const stop = (code: number) => {
  if (!backend.killed) backend.kill()
  if (!app.killed) app.kill()
  process.exit(code)
}

process.on("SIGINT", () => stop(130))
process.on("SIGTERM", () => stop(143))

const exited = await Promise.race([backend.exited, app.exited])
stop(exited)
