import { SetupTest } from "./test.coffee"

App({
  inputString : "",
  reverse(){
    return this.inputString().split("").reverse().join("")
  },
  created(){
    let test = new SetupTest("Moin, Erde!")
    test.logTestString()
  },
  render(){
    <div>
      <h1>test-setup</h1>
      <input b="value : inputString"/>
      <p b="text : reverse"></p>
    </div>
  }
});
