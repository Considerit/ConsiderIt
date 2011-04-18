//from bbyidx

function populateExampleText(formField, exampleText, exampleCssClass, realTextClass) {
  exampleText += "\xA0"
  if(!formField.getValue() || formField.getValue() == exampleText) {
    formField.setValue(exampleText)
    formField.className = exampleCssClass
    formField.blur()  // User may have clicked while we were populating text; if so, make them click again to clear text
  } else {
    formField.className = realTextClass
  }
}

function addExampleText(formField, exampleText, exampleCssClass, realTextClass) {
  Event.observe(
    window, 'load',
    function() {
      populateExampleText(formField, exampleText, exampleCssClass, realTextClass)
    }
  )
  Event.observe(
    formField, 'focus',
    function() {
      if(formField.className == exampleCssClass) {
        formField.setValue('')
        formField.className = realTextClass
      }
    }
  )
  Event.observe(
    formField, 'blur',
    function() {
      populateExampleText(formField, exampleText, exampleCssClass, realTextClass)
    }
  )
  Event.observe(
    formField.form, 'submit',
    function() {
      if(formField.className == exampleCssClass) {
        formField.setValue('')
      }
    }
  )
}
