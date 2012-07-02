// ...
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery.noblecount.min.js
//= require jquery.example.min.js
//= require jquery.jcarousel.min.js
//= require jquery.autoresize.js
//= require jquery.html5form.js
//= require jquery.inline_labels.js
//= require javascripts/reflect.considerit.js
//= require javascripts/acts_as_followable.js
//= require ZeroClipboard.js
//= require considerit

//http://blog.colin-gourlay.com/blog/2012/02/safely-using-ready-before-including-jquery/
(function($,d){$.each(readyQ,function(i,f){$(f)});$.each(bindReadyQ,function(i,f){$(d).bind("ready",f)})})(jQuery,document)
