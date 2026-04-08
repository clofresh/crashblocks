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
