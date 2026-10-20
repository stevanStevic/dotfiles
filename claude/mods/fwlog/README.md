# fwlog - live firmware log pane

Shows the tail of a firmware console capture in a Claude Code pane. It never opens a
serial port (a second reader splits the byte stream and breaks flashing and e2e runs);
it only tails a file.

## Contract for capture scripts

    mkdir -p /tmp/claude-bench
    <capture> >> /tmp/claude-bench/<port>.log     # e.g. ttyUSB0.log, ttyACM0.log

- Write the capture from the session that owns the board, with the path in the
  command itself (`... | tee -a /tmp/claude-bench/ttyUSB0.log`, `>> ...`, `> ...`).
  That claims the log for that session.
- The file name minus `.log` is shown as the port.
- Raw ESP-IDF output is fine: ANSI colour codes and `\r` are stripped, lines are
  coloured by level (E red, W yellow, D/V dim, panics red).
- Truncating or recreating the file is handled (the pane reloads).

## Tabs and sessions

The pane has one tab per log (`1: ttyUSB0  2: ttyUSB1*`; `*` = written in the last
5 s, `<` = shown). Click a tab, or press its digit while the pane has focus
(click it or ctrl+x tab). The shown tab sticks: two live boards never flip the view.

Each session starts on its own log:

- A Bash or Monitor command that writes `/tmp/claude-bench/<x>.log` (`>`, `>>`,
  `tee`, `tee -a`) claims it for that session and switches the pane to it.
  Reading one (`tail`, `cat`, `grep`) does not.
- With nothing chosen, the pane shows this session's newest claimed log, else the
  newest log overall (chosen once, then it sticks).
- Only a session's own log opens the pane by itself.
- `/fwlog ttyUSB1` (or a path) shows that log in this session only.

## Scrolling

The body keeps the last 1000 lines. Mouse wheel and PgUp/PgDn scroll back, Home
jumps to the oldest; while scrolled the view stays on the same lines as new ones
arrive and the header shows `[back N of M, End follows]`. End (or scrolling to the
bottom) follows live output again.

## Behaviour

- Polls every 500 ms; re-reads only when size or mtime changed (`tail -n 1000`).
- Opens by itself when a log this session claimed or pinned was written in the
  last 2 minutes.
  Docks beside the transcript in fullscreen layout (asks for 100 columns),
  otherwise sits inline above the prompt, 8 log lines + tabs and a header.
- Closing it by hand keeps it closed for that file; a different file going live,
  or `/fwlog`, opens it again.

## Command

- `/fwlog` - toggle the pane
- `/fwlog <port|path>` - show that log in this session (`ttyUSB1`, or any file such
  as embedded/mcs/build/lsleep/bench.log, which gets its own tab)
- `/fwlog auto` - go back to this session's newest claimed log (or the newest
  overall if it has claimed none)
