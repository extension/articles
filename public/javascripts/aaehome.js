// === COPYRIGHT:
//  Copyright (c) 2005-2009 North Carolina State University
//  Developed with funding for the National eXtension Initiative.
// === LICENSE:
//  BSD(-compatible)
//  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

function equalHeight(group) {
    tallest = 0;
    group.each(function() {
        thisHeight = $(this).height();
        if(thisHeight > tallest) {
            tallest = thisHeight;
        }
    });
    group.height(tallest);
}

$(document).ready(function() {
    equalHeight($(".column"));
});