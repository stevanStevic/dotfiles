import type { EngineInterface, Register } from 'claude-code'

import type { FwLogTab, FwLogView } from '../types'
import {
  appendedCount,
  chooseActive,
  claimedBy,
  clockText,
  parseTail,
  portOf,
  resolveTarget,
  tabsOf,
  windowOf,
} from './logic'

// Contract: capture scripts append a port's console to /tmp/claude-bench/<port>.log.
// The pane shows one tab per log. Each session starts on the newest log its own
// commands write (> / >> / tee), and the chosen tab sticks: two live ports never
// flip the view. /fwlog <port|path> or a tab press switches.
// It never opens a serial port: a second reader would split the byte stream.
const DIR = '/tmp/claude-bench'
const PANE = 'fwlog'
const KEEP = 1000
const POLL_MS = 500
const LIVE_MS = 120_000 // a log written this recently may open the pane
const ACTIVE_MS = 5_000 // a tab written this recently is marked live
const ROWS = 10 // tabs + header + 8 log lines, when seated inline
const COLUMNS = 100 // body width asked for when docked
const CHROME = 2 // tab row + header row above the log lines

const VIEW = { plugin: 'fwlog', key: 'view' } as const
const ACTIVE = { plugin: 'fwlog', key: 'active' } as const
const TABS = { plugin: 'fwlog', key: 'tabs' } as const
const DISMISSED = { plugin: 'fwlog', key: 'dismissedFile' } as const
const CLAIMED = { plugin: 'fwlog', key: 'claimed' } as const
const BACK = { plugin: 'fwlog', key: 'back' } as const

const EMPTY: FwLogView = { file: null, lines: [], note: '', mtimeMs: 0 }

let lastKey = ''
let lastTabsKey = ''
let lastFile: string | null = null
let lastSize = 0
let isPolling = false

async function isOpen($: EngineInterface): Promise<boolean> {
  const panes = await $.ui.panes()
  return panes.some(p => p.id === PANE)
}

async function openPane($: EngineInterface): Promise<void> {
  await $.ui.open({ id: PANE, title: 'fwlog', rows: ROWS, columns: COLUMNS })
}

// Switches the shown tab; the next poll loads it.
async function select($: EngineInterface, file: string | null): Promise<void> {
  await $.state.set(ACTIVE, file)
  await $.state.set(BACK, 0)
  lastKey = ''
}

async function poll($: EngineInterface): Promise<void> {
  const { value: claimed = [] } = await $.state.get(CLAIMED)
  const { value: current = null } = await $.state.get(ACTIVE)
  const entries = await $.fs.list(DIR).catch(() => [])
  const now = await $.clock.now()

  const found = tabsOf(entries, DIR, current)
  const file = chooseActive(current, claimed, found)
  if (file !== current) await $.state.set(ACTIVE, file)

  const tabs: FwLogTab[] = found.map(t => ({
    file: t.file,
    isLive: now - t.mtimeMs < ACTIVE_MS,
  }))
  const tabsKey = tabs.map(t => `${t.file}${t.isLive ? '*' : ''}`).join('|')
  if (tabsKey !== lastTabsKey) {
    lastTabsKey = tabsKey
    await $.state.set(TABS, tabs)
  }

  if (file === null) {
    if (lastKey !== 'none') {
      lastKey = 'none'
      await $.state.set(VIEW, { ...EMPTY, note: `waiting for ${DIR}/*.log` })
    }
    return
  }

  const stat = await $.fs.stat(file).catch(() => undefined)
  if (stat === undefined) {
    const key = `missing|${file}`
    if (lastKey !== key) {
      lastKey = key
      await $.state.set(VIEW, { ...EMPTY, file, note: 'file does not exist yet' })
    }
    return
  }

  const key = `${file}|${stat.size}|${stat.mtimeMs}`
  if (key === lastKey) return
  const isTruncated = file === lastFile && stat.size < lastSize
  lastKey = key
  lastFile = file
  lastSize = stat.size

  const tail = await $.process.run(['tail', '-n', String(KEEP), file], { timeoutMs: 5000 })
  const lines = parseTail(tail.stdout, KEEP)
  const { value: prev = EMPTY } = await $.state.get(VIEW)
  const { value: back = 0 } = await $.state.get(BACK)
  if (prev.file !== file) {
    if (back !== 0) await $.state.set(BACK, 0)
  } else if (back > 0 && !isTruncated) {
    // Scrolled back: keep the same lines in view while new ones arrive.
    await $.state.set(BACK, back + appendedCount(prev.lines, lines))
  }
  await $.state.set(VIEW, {
    file,
    lines,
    note: isTruncated ? 'truncated, reloaded' : '',
    mtimeMs: stat.mtimeMs,
  })

  // Only this session's own log opens the pane by itself.
  const { value: dismissed = null } = await $.state.get(DISMISSED)
  if (
    claimed.includes(file) &&
    now - stat.mtimeMs < LIVE_MS &&
    dismissed !== file &&
    !(await isOpen($))
  ) {
    await openPane($)
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'fwlog',
      description: `Toggle the firmware log pane (/fwlog <port|path> shows that log, /fwlog auto picks this session's own)`,
    })
    lastKey = ''
    lastTabsKey = ''
    $.clock.every(POLL_MS, () => {
      if (isPolling) return
      isPolling = true
      void poll($)
        .catch(err => $.ui.log(`fwlog poll: ${String(err)}`, { to: 'debug' }))
        .finally(() => {
          isPolling = false
        })
    })

    return next(e)
  })

  on('command.run', { command: 'fwlog' }, async ($, e) => {
    const arg = e.args.trim()
    const { value: view = EMPTY } = await $.state.get(VIEW)

    if (arg === '') {
      if (await isOpen($)) {
        await $.state.set(DISMISSED, view.file)
        await $.ui.close({ id: PANE })
        return { text: 'fwlog pane closed; it reopens when this session writes a log, or with /fwlog.' }
      }
      await $.state.set(DISMISSED, null)
      await openPane($)
      return { text: `fwlog showing ${view.file ?? `${DIR}/*.log (none yet)`}.` }
    }

    const target = arg === 'auto' ? null : resolveTarget(arg, DIR)
    await select($, target)
    await $.state.set(DISMISSED, null)
    await openPane($)
    if (target !== null) return { text: `fwlog showing ${target}.` }
    const { value: claimed = [] } = await $.state.get(CLAIMED)
    return {
      text:
        claimed.length > 0
          ? `fwlog showing this session's newest log (${claimed.map(portOf).join(', ')}).`
          : `fwlog showing the newest ${DIR}/*.log (this session has written none yet).`,
    }
  })

  // A command that writes a capture log claims it for this session and shows it.
  on('tool.call', async ($, e, next) => {
    const command =
      e.tool === 'Bash' || e.tool === 'Monitor' ? (e as { command?: unknown }).command : undefined
    if (typeof command === 'string' && command.includes(DIR)) {
      const found = claimedBy(command, DIR)
      const newest = found[found.length - 1]
      if (newest !== undefined) {
        const { value: claimed = [] } = await $.state.get(CLAIMED)
        if (found.some(f => !claimed.includes(f))) {
          await $.state.set(CLAIMED, [...claimed.filter(f => !found.includes(f)), ...found])
          await $.state.set(DISMISSED, null)
          await select($, newest)
        }
      }
    }
    return next(e)
  })

  // The body is a window over the tail: wheel and page keys move it back through
  // the KEEP lines, End (or scrolling to the bottom) follows again.
  on('ui.scroll', { requestId: PANE }, async ($, e) => {
    const { value: view = EMPTY } = await $.state.get(VIEW)
    const { value: back = 0 } = await $.state.get(BACK)
    const room = Math.max(1, e.bodyRows - CHROME)
    const moved = windowOf(view.lines, room, back - e.by).back
    if (moved !== back) await $.state.set(BACK, moved)
    return {}
  })

  on('ui.close', { id: PANE }, async ($, e, next) => {
    if (e.origin.kind === 'person') {
      const { value: view = EMPTY } = await $.state.get(VIEW)
      await $.state.set(DISMISSED, view.file)
    }
    return next(e)
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const { value: view = EMPTY } = await $.state.get(VIEW)
    const { value: tabs = [] } = await $.state.get(TABS)
    const { value: active = null } = await $.state.get(ACTIVE)
    const { value: back = 0 } = await $.state.get(BACK)
    const room = Math.max(1, e.props.scroll.bodyRows - CHROME)
    const win = windowOf(view.lines, room, back)

    const shown = view.file === active ? view : { ...EMPTY, file: active, note: 'loading' }
    const where = shown.file ?? DIR
    const when = shown.mtimeMs > 0 ? `  last write ${clockText(shown.mtimeMs)}` : ''
    const scrolled = win.back > 0 ? `  [back ${win.back} of ${view.lines.length}, End follows]` : ''
    const header = `${where}${when}${scrolled}${shown.note ? `  (${shown.note})` : ''}`
    const rows = shown === view ? win.shown : []

    return (
      <Box flexDirection="column">
        <Box flexDirection="row" gap={2}>
          {tabs.length === 0 && <Text dimColor>no logs in {DIR}</Text>}
          {tabs.map((tab, i) => (
            <Button
              key={tab.file}
              plain
              hotkey={i < 9 ? String(i + 1) : undefined}
              dimColor={tab.file !== active}
              label={`${portOf(tab.file)}${tab.isLive ? '*' : ''}${tab.file === active ? ' <' : ''}`}
              onPress={() => select($, tab.file)}
            />
          ))}
        </Box>
        <Text dimColor wrap="truncate-middle">
          {header}
        </Text>
        {rows.length === 0 && <Text dimColor>No log lines yet.</Text>}
        {rows.map(line => (
          <Text
            wrap="truncate"
            color={line.level === 'E' ? 'red' : line.level === 'W' ? 'yellow' : undefined}
            dimColor={line.level === 'D' || line.level === 'V'}
          >
            {line.text === '' ? ' ' : line.text}
          </Text>
        ))}
      </Box>
    )
  })
}
