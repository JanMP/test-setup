import Snap from "snapsvg-cjs"
import { GeometryDraw } from "../GeometryDraw.coffee"

Drawing({
  id : 'drawing',
  width : '100',
  height : '100',
  renderDrawing(){},
  rendered(){
    let s = new GeometryDraw(this.id())
    this.renderDrawing(s)
  },
  render(){
    <svg id={this.id()} width={this.width()} height={this.height()}>
    </svg>
  }
})
