import { Component } from 'excalibur';
import { GridPos } from '../../core/Types';
export class GridPositionComponent extends Component {
    constructor(public pos: GridPos) { super(); }
}
