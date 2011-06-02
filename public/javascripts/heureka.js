/*
  *This javascript file holds the javascripts used for the heureka project.
*/

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

function importData(text1, text2) {
  text2.value = text1.value
}

function clearData(datafield) {
  datafield.value = ""
}

function clearList(dataList) {
  
    for (i = dataList.options.length - 1; i >= 0; i--){
      dataList.options[i] = null     
    }
  
}

function clearSelectedValues(dataList) {
   len = dataList.options.length
   for (i = len - 1; i >= 0; i--) {
     if (dataList.options[i].selected) {
         dataList.options[i] = null
     }   
   }
   
   // dataList.options[dataList.selectedIndex] = null
}

function enableDisable(toEnable, toDisable) {
    toEnable.disabled=false
    toDisable.disabled = true    
}

function changeBackground(spanElement) {
    if (spanElement.className == "keyword") {
      spanElement.className = "hoverkeyword"
    }
    else{
      spanElement.className = "keyword"
    }
    
}

function handleComplete(responseObj, divElement) {
    if (responseObj.status == 200) {
      divElement.innerHTML = '<p class="success">Changes saved!</p>'
    }
    else {
      divElement.innerHTML = '<p class="error">There was an error saving your settings. Please try again.</p>'
    }
    
    new Effect.Opacity(divElement.id, {duration:6.0, from:1.0, to:0.0})
}

function addToList(formControl, elementToAdd) {
    len = formControl.options.length
    formControl.options[len] = new Option(elementToAdd)
    
}

function addValuesToList(formControl, add_text) {
    if (add_text.indexOf(",") >= 0) {
      keyword_array = add_text.split(",")
      for(i=0; i< keyword_array.length; i++) {
        len = formControl.options.length
        formControl.options[len] = new Option(keyword_array[i])
      }
    }      
    else {
      addToList(formControl, add_text)   
    }
    
}

function changeValue(textField, newValue) {
    textField.value = newValue    
}

function selectAll(dataList) {
    len = dataList.options.length
    for (i=0; i < len; i++) {
        dataList.options[i].selected = true
    }
    
}

function toggleTextControl(isChecked, text_element) {
    if(isChecked == true) {
        text_element.disabled = false
    }
    else {
        text_element.disabled = true
    }
}

function submit_on_enter(selectControl, textControl) {
    input_text = textControl.value
    if (input_text.charCodeAt(input_text.length-1) == 10) {
      addValuesToList(selectControl, input_text)
      textControl.value = ""
      textControl.focus()
    }
}

function editListOption(editBox, list) {
    list[list.selectedIndex].text = editBox.value
    list[list.selectedIndex].value = editBox.value
}

var Timezone = {
  set : function() {
    var date = new Date();
    var timezone = "timezone=" + -date.getTimezoneOffset() * 60;
    date.setTime(date.getTime() + (1000*24*60*60*1000));
    var expires = "; expires=" + date.toGMTString();
    document.cookie = timezone + expires + "; path=/";
  }
}


$j(document).ready(function() {
 $j(".fancybox").fancybox({
		'titleShow'		: false
	});
})
