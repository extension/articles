// === COPYRIGHT:
//  Copyright (c) 2005-2009 North Carolina State University
//  Developed with funding for the National eXtension Initiative.
// === LICENSE:
//  BSD(-compatible)
//  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

function identityEnable(toEnable) {
    toEnable.disabled=false
}

function identityDisable(toDisable) {
    toDisable.disabled=true
}

function fitTextArea(textControl) {
  textArray = new Array()
  
  controlText = textControl.value
  
  numRows = textControl.rows
  textArray = controlText.split('\n')
  
  if (textArray.length > numRows) {
    textControl.rows = textArray.length + 7
  }
  
  if (textArray.length < numRows - 7) {
    textControl.rows = textArray.length + 1
  }
  
}

function addTagsToList(formControl, tagToAdd) {
    separator = ','    
	if(formControl.value == '')
    	formControl.value = tagToAdd
	else
		formControl.value = formControl.value + separator + tagToAdd
}

function clearFormControl(formControl) {
	formControl.value = ''
}