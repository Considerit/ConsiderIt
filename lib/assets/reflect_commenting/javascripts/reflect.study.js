/* Copyright (c) 2010 Travis Kriplean (http://www.cs.washington.edu/homes/travis/)
 * Licensed under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 * 
 * DOM manipulations for the Reflect research surveys. Basically drop in 
 * a short survey when the user takes specific actions (like adding bullet).
 * 
 * See server/api/ApiReflectStudyAction for high level about research study. 
 */


/////////////////////
//enclosure
if ( typeof Reflect == 'undefined' ) {
	Reflect = {};
	// ///////////////////
}

var $j = jQuery.noConflict();

Reflect.study = {

	load_surveys : function () {
		var bullets = [],
			user = Reflect.utils.get_logged_in_user();
		$j( '.bullet' ).each( function () {
			var bullet = $j( this ).data( 'bullet' );
			if ( bullet.id
				&& (bullet.user == user || bullet.comment.user == user) ) 
			{
				bullets.push( bullet.id );
			}
		} );
		Reflect.api.server.get_survey_bullets( {
				bullets : JSON.stringify( bullets )
			}, function ( data ) {
				// for each candidate bullet NOT in data, lay down
				// appropriate survey
				for ( var i in data['bullets'] ){
					var bullet = $j( '#bullet-' + data['bullets'][i] )
							.data( 'bullet' );
					Reflect.study.new_bullet_survey( 
								bullet, bullet.comment, bullet.$elem );							
				}
				for ( var i in data['responses'] ){
					var bullet = $j( '#bullet-' + data['responses'][i] )
							.data( 'bullet' );
						Reflect.study.new_bullet_reaction_survey( 
								bullet, bullet.comment, bullet.$elem );						
				}				
				
			} );
	},
	_bullet_survey_base : function ( comment, bullet, title, checkbox_name,
			checkboxes, survey_id, element ) 
	{
		if ( Reflect.data[comment.id][bullet.id]
                  && Reflect.data[comment.id][bullet.id].survey_responses ) {
			return;
		}

		fields = '';
		for ( var i in checkboxes) {
			var box = checkboxes[i];
			if ( box == 'other' ) {
				fields += '<input type="checkbox" name="'
						+ checkbox_name + '-' + bullet.id + '" id="other-' + bullet.id
						+ '" value="' + i
						+ '" class="other survey_check" /><label for="other-' + bullet.id
						+ '">other</label> <input type="text" class="other_text" name="other_text" /><br>';
			} else {
				fields += '<input type="checkbox" name="' + checkbox_name + '-'
						+ bullet.id + '" id="' + box + '-' + bullet.id
						+ '" value="' + i + '" class="survey_check" />'
						+ '<label for="' + box + '-' + bullet.id + '">' + box
						+ '</label><br>';
			}
		}

		// TODO: move this to html template
		var prompt = $j( ''
				+ '<div class="survey_prompt">'
				+ '	<div class="survey_intro">'
				+ '			<ul>'
				+ '				<li class="survey_label"><span>'
				+ title
				+ '</span></li>'
				+ '				<li class="cancel_survey"><button class="skip"><img title="Skip this survey" src="'
				+ Reflect.api.server.media_dir
				+ '/cancel_black.png" ></button></li>'
				+ '				<li style="clear:both"></li>'
				+ '			</ul>'
				+ '	</div>'
				+ '	<div class="survey_detail">'
				+ '	<p class="validateTips">Check all that apply. Your response will not be shown to others.</p>'
				+ '	<form>' + '	<fieldset>' + fields + '</fieldset>'
				+ '<button class="done" type="button">Done</button>'
				+ '<button class="skip" type="button">Skip</button>'
				+ '	</form>' + '	</div>' + '</div>' );

		prompt.find( '.survey_detail' ).hide();
		prompt.find( '.done' ).attr( 'disabled', true );
		prompt.find( 'input' ).click( function () {
			prompt.find( '.done' )
				.attr( 'disabled', prompt.find( 'input:checked' ).length == 0 );
		} );

		function open () {
			$j( this ).parents( '.survey_prompt' ).find( '.survey_detail' )
					.slideDown();
			$j( this ).unbind( 'click' );
			$j( this ).click( close );
		}
		function close () {
			$j( this ).parents( '.survey_prompt' ).find( '.survey_detail' )
					.slideUp();
			$j( this ).unbind( 'click' );
			$j( this ).click( open );
		}
		prompt.find( '.survey_label' ).click( open );

		prompt.find( '.done' ).click( function () {
			prompt.find( ':checkbox:checked' ).each( function () {
				var response_id = $j( this ).val();
				if ( $j( this ).hasClass( 'other' ) ) {
					var text = prompt.find( 'input:text' ).val();
				} else {
					var text = '';
				}

				var params = {
					bullet_id : bullet.id,
					comment_id : comment.id,
					text : text,
					survey_id : survey_id,
					response_id : response_id,
					bullet_rev : bullet.rev
				};
				var vals = {
					params : params,
					success : function ( data ) {
					},
					error : function ( data ) {
					}
				};

				Reflect.api.server.post_survey_bullets( vals );

			} );

			prompt.fadeTo( "slow", 0.01, function () { // fade
				prompt.slideUp( "slow", function () { // slide up
					prompt.remove(); // then remove from the DOM
				} );
			} );

		} );
		prompt.find( '.skip' ).click( function () {
			var response_id = $j( this ).val();
			if ( $j( this ).attr( 'id' ) == 'other' ) {
				var text = prompt.find( 'input:text' ).val();
			} else {
				var text = '';
			}

			var params = {
				bullet_id : bullet.id,
				bullet_rev : bullet.rev,
				comment_id : comment.id,
				text : text,
				survey_id : survey_id,
				response_id : -1
			};
			var vals = {
				params : params,
				success : function ( data ) {
				},
				error : function ( data ) {
				}
			};

			Reflect.api.server.post_survey_bullets( vals );

			prompt.fadeTo( "slow", 0.01, function () { // fade
				prompt.slideUp( "slow", function () { // slide up
					prompt.remove(); // then remove from the DOM
				} );
			} );
		} );
		prompt.hide();
		element.append( prompt );
		prompt.fadeIn( 'slow' );

	},
	new_bullet_survey : function ( bullet, comment, element ) {
		var commenter = comment.user_short, 
			checkboxes = [
				'make sure other people will see the point',
				'teach ' + comment.user_short + ' something',
				'show other readers that you understand',
				'show ' + comment.user_short + ' that you understand',
				'help you understand the comment better', 'other' ], 
			title = 'Why did you add this summary?', 
			checkbox_name = 'point_reaction', 
			survey_id = 1;

		Reflect.study._bullet_survey_base( 
				comment, bullet, title, checkbox_name, 
				checkboxes, survey_id, element );
	},

	new_bullet_reaction_survey : function ( bullet, comment, element ) {

		var checkboxes = [ 
				'It shows that people are listening to what I say',
				'It shows that I need to clarify what I meant',
				bullet.user + ' did not understand, though my point is clear',
				bullet.user + '&rsquo;s phrasing makes my point clear',
				'It shows me a different way of phrasing my point',
				'Thanks, ' + bullet.user,
				'It makes it easier for others to hear my point',
				'It makes it easier for others to understand my point', 
				'other' ], 
			title = 'How do you feel about this summary?', 
			checkbox_name = 'adding_point', 
			survey_id = 2;

		Reflect.study._bullet_survey_base( 
				comment, bullet, title, checkbox_name, 
				checkboxes, survey_id, element );
	},
	
	post_mousehover : function (entity_type, entity_id){
		Reflect.api.server.post_mousehover(
			{
		 	entity_type: entity_type,
		 	entity_id: entity_id,
		 	success: function(data){
		 	},
		 	error: function(data){
		 	}
		 });
	},
	post_bullet_mousehover : function ( event ) {
		try {
		  	var id = $j(event.target).parents('.bullet').attr('id').substring(7);
		  	Reflect.study.post_mousehover(2, id);
		} catch (e) {
			
		}
	},
	post_comment_mousehover : function ( event ) {
		var id = $j(event.target).parents('.comment').attr('id').substring(8);
		Reflect.study.post_mousehover(1, id);	
	},	
	post_blog_mousehover : function ( event ) {
		var id = $j(event.target).parents('.blogpost_body').attr('id').substring(9);
		Reflect.study.post_mousehover(0, id);	
	},	
	
	instrument_bullet : function( element ) {
		var config = {    
		     over: Reflect.study.post_bullet_mousehover, // function = onMouseOver callback (REQUIRED)    
		     timeout: 500, // number = milliseconds delay before onMouseOut    
		     out: function(){}, // function = onMouseOut callback (REQUIRED)   
		     interval: 1000
		};
		
		$j(element).find('.bullet_main_wrapper').hoverIntent( config );
		
	},
	instrument_mousehovers : function (  ) {
		var config = {    
		     over: Reflect.study.post_bullet_mousehover, // function = onMouseOver callback (REQUIRED)    
		     timeout: 500, // number = milliseconds delay before onMouseOut    
		     out: function(){}, // function = onMouseOut callback (REQUIRED)   
		     interval: 1000
		};
		
		$j(".bullet_main_wrapper").hoverIntent( config );
		
		config.over = Reflect.study.post_comment_mousehover;
		$j(".rf_comment_text_wrapper").hoverIntent( config );
		
		config.over = Reflect.study.post_blog_mousehover;
		$j(".blogpost_body").hoverIntent( config );		
	}
};
