class SetupTest
  constructor : (@testString) ->
    console.log "setupTest constructor"
  logTestString : -> console.log @testString

exports.SetupTest = SetupTest
