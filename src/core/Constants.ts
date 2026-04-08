export const GRID_WIDTH = 8;
export const GRID_HEIGHT = 14;
export const TILE_SIZE = 64;
export const COLORS = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF'];
export const ROTATIONS = ['e', 's', 'w', 'n'] as const;
export type Rotation = typeof ROTATIONS[number];
