import { Component } from 'excalibur';
import { BlockType } from '../../core/Types';
export class TypeComponent extends Component {
    constructor(public type: BlockType) { super(); }
}
