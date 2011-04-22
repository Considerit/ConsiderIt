// TODO: clean this up, namespace it...

$j = jQuery.noConflict();


function callback_judge_point_success(response_text, point_id, judgement, is_from_other_list) {

    if ( is_from_other_list == 1 ) {
      var old_point = $j('#point_in_list_other-' + point_id),
          jsoned = $j.parseJSON(response_text),
          new_point = jsoned['new_point'];

      if ( old_point.hasClass('pro') ) {
        var new_point_list = $j('#points_self_pro .point_list');
				var other_point_list = $j('#points_other_pro .point_list');
      } else {
        var new_point_list = $j('#points_self_con .point_list');
        var other_point_list = $j('#points_other_con .point_list');
      }
      
      old_point.fadeOut('slow', function(){
        if ( new_point && (judgement == 1 && other_point_list.find('#' + $j($j(new_point)[0]).attr('id')).length == 0)) {
          var sel = old_point.attr('id');
					old_point.replaceWith(new_point);     
          add_tips(sel);
        } else {
          old_point.remove();
        }
        
        if ( judgement == 1 ) {
          new_point_list
            .append(jsoned['approved_point']);
          add_tips(new_point_list.attr('id') + '.point_in_list:last');	
        }
        update_list_counts(other_point_list, judgement, jsoned['pagination']);
        
      });  
    }
    else {
      var old_point = $j('#point_in_list_self-' + point_id),
          jsoned = $j.parseJSON(response_text),
          new_point = jsoned['new_point'];    
            
      if ( old_point.hasClass('pro') ) {
        var new_point_list = $j('#points_other_pro .point_list');
      } else {
        var new_point_list = $j('#points_other_con .point_list');
      }
      
      old_point.fadeOut('slow', function(){
        old_point.remove(); 
        new_point_list
          .append(jsoned['approved_point']);
        add_tips(new_point_list.attr('id') + '.point_in_list:last');                            
        update_list_counts(new_point_list, judgement, jsoned['pagination']); 
      });        
      
    }
}

function update_list_counts(point_list, judgement, pagination) {
  var footer = point_list.parent().find('.point_list_footer'),
      total = footer.find('.total');
      
  footer.find('.total').html(pagination);  
}


function set_more_less_text_toggle(sel, point_id, initiative_id) {
  $j(sel + ' .toggle.more').click(function(){
    $j(sel + ' .point_text.full').slideDown();
    $j(this).fadeOut(function(){$j(sel + ' .less').fadeIn();});
    var data = {
      point_text_toggle: {
        more: true,
        point_id: point_id,
        initiative_id: initiative_id
      }
    };
    $j.post('/study/point_text_toggle', data);
  });

  $j(sel + ' .toggle.less').click(function(){
    $j(sel + ' .point_text.full').slideUp();
    $j(this).fadeOut(function(){$j(sel + ' .more').fadeIn();});
    var data = {
      point_text_toggle: {
        more: false,
        point_id: point_id,
        initiative_id: initiative_id
      }
    };
    $j.post('/study/point_text_toggle', data);    
  });

}

function log_general(el, action, extra, async){
  if (!async){
    async = true;
  }
  var data = {
    general_log: {
      el_id: $j(el).attr('id'),
      el_class: $j(el).attr('class'),
      tag: el.nodeName.toLowerCase(),
      page: window.location.pathname,
      action: action,
      extra: extra
    }
  };
  
  $j.ajax({
    type: 'POST',
    url: '/study/general_log',
    data: data,
    async: async,
    success: function(){}
  });  
  
}

function new_point_positive_count( t_obj, char_area, c_settings, char_rem ) {
	var chars;
	if ( t_obj.hasClass('input-text') ) chars = 140;
	else chars = 500;
	
	var submit_button = t_obj.parents( '.newpointform' ).find( '.point-submit input' );
	
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
  } else if ( char_rem < chars && $j( t_obj ).data( 'disabled' ) ) {
    t_obj.data( 'disabled', false );
    submit_button
        .attr( 'disabled', false );
  } else if ( char_rem == chars ) {
    t_obj.data( 'disabled', true );
    submit_button
        .attr( 'disabled', true );
  }
}

function new_point_negative_count( t_obj, char_area, c_settings, char_rem ) {
  if ( !char_area.hasClass( 'too_many_chars' ) ) {
    char_area.addClass( 'too_many_chars' ).css( {
      'font-weight' : 'bold',
      'font-size' : '175%'
    } );

    t_obj.parents( '.newpointform' ).find( '.point-submit input' )
        .animate( {
          opacity : .25,
          duration : 50
        } ).attr( 'disabled', true ).css( 'cursor', 'default' );
    t_obj.data( 'disabled', true );

  }
}


function set_noble_count_for_new_point(form_sel){
  var form = $j(form_sel);
      
  form.find('.point-title').NobleCount( form_sel + ' .point-title-group .count', {
    on_negative : new_point_negative_count,
    on_positive : new_point_positive_count,
		block_negative: true,
    max_chars : 140
  });
  
  form.find('.point-description').NobleCount( form_sel + ' .point-description-group .count', {
    on_negative : new_point_negative_count,
    on_positive : new_point_positive_count,
    max_chars : 500,
		block_negative: true
  });  
}

//TODO: generalize these noble count things
function new_comment_positive_count( t_obj, char_area, c_settings, char_rem ) {
  var chars;
  if ( t_obj.parent().hasClass('the_subject') ) chars = 90;
  else chars = 1000;
  
  var submit_button = t_obj.parents( '.form' ).find( '.comment_submit' );
  
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
  } else if ( char_rem < chars && $j( t_obj ).data( 'disabled' ) ) {
    t_obj.data( 'disabled', false );
    submit_button
        .attr( 'disabled', false );
  } else if ( char_rem == chars ) {
    t_obj.data( 'disabled', true );
    submit_button
        .attr( 'disabled', true );
  }
}

function new_comment_negative_count( t_obj, char_area, c_settings, char_rem ) {
  if ( !char_area.hasClass( 'too_many_chars' ) ) {
    char_area.addClass( 'too_many_chars' ).css( {
      'font-weight' : 'bold',
      'font-size' : '175%'
    } );

    t_obj.parents( '.form' ).find( '.comment_submit' )
        .animate( {
          opacity : .25,
          duration : 50
        } ).attr( 'disabled', true ).css( 'cursor', 'default' );
    t_obj.data( 'disabled', true );

  }
}


function set_noble_count_for_comment(form_sel){
  var form = $j(form_sel);
      
  form.find('.the_subject input').NobleCount( form_sel + ' .the_subject .count', {
    on_negative : new_comment_negative_count,
    on_positive : new_comment_positive_count,
    block_negative: true,
    max_chars : 90
  });
  
  form.find('.body textarea').NobleCount( form_sel + ' .body .count', {
    on_negative : new_comment_negative_count,
    on_positive : new_comment_positive_count,
    max_chars : 1000,
    block_negative: true
  });  
}


considerit = {
  add_new : function( response_text, sel ) {
    $j(sel + ' .point_list').append(response_text);
		$j(sel + ' .newpointform textarea').val('');
		$j(sel + ' .newpointform .point-title-group .count').html(140);
    $j(sel + ' .newpointform .point-description-group .count').html(500);
				
    considerit.cancelnewpointbuttonclicked( sel   );
  },
  newpointbuttonclicked : function (sel) {
    $j(sel + ' .newpointbutton').fadeOut('normal', function() {
      $j(sel + ' .newpointform').fadeIn('slow');      
    });
  },
  cancelnewpointbuttonclicked : function (sel) {
    $j(sel + ' .newpointform').fadeOut('slow', function(){
      $j(sel + ' .newpointbutton').fadeIn();    
    });    
  
  }
};

function get_bucket(value) {
  value = parseFloat(value);
  var ret;
  
  if (value == -1)
    ret = 0;
  else if (value == 1)
    ret = 6;
  else if (value <= 0.05 && value >= -0.05)
    ret = 3;
  else if (value >= 0.5)
    ret = 5;
  else if (value <= -0.5)
    ret = 1;
  else if (value >= 0.05)
    ret = 4;
  else if (value <= -0.05)
    ret = 2;
  
  return 6 - ret
}

function set_slider_value(new_value, initiative_name){
    
    var supporting = new_value > 0,
      size = new_value * 50;
    if ( supporting ) {
      $j( '.slider_table .right').css('font-size', 100 + 1.5 * size + '%');
      $j( '.slider_table .left').css('font-size', 100 - size + '%');
    } else {
      $j( '.slider_table .right').css('font-size', 100 + size + '%');
      $j( '.slider_table .left').css('font-size', 100 - 1.5 * size + '%');
    }
    
    $j('#stance-value').val( new_value);  
    set_stance(get_bucket(new_value), true);
}

function initialize_sliders(starting_value, initiative_name, initiative_id){
  var params = { 
    min: -1.0, 
    max: 1.0, 
    value: starting_value, 
    step: .015,
    slide: function(event, ui) {
      $j('.slider').each(function(){
        if ( ui.value != $j(this).slider('value') ) {
          $j(this).slider('value', ui.value)
        }
      });
    },
    change: function(event, ui) {
			value = ui.value
      set_slider_value(value, initiative_name);
    },
    stop: function(event, ui){
      data = {
        slider_movement : {
          initiative_id: initiative_id,
          value: ui.value,
          slider_id: $j(this).attr('id').substring(6)  
        }
      };
      
      $j.post('/study/slider_move', data);
            
    }
    };
    
  $j(".slider").slider(params);
  set_slider_value(starting_value, initiative_name);
}

function set_stance(bucket, dontadjust) {
  if (dontadjust) bucket = parseInt(bucket)
  $j('.stance_name').text(stance_name(bucket));
  //$j('.stance_name').css('color', stance_color(bucket));  
}

function stance_color(d) {
  //return ["#AA3300", "#CC9900", "#DDBB00", 
  //        "#DDDD00", "#BBDD00", "#99DD00", "#66DD00"][d]
  return ["#AAA", "#888", "#555", 
          "#333", "#555", "#888", "#AAA"][d]  
}

function stance_name(d) {
  switch (d) {
    case 0: 
      return "strongly oppose"
    case 1: 
      return "oppose"
    case 2:
      return "moderately oppose"
    case 3:
      return "are neutral on"
    case 4:
      return "moderately support"
    case 5:
      return "support"
    case 6:
      return "strongly support"
  }
}

function callback_add_comment_success(response_text, parent_id, grounded_in_point){
  var response = $j.parseJSON(response_text);
	
  var new_point = response['new_point']; 
	
	if (grounded_in_point) { 
	  rerendered_point = response['rerendered_ranked_point'];
		$j('#ranked_point-'+grounded_in_point).replaceWith(rerendered_point);		
		add_tips('#ranked_point-'+grounded_in_point);
	}

  //new_point.hide();
  
  if(parent_id){
    $j('#comment-'+parent_id+' .comment_children:first').prepend(new_point);
    $j('.new_comment textarea').val("");
		$j('#comment-'+parent_id+' .reply_row a.cancel').trigger('click');
  } else {
    $j('.comment_section > .new_comment:first').before(new_point);
    $j('.new_comment textarea, .new_comment li.the_subject input').val("");
  }
  //new_point.fadeIn('slow');
	
	add_tips('#comment-'+parent_id+' .comment_children:first .comment:first');
	
	if (grounded_in_point) {
		$j('html, body').animate({
  		scrollTop: $j("#comment-" + response['comment_id']).offset().top}, 1000);  
  }
}

function set_reply_toggle_events(comment_id){
	$j('#comment-'+comment_id+' a.reply:first').click(function(){
		$j('#comment-'+comment_id+' div.reply.hide:first').slideDown(function(){
			$j('#comment-'+comment_id+' a.reply:first').fadeOut();
	   });
  });

  $j('#comment-'+comment_id+' .new_comment:first a.cancel').click(function(){
    $j('#comment-'+comment_id+' div.reply.hide:first').slideUp(function(){
      $j('#comment-'+ comment_id +' a.reply:first').fadeIn();
     });
  });
		
}

function set_comment_reply_toggle_events(){
  $j('.comment').each(function(){
	 set_reply_toggle_events($j(this).attr('id').substring(8));
	});
}

function add_tips(sel){
  if (!sel) {
    $j('.add_qtip').qtip({ style: { name: 'cream', tip: true }, position: {corner: { target: 'bottomMiddle', tooltip: 'topMiddle' } }});
	} else {
    $j(sel + ' .add_qtip').qtip({ style: { name: 'cream', tip: true }, position: {corner: { target: 'bottomMiddle', tooltip: 'topMiddle' } }});  
  }
}

function stance_group_clicked(bucket, option_id) {
  if ( bucket == 'all' ) group_name = 'everyone';
  else group_name = stance_name(bucket);

  $j.get("/options/" + option_id + "/points", { bucket: bucket },
    function(data){
      $j('#ranked_points').html(data);
      add_tips('#ranked_points');
  } );        
}  

//TODO: replace this with unobtrusive javascript remote call
function paginate_ranked_list(next, is_pro, page, bucket, option_id) {
  
  if (!bucket){
    bucket = 'all';
  }
  var options = { bucket: bucket  };
  
  if ( is_pro ) {
    options['pros_only'] = true;
    var sel = '#points_self_pro .inner';
  } else {
    options['cons_only'] = true;
    var sel = '#points_self_con .inner';
  }
  
  if ( next ) {
    options['page'] = page + 1;
  } else {
    options['page'] = page - 1;
  }
  
  $j.get("/options/" + option_id + "/points", options, function(data){
    $j(sel).html(data);
    add_tips(sel);  
  });        
}   

function paginate_point_list_callback(html, column_selector) {
	$j(column_selector).html(html);
	add_tips(column_selector);
}

function callback_refresh_points_in_list(response_text, list_sel, is_next) {
  var parent = $j(list_sel + ' .point_list'),
      jsoned = $j.parseJSON(response_text),
      new_block = $j(jsoned['html']);
			
  new_block.each(function(){
		if ($j(this).hasClass('point_in_list')){
			$j(this).hide();
		}
	});

  parent.children('.point_in_list').fadeOut(function(){
		parent.html(new_block);
		parent.children('.point_in_list').fadeIn();
    add_tips(list_sel + ' .point_list');                            		
	});
		
  update_list_counts(parent, 0, jsoned['pagination'] );
}
