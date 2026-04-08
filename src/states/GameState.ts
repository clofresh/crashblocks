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
