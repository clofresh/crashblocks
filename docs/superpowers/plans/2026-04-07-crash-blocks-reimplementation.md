# Crash Blocks Reimplementation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reimplement the "Crash Blocks" game using Excalibur.js, TypeScript, and Vite with a modernized ECS architecture.

**Architecture:** 
- **ECS**: Blocks and pairs as entities with specific components (`Color`, `Type`, `GridPosition`, `Animation`).
- **State Pattern**: Game loop managed by a state machine (`TryNew`, `InControl`, `Gravity`, `ClearBlocks`).
- **Grid Manager**: Logical `grid[x][y]` map for collision and chain clearing.

**Tech Stack:** TypeScript, Excalibur.js, Vite.

---

## File Structure

- `index.html`: Entry point for Vite.
- `package.json`: Project dependencies.
- `tsconfig.json`: TypeScript configuration.
- `vite.config.ts`: Vite configuration.
- `src/main.ts`: Game entry point and initialization.
- `src/game.ts`: Excalibur game class definition.
- `src/core/`:
    - `GameManager.ts`: Singleton for game state, scoring, and logical grid.
    - `Constants.ts`: Game constants (grid size, colors, etc.).
    - `Types.ts`: Core TypeScript interfaces and types.
- `src/ecs/`:
    - `components/`:
        - `ColorComponent.ts`: Block color.
        - `TypeComponent.ts`: Block type (`normal` vs `crash`).
        - `GridPositionComponent.ts`: Logical grid coordinates.
        - `AnimationComponent.ts`: Visual interpolation data.
        - `PairComponent.ts`: Rotation and pair relationship.
- `src/systems/`:
    - `InputSystem.ts`: Handles keyboard/touch input.
    - `CollisionSystem.ts`: Validates moves against the logical grid.
    - `GravitySystem.ts`: Manages block falling and grid updates.
    - `ChainSystem.ts`: Performs BFS for chain clearing.
- `src/states/`:
    - `GameState.ts`: Base class for game states.
    - `TryNewState.ts`: Handles spawning new pairs.
    - `InControlState.ts`: Handles player input and movement.
    - `GravityState.ts`: Handles the gravity drop phase.
    - `ClearBlocksState.ts`: Handles chain detection and deletion.

---

## Implementation Tasks

### Task 1: Project Scaffolding
**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `vite.config.ts`
- Create: `index.html`

- [ ] **Step 1: Initialize `package.json`**
```json
{
  "name": "crash-blocks",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "excalibur": "^0.14.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "vite": "^5.0.0"
  }
}
```

- [ ] **Step 2: Initialize `tsconfig.json`**
```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "dist"
  },
  "include": ["src"]
}
```

- [ ] **Step 3: Initialize `vite.config.ts`**
```typescript
import { defineConfig } from 'vite';

export default defineConfig({});
```

- [ ] **Step 4: Initialize `index.html`**
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Crash Blocks</title>
    <style>
      body { margin: 0; overflow: hidden; background: #000; }
      canvas { display: block; }
    </style>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

- [ ] **Step 5: Commit scaffolding**
```bash
git add .
git commit -m "chore: scaffold project with vite and excalibur"
```

### Task 2: Core Types and Constants
**Files:**
- Create: `src/core/Constants.ts`
- Create: `src/core/Types.ts`

- [ ] **Step 1: Define `Constants.ts`**
```typescript
export const GRID_WIDTH = 8;
export const GRID_HEIGHT = 14;
export const TILE_SIZE = 64;
export const COLORS = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF'];
export const ROTATIONS = ['e', 's', 'w', 'n'] as const;
export type Rotation = typeof ROTATIONS[number];
```

- [ ] **Step 2: Define `Types.ts`**
```typescript
export type BlockType = 'normal' | 'crash';
export interface GridPos {
    x: number;
    y: number;
}
```

- [ ] **Step 3: Commit constants**
```bash
git add src/core/
git commit -m "feat: add core constants and types"
```

### Task 3: ECS Components
**Files:**
- Create: `src/ecs/components/ColorComponent.ts`
- Create: `src/ecs/components/TypeComponent.ts`
- Create: `src/ecs/components/GridPositionComponent.ts`
- Create: `src/ecs/components/AnimationComponent.ts`
- Create: `src/ecs/components/PairComponent.ts`

- [ ] **Step 1: Implement `ColorComponent.ts`**
```typescript
import { Component } from 'excalibur';
export class ColorComponent extends Component {
    constructor(public color: string) { super(); }
}
```

- [ ] **Step 2: Implement `TypeComponent.ts`**
```typescript
import { Component } from 'excalibur';
import { BlockType } from '../../core/Types';
export class TypeComponent extends Component {
    constructor(public type: BlockType) { super(); }
}
```

- [ ] **Step 3: Implement `GridPositionComponent.ts`**
```typescript
import { Component } from 'excalibur';
import { GridPos } from '../../core/Types';
export class GridPositionComponent extends Component {
    constructor(public pos: GridPos) { super(); }
}
```

- [ ] **Step 4: Implement `AnimationComponent.ts`**
```typescript
import { Component } from 'excalibur';
import { GridPos } from '../../core/Types';
export class AnimationComponent extends Component {
    constructor(
        public prevPos: GridPos,
        public targetPos: GridPos,
        public progress: number = 0
    ) { super(); }
}
```

- [ ] **Step 5: Implement `PairComponent.ts`**
```typescript
import { Component } from 'excalibur';
import { Rotation } from '../../core/Constants';
export class PairComponent extends Component {
    constructor(public rotation: Rotation) { super(); }
}
```

- [ ] **Step 6: Commit components**
```bash
git add src/ecs/components/
git commit -m "feat: implement ECS components for blocks"
```

### Task 4: Game Manager and Logical Grid
**Files:**
- Create: `src/core/GameManager.ts`

- [ ] **Step 1: Implement `GameManager` singleton**
```typescript
import { GridPos } from './Types';
import { GRID_WIDTH, GRID_HEIGHT } from './Constants';

class GameManager {
    public grid: any[][] = Array.from({ length: GRID_WIDTH }, () => 
        Array.from({ length: GRID_HEIGHT }, () => null)
    );
    public score = 0;

    public setBlock(x: number, y: number, block: any) {
        if (x >= 0 && x < GRID_WIDTH && y >= 0 && y < GRID_HEIGHT) {
            this.grid[x][y] = block;
        }
    }

    public getBlock(x: number, y: number): any {
        if (x >= 0 && x < GRID_WIDTH && y >= 0 && y < GRID_HEIGHT) {
            return this.grid[x][y];
        }
        return null;
    }

    public isWithinBounds(x: number, y: number): boolean {
        return x >= 0 && x < GRID_WIDTH && y >= 0 && y < GRID_HEIGHT;
    }
}

export const gameManager = new GameManager();
```

- [ ] **Step 2: Commit Game Manager**
```bash
git add src/core/GameManager.ts
git commit -m "feat: add Game Manager and logical grid"
```

### Task 5: Base Game Class and State Machine
**Files:**
- Create: `src/game.ts`
- Create: `src/states/GameState.ts`

- [ ] **Step 1: Define `GameState` base class**
```typescript
import { CrashBlocksGame } from '../game';

export abstract class GameState {
    protected game: CrashBlocksGame;
    constructor(game: CrashBlocksGame) {
        this.game = game;
    }
    abstract update(dt: number): void;
    abstract enter(): void;
    abstract exit(): void;
}
```

- [ ] **Step 2: Implement `CrashBlocksGame` class**
```typescript
import { Excalibur } from 'excalibur';
import { GameState } from './states/GameState';

export class CrashBlocksGame extends Excalibur.Game {
    private currentState: GameState | null = null;

    public transitionTo(state: GameState) {
        if (this.currentState) this.currentState.exit();
        this.currentState = state;
        this.currentState.enter();
    }

    public update(dt: number) {
        if (this.currentState) this.currentState.update(dt);
    }
}
```

- [ ] **Step 3: Commit State machine**
```bash
git add src/game.ts src/states/GameState.ts
git commit -m "feat: add base game class and state machine"
```
