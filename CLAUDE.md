# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Crash Blocks is a falling-block puzzle game (Puyo Puyo / Dr. Mario style) built with the [LÖVE](https://love2d.org) 2D Lua framework. Targets desktop and Android (via `packaging/love-android-sdl2`). `conf.lua` pins the LÖVE API version to **0.10.2** — newer LÖVE versions have breaking changes (e.g. color values are 0–1 floats instead of 0–255 ints, `math.atan2` is gone, `love.audio.newSource` requires a type argument), so the code as written will only run cleanly on 0.10.x.

## Build / run

Everything is driven by the `Makefile`:

- `make` or `make run-desktop` — builds the `assets/` tree (symlinks/Tiled exports/SVG meshes from `src_assets/`) then launches `love .`.
- `make assets` — just (re)build the `assets/` tree. Required because `src/sound.lua` and friends load from `assets/sounds/...`, not `src_assets/`.
- `make game.love` — package a `.love` file (zips code + assets).
- `make install-love` / `make run-mobile` / `make install-apk` / `make logcat` — Android targets, all assume `adb` and the `packaging/love-android-sdl2` checkout. The APK build runs `gradle build` inside `$(ANDROID_DIR)` and needs `local.properties` pointing at `/opt/android-sdk` and `/opt/android-ndk`.
- `make dropbox` — copies the built `.love` to `~/Dropbox/Apps/love/`.

There are no tests, no linter, and no package manager — the project is just Lua source loaded by LÖVE. Debug mode is opt-in: pass `-debug` on the command line and `main.lua` will `require("mobdebug").start()` each frame.

`assets/` and `*.love` are git-ignored; only `src_assets/` is checked in. The `assets/sounds/*` files referenced by `Sound.load()` are produced by `make` symlinking from `src_assets/sounds/`.

## Architecture

### Entry point and globals

`main.lua` `require`s every file in `src/` (no module returns except `sound.lua`) so most game state lives in **globals**: `grid`, `gridInfo`, `colors`, `colorVals`, `currentPair`, `nextPair`, `crashBlocks`, `state`, `keyMappings`, `touches`, `mouseGridPos`. Editing one file frequently affects others through these globals — there is no module boundary to lean on.

`love.load` seeds RNG, loads sounds, initializes `crashBlocks[color] = {}` for every color, creates the first `nextPair`, and sets `state = tryNew`. `love.update(dt)` just calls `state(dt)`; `love.draw` renders `currentPair` (the falling pair) plus everything in `grid`.

### State machine (`src/states.lua`)

The whole game loop is a function-valued global `state` that each frame replaces itself with the next state. The flow is:

```
tryNew  ──► inControl  ──► delay(...) ──► inControl          (movement tween)
                       └─► delay(...) ──► applyGravity       (lock + drop)
                                          │
                                          ▼
                                       clearBlocks
                                          │  more chains?
                                          ├──── yes ──► delay ──► applyGravity (loop)
                                          └──── no  ──► tryNew
```

- `tryNew` promotes `nextPair` to `currentPair` at `(startX, startY, startDir)`. If it can't fit, the game prints "Game over" and quits.
- `inControl` reads `getInputs()` and computes a tentative `(newX, newY, newDir)`. On a successful move it stamps `prevX/prevY/t = 0` on the affected block(s) and switches to `delay(0.1, inControl)` (or `0.025` for soft-drop). On a failed soft-drop it locks the pair into `grid`, registers any `crash` blocks in `crashBlocks[color]`, and falls into `applyGravity`.
- `applyGravity` walks each column bottom-up, drops blocks one row at a time per pass, re-schedules itself via `delay(0.1, ...)` while anything moved, and finally hands off to `clearBlocks`.
- `clearBlocks` runs `findChain` (BFS over same-color neighbors) starting from each registered crash block. Chains of length > 1 are flagged for deletion via `gridDel` (which sets `state='deleting'` and `t=0` so the draw code can fade them out), then re-enters `applyGravity` after a delay. When nothing more clears it returns to `tryNew`.

### `delay(delayTimeLimit, nextState)`

This is the core animation primitive. It returns a closure used as the next `state`. Each frame it advances `delayTime` and writes the normalized progress `pct = delayTime / delayTimeLimit` into the `t` field of `currentPair.first/second` and **every block in `grid` that already has a `t` set**. When the timer expires it clears `prevX/prevY/t` on all those blocks (and removes any `state == 'deleting'` blocks from the grid), then assigns `state = nextState`. The renderer (`drawBlock` in `src/block.lua`) uses `prevX/prevY/t` via `getPixelCoords` to interpolate position, and uses `t` directly to fade out deleting blocks.

Important consequence: any block you want animated this frame must have `prevX`, `prevY`, and `t = 0` set **before** transitioning into a `delay` state — otherwise `delay` will skip it. See the `inputs.left/right/down/rotate` branches in `inControl` for the pattern.

### Grid model (`src/grid.lua`)

`grid` is a sparse `grid[x][y]` table; always go through `gridSet/gridGet/gridDel` rather than indexing directly so missing columns don't blow up. `gridInfo` is `{w=8, h=14, tileWidth=128, tileHeight=128}` — the playable area is `1..w-1` × `1..h-1` (note the strict `<` in `canMove`), so column 0 / column `w` / row `h` are walls.

A "pair" is `{first, second, x, y, dir}` where `dir ∈ {'e','s','w','n'}`. `getGridCoords(pair)` expands a pair into `firstX, firstY, secondX, secondY`. `nextDir` defines the rotation order `e → s → w → n → e`. `canMove` is the only collision check and is also used by `tryNew` to detect game over.

### Blocks and chains (`src/block.lua`)

Blocks are plain tables: `{color, type, prevX?, prevY?, t?, state?}`. `type` is `'normal'` (drawn as a square) or `'crash'` (drawn as a circle, ~30% spawn rate per `randomBlock`). Only crash blocks are kept in `crashBlocks[color]` and only chains seeded from a crash block of length > 1 are cleared — a normal-only group is inert. After a chain clears, only crash entries from `toRemove` are pulled out of `crashBlocks`; normal blocks were never tracked there.

`findChain` takes a `{x, y, blockInfo}` triple (note the `[3]` indexing — it's a positional tuple, not a record) and walks `getNeighbors` building a same-color connected component. The `seen` table is shared across crash-block iterations of the same color to avoid double-clearing.

### Input (`src/input.lua`)

`getInputs()` returns `{left?, right?, down?, rotate?, touches}`. Keyboard mapping is fixed in `keyMappings` (`a`/`d`/`s`/space). Touch is a swipe gesture: a single in-flight touch is converted to a unit vector and bucketed by angle (`atan2`-based) into one of the four actions; only the first touch in `touches` is considered (the loop has an unconditional `break`). `love.touchpressed/moved/released` mutate the global `touches` table.

### Sound (`src/sound.lua`)

The only file that returns a module. Loads sources from `assets/sounds/`, so `make assets` must have run. `Sound.playBeep` picks a random beep from `Sound.beep` (currently a 1-element array — the loop in `Sound.load` is `for i = 1, 1`, easy to extend by dropping more `beepN.wav` into `src_assets/sounds/` and bumping the upper bound).
