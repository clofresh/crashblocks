# Design Spec: Crash Blocks Reimplementation (Excalibur.js + Vite)

## Date: 2026-04-07
## Status: Proposed

### 1. Overview
Reimplement the "Crash Blocks" falling-block puzzle game using TypeScript, Excalibur.js, and Vite. The goal is to move from a global-state Lua architecture to a modernized Entity-Component-System (ECS) architecture.

### 2. Architecture

#### 2.1 ECS Mapping
Instead of global variables, the game state is distributed across entities and components:

*   **Block Entity**: Represents a single game block.
    *   `ColorComponent`: Stores block color.
    *   `TypeComponent`: Stores block type (`normal` vs `crash`).
    *   `GridPositionComponent`: Tracks logical grid coordinates `(x, y)`.
    *   `AnimationComponent`: Manages visual interpolation between logical positions.
*   **Pair Entity**: A container for the falling duo.
    *   `PairComponent`: Tracks current rotation direction (`e`, `s`, `w`, `n`).
*   **GameManager (Resource)**: A singleton managing the overall game loop, scoring, and the logical `grid[x][y]` map.

#### 2.2 State Machine
The game logic is driven by a State Pattern, replacing the Lua function-based state machine:
*   **State Flow**: `TryNewState` $\to$ `InControlState` $\to$ `GravityState` $\to$ `ClearBlocksState` $\to$ `TryNewState`.
*   **Transitions**: Handled by the `GameManager`.

### 3. Gameplay Mechanics

#### 3.1 Movement & Rotation
*   **Input**: `InputManager` maps keyboard (A/D/S/Space) and touch swipes to game actions.
*   **Collision**: `CollisionSystem` checks the `GameManager`'s logical grid for boundaries and existing blocks before allowing movement or rotation.

#### 3.2 Gravity & Chain Clearing
*   **Gravity**: A system that iterates the grid bottom-up, dropping blocks into empty spaces.
*   **Chain Logic**: 
    *   Identifies `crash` blocks upon locking.
    *   Performs BFS to find same-color connected components.
    *   Clears components of size $> 1$ that contain at least one `crash` block.
*   **Visuals**: Use Excalibur's `Tween` system for fade-out and scaling animations during block deletion.

#### 3.3 Animation Timing
Replaces the manual `t` interpolation with **Timed Transitions**:
*   Logical grid updates immediately.
*   `AnimationComponent` interpolates visual positions over a set duration (e.g., $0.1\text{s}$), mimicking the original `delay()` primitive.

### 4. Technical Stack
*   **Language**: TypeScript
*   **Engine**: Excalibur.js
*   **Bundler**: Vite
*   **Target**: Web browser (Desktop/Mobile)
