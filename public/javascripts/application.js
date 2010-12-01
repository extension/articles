// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function showAndHide(toShow,toHide) {
	toShow.show();
	toHide.hide();
}

update_category = function(category) {
   var url_split = window.document.URL.toString().split("/");
	url_split[3]= category.replace(/ /g, '+');
   if ( url_split.length > 6 && url_split[4] != 'events') {
      url_split.splice(6);
   }
	
	window.location.href = url_split.join('/');
} 

update_state = function(state) {
   var url_split = window.document.URL.toString().split("/");
   
	if (url_split.length == 5 || url_split.length == 6 ) {
		url_split[5]= state;
	} else {
		url_split[7]= state;
	}
	
   window.location.href = url_split.join('/')
}

set_select_focus = function() {$('zip_or_state').focus();}

// no longer used, but kept around since we may need it in the future
function checkFabricatedHomeSize() {
   var img = $$('.logo img')[0];
   if (img && img.width) {
      if (img.width < 400) {
         $$('.branding_wrapper')[0].removeClassName('doublewide');
      } else {
         $$('.branding_wrapper')[0].addClassName('doublewide');
      }
   }
}

//Done with utils

// onload event callback
function startmeup() {
   // order matters here
   processLinks();
   if (! location.href.include('/print')) {
      processColumns();
   }
   processTableOfContents();
   processBreaks();
   processFlash();
   if (location.href.include('/preview')) {
       getBodyHeight();
    }
   return;
}

Event.observe(window, 'load', startmeup);

function getBodyHeight() {
    var dimensions = $('body_wrapper').getDimensions();
    $("preview_wrapper").style.height = dimensions.height + 'px';
}

function processFlash() {
	fn = $('flash_notice')
	if(!fn) return;
	if(fn.innerHTML == '') return;
	
	new Effect.Opacity(fn, {duration:1.0, from:1.0, to:0.0, delay: 10});
	
}

// pop-up a learning lesson window...size is fixed at 800x590
// <a href="http://www.ll.com/" 
//    onclick="popUpLesson(this.href); return false;">Example</a>
function popUpLesson(e) {
   Event.stop(e);
   var link = this.href;
   var date = new Date();
   var id = date.getTime();
   var width = 800;
   var height = 590;
   var left = (screen.width - width)/2;
   var top = (screen.height - height)/2;
   window.open(link, "lesson" + id, "toolbar=0,scrollbars=0,location=0,statusbar=0,menubar=0,resizable=0,width="+width+",height="+height+",left="+left+",top="+top);
}

function popUpDecision(e) {
   Event.stop(e);
   var link = this.href;
   var date = new Date();
   var id = date.getTime();
   var width = 790;
   var height = 590;
   var left = (screen.width - width)/2;
   var top = (screen.height - height)/2;
   window.open(link, "decision" + id, "toolbar=0,scrollbars=0,location=0,statusbar=0,menubar=0,resizable=0,width="+width+",height="+height+",left="+left+",top="+top);
}

// add an onClick event to all learninglessons links
function processLinks() {
   $$('.content_page a').each(function(link){
      if ( link.href.indexOf('learninglessons') > 1 ) {
         Event.observe(link, 'click', popUpLesson);
      } else if ( link.href.indexOf('decisiontree') > 1 ) {
         Event.observe(link, 'click', popUpDecision);
      }
   })
}

function processBreaks() {
   var allPs = document.getElementsByTagName("p");
   $A(allPs).each(function(p) {
      // handle the IE case
      // then the rest of the world
      if (p.childNodes.length == 1 && p.childNodes[0].nodeName == "BR") {
         $(p).remove();
      } else if (p.childNodes.length == 2 && p.childNodes[0].nodeName == "BR") {
         if (p.childNodes[1].nodeValue == "\n") {
            $(p).remove();
         }
      }
   })
}

function processColumns() {
   var twocol = $("second_column_content");

   if ( twocol ) {
	  twocol = twocol.remove();
	  $('article').style.float = 'left';
      $('article').setAttribute("className", "primarycolumn") // fix for IE7
      $('article').setAttribute("class", "primarycolumn")
	  
	  if(twocol.firstDescendant() && twocol.firstDescendant().nodeName == 'P'){
	  	var first =twocol.firstDescendant();
		if(first && first.firstDescendant() && first.firstDescendant().nodeName == 'BR')
			twocol.firstDescendant().remove();
	  }
	  $('article').insert({before: twocol})      
   }
   return;
}

function addTagsToList(formControl, tagToAdd) {
    separator = ','    
	if(formControl.value == '')
    	formControl.value = tagToAdd
	else
		formControl.value = formControl.value + separator + tagToAdd
}

function processTableOfContents() {
   var toc = $("toc");
   if ( toc ) {
      // just want the stuff in the <ul> block
      var ul = toc.getElementsByTagName('ul')[0];
	  ul.id = 'table_of_contents_ul'
	  toc.select('span.tocnumber').each(function(span){
	  	span.remove()
	  })
	  var div = document.createElement('div')
	  div.id = 'table_of_contents'
	  div.innerHTML = '<h3>Table of Contents</span> <a href="#" id="table_of_contents_button" onclick="toggle_table_of_contents()"> (Hide)</a></h3>'
	  div.appendChild(ul)
      // ul.style.display = 'none'
	  $('article').insert({before: div})
	  toc.remove();
   }
   return toc;
}

toggle_table_of_contents = function() {
	$('table_of_contents_ul').toggle();
	
	if($('table_of_contents_ul').style.display == 'none') {
		$('table_of_contents_button').innerHTML = ' (Show)'
	} else {
		$('table_of_contents_button').innerHTML = ' (Hide)'
	}
	return;
}


