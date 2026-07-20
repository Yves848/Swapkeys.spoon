# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A collection of [Hammerspoon](https://www.hammerspoon.org/) Spoons developed for personal
use (Belgian AZERTY keyboard, smart lighting). Each `*.spoon/` directory is a self-contained
Spoon whose entire implementation lives in its `init.lua`. There is no build step, no
dependency manager, and no test suite — a Spoon is loaded and run directly by the Hammerspoon
runtime.

The canonical copies live in `~/.hammerspoon/Spoons/`; this repo is the version-controlled
mirror. When editing here, remember the running copy in `~/.hammerspoon/Spoons/<name>.spoon/`
must be re-synced (and Hammerspoon reloaded) to take effect.

## The Spoons

- **SwapKeys** — remaps keystrokes via `hs.eventtap` (`<`/`>`, `@`/`#`), toggleable.
- **NumpadDot** — forces the numpad `.` to emit a period regardless of layout.
- **WindowStep** — step-move / step-resize the focused window from the keyboard.
- **WindowSnap** — Magnet/Rectangle-style placement (halves, quarters, thirds, maximize, center); floats the window via yabai first.
- **Yabai** — drives the yabai tiling WM (focus/swap/warp, Spaces, multi-display, layout cycle) via `hs.task`.
- **CheatSheet** — floating `hs.webview` popup (toggle hotkey) listing all shortcuts from a configurable `sections` table.
- **WLED** — mDNS discovery + control of WLED devices (menubar + chooser).
- **LedControl** — client for the LedControl FastAPI service (menubar, scenes, hotkeys).

## Architecture

Every Spoon follows the same Hammerspoon module contract: `init.lua` returns a table `obj`
(with `obj.__index = obj`) carrying metadata (`name`, `version`, `author`, `license`) and
lifecycle methods. The conventional shape across these Spoons:

- `obj:start()` / `obj:stop()` — install / tear down the Spoon's machinery (an `hs.eventtap`,
  an `hs.menubar`, timers, an `hs.task`). `start()` is what actually activates the Spoon.
- `obj:bindHotkeys(mapping)` — the standard Spoon convention for wiring keys; `mapping` is a
  table of `action = { {mods}, "key" }`. See each Spoon's header docstring for the action names.
- Runtime-tunable fields are exposed as `obj.<field>` (e.g. `WindowStep.step`,
  `WLED.staticDevices`, `LedControl.projectPath`) and are meant to be set from
  `~/.hammerspoon/init.lua` *before* calling `:start()`.

Two recurring patterns worth knowing:

- **eventtap remappers** (SwapKeys, NumpadDot): the callback inspects `e:getKeyCode()` /
  `e:getFlags()`. Return `true` to **swallow** the original event (SwapKeys emits a
  replacement with `hs.eventtap.keyStrokes`), or `false` to let it through — NumpadDot mutates
  the event in place with `e:setUnicodeString(...)` and returns `false`. Key codes are macOS
  virtual key codes; prefer `hs.keycodes.map[...]` over hard-coded numbers where possible.
- **network/service Spoons** (WLED, LedControl): async HTTP via `hs.http.asyncGet/asyncPost`,
  JSON via `hs.json`, a menubar UI, and mDNS discovery. LedControl can launch the FastAPI
  service itself via `hs.task` specifically so the child inherits Hammerspoon's macOS "Local
  Network" permission — a terminal-launched service cannot reach the LAN devices.

## Development

There is no CLI test loop — iteration happens inside Hammerspoon: reload the config
(menubar → Reload Config, or `hs.reload()`) after syncing the edited Spoon into
`~/.hammerspoon/Spoons/`. Use the Hammerspoon Console for logging (`hs.printf`, `hs.logger`,
`print`) — SwapKeys ships commented-out `hs.logger` scaffolding for discovering key codes.

## Conventions

Code comments, header docstrings, and user-facing `hs.alert.show` messages are in French.
Match that when editing.
