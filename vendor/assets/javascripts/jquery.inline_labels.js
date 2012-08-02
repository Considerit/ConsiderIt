/****************************************************************************
 * for each input with placeholder attribute set, replace with inline labels
 ****************************************************************************/

// heavily modified version of below plugin -Travis

/*!
* Cross-browser Inline Labels Plugin for jQuery
*
* Copyright (c) 2010 Mark Dodwell (@madeofcode)
* Licensed under the MIT license
*
* Requires: jQuery v1.3.2
* Version: 0.1.0
*/

(function($){
  // is an input blank
  $.fn.isEmpty = function() {
    return $.trim($(this)[0].value) === '';
  };

  // return top/left offset for element
  $.fn.innerOffset = function() {
    var el = $(this);

    // TODO check for nil?
    var topOffset = 
      parseInt(el.css('marginTop')) + 
      parseInt(el.css('paddingTop')) +
      parseInt(el.css('borderTopWidth'));
      
    // TODO check for nil?
    var leftOffset = 
      parseInt(el.css('marginLeft')) + 
      parseInt(el.css('paddingLeft')) +
      parseInt(el.css('borderLeftWidth'));

    return { top: topOffset, left: leftOffset };
  };


  $.fn.inlined_labels = function(){
    
    $(this).each(function(){ 

      var el = $(this), 
          label = $('<label></label>'),
          leftOffset = el[0].tagName == "TEXTAREA" ? 0 : 2,
          hidden_parent = el.is(":visible") ? null : el.parents(':hidden:last');

      if ( hidden_parent ) {
        console.log(hidden_parent.attr('class'))
        console.log(el);
      }
      if( el.data('inlined') ) return;
      el.data('inlined', true);

      if( hidden_parent ) {
        hidden_parent.show();
      }

      label
        .attr('for', el.attr('name'));
      label
        .text(el.attr('placeholder'))
        .addClass('inline')
        .css({
          fontSize: el.css('fontSize'), 
          fontFamily: el.css('fontFamily'),
          fontWeight: el.css('fontWeight'),
          lineHeight: el.css('lineHeight'),
          letterSpacing: el.css('letterSpacing'),
          top: el.position().top + el.innerOffset().top,
          left: el.position().left + el.innerOffset().left + leftOffset,
          width: el.width() - leftOffset
        });

      if( hidden_parent ) {
        hidden_parent.hide();
        hidden_parent.css('display', '');
      }


      el.before(label);
      el.attr('placeholder', '');

      // delegate mousedown to input
      label.mousedown(function(e) {
          $(this).next().focus();
          e.stopPropagation();
          e.preventDefault();
          return false;
        });

      el.focus(function() {
        var el = $(this);
        var label = el.prev();

        label.addClass("focus");

        // clear existing timer (maybe don't need this?)
        var timer = el.data('inline.timer');
        window.clearInterval(timer);
        el.data('inline.timer', null);

        // set timer
        el.data('inline.timer', window.setInterval(function() {
          if (!el.isEmpty()) label.removeClass('empty');
        }, 25));
      });

      el.blur(function() {
        var el = $(this);
        var label = el.prev();

        label.removeClass("focus");

        // cancel timer
        var timer = el.data('inline.timer');
        window.clearInterval(timer);
        el.data('inline.timer', null);

        if (el.isEmpty()) label.addClass("empty");
      });

      // show input if empty
      if (el.isEmpty()) label.addClass("empty");
    });
  }
})(jQuery);