import { Engine } from 'excalibur';
import { GameState } from './states/GameState';

export class CrashBlocksGame extends Engine {
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
