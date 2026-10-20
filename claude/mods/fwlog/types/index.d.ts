export type FwLogLevel = 'E' | 'W' | 'I' | 'D' | 'V' | ''

export type FwLogLine = { level: FwLogLevel; text: string }

export type FwLogView = {
  file: string | null
  lines: FwLogLine[]
  note: string
  mtimeMs: number
}

export type FwLogTab = { file: string; isLive: boolean }

declare module 'claude-code' {
  interface PluginState {
    fwlog: {
      view: FwLogView
      active: string | null
      tabs: FwLogTab[]
      dismissedFile: string | null
      claimed: string[]
      back: number
    }
  }
}
