import { describe, expect, test } from 'claude-code/testing'

import {
  appendedCount,
  chooseActive,
  claimedBy,
  levelOf,
  parseTail,
  pickNewest,
  portOf,
  resolveTarget,
  stripAnsi,
  tabsOf,
  windowOf,
} from './logic'

const D = '/tmp/claude-bench'
const L = (...texts: string[]) => texts.map(text => ({ level: '' as const, text }))

describe('fwlog logic', () => {
  test('strips ESP-IDF colour codes and carriage returns', async () => {
    expect(stripAnsi('\x1b[0;31mE (123) tag: boom\x1b[0m\r')).toBe('E (123) tag: boom')
  })

  test('classifies ESP-IDF levels and panics', async () => {
    expect(levelOf('E (10) wifi: fail')).toBe('E')
    expect(levelOf('W (10) wifi: slow')).toBe('W')
    expect(levelOf('I (10) main: ok')).toBe('I')
    expect(levelOf('D (10) x: y')).toBe('D')
    expect(levelOf("Guru Meditation Error: Core  0 panic'ed (LoadProhibited)")).toBe('E')
    expect(levelOf('ESP-ROM:esp32s3-20210327')).toBe('')
  })

  test('keeps only the last N lines and drops the trailing newline', async () => {
    const out = parseTail('a\nb\n\x1b[0;33mW (1) t: w\x1b[0m\n', 2)
    expect(out).toEqual([
      { level: '', text: 'b' },
      { level: 'W', text: 'W (1) t: w' },
    ])
  })

  test('picks the newest .log file, ignoring others', async () => {
    const entries = [
      { name: 'ttyUSB0.log', kind: 'file', mtimeMs: 10 },
      { name: 'ttyACM0.log', kind: 'file', mtimeMs: 30 },
      { name: 'notes.txt', kind: 'file', mtimeMs: 99 },
      { name: 'old', kind: 'dir', mtimeMs: 0 },
    ]
    expect(pickNewest(entries, '/tmp/claude-bench')).toBe('/tmp/claude-bench/ttyACM0.log')
    expect(pickNewest([], '/tmp/claude-bench')).toBe(null)
  })

  test('derives the port from the file name', async () => {
    expect(portOf('/tmp/claude-bench/ttyUSB1.log')).toBe('ttyUSB1')
  })

  test('newest among claimed logs only', async () => {
    const entries = [
      { name: 'ttyUSB0.log', kind: 'file', mtimeMs: 10 },
      { name: 'ttyUSB1.log', kind: 'file', mtimeMs: 30 },
    ]
    expect(pickNewest(entries, D, [`${D}/ttyUSB0.log`])).toBe(`${D}/ttyUSB0.log`)
    expect(pickNewest(entries, D, [`${D}/ttyACM0.log`])).toBe(null)
  })

  test('claims logs a command writes, not ones it only reads', async () => {
    expect(claimedBy(`idf.py monitor 2>&1 | tee -a ${D}/ttyUSB0.log`, D)).toEqual([`${D}/ttyUSB0.log`])
    expect(claimedBy(`cat /dev/ttyUSB1 >> "${D}/ttyUSB1.log" &`, D)).toEqual([`${D}/ttyUSB1.log`])
    expect(claimedBy(`python cap.py > ${D}/ttyUSB0.log; tee ${D}/x.log`, D)).toEqual([
      `${D}/ttyUSB0.log`,
      `${D}/x.log`,
    ])
    expect(claimedBy(`tail -n 50 ${D}/ttyUSB1.log; ls ${D}`, D)).toEqual([])
    expect(claimedBy(`grep -c E ${D}/ttyUSB0.log > /tmp/count`, D)).toEqual([])
  })

  test('resolves a port name or path typed after /fwlog', async () => {
    expect(resolveTarget('ttyUSB1', D)).toBe(`${D}/ttyUSB1.log`)
    expect(resolveTarget('ttyUSB1.log', D)).toBe(`${D}/ttyUSB1.log`)
    expect(resolveTarget('embedded/mcs/bench.log', D)).toBe('embedded/mcs/bench.log')
  })

  test('counts lines appended after the previous tail', async () => {
    expect(appendedCount(L('a', 'b'), L('a', 'b', 'c', 'd'))).toBe(2)
    expect(appendedCount(L('a', 'b'), L('b', 'c'))).toBe(1)
    expect(appendedCount(L('a', 'b'), L('a', 'b'))).toBe(0)
    expect(appendedCount([], L('a'))).toBe(1)
  })

  test('scroll window clamps to the oldest and newest lines', async () => {
    const lines = L('1', '2', '3', '4', '5')
    expect(windowOf(lines, 2, 0)).toEqual({ shown: L('4', '5'), back: 0 })
    expect(windowOf(lines, 2, 2)).toEqual({ shown: L('2', '3'), back: 2 })
    expect(windowOf(lines, 2, 99)).toEqual({ shown: L('1', '2'), back: 3 })
    expect(windowOf(lines, 2, -5)).toEqual({ shown: L('4', '5'), back: 0 })
    expect(windowOf(lines, 9, 4)).toEqual({ shown: lines, back: 0 })
  })

  test('one tab per log, sorted, plus a pinned path outside the folder', async () => {
    const entries = [
      { name: 'ttyUSB1.log', kind: 'file', mtimeMs: 30 },
      { name: 'ttyUSB0.log', kind: 'file', mtimeMs: 10 },
      { name: 'notes.txt', kind: 'file', mtimeMs: 99 },
    ]
    expect(tabsOf(entries, D, null).map(t => t.file)).toEqual([`${D}/ttyUSB0.log`, `${D}/ttyUSB1.log`])
    expect(tabsOf(entries, D, 'x/bench.log').map(t => t.file)).toEqual([
      `${D}/ttyUSB0.log`,
      `${D}/ttyUSB1.log`,
      'x/bench.log',
    ])
  })

  test('a chosen tab sticks; otherwise own newest, then newest overall', async () => {
    const tabs = [
      { file: `${D}/ttyUSB0.log`, mtimeMs: 10 },
      { file: `${D}/ttyUSB1.log`, mtimeMs: 30 },
    ]
    // Two live ports: the chosen one never flips to the newer one.
    expect(chooseActive(`${D}/ttyUSB0.log`, [], tabs)).toBe(`${D}/ttyUSB0.log`)
    expect(chooseActive(null, [`${D}/ttyUSB0.log`], tabs)).toBe(`${D}/ttyUSB0.log`)
    expect(chooseActive(null, [`${D}/ttyACM0.log`], tabs)).toBe(`${D}/ttyACM0.log`)
    expect(chooseActive(null, [], tabs)).toBe(`${D}/ttyUSB1.log`)
    expect(chooseActive(null, [], [])).toBe(null)
  })
})
