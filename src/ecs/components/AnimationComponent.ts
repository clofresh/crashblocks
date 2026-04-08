import { Component } from 'excalibur';
import { GridPos } from '../../core/Types';
export class AnimationComponent extends Component {
    constructor(
        public prevPos: GridPos,
        public targetPos: GridPos,
        public progress: number = 0
    ) { super(); }
}
