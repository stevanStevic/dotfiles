import type { FwLogLevel, FwLogLine } from '../types'

// ESP-IDF colours its log lines with SGR codes; a tee'd capture keeps them.
const ANSI = /\x1b\[[0-9;?]*[A-Za-z]/g
const IDF_PREFIX = /^([EWIDV]) \(\d+\)/
const PANIC = /Guru Meditation|abort\(\) was called|panic'ed|Backtrace:|assert failed/

export function stripAnsi(text: string): string {
  return text.replace(ANSI, '').replace(/\r/g, '')
}

export function levelOf(line: string): FwLogLevel {
  const m = IDF_PREFIX.exec(line)
  if (m) return m[1] as FwLogLevel
  return PANIC.test(line) ? 'E' : ''
}

// The last `max` lines of a tail's output, ANSI stripped and classified.
export function parseTail(stdout: string, max: number): FwLogLine[] {
  const lines = stripAnsi(stdout).split('\n')
  if (lines.length > 0 && lines[lines.length - 1] === '') lines.pop()
  return lines.slice(-max).map(text => ({ level: levelOf(text), text }))
}

type Entry = { name: string; kind: string; mtimeMs: number }

// The most recently modified `*.log` file in `dir`, or null. With `only`, just
// the paths in it count (a session's claimed logs).
export function pickNewest(
  entries: readonly Entry[],
  dir: string,
  only?: readonly string[],
): string | null {
  let best: Entry | null = null
  for (const entry of entries) {
    if (entry.kind !== 'file' || !entry.name.endsWith('.log')) continue
    if (only !== undefined && !only.includes(`${dir}/${entry.name}`)) continue
    if (best === null || entry.mtimeMs > best.mtimeMs) best = entry
  }
  return best === null ? null : `${dir}/${best.name}`
}

// Logs a command writes into `dir`: `> f`, `>> f`, `tee f`, `tee -a f`.
// Merely naming a log (ls, cat, grep) does not claim it.
export function claimedBy(command: string, dir: string): string[] {
  const esc = dir.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&')
  const re = new RegExp(`(?:>>?|\\btee(?:\\s+-a)?)\\s*["']?(${esc}/[\\w.-]+\\.log)`, 'g')
  const found = new Set<string>()
  for (const m of command.matchAll(re)) if (m[1] !== undefined) found.add(m[1])
  return [...found]
}

// A port name (`ttyUSB1`) or a path, as typed after /fwlog.
export function resolveTarget(arg: string, dir: string): string {
  return arg.includes('/') ? arg : `${dir}/${arg.endsWith('.log') ? arg : `${arg}.log`}`
}

// How many lines `next` added after `prev` ended, for keeping a scrolled
// window anchored while the tail grows. All of `next` when there is no overlap.
export function appendedCount(prev: readonly FwLogLine[], next: readonly FwLogLine[]): number {
  const last = prev[prev.length - 1]
  if (last === undefined) return next.length
  for (let i = next.length - 1; i >= 0; i--) {
    if (next[i]?.text === last.text) return next.length - 1 - i
  }
  return next.length
}

// The window of `room` lines ending `back` lines above the newest, `back`
// clamped so the window never runs past the oldest line.
export function windowOf(
  lines: readonly FwLogLine[],
  room: number,
  back: number,
): { shown: FwLogLine[]; back: number } {
  const maxBack = Math.max(0, lines.length - room)
  const b = Math.min(Math.max(0, back), maxBack)
  return { shown: lines.slice(Math.max(0, lines.length - room - b), lines.length - b), back: b }
}

// `/tmp/claude-bench/ttyUSB0.log` -> `ttyUSB0`.
export function portOf(path: string): string {
  const base = path.slice(path.lastIndexOf('/') + 1)
  return base.endsWith('.log') ? base.slice(0, -4) : base
}

export function clockText(ms: number): string {
  const d = new Date(ms)
  const two = (n: number) => String(n).padStart(2, '0')
  return `${two(d.getHours())}:${two(d.getMinutes())}:${two(d.getSeconds())}`
}

export type FwTabEntry = { file: string; mtimeMs: number }

// The tabs a pane shows: every `*.log` in `dir` by name, plus `active` when it
// lives elsewhere (a pinned path).
export function tabsOf(
  entries: readonly Entry[],
  dir: string,
  active: string | null,
): FwTabEntry[] {
  const tabs = entries
    .filter(e => e.kind === 'file' && e.name.endsWith('.log'))
    .map(e => ({ file: `${dir}/${e.name}`, mtimeMs: e.mtimeMs }))
    .sort((a, b) => a.file.localeCompare(b.file))
  if (active !== null && !tabs.some(t => t.file === active)) tabs.push({ file: active, mtimeMs: 0 })
  return tabs
}

// Which tab to show. A chosen tab sticks (no flipping between two live ports);
// with none chosen: this session's newest claimed log, else the newest overall.
export function chooseActive(
  current: string | null,
  claimed: readonly string[],
  tabs: readonly FwTabEntry[],
): string | null {
  if (current !== null) return current
  const newest = (list: readonly FwTabEntry[]) =>
    list.reduce<FwTabEntry | null>((b, t) => (b === null || t.mtimeMs > b.mtimeMs ? t : b), null)
  const own = newest(tabs.filter(t => claimed.includes(t.file)))
  if (own !== null) return own.file
  if (claimed.length > 0) return claimed[claimed.length - 1] ?? null
  return newest(tabs)?.file ?? null
}
