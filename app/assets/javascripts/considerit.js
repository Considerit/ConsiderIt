
me = {
  init : function() {

    ConsiderIt.delegators();

    ConsiderIt.update_unobtrusive_edit_heights($(".unobtrusive_edit textarea"));

    ConsiderIt.per_request();
    
    
    $('.autoResize, .pointform textarea.point-title, .pointform input[type="text"]').autoResize({extraSpace: 10, maxWidth: 'original'});
    //$('.pointform > form').validateOnBlur();

    $('textarea#statement').autoResize({extraSpace: 5});
    
    // if ( ConsiderIt.results_page ) {
    //   $.get('/' + $.trim($('#proposal_long_id').text()) + '/results', function(data){
    //     var $segments = $(data['segments']);
    //     $('.explore#ranked_points').append($segments);

    //     $('.thanks').fadeOut(function(){
    //       $(this).siblings('.results_prompt').fadeIn();                

    //       $('#histogram').animate({'top': '0px'}, 'slow', function(){
    //         $('.support,.oppose,#axis_arrow,.personal_position.update', $(this)).delay(100).fadeIn();
    //       });
    //     });
    //   });
    // }

    // if ( ConsiderIt.point_page ) {
    //   $('iframe').focus().contents().trigger('keyup').find('#page').trigger('keyup');            
    //   $(".unobtrusive_edit textarea").trigger('keyup');      
    // }

    //ConsiderIt.points.create.initialize_counters('.newpointform, .editpointform');


  },
  per_request : function() {

    // $('.new_comment .is_counted, .pro_con_list .is_counted').each(function(){
    //   if( !$(this).data('has_noblecount') ){        

    //     $(this).NobleCount($(this).siblings('.count'), {
    //       block_negative: true,
    //       max_chars : parseInt($(this).siblings('.count').text())          
    //       //on_negative : ConsiderIt.noblecount.negative_count,
    //       //on_positive : ConsiderIt.noblecount.positive_count
    //     });
    //   }
    // });  


    $('[placeholder]').inlined_labels();

    //$('form.html5:not(.html5formified)').html5form();
    //$('form').h5Validate({errorClass : 'error'});

    $('.autoResize').trigger('keyup');

  },

  delegators : function() {

    /////////////
    // ACCOUNTS
    /////////////

    $(document)

      .on('click', '#acknowledgment a', function(){
        show_tos(700, 700);  
      })

      .on('click', '#zipcode_entered .reset a', function(){
        $(this).siblings('.resetform').show();
      });

    //////////////
    // PROPOSALS
    //////////////
    $(document)
      .on('click', '.proposal_prompt a.show_proposal_description', function(){
        $('.proposal_prompt').removeClass('hiding');
        $(this).remove();
      })

      
      // .on('click', '.description_wrapper a.hidden, .description_wrapper a.showing', function(){
      //   var $block = $(this).parents('.extra:first'),
      //       $full_text = $block.find('.full'), 
      //       show = $(this).hasClass('hidden');

      //   if (show) {
      //     $full_text.slideDown();
      //     $block.find('a.hidden')
      //       .text('hide')
      //       .toggleClass('hidden showing');
      //   } else {
      //     $full_text.slideUp(1000);
      //     $block.find('a.showing')
      //       .text('show')
      //       .toggleClass('hidden showing');      

      //     $('html, body').animate({
      //       scrollTop: 0
      //     }, 1000);

      //   }

      // })
      .on('click', '.edit_page a', function(){
        $(this).toggleClass('edit_mode');
        $('.unobtrusive_edit_form').toggleClass('implicit_edit_mode explicit_edit_mode');
        if ($(this).hasClass('edit_mode')) {
          $('.unobtrusive_edit_form textarea:first').focus();
        } else {
          $('.unobtrusive_edit_form textarea').blur();
        }
      })      

      .on('keyup', '.unobtrusive_edit input[type="text"], .unobtrusive_edit textarea', function(){
        var save_block = $(this).siblings('.save_block');
        if (!save_block.is('.fading')) {      
          save_block.find('input').show();
          save_block.find('.updated').hide();
        }
      })
      .on('ajax:success', '.unobtrusive_edit_form', function(data, response, xhr){
        var $save_block = $(this).find('.save_block');
        //$save_block.find('input').remove();
        $save_block.addClass('fading');

        $save_block.find('input').hide();

        $save_block.find('.updated').show().delay(1200).fadeOut(function(){
          $save_block.removeClass('fading');
        }); 
        if ( $(this).attr('sync_with') ){
          $($(this).attr('sync_with')).text($(this).find('textarea').val());
        }
      })
      .on('focus', '.unobtrusive_edit input[type="text"], .unobtrusive_edit textarea', function(){
        var save_block = $(this).siblings('.save_block');
        save_block.show();
      })      
      .on('blur', '.unobtrusive_edit input[type="text"], .unobtrusive_edit textarea', function(e){
        var save_block = $(this).siblings('.save_block');
        if (!save_block.is('.fading')) {
          save_block
            .find('.updated').hide();
        }
        //if ( !$(e.target).hasClass('.save_block') && !$(e.target).parents('.save_block').length > 0 ) {
        //  save_block.hide();
        //}
      })

    //////////////
    // POINTS
    //////////////

    // new button clicked
    // $(document).on('click', '.pro_con_list.dynamic .newpoint .newpointbutton a.write_new', function(){
    //   //$('.droppable').fadeOut();

    //   $(this).fadeOut(100, function(){
    //     //$('.newpoint').hide();
    //     $(this).parents('.newpoint').find('.pointform')
    //       .fadeIn('fast', function(){
    //         $(this).find('iframe').focus().contents().trigger('keyup').find('#page');            
    //         $(this).find('input,textarea').trigger('keyup');
    //         $(this).find('.point-title').focus(); 

    //       })

    //   });  
    // });

    // edit point
    $(document).on('click', 'a.editpoint', function(e){
      var point = $(this).parents('.point_in_list,.point');
      point.toggleClass('edit_state');
    });

    // Update callback
    $(document).on('ajax:success', '.pro_con_list.dynamic .editpointform form', function(data, response, xhr){
      $(this).parents('.point_in_list:first').replaceWith(response['new_point']);
      hide_lightbox(); 
    });

    // Delete callback
    $(document).on('ajax:success', '.pro_con_list.dynamic a.delete_point', function(data, response, xhr){
      var $deleted_point = $(this).parents('.point_in_list').filter(":first");
      if ($deleted_point.is('#expanded')){
        unexpand_point($deleted_point);
      }           
      $deleted_point.fadeOut();
    });

    var close_point_click = function(e){
      if ( !$(e.target).is('#expanded') && $(e.target).parents('.point_in_list#expanded').length == 0  && $('body > .ui-widget-overlay').length == 0 && $(e.target).filter(':visible').length > 0) {
        $('.point_in_list#expanded .toggle.less:visible').trigger('click');

      }
    };

    var close_point_key = function(e) { 
      if (e.keyCode == 27 && $('body > .ui-widget-overlay').length == 0) {
        $('.point_in_list#expanded .toggle.less:visible').trigger('click');
      }
    };

    // Toggle point details ON
    // $(document).on('click', '.point_in_list:not(.noclick):not(#expanded)', function(){
    //   var real_point = $(this), point_id = real_point.attr('point');
          
    //   var placeholder = $('<li>'); 
    //   placeholder
    //     .attr('id', real_point.attr('id'))
    //     .height(real_point.height())
    //     .addClass(real_point.attr('class'))
    //     .css('visibility', 'hidden');

    //   //close other open points...
    //   $('#expanded .toggle.less:visible').trigger('click');

    //   real_point.after(placeholder);

    //   var body = real_point.find('> .body'),
    //       full = body.find('> .full'),
    //       extra = real_point.find('.extra'),
    //       is_pro = real_point.hasClass('pro'),
    //       is_margin = real_point.hasClass('m-point-peer'),
    //       details_loaded = extra.find('> .ajax_loading').length == 0;

    //   real_point.data({
    //     'container': placeholder.parent()
    //   });

    //   real_point
    //     .css({
    //       'top': placeholder.position().top,
    //       'left': placeholder.position().left,
    //       'background-image': 'none'
    //       //'visibility' : 'hidden'
    //     });

    //   if (real_point.is('.m-point-peer') ) {

    //     var $hidden = real_point.children();
    //     $hidden.css('visibility', 'hidden');
    //   }
    //   real_point.offset(); // forces Chrome to execute proper animation

    //   var top = $('.slate:visible').offset().top - placeholder.parents('.point_list').offset().top, 
    //       left = $('.slate:visible').offset().left - 136;

    //       //left = ConsiderIt.results_page ? $('.slate:visible').offset().left - 136 : $('.margin:first').offset().left + 9;
    //   left -= placeholder.parents('.point_list').offset().left

    //   real_point
    //     .attr('id', 'expanded')
    //     .css({
    //       'top': top, 'left': left,
    //       'background-image': ''
    //       //'visibility': ''
    //     });

    //   if (real_point.is('.m-point-peer') ) {
    //     setTimeout(function(){$hidden.css('visibility', '');},300);
    //   }
    //   $(document)
    //     .click(close_point_click)
    //     .keyup(close_point_key);

    //   $('html, body').animate({
    //     scrollTop: $('.slate:visible').offset().top - 20
    //   }, 1000);

    //   if ( !details_loaded ) {
    //     var proposal_id = $.trim($('#proposal_long_id').text());

    //     $.get('/' + proposal_id + '/points/' + point_id, {'origin' : is_margin ? 'margin' : 'self'}, function(data){
    //       $('.extra', real_point)
    //         .html(data.details)
    //         .find('textarea').autoResize({extraSpace:0});    

    //       setTimeout(function(){
    //         real_point.find('iframe').focus().contents().trigger('keyup').find('#page').trigger('keyup');   
    //         real_point.find(".unobtrusive_edit textarea").trigger('keyup');
    //       }, 1000);

    //       $('#l-content').css('height', Math.max($('#l-content').height(), $('.slate:visible').offset().top + real_point.height() + 100));

    //     });
    //   } else{
    //     setTimeout(function(){
    //       real_point.find('iframe').focus().contents().trigger('keyup').find('#page').trigger('keyup');   
    //       real_point.find(".unobtrusive_edit textarea").trigger('keyup');        
    //     }, 1000);

    //     $('#l-content').css('height', Math.max($('#l-content').height(), $('.slate:visible').offset().top + real_point.height() + 100));

    //   }      


    // });

    // // Toggle point details OFF
    // var unexpand_point = function($point) {
    //   var placeholder = $('#point-' + $point.attr('point'), $point.data('container'));

    //   $(document)
    //     .unbind('click', close_point_click)
    //     .unbind('keyup', close_point_key);

    //   $point
    //     .css({'left':'','top':'','height':'', 'width': ''})
    //     .attr('id', placeholder.attr('id'));
    //   //placeholder.after($point);
    //   placeholder.remove();

    //   $point.trigger('mouseleave');
    //   $('#l-content').css('height', '');

    // };
    // $(document).on('click', '#expanded .toggle.less', function(){
    //   unexpand_point($(this).parents('#expanded'));
    // });


    //////////////
    //COMMENTS
    //////////////

    // post new comment
    $(document).on('ajax:success', '.new_comment form', function(data, response, xhr){
      var new_point = response['new_point'];

      $(this).parents('.new_comment').filter(":first").before(new_point);
      $(this).find('textarea, .the_subject input').val("");

      if ( response['is_following'] ) {
        var commentable = $(this).parents('.commentable:first');
        commentable.find('.follow').hide();
        commentable.find('.unfollow').show();
      }
    });

    // update comment
    $(document).on('ajax:success', '.comment form', function(data, response, xhr){
      var updated_comment = response['updated_comment'];
      $parent = $(this).parents('.comment').filter(":first");
      $parent.replaceWith(updated_comment);
    });

    $(document).on('click', '.comment .edit_comment a', function(){
      $(this).parents('.edit_comment').find('.edit_form').toggleClass('hide');
      $(this).parents('.edit_comment').find('> a').toggleClass('hide');
    });


    //////////////
    // POSITIONS
    //////////////

    // Toggle position statement clicked

    // $(document).on('mouseenter', "#histogram .bar.hard_select .view_statement", function(event){
    //   if ( $('#expanded').length == 0 ) {
    //     $(this).children('.details').show();
    //   }
    // });    

    // $(document).on('mouseout', "#histogram .bar.hard_select .view_statement", function(event){
    //   if ( $('#expanded').length == 0 ) {      
    //     $(this).children('.details').hide();
    //   }
    // });    


    // var close_bar_click = function(e){
    //   if ( !$(e.target).is('.bar.selected') && $(e.target).parents('.bar.selected').length == 0 && $('.point_in_list#expanded').length == 0 && !$(e.target).hasClass('pro_con_list') && $(e.target).parents('.pro_con_list').length == 0 ) {
    //     $('.bar.selected').trigger('click');
    //   }
    // };

    // var close_bar_key = function(e) { 
    //   if (e.keyCode == 27 && $('.point_in_list#expanded').length == 0 && $('body > .ui-widget-overlay').length == 0) {
    //     $('.bar.selected').trigger('click');
    //   }
    // };

    // function select_bar($bar, hard_select) {
    //   var bucket = $bar.attr('bucket'),
    //       $stored = $('#domain_'+bucket),
    //       $histogram = $('#histogram');

    //   $('.bar.selected', $histogram).removeClass('selected hard_select soft_select');
    //   $bar.addClass('selected ' + (hard_select ? 'hard_select' : 'soft_select'));

    //   $stored.show();
    //   $('#ranked_points .pro_con_list:not(#domain_' + bucket + '), .statements').hide();
    //   var $col = $('.full_column', $stored);
    //   if ( !$col.data('carousel_initialized') ) {
    //     $col.dynamicList({'operation': 'refresh'});
    //     $col.data('carousel_initialized', true);
    //   }
    //   $(document)
    //     .click(close_bar_click)
    //     .keyup(close_bar_key);
    // }

    // $(document).on('click', '#histogram .bar.full:not(.hard_select)', function(){
    //   if ( $('#expanded').length == 0 ) {
    //     select_bar($(this), true);
    //   }
    // });
    
    // $(document).on('mouseover', '#histogram .bar.full:not(.selected)', function(){
    //   if ( $('#expanded').length > 0 || $('#histogram .bar.hard_select').length > 0) { return; }
    //   select_bar($(this), false);
    // });

    // function deselect_bars($selected_bar) {
    //   $('#domain_all')
    //     .show()
    //     .siblings('.pro_con_list').hide();
      
    //   //$('.pro_con_list')
    //   //  .removeClass('segmented');

    //   $('.view_statement .details:visible', $selected_bar).hide();
      
    //   $selected_bar.removeClass('selected hard_select soft_select');

    //   $(document)
    //     .unbind('click', close_bar_click)
    //     .unbind('keyup', close_bar_key);
    // }

    // $(document).on('click', '#histogram .bar.selected:not(.soft_select)', function(){
    //   deselect_bars($(this));
    // });
    // $(document).on('mouseleave', '#histogram .bar.full.soft_select', function(e){
    //   var $selected_bar = $('#histogram .bar.selected');
    //   if ( $selected_bar.length == 0 ) { return; }
    //   deselect_bars($selected_bar);        
    // });    
        
    // $(document).on('click', "#histogram .position_statement .important_points .show, .position_statement .important_points .hide", function(){
    //   $(this).parent().children().fadeToggle(); 
    // });


  },

  positions : {

    
    close_segment_click : function(e){
      if ( $(e.target).parents('.point_in_list#expanded').length == 0  && $('body > .ui-widget-overlay').length == 0) {
        $('.point_in_list#expanded .toggle.less:visible').trigger('click');
      }
    },

    close_segment_key : function(e) { 
      if (e.keyCode == 27) {
        $('.point_in_list#expanded .toggle.less:visible').trigger('click');
      }
    },
    
  },

  update_unobtrusive_edit_heights : function (els) {
    els.each(function(){
        var lineHeight = parseFloat($(this).css("line-height")) || parseFloat($(this).css("font-size")) * 1.5;
        var lines = $(this).attr("rows")*1 || $(this).prop("rows")*1;
        $(this).css("height", lines*lineHeight);
    });    
  },

  
};

_.extend(window.ConsiderIt, me);


function show_tos(width, height) {
  var screenX     = typeof window.screenX != 'undefined' ? window.screenX : window.screenLeft,
      screenY     = typeof window.screenY != 'undefined' ? window.screenY : window.screenTop,
      outerWidth  = typeof window.outerWidth != 'undefined' ? window.outerWidth : document.body.clientWidth,
      outerHeight = typeof window.outerHeight != 'undefined' ? window.outerHeight : (document.body.clientHeight - 22),
      left        = parseInt(screenX + ((outerWidth - width) / 2), 10),
      top         = parseInt(screenY + ((outerHeight - height) / 2.5), 10),
      features    = ('width=' + width + ',height=' + height + ',left=' + left + ',top=' + top + ',scrollbars=yes');

      var tos = window.open('/home/terms-of-use', 'Terms of Use', features);

  if (tos.focus)
    tos.focus();

  return false;
}


$.fn.autoGrowInput = function(o) {

    o = $.extend({
        maxWidth: 1000,
        minWidth: 0,
        comfortZone: 10
    }, o);

    this.filter('input:text').each(function(){

        var minWidth = o.minWidth,
            val = '',
            input = $(this),
            testSubject = $('<tester/>').css({
                position: 'absolute',
                top: -9999,
                left: -9999,
                width: 'auto',
                fontSize: input.css('fontSize'),
                fontFamily: input.css('fontFamily'),
                fontWeight: input.css('fontWeight'),
                letterSpacing: input.css('letterSpacing'),
                whiteSpace: 'nowrap'
            }),
            check = function() {
                if (val === (val = input.val())) {return;}

                // Enter new content into testSubject
                var escaped = val.replace(/&/g, '&amp;').replace(/\s/g,' ').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                testSubject.html(escaped);

                // Calculate new width + whether to change
                var testerWidth = testSubject.width(),
                    newWidth = (testerWidth + o.comfortZone) >= minWidth ? testerWidth + o.comfortZone : minWidth,
                    currentWidth = input.width(),
                    isValidWidthChange = (newWidth < currentWidth && newWidth >= minWidth)
                                         || (newWidth > minWidth && newWidth < o.maxWidth);

                // Animate width
                if (isValidWidthChange) {
                    input.width(newWidth);
                }

            };

        testSubject.insertAfter(input);

        $(this).bind('keyup keydown blur update', check);

    });

    return this;

};

//http://blog.colin-gourlay.com/blog/2012/02/safely-using-ready-before-including-jquery/
(function($,d){$.each(readyQ,function(i,f){$(f)});$.each(bindReadyQ,function(i,f){$(d).bind("ready",f)})})(jQuery,document)
