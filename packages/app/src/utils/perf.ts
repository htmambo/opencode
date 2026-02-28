type NavParamsInput = {
  dir?: string
  from?: string
  to?: string
}

type NavMarkInput = {
  dir?: string
  to?: string
  name: string
}

const mark = (name: string) => {
  if (!import.meta.env.DEV) return
  if (typeof performance === "undefined") return
  if (typeof performance.mark !== "function") return
  performance.mark(name)
}

export const navParams = (input: NavParamsInput) => {
  const dir = input.dir ?? "unknown"
  const from = input.from ?? "new"
  const to = input.to ?? "unknown"
  mark(`nav:params:${dir}:${from}:${to}`)
}

export const navMark = (input: NavMarkInput) => {
  const dir = input.dir ?? "unknown"
  const to = input.to ?? "unknown"
  mark(`nav:mark:${dir}:${to}:${input.name}`)
}
