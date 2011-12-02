var ConsiderIt; //global namespace for ConsiderIt js methods

(function($) {

$j = jQuery.noConflict();



ConsiderIt = {
  study : false,
  subdirectory: '/blogademia',
  init : function() {

    ConsiderIt.delegators();

    ConsiderIt.per_request();

    $j(document).ajaxComplete(function() {
      ConsiderIt.per_request();
    });
    
    $j('a.smooth_anchor').click(function(){
      $j('html, body').animate({
        scrollTop: $j($j(this).attr('href')).offset().top}, 1000);
        return false;
    });

    $j("#points_other_pro, #points_other_con").each(function(){
      $j(this).infiniteCarousel({
        speed: 1000,
        vertical: true,
        total_items: parseInt($j(this).find('.total:first').text()),
        items_per_page: 4,
        loading_from_ajax: true, 
        dim: 600,
        resetSizePerPage: true,
        total_items_callback: function($carousel){
          if ($carousel.find('.total:first').length > 0) {
            return parseInt($carousel.find('.total:first').text());
          } else {
            return $carousel.find('li.point_in_list').length;
          }
        }
      });
    }); 

    $j('#intro .initiatives.horizontal').infiniteCarousel({
      speed: 1500,
      vertical: false,
      total_items: 5,
      items_per_page: 5,
      loading_from_ajax: false,
      dim: 680
    });

    $j('#description .initiatives.horizontal').infiniteCarousel({
      speed: 1500,
      vertical: false,
      total_items: 8,
      items_per_page: 8,
      loading_from_ajax: false,
      dim: 720
    });    

    $j('.initiatives.vertical').infiniteCarousel({
      speed: 1500,
      vertical: true,
      total_items: 5,
      items_per_page: 5,
      loading_from_ajax: false,
      dim: 250
    });

    $j('.statement_carousel .vertical_carousel').infiniteCarousel({
      speed: 1500,
      vertical: true,
      //total_items: 5,
      items_per_page: 12,
      loading_from_ajax: false,
      dim: 610,
      resetSizePerPage: false
    });    

    if( $j('#intro').length == 0 ){
      //$j('#masthead').append('<a class="home" href="/">home</a>');
    }

    //ConsiderIt.points.create.initialize_counters('.newpointform, .editpointform');

    // google analytics
    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
        
  },
  per_request : function() {

    if ( !$j.browser.msie ) {
      $j('.add_corner').corner('5px');
      $j('#nav-user').corner('bottom bl 5px');  
      $j('#masthead').corner('round top 5px');
      $j('.point_in_list_margin .inner, .point_in_list.expanded .inner').corner('5px');
      $j('#initiative #description .initiative_item').corner('round top 5px');
      //$j('.avatar').corner('5px');
      $j('input[type="submit"]').corner('5px');
      $j('#registration_form .primary, #registration_form .secondary').corner('8px');
      $j('#pledge_form button').corner('5px');
      $j('#confirmation_sent button#go').corner('5px');
      $j('.newpointform > form').corner('5px');
      $j('.point_link_prompt .button').corner('5px');
      $j('#console').corner('5px');
      $j('#console .nav a').corner('5px');
      $j('.point_in_list .comment_text').corner('5px');
      $j('.droppable').corner('5px');
    }

    $j('.carousel .point_in_list_margin.pro').draggable({
      helper: 'clone',
      cursor: 'move',
      snap: '#drop-pro'
    });

    $j('.carousel .point_in_list_margin.con').draggable({
      helper: 'clone',
      cursor: 'move',
      snap: '#drop-con'
    });

    $j('#drop-con').droppable( {
      hoverClass: 'hovered',
      drop: function( event, ui ) {
        var draggable = ui.draggable;
        $j('#inclusion_submit', draggable).trigger('click');
      },
      accept: '.con'
    } );

    $j('#drop-pro').droppable( {
      hoverClass: 'hovered',
      drop: function( event, ui ) {
        var draggable = ui.draggable;
        $j('#inclusion_submit', draggable).trigger('click');
      },
      accept: '.pro'
    } );      
           
    $j('.has_example').each(function(){
      if($j(this).val() == '') {
        $j(this).example(function() {
          return $j(this).attr('title'); 
        });
      }
    });

    $j('.add_qtip').each(function(){
      if(!$j(this).data('qtip')) {
        $j(this).qtip({ 
          style: { name: 'cream', tip: true }, 
          position: {corner: { target: 'bottomMiddle', tooltip: 'topMiddle' } }
        });
      }
    });

    $j('.new_comment .is_counted, .user_position .is_counted').each(function(){
      if( !$j(this).data('has_noblecount') ){        

        $j(this).NobleCount($j(this).siblings('.count'), {
          block_negative: true,
          max_chars : parseInt($j(this).siblings('.count').text()),          
          on_negative : ConsiderIt.noblecount.on_negative,
          on_positive : ConsiderIt.noblecount.on_positive
        });
      }
    });  

    $j("#ranked_points .points_board").each(function(){
      $j(this).infiniteCarousel({
        speed: 1000,
        vertical: true,
        total_items: parseInt($j(this).find('.total:first').text()),
        items_per_page: 4,
        loading_from_ajax: true, 
        dim: 700,
        resetSizePerPage: true,
        total_items_callback: function($carousel){
          return parseInt($carousel.find('.total:first').text());
        }
      });
    });   

    ConsiderIt.update_carousel_heights();

  },

  delegators : function() {

    /////////////
    // ACCOUNTS
    /////////////

    $j(document).delegate('#confirmation_sent button#go', 'click', function(){
        $j('#pledge_dialog').dialog('close');
      });

    $j(document).delegate('#lvg_account a.cancel', 'click', function(){
      $j('.user_dialog, #settings_dialog').dialog('close');
    });

    $j(document).delegate('#acknowledgment a', 'click', function(){
      show_tos(500, 700);  
    });

    $j(document).delegate('#zipcode_entered .reset a', 'click', function(){
      $j(this).siblings('.resetform').show();
    });

    //////////////
    // OPTIONS
    //////////////
    $j(document).delegate('#description a.show_option_description', 'click', function(){
      $j('#description').removeClass('hiding');
      $j(this).remove();
    });

    $j(document).delegate('.description_wrapper .prompt a', 'click', function(){
      if($j(this).hasClass('hidden')){
        $j(this).parents('.prompt:first').siblings('.full').slideDown();
        $j(this).text('hide');
      } else {
        $j(this).parents('.prompt:first').siblings('.full').slideUp();
        $j(this).text('show');
      }
      $j(this).toggleClass('hidden');

    });

    //////////////
    // POSITIONS
    //////////////

    // Toggle position statement clicked

    $j("#step_through").delegate(".statement a, .full_statement a.close", 'click', function(event){
      var user_id = $j.trim($j(this).parent().find('.userid').text()),
          prompt = $j("#user-" + user_id + " a").find('.read_statement'),
          closing = !$j(this).hasClass('.view_statement') && $j(this).find('.username:visible').length == 0,
          full_statement = $j("#user-" + user_id + "-full"),
          statement = $j("#user-" + user_id);

      if ( closing ) {
        statement.removeClass('active');
        $j('.discuss').slideUp();
        hide_lightbox();
      } else {
        $j('.full_statement a.close:visible').trigger('click');
        statement.addClass('active');

        show_lightbox();
      }

      full_statement.slideToggle('slow', function(){
        if (!closing) { 
          full_statement.find('.discuss').slideDown('slow');
        }
      });

      if ( !closing ) {
        ConsiderIt.positions.stance_group_clicked('user-' + user_id);
      } else if ( event.which ) { // don't want to do anything if triggered programmatically

      }


    });    

    $j("#step_through").delegate(".show_all", 'click', function(){
      ConsiderIt.positions.stance_group_clicked('all');      
    });

    $j('#step_through').delegate(".full_statement .important_points .show, .full_statement .important_points .hide", 'click', function(){
      $j(this).parent().children().fadeToggle(); 
    });
            
    //////////////
    // POINTS
    //////////////

    // new button clicked
    $j('#points').delegate('.newpoint .newpointbutton button', 'click', function(){
      $j(this).parents('.newpoint:first').find('.pointform').fadeIn('fast');      
      show_lightbox();
    });

    // edit point clicked
    $j('#points').delegate('a.editpoint', 'click', function(){
      $j(this).parents('.edit:first').find('.pointform').fadeIn('fast');      
      show_lightbox();
    });

    // new/edit point cancel clicked
    $j('#points').delegate('.new_point_cancel', 'click', function(){
      $j(this).parents('.pointform:first').fadeOut(function(){
        hide_lightbox();
      });
    });

    // Create callback
    $j('#points').delegate('.newpoint .newpointform form', 'ajax:success', function(data, response, xhr){
      $j(this).parents('.points_self:first').find('.point_list:first').append(response['new_point']);
      $j(this).find('textarea').val('');
      $j(this).find('.point-title-group .count').html(140);
      $j(this).find('.point-description-group .count').html(2000);
      
      $j(this).find('.new_point_cancel').trigger('click');
    });

    // Update callback
    $j('#points').delegate('.editpointform form', 'ajax:success', function(data, response, xhr){
      $j(this).parents('.point_in_list:first').replaceWith(response['new_point']);
      hide_lightbox(); 
    });

    // Delete confirmation prompt
    $j('#points').delegate('a.delete_point', 'click', function(){
      $j(this).siblings('form').show();  
    });
    $j('#points').delegate('.deletepointform a.cancel', 'click', function(){
      $j(this).parents('form').hide();  
    });

    // Delete callback
    $j('#points').delegate('.deletepointform form', 'ajax:success', function(data, response, xhr){
      $j(this).parents('.point_in_list:first').fadeOut();
    });

    // Toggle point details ON
    $j(document).delegate('.point_in_list .toggle.more', 'click', function(){
      var real_point = $j(this).parents('.point_in_list');      
      real_point.draggable( "disable" );
      var placeholder = $j('<li>'); 
      placeholder
        .addClass('point_in_list')
        .attr('id', real_point.attr('id'))
        .height(real_point.height())
        .css('visibility', 'hidden');

      var is_pro = real_point.hasClass('pro');

      // store properties for restoration later...
      real_point.data('properties', {
        width: real_point.css('width'),
        marginLeft: real_point.css('marginLeft')
      });

      real_point.after(placeholder);

      real_point = real_point.detach();
      $j('body').append(real_point);

      real_point
        .addClass('expanded')
        .css({
          'z-index': 1001,
          'position': 'absolute',
          'top': placeholder.offset().top,
          'left': placeholder.offset().left 
        });

      show_lightbox();

      if ( !is_pro ){
        offset = real_point.hasClass('point_in_list_margin') ? -900 : -700;
        offset += real_point.width();
      } else {
        offset = real_point.hasClass('point_in_list_margin') ? 0 : -200;
      }

      var animate_properties = { 
        width: '900px',
        marginLeft:  offset + 'px'
      };


      real_point.animate(animate_properties, function(){
        real_point.find('.point_text.full').slideDown(function(){
          real_point.find('.avatar').fadeIn();
          real_point.find('.discuss').slideDown();
        });
      });

      real_point.find('.toggle.more').fadeOut(function(){real_point.find('.less').fadeIn();});
      ConsiderIt.per_request();
    });

    // Toggle point details OFF
    $j(document).delegate('.point_in_list .toggle.less', 'click', function(){

      var real_point = $j(this).parents('.point_in_list'), 
          placeholder = $j('#' + real_point.attr('id') + ':not(.expanded)'),
          is_pro = real_point.hasClass('pro'),
          animate_properties = real_point.data('properties');

      real_point.find('.discuss').slideUp(function(){
        real_point.find('.avatar').fadeOut();
        real_point.find('.point_text.full').slideUp(function(){
          real_point.animate(animate_properties, function(){
            real_point.css({
              'z-index': 'inherit',
              'position': 'relative',
              'top': 'auto',
              'left': 'auto',
              'right': 'auto',
              'display': 'block'
            });

            real_point
              .removeClass('expanded')
              .find('.toggle.less').hide();
            
            placeholder.replaceWith(real_point);

            if ( real_point.hasClass('point_in_list_margin') ) {
              real_point.draggable( "enable" );
            }

            hide_lightbox();  

            placeholder.remove();
            real_point.find('.more').fadeIn();

          });
        });        


      });


      
    });


    //////////////
    // INCLUSIONS
    //////////////

    // Include in list
    $j(document).delegate('.include .judgepointform form', 'ajax:success', function(data, response, xhr){
      var included_point = $j(this).parents('.point_in_list_margin'), 
      replacement_point = $j(response['new_point']);
    
      if ( included_point.hasClass('pro') ) {
        var user_point_list = $j('#points_on_board_pro .point_list');
        var other_point_list = $j('#points_other_pro .point_list');
      } else {
        var user_point_list = $j('#points_on_board_con .point_list');
        var other_point_list = $j('#points_other_con .point_list');
      }

      var carousel = other_point_list.parents('.infiniteCarousel:first'),
          replacement_point_already_in_list = other_point_list.find('#' + replacement_point.attr('id')).length > 0;

      included_point.fadeOut('slow', function() {
        // only use replacement point if it doesn't already exist in the list
        included_point = replacement_point && replacement_point.length > 0 && !replacement_point_already_in_list
           ? included_point.replaceWith(replacement_point) 
           : included_point.detach();

        replacement_point.draggable({
          helper: 'clone',
          cursor: 'move'
        });
        user_point_list.append(included_point);
        included_point
          .removeClass('point_in_list_margin')
          .addClass('point_in_list_self')
          .fadeIn('slow');

        carousel.infiniteCarousel({'operation': 'refresh', 'total_items': parseInt(response['total_remaining'])});
      });
    });

    // Remove from list
    $j(document).delegate('.remove .judgepointform form', 'ajax:success', function(data, response, xhr){
      var old_point = $j(this).parents('.point_in_list_self:first'),
        other_point_list = old_point.hasClass('pro') ? $j('#points_other_pro .point_list') : $j('#points_other_con .point_list'),
        carousel = other_point_list.parents('.infiniteCarousel:first');

      old_point.fadeOut('slow', function(){
        old_point = old_point.detach(); 
        other_point_list.append(old_point);
        carousel.infiniteCarousel({'operation': 'refresh', 'total_items': parseInt(response['total_remaining'])});
        old_point
          .fadeIn('slow')
          .removeClass('point_in_list_self')
          .addClass('point_in_list_margin')
          .corner('5px')
          .draggable({
            helper: 'clone',
            cursor: 'move'
          });
      });
    });

    //////////////
    //COMMENTS
    //////////////

    // post new comment
    $j(document).delegate('.new_comment form', 'ajax:success', function(data, response, xhr){
        
      var new_point = response['new_point'],
      $parent = $j(this).parents('.comment:first');
      //because we cloned the point in order to show an expanded version when the point in the list 
      // is contained in the carousel, need to add the comment in both places...
      $parent = $j('#' + $parent.attr('id'));
      if($parent.length > 0){
        $parent.find('.comment_children:first').prepend(new_point);
        $j('.new_comment textarea').val("");
        $parent.find('.reply_row a.cancel').trigger('click');
      } else {
        $j(this).parents('.new_comment:first').before(new_point);
        $j(this).find('textarea, .the_subject input').val("");
      }

    });

  },

  positions : {

    set_slider_value : function(new_value, initiative_name){
        
      var supporting = new_value > 0,
        size = new_value * 50;
      if ( supporting ) {
        $j( '.slider_table .right').css('font-size', 100 + 1.5 * size + '%');
        $j( '.slider_table .left').css('font-size', 100 - size + '%');
      } else {
        $j( '.slider_table .right').css('font-size', 100 + size + '%');
        $j( '.slider_table .left').css('font-size', 100 - 1.5 * size + '%');
      }
      
      $j('#stance-value').val( new_value );  
    },
    
    stance_group_clicked : function(bucket) {

      var option_id = $j('#option_id').text(),
          position_id = $j('#position_id').text(),
          nest = '.ranked_points_bucket_'+bucket,
          $stored = $j(nest);

      // update position statements
      if ( bucket.toString().substring(0,4) == 'user' ){
        if( $stored.length > 0 ) {
          $stored.fadeIn();
        } else {
          $j.get(ConsiderIt.subdirectory + "/options/" + option_id + "/points", { bucket: bucket },
            function(data){
              $j('.full_statement:visible .important_points').append(data['points']);
          } );
        }
      } else if ( bucket == 'all' ) {
        $j('#ranked_points .group').fadeOut();
        $stored.fadeIn();
        $j('.statement:hidden').fadeIn();

        $j('.showing_filtered').fadeOut(function(){
          $j('.showing_all').fadeIn();
        });

        $j('.explore#ranked_points h3.banner').text('All reviews');
        $j('.explore#ranked_points h3.subheader').text('Ranked pros and cons that reviewers considered important.');

        $j('li.step.statement_carousel').data('showing', bucket);
        reset_selected_idx();
        $j('.statement_carousel .vertical_carousel')
          .infiniteCarousel({'operation': 'restart'});
      } else {

        if( $stored.length > 0 ) {
          $j('#ranked_points .group').fadeOut();
          $stored.fadeIn();
        } else {
          $j.get(ConsiderIt.subdirectory + "/options/" + option_id + "/points", { bucket: bucket },
            function(data){
              $j('#ranked_points .group').fadeOut();
              $j('#ranked_points').append(data['points']);
          } );
        }        
        var with_bucket = $j('.bucket-' + bucket),
            without_bucket = $j('.statement:not(.bucket-' + bucket);
        without_bucket.fadeOut('slow', function(){
          with_bucket.fadeIn('slow');
        });

        $j('.explore#ranked_points h3.banner').html(ConsiderIt.positions.stance_name(bucket));
        $j('.explore#ranked_points h3.subheader').text('Ranked pros and cons these reviewers considered important.');

        if ( $j('.showing_filtered:hidden').length > 0) {
          $j('.showing_all').fadeOut(function(){
            $j('.showing_filtered').fadeIn();
          });
        }

        $j('.full_statement:visible a.close').trigger('click');
        $j('li.step.statement_carousel').data('showing', bucket);
        $j('.statement_carousel .vertical_carousel')
          .infiniteCarousel({'operation': 'restart'});        
      }


    
      //if (ConsiderIt.study){
      //  $j.post('/home/study/3', {
      //    position_id: position_id,
      //    option_id: option_id,
      //    detail1: bucket
      //  });  
      //}
                  
    },
    
    set_stance : function(bucket, dontadjust) {
      if (dontadjust) bucket = parseInt(bucket)
      $j('.stance_name').text(ConsiderIt.positions.stance_name(bucket));
    },
    
    stance_name : function(d) {
      switch (d) {
        case 0: 
          return "Strong opposers"
        case 1: 
          return "Opposers"
        case 2:
          return "Borderline opposers"
        case 3:
          return "Neutral reviewers"
        case 4:
          return "Borderline supporters"
        case 5:
          return "Supporters"
        case 6:
          return "Strong supporters"
      }
    }  
    
  },

  update_carousel_heights: function(){
    $j('.points_other .point_list').css({
      'height': $j('.user_position').height()
    })
  },
  noblecount :  {
    positive_count : function( t_obj, char_area, c_settings, char_rem ) {
      var submit_button = t_obj.parents( 'form' ).find( 'input[type="submit"]' );
      
      if ( char_area.hasClass( 'too_many_chars' ) ) {
        char_area.removeClass( 'too_many_chars' ).css( {
          'font-weight' : 'normal',
          'font-size' : '125%'
        } );
    
        submit_button
            .animate( {
              opacity : 1,
              duration : 50
            } ).attr( 'disabled', false ).css( 'cursor', 'pointer' );
        t_obj.data( 'disabled', false );
      } else if ( char_rem < c_settings.max_chars && $j( t_obj ).data( 'disabled' ) ) {
        t_obj.data( 'disabled', false );
        submit_button
            .attr( 'disabled', false );
      } else if ( char_rem == c_settings.max_chars ) {
        t_obj.data( 'disabled', true );
        submit_button
            .attr( 'disabled', true );
      }
      
    },    
    negative_count : function( t_obj, char_area, c_settings, char_rem ) {
      var submit_button = t_obj.parents( 'form' ).find( 'input[type="submit"]' );
      if ( !char_area.hasClass( 'too_many_chars' ) ) {
        char_area.addClass( 'too_many_chars' ).css( {
          'font-weight' : 'bold',
          'font-size' : '175%'
        } );
    
        t_obj.parents( parent_selector ).find( submit_selector )
            .animate( {
              opacity : .25,
              duration : 50
            } ).attr( 'disabled', true ).css( 'cursor', 'default' );
        t_obj.data( 'disabled', true );
    
      } 
    }
  }
  
};

})(jQuery);


// TODO: integrate better into code

function show_lightbox(callback){
  $j('#lightbox').css({
    'background' : '#000000',
    'z-index' : 1000
  });
  if ( !$j.browser.msie ) {

    $j('#lightbox').fadeIn('slow', callback);
  } else {
    
  }
}

function hide_lightbox(callback){
  if ( !$j.browser.msie ) {
    $j('#lightbox').fadeOut('slow', callback);
  } else {
    $j('#lightbox').css({
      'background' : 'transparent',
      'z-index' : -100
    });    
  }
}

// FROM: https://github.com/ryanb/complex-form-examples/blob/master/public/javascripts/application.js
function remove_fields(link) {
  jQuery(link).parents('.point_link_form').remove();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  var new_content = content.replace(regexp, new_id);
  jQuery(link).parent().prepend(new_content);
}

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

function login(provider_url, width, height) {
  var screenX     = typeof window.screenX != 'undefined' ? window.screenX : window.screenLeft,
      screenY     = typeof window.screenY != 'undefined' ? window.screenY : window.screenTop,
      outerWidth  = typeof window.outerWidth != 'undefined' ? window.outerWidth : document.body.clientWidth,
      outerHeight = typeof window.outerHeight != 'undefined' ? window.outerHeight : (document.body.clientHeight - 22),
      left        = parseInt(screenX + ((outerWidth - width) / 2), 10),
      top         = parseInt(screenY + ((outerHeight - height) / 2.5), 10),
      features    = ('width=' + width + ',height=' + height + ',left=' + left + ',top=' + top + ',scrollbars=yes');

  newwindow = window.open(provider_url, '_blank', features);

  if (window.focus)
    newwindow.focus();

  return false;
}
