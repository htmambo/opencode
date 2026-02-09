import { Button } from "@opencode-ai/ui/button"
import { Switch } from "@opencode-ai/ui/switch"
import { TextField } from "@opencode-ai/ui/text-field"
import { showToast } from "@opencode-ai/ui/toast"
import { For, Show, createEffect, createMemo, type Component, type JSX } from "solid-js"
import { createStore } from "solid-js/store"
import type { Config } from "@opencode-ai/sdk/v2/client"
import { useGlobalSync } from "@/context/global-sync"
import { useLanguage } from "@/context/language"

type JsonPrimitive = string | number | boolean | null
type Json = JsonPrimitive | Json[] | JsonRecord
interface JsonRecord {
  [key: string]: Json
}
type Path = Array<string | number>
type Mode = "visual" | "json"

const isRecord = (value: unknown): value is JsonRecord => {
  if (!value) return false
  if (typeof value !== "object") return false
  if (Array.isArray(value)) return false
  return true
}

const toRecord = (value: unknown): JsonRecord => {
  if (isRecord(value)) return value
  return {}
}

const title = (value: string) => {
  return value
    .replace(/[_-]+/g, " ")
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/\b\w/g, (match) => match.toUpperCase())
}

const formatJson = (value: JsonRecord) => {
  return JSON.stringify(value, null, 2)
}

const parseJson = (value: string) => {
  try {
    const parsed = JSON.parse(value) as Json
    if (!isRecord(parsed)) return
    return parsed
  } catch {
    return
  }
}

const getAtPath = (value: Json, path: Path): Json | undefined => {
  if (path.length === 0) return value
  const head = path[0]
  const rest = path.slice(1)

  if (Array.isArray(value)) {
    const index = typeof head === "number" ? head : Number(head)
    return getAtPath(value[index] as Json, rest)
  }

  if (isRecord(value)) {
    return getAtPath(value[String(head)] as Json, rest)
  }

  return
}

const updateAtPath = (value: Json, path: Path, next: Json): Json => {
  if (path.length === 0) return next
  const head = path[0]
  const rest = path.slice(1)

  if (Array.isArray(value)) {
    const index = typeof head === "number" ? head : Number(head)
    const list = value.slice()
    const current = list[index] as Json | undefined
    list[index] = rest.length === 0 ? next : updateAtPath(current ?? null, rest, next)
    return list
  }

  if (isRecord(value)) {
    const key = String(head)
    const current = value[key]
    return {
      ...value,
      [key]: rest.length === 0 ? next : updateAtPath(current ?? null, rest, next),
    }
  }

  return value
}

const defaultFor = (value: Json | undefined): Json => {
  if (typeof value === "string") return ""
  if (typeof value === "number") return 0
  if (typeof value === "boolean") return false
  if (Array.isArray(value)) return []
  if (isRecord(value)) return {}
  if (value === null) return null
  return ""
}

export const SettingsConfig: Component = () => {
  const globalSync = useGlobalSync()
  const language = useLanguage()

  const serverConfig = createMemo(() => toRecord(globalSync.data.config))
  const serverSignature = createMemo(() => JSON.stringify(serverConfig()))
  const serverJson = createMemo(() => formatJson(serverConfig()))

  const [store, setStore] = createStore({
    config: serverConfig(),
    json: serverJson(),
    saving: false,
    dirty: false,
    jsonDirty: false,
    mode: "visual" as Mode,
    path: [] as Path,
  })

  const setMode = (next: Mode) => {
    if (next === store.mode) return
    if (next === "json" && !store.jsonDirty) {
      setStore("json", formatJson(store.config))
    }
    setStore("mode", next)
  }

  const setJson = (value: string) => {
    const jsonDirty = value !== serverJson()
    const configDirty = JSON.stringify(store.config) !== serverSignature()
    setStore({
      json: value,
      jsonDirty,
      dirty: jsonDirty || configDirty,
    })
  }

  const setConfig = (next: JsonRecord) => {
    const configDirty = JSON.stringify(next) !== serverSignature()
    setStore({
      config: next,
      dirty: configDirty || store.jsonDirty,
    })
    if (!store.jsonDirty) {
      setStore("json", formatJson(next))
    }
  }

  createEffect(() => {
    const next = serverConfig()
    if (store.dirty) return
    setStore({
      config: next,
      json: formatJson(next),
      dirty: false,
      jsonDirty: false,
    })
  })

  const samePath = (left: Path, right: Path) => {
    if (left.length !== right.length) return false
    return left.every((value, index) => value === right[index])
  }

  const clampPath = (path: Path, config: JsonRecord) => {
    let next = path
    while (next.length > 0) {
      const value = getAtPath(config, next)
      if (Array.isArray(value)) return next
      if (isRecord(value)) return next
      next = next.slice(0, -1)
    }
    return []
  }

  const setPath = (path: Path) => {
    setStore("path", clampPath(path, store.config))
  }

  createEffect(() => {
    const next = clampPath(store.path, store.config)
    if (samePath(next, store.path)) return
    setStore("path", next)
  })

  const setValue = (path: Path, value: Json) => {
    setConfig(updateAtPath(store.config, path, value) as JsonRecord)
  }

  const updateArray = (path: Path, update: (value: Json[]) => Json[]) => {
    const current = getAtPath(store.config, path)
    if (!Array.isArray(current)) return
    setConfig(updateAtPath(store.config, path, update(current)) as JsonRecord)
  }

  const updateObject = (path: Path, update: (value: JsonRecord) => JsonRecord) => {
    const current = getAtPath(store.config, path)
    if (!isRecord(current)) return
    setConfig(updateAtPath(store.config, path, update(current)) as JsonRecord)
  }

  const nextKey = (value: JsonRecord) => {
    const base = "new_field"
    if (!(base in value)) return base
    let index = 1
    let key = `${base}_${index}`
    while (key in value) {
      index += 1
      key = `${base}_${index}`
    }
    return key
  }

  const addField = (path: Path) => {
    updateObject(path, (value) => ({
      ...value,
      [nextKey(value)]: "",
    }))
  }

  const removeField = (path: Path, key: string) => {
    updateObject(path, (value) => {
      const next = { ...value }
      delete next[key]
      return next
    })
  }

  const renameField = (path: Path, key: string, next: string) => {
    const name = next.trim()
    if (!name) return
    if (name === key) return
    updateObject(path, (value) => {
      if (name in value) return value
      const entries = Object.entries(value).map((entry) => {
        if (entry[0] === key) return [name, entry[1]] as const
        return entry
      })
      return Object.fromEntries(entries) as JsonRecord
    })
  }

  const reset = () => {
    setStore({
      config: serverConfig(),
      json: serverJson(),
      dirty: false,
      jsonDirty: false,
    })
  }

  const save = () => {
    if (store.mode === "json") {
      const next = parseJson(store.json)
      if (!next) {
        showToast({
          title: language.t("settings.config.toast.invalid.title"),
          description: language.t("settings.config.toast.invalid.description"),
        })
        return
      }
      updateConfig(next)
      return
    }

    updateConfig(store.config)
  }

  const updateConfig = (next: JsonRecord) => {
    setStore("saving", true)

    globalSync
      .updateConfig(next as Config)
      .then(() => {
        globalSync.set("config", next as Config)
        setStore({
          config: next,
          json: formatJson(next),
          dirty: false,
          jsonDirty: false,
        })
      })
      .catch((err: unknown) => {
        const message = err instanceof Error ? err.message : String(err)
        showToast({ title: language.t("common.requestFailed"), description: message })
      })
      .finally(() => setStore("saving", false))
  }

  const ConfigRow: Component<{ title: string; description?: string; children: JSX.Element }> = (props) => {
    return (
      <div class="flex flex-wrap items-center justify-between gap-4 px-4 py-3 border-b border-border-weak-base last:border-none">
        <div class="flex flex-col gap-0.5 min-w-0">
          <span class="text-14-medium text-text-strong truncate">{props.title}</span>
          <Show when={props.description}>
            <span class="text-12-regular text-text-weak">{props.description}</span>
          </Show>
        </div>
        <div class="flex-shrink-0 w-full sm:w-auto">{props.children}</div>
      </div>
    )
  }

  const labelFor = (value: string | number, parent: Json) => {
    if (Array.isArray(parent)) {
      const index = typeof value === "number" ? value : Number(value)
      if (!Number.isNaN(index)) {
        return language.t("settings.config.array.item", { index: index + 1 })
      }
      return String(value)
    }

    return title(String(value))
  }

  const summaryFor = (value: Json) => {
    if (Array.isArray(value)) return language.t("settings.config.array.items", { count: value.length })
    if (isRecord(value)) return language.t("settings.config.object.fields", { count: Object.keys(value).length })
    return ""
  }

  const current = createMemo(() => {
    const value = getAtPath(store.config, store.path)
    if (value === undefined) return store.config
    return value
  })

  const currentLabel = createMemo(() => {
    if (store.path.length === 0) return language.t("settings.config.breadcrumb.root")
    const parent = store.path.length === 1 ? store.config : getAtPath(store.config, store.path.slice(0, -1))
    return labelFor(store.path[store.path.length - 1], parent ?? store.config)
  })

  const breadcrumbs = createMemo(() => {
    let parent: Json = store.config
    return store.path.map((segment, index) => {
      const label = labelFor(segment, parent)
      const path = store.path.slice(0, index + 1)
      if (Array.isArray(parent)) {
        const item = parent[typeof segment === "number" ? segment : Number(segment)] as Json
        parent = item
        return { label, path }
      }
      if (isRecord(parent)) {
        parent = parent[String(segment)] as Json
      }
      return { label, path }
    })
  })

  const ScalarField: Component<{
    label: string
    value: Json
    path: Path
  }> = (props) => {
    if (typeof props.value === "boolean") {
      return (
        <ConfigRow title={props.label}>
          <Switch checked={props.value} onChange={(checked) => setValue(props.path, checked)} />
        </ConfigRow>
      )
    }

    if (typeof props.value === "number") {
      return (
        <ConfigRow title={props.label}>
          <TextField
            type="text"
            inputMode="decimal"
            value={String(props.value)}
            onChange={(value) => {
              if (!value.trim()) {
                setValue(props.path, 0)
                return
              }
              const next = Number(value)
              if (Number.isNaN(next)) return
              setValue(props.path, next)
            }}
            class="w-full sm:w-56"
          />
        </ConfigRow>
      )
    }

    if (typeof props.value === "string") {
      return (
        <ConfigRow title={props.label}>
          <TextField
            type="text"
            value={props.value}
            onChange={(value) => setValue(props.path, value)}
            class="w-full sm:w-56"
          />
        </ConfigRow>
      )
    }

    if (props.value === null) {
      return (
        <ConfigRow title={props.label} description={language.t("settings.config.value.null")}>
          <Button size="small" variant="secondary" onClick={() => setValue(props.path, "")}>
            {language.t("settings.config.value.set")}
          </Button>
        </ConfigRow>
      )
    }

    return (
      <ConfigRow title={props.label} description={language.t("settings.config.value.unsupported")}>
        <Button size="small" variant="secondary" onClick={() => setValue(props.path, "")}>
          {language.t("settings.config.value.set")}
        </Button>
      </ConfigRow>
    )
  }

  const EnterRow: Component<{
    label: string
    description: string
    onEnter: () => void
  }> = (props) => {
    return (
      <ConfigRow title={props.label} description={props.description}>
        <Button size="small" variant="secondary" onClick={props.onEnter}>
          {language.t("settings.config.nav.enter")}
        </Button>
      </ConfigRow>
    )
  }

  const ValueField: Component<{
    label: string
    value: Json
    path: Path
  }> = (props) => {
    if (Array.isArray(props.value)) {
      return <EnterRow label={props.label} description={summaryFor(props.value)} onEnter={() => setPath(props.path)} />
    }

    if (isRecord(props.value)) {
      return <EnterRow label={props.label} description={summaryFor(props.value)} onEnter={() => setPath(props.path)} />
    }

    return <ScalarField label={props.label} value={props.value} path={props.path} />
  }

  const ObjectLevel: Component<{
    value: JsonRecord
    path: Path
    label: string
  }> = (props) => {
    const entries = () => Object.entries(props.value)

    return (
      <div class="border border-border-weak-base rounded-lg overflow-hidden bg-surface-base">
        <div class="flex items-center justify-between px-4 py-3 border-b border-border-weak-base">
          <div class="flex flex-col gap-0.5">
            <span class="text-13-medium text-text-strong">{props.label}</span>
            <span class="text-12-regular text-text-weak">{summaryFor(props.value)}</span>
          </div>
          <Button size="small" variant="secondary" onClick={() => addField(props.path)}>
            {language.t("settings.config.object.add")}
          </Button>
        </div>
        <Show
          when={entries().length > 0}
          fallback={
            <div class="px-4 py-3 text-12-regular text-text-weak">{language.t("settings.config.object.empty")}</div>
          }
        >
          <div class="flex flex-col">
            <For each={entries()}>
              {(entry) => (
                <div class="border-b border-border-weak-base last:border-none">
                  <div class="flex flex-col gap-3 px-4 py-3">
                    <div class="flex flex-col gap-1">
                      <span class="text-12-regular text-text-weak">{language.t("settings.config.object.key")}</span>
                      <div class="flex flex-wrap items-center gap-2">
                        <TextField
                          type="text"
                          value={entry[0]}
                          placeholder={language.t("settings.config.object.key.placeholder")}
                          onChange={(value) => renameField(props.path, entry[0], value)}
                          class="w-full sm:w-64"
                        />
                        <Button size="small" variant="ghost" onClick={() => removeField(props.path, entry[0])}>
                          {language.t("settings.config.object.remove")}
                        </Button>
                      </div>
                    </div>
                    <div class="flex flex-col gap-1">
                      <span class="text-12-regular text-text-weak">{language.t("settings.config.object.value")}</span>
                      <div class="bg-surface-raised-base rounded-lg">
                        <ValueField
                          label={language.t("settings.config.object.value")}
                          value={entry[1]}
                          path={[...props.path, entry[0]]}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </For>
          </div>
        </Show>
      </div>
    )
  }

  const ArrayLevel: Component<{
    value: Json[]
    path: Path
    label: string
  }> = (props) => {
    return (
      <div class="border border-border-weak-base rounded-lg overflow-hidden bg-surface-base">
        <div class="flex items-center justify-between px-4 py-3 border-b border-border-weak-base">
          <div class="flex flex-col gap-0.5">
            <span class="text-13-medium text-text-strong">{props.label}</span>
            <span class="text-12-regular text-text-weak">{summaryFor(props.value)}</span>
          </div>
          <Button
            size="small"
            variant="secondary"
            onClick={() => updateArray(props.path, (value) => [...value, defaultFor(value[0])])}
          >
            {language.t("settings.config.array.add")}
          </Button>
        </div>
        <Show
          when={props.value.length > 0}
          fallback={
            <div class="px-4 py-3 text-12-regular text-text-weak">{language.t("settings.config.array.empty")}</div>
          }
        >
          <div class="flex flex-col">
            <For each={props.value}>
              {(item, index) => (
                <div class="border-b border-border-weak-base last:border-none">
                  <div class="flex items-center justify-between gap-4 px-4 py-3">
                    <span class="text-12-medium text-text-strong">
                      {language.t("settings.config.array.item", { index: index() + 1 })}
                    </span>
                    <Button
                      size="small"
                      variant="ghost"
                      onClick={() =>
                        updateArray(props.path, (value) => value.filter((_, itemIndex) => itemIndex !== index()))
                      }
                    >
                      {language.t("settings.config.array.remove")}
                    </Button>
                  </div>
                  <div class="px-4 pb-3">
                    <div class="bg-surface-raised-base rounded-lg">
                      <ValueField
                        label={language.t("settings.config.array.value")}
                        value={item}
                        path={[...props.path, index()]}
                      />
                    </div>
                  </div>
                </div>
              )}
            </For>
          </div>
        </Show>
      </div>
    )
  }

  const Breadcrumbs: Component = () => {
    return (
      <div class="flex flex-wrap items-center gap-2 rounded-lg border border-border-weak-base bg-surface-raised-base px-3 py-2">
        <Button
          size="small"
          variant="ghost"
          onClick={() => setPath(store.path.slice(0, -1))}
          disabled={store.path.length === 0}
        >
          {language.t("settings.config.nav.back")}
        </Button>
        <div class="flex flex-wrap items-center gap-1 text-12-regular text-text-weak">
          <Button size="small" variant="ghost" onClick={() => setPath([])}>
            {language.t("settings.config.breadcrumb.root")}
          </Button>
          <For each={breadcrumbs()}>
            {(item) => (
              <>
                <span class="text-text-weak">/</span>
                <Button size="small" variant="ghost" onClick={() => setPath(item.path)}>
                  {item.label}
                </Button>
              </>
            )}
          </For>
        </div>
      </div>
    )
  }

  return (
    <div class="flex flex-col h-full overflow-y-auto no-scrollbar">
      <div class="sticky top-0 z-10 bg-[linear-gradient(to_bottom,var(--surface-raised-stronger-non-alpha)_calc(100%_-_24px),transparent)]">
        <div class="flex flex-col gap-2 px-4 py-8 sm:p-8 max-w-[720px]">
          <h2 class="text-16-medium text-text-strong">{language.t("settings.config.title")}</h2>
          <p class="text-14-regular text-text-weak">{language.t("settings.config.description")}</p>
          <div class="flex flex-wrap items-center gap-2 pt-2">
            <div class="flex items-center gap-1 rounded-full border border-border-weak-base bg-surface-raised-base p-0.5">
              <Button
                size="small"
                variant={store.mode === "visual" ? "secondary" : "ghost"}
                onClick={() => setMode("visual")}
              >
                {language.t("settings.config.mode.visual")}
              </Button>
              <Button
                size="small"
                variant={store.mode === "json" ? "secondary" : "ghost"}
                onClick={() => setMode("json")}
              >
                {language.t("settings.config.mode.json")}
              </Button>
            </div>
            <Button size="small" variant="secondary" onClick={reset} disabled={!store.dirty}>
              {language.t("settings.config.action.reset")}
            </Button>
            <Button size="small" variant="primary" disabled={store.saving} onClick={save}>
              {store.saving ? language.t("common.saving") : language.t("settings.config.action.save")}
            </Button>
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-6 px-4 pb-8 sm:px-8 sm:pb-10 max-w-[720px]">
        <Show
          when={store.mode === "visual"}
          fallback={
            <TextField
              label={language.t("settings.config.editor.label")}
              description={language.t("settings.config.editor.description")}
              value={store.json}
              onChange={setJson}
              multiline
              class="w-full min-h-[320px] font-mono text-12-regular"
            />
          }
        >
          <Show
            when={Object.keys(store.config).length > 0}
            fallback={<div class="text-14-regular text-text-weak">{language.t("settings.config.empty")}</div>}
          >
            <div class="flex flex-col gap-4">
              <Breadcrumbs />
              <Show
                when={Array.isArray(current()) || isRecord(current())}
                fallback={
                  <div class="text-14-regular text-text-weak">{language.t("settings.config.value.unsupported")}</div>
                }
              >
                <Show
                  when={Array.isArray(current())}
                  fallback={
                    <ObjectLevel value={(current() as JsonRecord) ?? {}} path={store.path} label={currentLabel()} />
                  }
                >
                  <ArrayLevel value={current() as Json[]} path={store.path} label={currentLabel()} />
                </Show>
              </Show>
            </div>
          </Show>
        </Show>
      </div>
    </div>
  )
}
