import { GeometryDraw, TestSetup3 } from "./GeometryDraw.coffee"

App({
  testSetup : {},
  views : [],
  created(){
    let test = new TestSetup3()
    this.testSetup(test)
    this.views(test.getViews())
  },
  autorun(){
    console.log("autorun", this.views())
  },
  render(){
    <div>
      <Drawing b="repeat : views, key : key"/>
    </div>
  }
});
