/* Copyright (c) 2010 Travis Kriplean (http://www.cs.washington.edu/homes/travis/)
 * Licensed under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 * Website: http://www.cs.washington.edu/homes/travis/reflect
 * 
 * 
 * The core Reflect engine.
 * 
 * Powers implementations of Reflect for Wordpress, Greasemonkey, Drupal, Slashcode and 
 * Mediawiki (with LiquidThreads).
 * 
 * Applications need to define the DOM elements that Reflect needs to know about
 * in order for this engine to wrap the basic Reflect comment summarization elements
 * around desired text blocks. Each application should define a reflect.{APPLICATION}.js
 * file where this configuration takes place. 
 * 
 * The script can take it from there. 
 * 
 * Browser compatability (out of date):
 * 
 *   firefox : good
 *    safari : good
 *    chrome : good      
 *    opera : ?
 *    IE6 : ?
 *    IE7 : usable
 *    IE8 : good
 * 
 * global Class, jQuery
 */

var Reflect;

(function($j) {
  
/**
* Top-level enclosure. Structure:
* 
*  Reflect
*    .config : default configuration options
*    .Contract : base Class for implementing Reflect contract
*    .api : base Class and methods for interacting with server
*    .handle : methods for responding to events 
*    .templates : contains templates for dynamically adding HTML
*    .enforce_contract : takes a contract and existing DOM and wraps Reflect elements around it
*    .init : fetches data from server, downloads templates, enforces contract, other init-y things
*    .utils : misc methods used throughout
*/    
Reflect = {
  
  data : {},

  /**
  * Basic settings. Usually overriden per implementation.
  */        
  config : {
    api : {
      /* Reflect API server */
      server_loc : '',
      /* location where media is served from */
      media_dir : '',
      /* unique identifier for this application */
      domain : ''
    },
    contract : {
      /* components is an array of objects, each of which defines key attributes of 
       * each DOM element which should be wrapped with Reflect text summarization.
       * 
       * The attributes of each component are:
       *   comment_identifier : jquery selector for the comment element
       *   comment_offset : offset within the comment element's ID field where the ID begins
       *   comment_text : jquery selector for the text of the comment
       *   get_commenter_name : function that returns the name of the commenter, given a comment ID
       */        
      components : []
    },
     view : {
       /* Enables client side community moderation of Reflect bullets */
       enable_rating : false,
       /* If the bullet summaries have a picture of the listener. Note that this also requires
          the definition of Reflect.api.server./usr/local/webroot/slash/site/localhost_pic(), as well as having the 
          server return u_pic (a url to the user's pic) for each bullet. */
       uses_profile_pic : false,
       /* Textual prompts */
       text : {
         //bullet_prompt: 'Tell us what you hear {{COMMENTER}} saying', 
         //bullet_prompt: 'Summarize what you hear {{COMMENTER}} saying', 
         //bullet_prompt: 'Summarize {{COMMENTER}}'s point', 
         //bullet_prompt: 'Add a point that {{COMMENTER}} makes',
         //bullet_prompt: 'Restate something {{COMMENTER}} says',
         //bullet_prompt: 'What is {{COMMENTER}}'s point?',
         //bullet_prompt: 'What point is {{COMMENTER}} making?',            
         bullet_prompt: 'What do you hear {{COMMENTER}} saying?',
         response_prompt: 'Did {{LISTENER}} understand your point?',
         //bullet_prompt_header: 'Points readers hear {{COMMENTER}} making',
         bullet_prompt_header: 'Points {{COMMENTER}} makes'         
       }
             
     },
    
    study : false
  },

  /**
  * Contract implements methods for identifying key DOM elements, as well as modifying
  * the served DOM, that is necessary for wrapping Reflect elements around comments. 
  * 
  * This is the base class. Reflect implementations should extend Contract in reflect.{APPLICATION}.js.
  */  
  Contract : Class.extend( {
    
    /* jquery selector or function for getting the logged in user */  
    user_name_selector : null,
    
    init : function ( config ) {
      this.components = config.components;
    },
    /* Function that is executed BEFORE the Reflect contract is enforced. 
     * This is where the served DOM is whipped into shape (if it isn't already).*/
    modifier : function () {},
    /* Function executed AFTER the Reflect contract has been enforced.*/
    post_process : function () {},
    /* Returns a jquery-wrapped element representing the comment list.*/    
    get_comment_thread : function () {},
    /* Some applications need to add css in the client. Call _addStyleSheet if needed.*/    
    add_css : function () {},
    _addStyleSheet : function ( style ) {
      $j( 'head' ).append( '<style type="text/css">' + style + '</style>' );
    }
  } ),

  /**
  * Get Reflect moving. 
  * 
  * Fetches data and templates from the server, enforces the contract. 
  */    
  init : function () {
    $j.ajaxSetup({ cache: false });

    // register the bridges
    $j.plugin( 'bullet', Reflect.entities.Bullet );
    $j.plugin( 'comment', Reflect.entities.Comment );
    $j.plugin( 'response', Reflect.entities.Response );
    //////////

    // instantiate the classes that may have been overridden
    Reflect.contract = new Reflect.Contract( Reflect.config.contract );
    Reflect.api.server = new Reflect.api.DataInterface( Reflect.config.api );
    //////////

    Reflect.contract.add_css();
    // TODO: per request
    // handle additional refactoring required for Reflect contract
    Reflect.contract.modifier();
    //////////

    // set up event delegation
    Reflect.handle.initialize_delegators();
    /////////////////////////

    Reflect.per_request();


  },

  per_request : function() {

    //////////
    // figure out which comments are present on the page so that we
    // can ask the server for the respective bullets
    var loaded_comments = [], component, i;
    for (i = 0; i < Reflect.contract.components.length; i += 1) {
      component = Reflect.contract.components[i];
      $j( component.comment_identifier + ':not(.rf_comment)' ).each( function () {
        var comment_id = $j( this ).attr( 'id' )
          .substring( component.comment_offset );
        loaded_comments.push( comment_id );
      } );
    }
  
    ////////////////////

    function get_data_callback ( data ) {
      for (var attrname in data) { Reflect.data[attrname] = data[attrname]; }
      
      Reflect.enforce_contract();
      Reflect.contract.post_process();

      if ( Reflect.config.study ) {
        Reflect.study.load_surveys();
        Reflect.study.instrument_mousehovers();
      }
    }

    function get_templates_callback ( data ) {      
      Reflect.templates.init( data );

      if ( loaded_comments.length > 0 ) {
        Reflect.api.server.get_data( {
            comments : JSON.stringify(loaded_comments)
          }, get_data_callback);
      }
    }

    // check if templates.html has already been loaded...
    if ( $j('#reflect_templates_present').length > 0 ) {
      get_templates_callback( null );
    } else {
      //Reflect.api.server.get_templates( get_templates_callback );      
    }  

  },
  /**
  * Take the current DOM and wrap Reflect elements where appropriate, guided
  * by the Reflect.contract. 
  */
  enforce_contract : function () {

    var user = typeof Reflect.contract.user_name_selector === 'function'
      ? Reflect.contract.user_name_selector()
      : $j(Reflect.contract.user_name_selector).text(), i;

    if ( !user || user === '' || user == 'undefined' ) {
      user = Reflect.api.server.get_current_user();
    }

    user_id = $j('#nav-user .settings').attr('user');

    if ( $j('.reflected').length == 0 ) {
      $j( Reflect.contract.get_comment_thread() )
          .addClass( 'reflected' );
      $j( '.reflected' ).append( '<span id="rf_user_name">' + user + '</span>' );
      $j( '.reflected' ).append( '<span id="rf_user_id">' + user_id + '</span>' );
    }
    
    for (i = 0; i < Reflect.contract.components.length; i += 1) {
      var component = Reflect.contract.components[i];

      $j( component.comment_identifier + ':not(.rf_comment)' )
        .each( function ( index ) {
          $j( this ).comment( {
            initializer : component
          });
          var comment = $j.data( this, 'comment' );

          if ( Reflect.data && Reflect.data[comment.id]) {
            var bullets = [];
            $j.each( Reflect.data[comment.id], function(key, val){
              bullets.push( val );      
            });

            // rank order of bullets in list
            bullets = bullets.sort( function ( a, b ) {
              var a_tot = 0.0, b_tot = 0.0, j;
              for (j = 0; j < a.highlights.length; j += 1) {
                a_tot  +=  parseFloat(a.highlights[j]);
              }
              for (j = 0; j < b.highlights.length; j += 1) {
                b_tot  +=  parseFloat( b.highlights[j] );
              }
              var a_score = a_tot / a.highlights.length,
                b_score = b_tot / b.highlights.length;
              return a_score - b_score;
            } );

            $j.each(bullets, function(key, bullet_info) {

              var bullet = comment.add_bullet( bullet_info ), 
                response = bullet_info.response;
              if ( response ) {
                bullet.add_response( response );
              } else if ( !bullet.response && comment.user_id === user_id ) {
                bullet.add_response_dialog();
              }
            });
            comment.hide_excessive_bullets();
          }

          // segment sentences we can index them during highlighting
          comment.elements.comment_text.wrap_sentences();
          comment.elements.comment_text.find( '.sentence' )
              .each( function ( index ) {
                $j( this ).attr( 'id', 'sentence-' + index );
              } );
          //so that we don't try to break apart urls into different sentences...
          comment.elements.comment_text.find('a').addClass('exclude_from_reflect');

          comment.add_bullet_prompt();

        } );
    }
  },
  /**
  * HTML templates so that we don't have to have long, ugly HTML snippets
  * managed via javascript. Use jquery.jqote2 to implement html templating.
  * HTML file full of scripts is fetched from server. Each script simply
  * contains HTML along with some templating methods. These scripts can 
  * then be created as parameterized HTML via jqote2. 
  * 
  * Reflect.templates stores compiled HTML templates at the ready. 
  */      
  templates : {
    init : function ( templates_from_server ) {      
      if ( templates_from_server ) $j( 'body' ).append( templates_from_server );
      
      $j.extend( Reflect.templates, {
        bullet : $j.jqotec( '#reflect_template_bullet' ),
        new_bullet_prompt : $j.jqotec( '#reflect_template_new_bullet_prompt' ),
        new_bullet_dialog : $j.jqotec( '#reflect_template_new_bullet_dialog' ),
        bullet_highlight : $j.jqotec( '#reflect_template_bullet_highlight' ),
        response : $j.jqotec( '#reflect_template_response' ),
        response_dialog : $j.jqotec( '#reflect_template_response_prompt' ),
        bullet_rating : $j.jqotec( '#reflect_template_bullet_rating'),
        bullet_badge_gallery : $j.jqotec( '#reflect_template_ratings_gallery')
      } );      
    }
  },
  
  /**
  * Methods for communicating with a generic Reflect API. Reflect applications 
  * should override the base api.DataInterface class in order to implement the 
  * specific application-specific server calls to the Reflect API. 
  */    
  api : {
    /**
    * This is a base class. Reflect implementations should replace DataInterface with 
    * a child class in reflect.{APPLICATION}.js.
    */    
    DataInterface : Class.extend( {
      init : function ( config ) {
        this.server_loc = config.server_loc;
        this.media_dir = config.media_dir;
        this.domain = config.domain;
      },
      post_bullet : function ( settings ) {
        throw 'not implemented';
      },
      post_response : function ( settings ) {
        throw 'not implemented';
      },
      post_rating : function ( settings ) {
        throw 'not implemented';
      },
      post_survey_bullets : function ( settings ) {
        throw 'not implemented';
      },
      get_data : function ( params, callback ) {
        throw 'not implemented';
      },
      get_current_user : function () {
        return 'Anonymous';
      },
      get_current_user_pic : function () {
        return '';
      },
      get_templates : function ( callback ) {
        throw 'not implemented';
      },
      is_admin : function () {
        return false;
      }
    } ),

    /* Ajax posting of bullet to Reflect API. */        
    post_bullet : function ( event ) {
      
      var bullet_obj = $j.data( $j( event.target )
          .parents( '.bullet' )[0], 'bullet' ), 
        text = $j.trim(bullet_obj.elements.bullet_text.html()), 
        highlights = [],
        modify = bullet_obj.id;

      if ( !modify ) {
        bullet_obj.added_this_session = true;
      }

      bullet_obj.comment.elements.comment_text.find( '.highlight' )
        .each( function(){ 
          highlights.push( $j( this ).attr( 'id' ).substring( 9 ) );});

      var params = {
        comment_id : bullet_obj.comment.id,
        text : text,
        user : Reflect.utils.get_logged_in_user(),
        highlights : JSON.stringify( highlights ),
        this_session : bullet_obj.added_this_session
      };

      bullet_obj.set_highlights(highlights);
      if ( bullet_obj.id ) {
        params.bullet_id = bullet_obj.id;
        params.bullet_rev = bullet_obj.rev;
      }

      function post_bullet_callback ( data ) {
        if ( data ) {
          bullet_obj.set_id( data.insert_id, data.rev_id );
          if (!Reflect.data[bullet_obj.comment.id]) {
            Reflect.data[bullet_obj.comment.id] = {};
          }
          Reflect.data[bullet_obj.comment.id][bullet_obj.id] = params;
          if ( Reflect.config.study && !modify ) {
            Reflect.study.new_bullet_survey( 
                bullet_obj, bullet_obj.comment, bullet_obj.$elem );
            Reflect.study.instrument_bullet(bullet_obj.$elem);
          }
        }
      }

      Reflect.api.server.post_bullet( {
        params : params,
        success : post_bullet_callback,
        error : function ( data ) {}
      } );
      bullet_obj.exit_highlight_state( false );
      bullet_obj.comment.add_bullet_prompt();
    },
    
    post_delete_bullet : function ( bullet_obj ) {
      var params = {
        'delete' : true,
        comment_id : bullet_obj.comment.id,
        bullet_id : bullet_obj.id,
        bullet_rev : bullet_obj.rev,
        this_session : bullet_obj.added_this_session
      };

      Reflect.api.server.post_bullet( {params:params} );

      bullet_obj.comment.elements.comment_text.find( '.highlight' )
          .removeClass( 'highlight' );
      bullet_obj.$elem.remove();      
    },
    
    /* Ajax posting of a response to Reflect API. */        
    post_response : function ( response_obj ) {

      function ajax_callback ( data ) {
        response_obj.set_id( data.insert_id, data.rev_id );
        if ( data.deactivate ) {
          response_obj.bullet.$elem.fadeOut();
        }
      }

      var bullet_obj = response_obj.bullet, 
        user = Reflect.utils.get_logged_in_user(),
        input_sel = ".response_prompt input:checked",
        signal = bullet_obj.$elem.find( input_sel ).val(),
        text = signal === '1' ? response_obj.elements.new_response_text.val() : '',         
        params = {
          bullet_id : bullet_obj.id,
          comment_id : bullet_obj.comment.id,
          bullet_rev : bullet_obj.rev,
          text : text,
          signal : signal,
          response : true,
          user : user };
          
      if ( response_obj.id ) {
        params.response_id = response_obj.id;
        params.response_rev = response_obj.rev;
      }

      Reflect.api.server.post_response( {
        params : params,
        success : ajax_callback,
        error : function ( data ) {}
      });
    },
    
    post_delete_response : function ( response_obj ) {
      var params = {
        'delete' : true,
        response : true,
        response_id : response_obj.id,
        bullet_id : response_obj.bullet.id,
        bullet_rev : response_obj.bullet.rev,
        comment_id : response_obj.bullet.comment.id
      };
      
      Reflect.api.server.post_response( {params:params} );
    },

    /* Ajax posting of a bullet rating to Reflect API. */        
    post_rating : function ( bullet_obj, rating, is_delete ) {

      function ajax_callback ( data ){
        bullet_obj.ratings.rating = data.rating;
        bullet_obj.update_badge_gallery();  
        if ( data.deactivate ) {
          bullet_obj.$elem.fadeOut();
        }        
      }
      
      var params = {
        bullet_id : bullet_obj.id,
        comment_id : bullet_obj.comment.id,
        bullet_rev : bullet_obj.rev,
        rating : rating,
        is_delete : is_delete
      };

      Reflect.api.server.post_rating( {
        params : params,
        success : ajax_callback,
        error : function ( data ) {}
      });
    }    

  },
  
  /**
  * Event handlers. Naming convention is to have [noun]_[action|event].
  */  
  handle : {
    /**
    * Establishes the event delegators. 
    */
    initialize_delegators : function() {

      $j(document).ajaxComplete(function(e, xhr, settings) {
        if ( settings.url.indexOf('reflect') == -1  ) {
          Reflect.per_request();
        }
      });

      //comments
      $j('.rf_comment.highlight_state .rf_comment_text .sentence')
        .live('click', Reflect.handle.sentence_click);

      $j('.rf_comment.highlight_state .rf_comment_text a.exclude_from_reflect')
        .live('click', function( event ){ event.preventDefault(); });

      $j('.rf_comment .rf_toggle_paginate a')
        .live('click', function ( event ) {
          $j( event.target ).parents('.summary').find('.bullet_list').children().fadeIn();
          $j( event.target ).parent().hide();
         });

      // bullets
      $j('.bullet.full_bullet')
        .live('mouseover',  Reflect.handle.bullet_mouseover)
        .live('mouseout',  Reflect.handle.bullet_mouseout);

      $j('.bullet.full_bullet .bullet_meta .delete')
        .live('click',  function( event ) { $j( this ).siblings( '.verification' ).show(); });

      $j('.bullet.full_bullet .bullet_meta .delete_nope')
        .live('click',  function( event ) { $j( this ).parents( '.verification' ).hide(); });

      $j('.bullet.full_bullet .bullet_meta .delete_for_sure')
        .live('click',  function( event ) {
          var bullet_obj = $j.data( $j( event.target )
              .parents( '.bullet' )[0], 'bullet' );
          Reflect.api.post_delete_bullet( bullet_obj );
        });

      $j('.bullet.full_bullet .bullet_meta .modify:enabled')
        .live('click',  function(event) {
          var bullet_obj = $j.data( $j( event.target )
              .parents( '.bullet' )[0], 'bullet' );
          if ( !bullet_obj.comment.$elem.hasClass('highlight_state') 
            && !bullet_obj.comment.$elem.hasClass('bullet_state')){
            bullet_obj.enter_edit_state();
          }
        });

      $j('.bullet.new_bullet .add_bullet:enabled')
        .live('click', function(event) {
          var bullet_obj = $j.data( $j( event.target )
              .parents( '.bullet' )[0], 'bullet' );
          bullet_obj.enter_edit_state();
        });

      $j('.bullet.modify .bullet_submit:enabled')
        .live('click', function(event) { 
          var bullet_obj = $j.data( $j( event.target ).parents( '.bullet' )[0], 'bullet' );
          bullet_obj.exit_edit_state( false );
          bullet_obj.enter_highlight_state();
          if ( bullet_obj.comment.elements.comment_text.find( '.highlight' ).length === 0 ) {
            bullet_obj.elements.submit_button.disable();
          } else {
            bullet_obj.elements.submit_button.enable();            
          }
          bullet_obj.comment.elements.bullet_list.find('.add_bullet').disable();
        });

      $j('.bullet.modify .cancel_bullet')
        .live('click', function(event) { 
          var bullet_obj = $j.data( $j( event.target ).parents( '.bullet' )[0], 'bullet' );
          bullet_obj.exit_edit_state( true );
        });

      $j('.bullet.connect .submit .bullet_submit:enabled')
        .live('click', Reflect.api.post_bullet);

      $j('.bullet.connect .submit .cancel_bullet')
        .live('click', function(event) { 
          var bullet_obj = $j.data( $j( event.target ).parents( '.bullet' )[0], 'bullet' );
          bullet_obj.exit_highlight_state( true );
          bullet_obj.comment.add_bullet_prompt(); });

      $j('.rate_bullet.not_anon .flag')
        .live( 'click', function(event) { Reflect.handle.bullet_flag(event); });

      // responses
      $j('.bullet.full_bullet .response_prompt')
        .live('click', function( event ) { 
          $j( this ).find('.response_eval').slideDown(); 
          $j( this ).find('.action_call').hide();
        });

      $j('.bullet.full_bullet .response_prompt .response_maybe')
        .live('click', function( event ) {
          var clarification = $j( this ).siblings('.new_response_text');
          if ( clarification.val().length == 0 ) {
            $j(this).parents('.response_prompt').find('.bullet_submit').attr('disabled', true);
          }
          clarification
            .focus();
        });

      $j('.bullet.full_bullet .response_prompt .response_field')
        .live('click', function( event ) {
          $j(this).parents('.response_prompt').find('.bullet_submit').attr('disabled', false);
        });

      $j('.bullet.full_bullet .response_prompt .bullet_submit')
        .live('click', function( event ) { 
          var response_obj = $j.data( $j( event.target )
              .parents( '.bullet' ).find('.rf_response')[0], 'response' );
          if ( response_obj.bullet.$elem.find('.response_prompt input:checked').length > 0 ) {
            Reflect.api.post_response( response_obj );
            response_obj.exit_dialog( );
          }
        });

      $j('.bullet.full_bullet .response_prompt .cancel_bullet')
        .live('click', function( event ) {  
          $j(event.target).parents('.response_eval').slideUp();
          $j(event.target).parents('.response_prompt').find('.action_call').fadeIn();
          return false;
        } );

      $j('.bullet.full_bullet .response_prompt .new_response_text')
        .live('focus', function(){
          $j(this).siblings('.response_maybe').attr('checked', true);
        });

      $j('.bullet.full_bullet .response_prompt .response_maybe')
        .live('click', function(){
          $j(this).siblings('.new_response_text').focus();
        }); 

    },
    bullet_mouseover : function ( event ) {
      var bullet_obj = $j.data( $j( this )[0], 'bullet' );

      bullet_obj.comment.$elem.not('.highlight_state').not('.bullet_state')
        .find( jQuery.map(bullet_obj.highlights, function(n, i){return '#sentence-' + n;}).join(',') )
        .addClass('highlight');
    },

    bullet_mouseout : function ( event ) {      
      var comment = $j
        .data( $j( event.target ).parents( '.rf_comment' )[0], 'comment' );

      if ( !comment.$elem.hasClass( 'highlight_state' )
          && !comment.$elem.hasClass( 'bullet_state' ) ) {
        comment.$elem.find( '.highlight' ).removeClass( 'highlight' );
      }
    },

    bullet_flag : function ( event ) {
      var flag_el = $j( event.target ).hasClass('flag') ? $j( event.target ) : $j( event.target ).parents('.flag');
      var flag = flag_el.attr('name'),
          bullet_obj = $j.data( $j( '#bullet-'+flag_el.parents('.rate_bullet')
            .find('.bullet_id').text())[0], 'bullet' ),
          is_delete = flag === bullet_obj.my_rating;

      bullet_obj.my_rating = is_delete ? null : flag;

      flag_el
        .toggleClass('selected')
        .siblings('.selected').removeClass('selected');

      Reflect.api.post_rating( bullet_obj, flag, is_delete );
      bullet_obj.$elem.find( '.rf_rating .rf_selector_container div').qtip('hide');
    },

    negative_count : function ( t_obj, char_area, c_settings, char_rem ) {
      if ( !char_area.hasClass( 'too_many_chars' ) ) {
        char_area.addClass( 'too_many_chars' );

        t_obj.parents( '.rf_dialog' ).find( '.bullet_submit' )
            .attr( 'disabled', true )
            .animate( {
              opacity : 0.25,
              duration : 50
            } ).css( 'cursor', 'default' );
        t_obj.data( 'disabled', true );

      }
    },
    positive_count : function ( t_obj, char_area, c_settings, char_rem ) {
      if ( char_area.hasClass( 'too_many_chars' ) ) {
        char_area.removeClass( 'too_many_chars' );

        t_obj.parents( '.rf_dialog' ).find( '.bullet_submit' )
            .attr( 'disabled', false )
            .animate( {
              opacity : 1,
              duration : 50
            } ).css( 'cursor', 'pointer' );
        t_obj.data( 'disabled', false );
      } else if ( char_rem < 140 && t_obj.data( 'disabled' ) ) {
        t_obj.data( 'disabled', false );
        t_obj.parents( 'li' ).find( '.submit .bullet_submit' ).attr( 'disabled', false );
      } else if ( char_rem === 140 && t_obj.parents('.response_dialog').length === 0 ) {
        t_obj.data( 'disabled', true )
        t_obj.parents( 'li' ).find( '.submit .bullet_submit' ).attr( 'disabled', true );
      }
    },
    sentence_click : function ( event ) {
      var parent = $j( event.target ).parents( '.rf_comment' ), 
          bullet = parent.find( '.connect_directions' )
            .parents( '.bullet' ).data( 'bullet' ), 
          submit = bullet.elements.submit_button;

      if ( $j( event.target ).hasClass( 'highlight' ) 
             && parent.find( '.rf_comment_text .highlight' ).length === 1 ) {
        submit.disable();
      } else {
        submit.enable();            
      }

      $j( event.target ).toggleClass( 'highlight' );
    }

  },

  /**
  * Object classes representing important object types: 
  * Comment, Bullet, and Response. 
  * 
  * Instantiations of each object class are attached to their respective DOM 
  * elements via jquery.data. And each object maintains reference to DOM 
  * element reference. 
  * 
  * Object instances know how to transform their own DOM given state changes. 
  * More than meets the eye. 
  * 
  * They also know how to manage adding children. For example, Comment knows
  * how to add Bullets. 
  * 
  * Instantiation is accomplished via jquery.plugin, enabling 
  * e.g. $j('#comment').comment(). Plugin registration accomplished in 
  * Reflect.init.
  */    
  entities : {

    Comment : {
      init : function ( options, elem ) {
        this.options = $j.extend( {}, this.options, options );

        this.$elem = $j( elem );
        this.elements = {};

        this.id = this.$elem.attr( 'id' )
            .substring( this.options.initializer.comment_offset );
      
        this.user = this.options.initializer.get_commenter_name( this.id );
        this.user_id = this.$elem.find('.body_row > .user').attr('user');

        if ( !this.user || this.user === '' ) {
          this.user = 'Anonymous';
        }
        this.user_short = Reflect.utils.first_name( this.user );
        this.bullets = [];
        this._build();
        return this;
      },
      options : {},
      _build : function () {
        var comment_text = this.$elem
            .find( this.options.initializer.comment_text + ':first' );
        this.$elem.addClass( 'rf_comment' );

        var wrapper = $j( '<td id="rf_comment_text_wrapper-'
            + this.id + '" class="rf_comment_text_wrapper">'
            + '<div class=rf_comment_text />' + '</td>' );

        var summary_block = $j( '<td id="rf_comment_summary-'
            + this.id + '" class="rf_comment_summary">'
            + '<div class="summary" id="summary-' + this.id + '">'
            //+ '<div class="reflect_header"><div class="rf_title">'
            //+ Reflect.config.view.text.bullet_prompt_header.replace('{{COMMENTER}}', this.user_short)
            //+ '</div></div>'
            + '<ul class="bullet_list" />' + '</div>' + '</td>' );

        var author_block = $j( '<span class="rf_comment_author">' 
            + this.user + '</span>' );
        
        wrapper.append( author_block );
        
        comment_text
          .wrapInner( wrapper )
          .append( summary_block )
          .wrapInner( $j( '<tr/>' ) )        
          .wrapInner( $j( '<table id="rf_comment_wrapper-' 
              + this.id + '" class="rf_comment_wrapper" />' ) );

        //so that we don't try to break apart urls into different sentences...
        comment_text.find('a').addClass('sentence');

        this.elements = {
          bullet_list : comment_text.find( '.bullet_list:first' ),
          comment_text : this.$elem.find( '.rf_comment_text:first' ),
          text_wrapper : this.$elem.find( '.rf_comment_text_wrapper:first' ),
          summary : this.$elem.find( '.rf_comment_summary' )
        };

      },
      _add_bullet : function ( params ) {
        var bullet = $j( '<li />' ).bullet( params );

        this.elements.bullet_list.append( bullet );

        var bullet_obj = $j.data( bullet[0], 'bullet' );
        this.bullets.push( bullet_obj );
        return bullet_obj;
      },
      add_bullet : function ( bullet_info ) {
        return this._add_bullet( {
          is_prompt : false,
          bullet_info : bullet_info,
          comment : this
        } );
      },
      add_bullet_prompt : function () {
        if ( this.user_id === Reflect.utils.get_logged_in_user_id()
            || this.elements.bullet_list.find( '.new_bullet' ).length > 0) {
          return;
        }

        return this._add_bullet( {
          is_prompt : true,
          comment : this
        } );
      },
      hide_excessive_bullets : function() {
        var HIDE_FACTOR = 150;
        function hide_loop( comment_text_height, bullet_obj, hide_only_deviants, hide_only_response_no ) {
          var i = bullet_obj.bullets.length - 1, hidden = 0,
            subset = hide_only_response_no ? '.rf_response_symbol.not' : '.graffiti, .troll';
          
          while (  i > 0 
            && bullet_obj.elements.bullet_list.height() > comment_text_height + HIDE_FACTOR ) {

            if ( (!hide_only_deviants 
                 || bullet_obj.bullets[i].$elem.find(subset).length > 0 )
                 && bullet_obj.bullets[i].$elem.is(':visible') ) {
              bullet_obj.bullets[i].$elem.hide();
              hidden  +=  1;
            }
            i -= 1;
          }
          return hidden;
        }

        if ( this.bullets.length < 2 ) { return; }
        var comment_text_height = this.elements.comment_text.height();
        if ( this.elements.bullet_list.height() > comment_text_height + HIDE_FACTOR ) {
          // first hide all bullets marked by commenter as not a summary
          var hidden = hide_loop( comment_text_height, this, true, true );
          // hide all suspected non-summaries
          hidden  +=  hide_loop( comment_text_height, this, true, false );
          // now just select from remaining
          hidden  +=  hide_loop( comment_text_height, this, false );
        
          var summary = hidden === 1 ? 'summary' : 'summaries';
          this.$elem.find('.summary')
            .append('<div class="rf_toggle_paginate">' + hidden + ' ' 
                    + summary + ' hidden. <a>show all</a></div><div class="cl"></div>');
        }
       }
    },

    Bullet : {
      init : function ( options, elem ) {
        this.options = $j.extend( {}, this.options, options.bullet_info );
        this.comment = options.comment;
        
        this.$elem = $j( elem );
        this.elements = {};

        this.set_attributes();
        this.response = null;
        this.ratings = this.options.ratings;

        if ( this.options.my_rating && this.options.my_rating != 'undefined' ) {
          this.my_rating = this.options.my_rating;
        }
        // Build the dom initial structure
        if ( options.is_prompt ) {
          this._build_prompt();
        } else {
          this._build();
        }
        return this;
      },
      set_attributes : function () {
        this.id = this.options.id || null;
        this.rev = this.options.rev || null;
        this.user = this.options.u || null;
        this.user_id = this.options.uid || null;        
        this.highlights = this.options.highlights || null;
        this.text = this.options.txt || null;
      },
      options : {},
      _build : function () {
        var logged_in_user = Reflect.utils.get_logged_in_user(),
            logged_in_user_id = Reflect.utils.get_logged_in_user_id(),
            template_vars = {
          bullet_text : Reflect.utils.escape( this.text ),
          user : Reflect.utils.escape( this.user ),
          logged_in_user : logged_in_user,
          commenter : this.comment.user,
          listener_pic : this.options.u_pic,
          uses_profile_pic : Reflect.config.view.uses_profile_pic,
          enable_actions : Reflect.api.server.is_admin()
            || (logged_in_user !== 'Anonymous' && logged_in_user_id === this.user_id && !this.response)
            || (logged_in_user === 'Anonymous' && logged_in_user_id === this.user_id && this.added_this_session)
        };

        this.$elem
          .addClass( 'bullet' )
          .html( $j.jqote( Reflect.templates.bullet, template_vars ) );
        
        if ( this.user_id === logged_in_user_id ) {
          this.$elem.addClass( 'self' );
        } else if ( this.comment.user_id === logged_in_user_id ) {
          this.$elem.addClass( 'responder_viewing' );
        }

        this.elements = {
          bullet_text : this.$elem.find( '.rf_bullet_text' ),
          bullet_main : this.$elem.find( '.bullet_main' ),
          bullet_meta : this.$elem.find( '.bullet_meta' ),
          bullet_eval : this.$elem.find( '.rf_evaluation' ),
          bullet_wrap : this.$elem.find( '.bullet_text' )
        };

        if ( this.id ) {
          this.set_id( this.id, this.rev );
          this.$elem.addClass( 'full_bullet' );
          if ( Reflect.config.view.enable_rating ) {
	          this.update_badge_gallery();
	        }
        }
        
      },
      _build_prompt : function () {
        var commenter = this.comment.user;
        var template_vars = {
          commenter : commenter,
          media_dir : Reflect.config.api.media_dir,
          bullet_prompt : Reflect.config.view.text.bullet_prompt.replace('{{COMMENTER}}', commenter)
        };
        
        var template = Reflect.templates.new_bullet_prompt;
        
        this.$elem
            .addClass( 'bullet new_bullet' )
            .html( $j.jqote( template, template_vars ) )            
            .find('.add_bullet').enable();
      },
      set_id : function ( id, rev ) {
        this.id = this.options.id = parseInt(id, 10);
        this.rev = this.options.rev = parseInt(rev, 10);
        this.$elem.attr( 'id', 'bullet-' + this.id );
      },
      set_highlights : function (highlights) {
        this.highlights = this.options.highlights = highlights;
      },
      enter_edit_state : function () {
        var text = this.id ? $j.trim(this.elements.bullet_text.html()) : '',
         template_vars = {
          media_dir : Reflect.api.server.media_dir,
          bullet_id : this.id,
          txt : Reflect.utils.escape( text ),
          commenter : this.comment.user_short
        };
        this.$elem
          .addClass( 'modify' )
          .html( 
            $j.jqote( Reflect.templates.new_bullet_dialog, template_vars ) );

        this.comment.$elem.addClass( 'bullet_state' );
        this.elements = {
          new_bullet_text : this.$elem.find( '.new_bullet_text' ),
          bullet_text : this.$elem.find( '.rf_bullet_text' ),
          submit_button : this.$elem.find( '.submit .bullet_submit' )
        };
        
        var settings = Reflect.default_third_party_settings.noblecount(), 
            count_sel = '#rf_comment_wrapper-' + 
            this.comment.id + ' .bullet.modify li.count';
            
        this.elements.new_bullet_text
          .autoResize({extraSpace: 0})
          .NobleCount($j(count_sel) , settings );
        this.options.text_backup = this.text;
        
        // wont work in Greasemonkey
        try {
          this.elements.new_bullet_text.focus();
        } catch ( err ) {}

      },
      exit_edit_state : function ( canceled ) {
        this.comment.$elem.removeClass( 'bullet_state' );
        this.$elem.removeClass( 'modify' );
        if ( canceled && !this.id ) {
          this._build_prompt();
        } else {
          $j.extend( this.options, {
            listener_pic:Reflect.api.server.get_current_user_pic(),
            txt: canceled ? this.options.txt : this.elements.new_bullet_text.val(),
            u: Reflect.utils.get_logged_in_user() } );
          
          this.set_attributes();
          this._build();
        }
      },
      enter_highlight_state : function () {
        this.$elem.addClass('connect');
        this.comment.$elem.addClass( 'highlight_state' );
        
        var child = $j('<div />')
            .addClass('rf_dialog')
            .append( $j.jqote( Reflect.templates.bullet_highlight ));
        this.elements.bullet_main.append( child );
        this.elements.submit_button = this.$elem.find( '.submit .bullet_submit' );
      },
      exit_highlight_state : function ( canceled ) {
        this.comment.$elem.removeClass( 'highlight_state' );
        
        if ( canceled && !this.id ) {
          this._build_prompt();
          this.$elem.removeClass( 'connect' );
        } else {
          if ( canceled ) {
            this.options.txt = this.options.text_backup;
            this.elements.bullet_text.text(this.options.txt);
          }
          this.$elem
            .removeClass( 'new_bullet' )
            .addClass( 'full_bullet' );
          var me = this;
          this.$elem.find( '.rf_dialog' ).fadeOut(200, function(){
            me.$elem.removeClass( 'connect' );
            $j(this).remove();
          });
          me.set_attributes();
        }
        this.comment.elements.text_wrapper.find( '.highlight' )
            .removeClass( 'highlight' );
        this.comment.elements.bullet_list.find('.add_bullet').enable();
      },
      _add_response : function ( params ) {
        //var response = $j( '<li />' ).response( params );
        //this.elements.bullet_eval.find('.rf_rating').after( response );
        var response = $j( '<span />' ).response( params );
        this.elements.bullet_wrap.append( response );
        this.response = response;
        this.$elem.addClass('has_response');
        return $j.data( response[0], 'response' );
      },
      add_response : function ( response_info ) {
        this.elements.bullet_meta.remove();
        return this._add_response( {
          response_info : response_info,
          is_prompt : false,
          bullet : this
        } );
      },
      add_response_dialog : function () {
        return this._add_response( {
          media_dir : Reflect.api.server.media_dir,
          is_prompt : true,
          bullet : this
        } );
      },
      update_badge_gallery : function() {
        var logged_in_user = Reflect.utils.get_logged_in_user(),
            template_vars = {
          rating : this.ratings ? this.ratings.rating : null,
          enable_rating : Reflect.config.view.enable_rating,
          commenter : this.comment.user,
          logged_in_user : logged_in_user
        };
        this.$elem.find('.rf_rating').remove();
        this.$elem.find('.badges')
          .prepend($j.jqote( Reflect.templates.bullet_badge_gallery, template_vars ));
        var me = this,
          qtip_settings = $j.extend( true, Reflect.default_third_party_settings.qtip(35), {
            content : Reflect.utils.badge_tooltip(this),
            position: { adjust: { y: 10, x: 0}},
            api : {
              beforeShow: function(){
                return !!me.ratings.rating;
              }
            }
          });

        this.$elem.find( '.rf_gallery_container' ).qtip(qtip_settings);

        template_vars = {
           bullet_author : Reflect.utils.first_name(this.user),
           bullet_id : this.id,
           rating : this.my_rating,
           ratings : this.ratings,
           logged_in_user : Reflect.utils.first_name(logged_in_user)
        };

        qtip_settings = $j.extend( true, Reflect.default_third_party_settings.qtip(50), {
          content: $j.jqote( Reflect.templates.bullet_rating, template_vars ),
          position: { adjust: { y: 0, x: 10}},
          hide: { fixed : true },
          style: { padding : 0 }
        });

        this.$elem.find( '.rf_rating .rf_selector_container div' ).qtip(qtip_settings);
          
      }
    },

    Response : {
      init : function ( options, elem ) {
        this.options = $j.extend( {}, this.options, options.response_info );
        this.$elem = $j( elem );
        this.bullet = options.bullet;

        this.set_attributes();
        this.elements = {};

        if ( options.is_prompt ) {
          this._build_prompt();
        } else {
          this._build();
        }
        return this;
      },
      options : {},
      set_attributes : function () {
        this.id = parseInt(this.options.id, 10);
        this.rev = parseInt(this.options.response_rev, 10);
        this.user = this.options.u;
        this.text = Reflect.utils.escape( this.options.txt );
      },
      _build : function () {
        var first_name = Reflect.utils.first_name(this.user),
          tag = Reflect.utils.escape( String(this.options.sig) );
        
        if ( tag === '2' || tag === '0' ) {
          var tip;
          switch ( tag ) {
            case '2':
              tip = 'Accuracy confirmed <div><a class="user">- ' + this.user + '</a></div>';
              break;
            case '0':
              tip = 'This is not a summary<div><a class="user">- ' + this.user + '</a></div>';
              break;
            default:
              throw 'Bad signal';
          }
          var qtip_settings = $j.extend(true, Reflect.default_third_party_settings.qtip(140), {
            content : tip,
            style : { width : 140 },
            position: { adjust: { y: 0, x: 0}}
          });
          
          this.$elem
            .html($j.jqote( Reflect.templates.response, {
                sig : tag,
                user : Reflect.utils.escape( first_name )
            }))
            .qtip(qtip_settings);
             
        } else if ( tag === '1' ) {
          this.bullet.$elem.append('<div class="rf_clarification"><span>clarification:</span>' 
            + this.text + ' <a class="user"> &ndash; ' + first_name + '</a></div>');
          this.$elem.hide();
        }
        
        this.$elem.addClass( 'rf_response' );
        this.set_id( this.id, this.rev );
      },
      _build_prompt : function () {
        var template_vars = {
            bullet_id : this.bullet.id,
            text : this.text,
            sig : Reflect.utils.escape( String(this.options.sig) ),
            user : Reflect.utils.escape( this.user ),
            summarizer : this.bullet.user,
            response_prompt : Reflect.config.view.text.response_prompt.replace('{{LISTENER}}', this.bullet.user)            
          };
          
        this.bullet.elements.bullet_main.append($j.jqote( Reflect.templates.response_dialog, template_vars ));
        this.$elem.addClass( 'rf_response');
        
        this.elements = {
          prompt : this.bullet.$elem.find( '.response_prompt' ),
          new_response_text : this.bullet.$elem.find( '.new_response_text' ),
          submit_button : this.$elem.find( '.submit .bullet_submit' )
        };

        var settings = Reflect.default_third_party_settings.noblecount(),
            count_sel = '#bullet-' 
            + this.bullet.id 
            + ' .response_prompt .count';
        this.elements.new_response_text
          .autoResize({extraSpace: 0})
          .NobleCount( $j(count_sel), settings );  

      },
      set_id : function ( id, rev ) {
        this.id = id;
        this.rev = rev;
        this.$elem.attr( 'id', 'response-' + this.id );
      },
      exit_dialog : function ( ) {   
        var accurate_sel = "input[name='accurate-" + this.bullet.id + "']:checked";
        
        $j.extend( this.options, {
            u : Reflect.utils.get_logged_in_user(),
            txt : this.elements.new_response_text.val(),
            sig : this.elements.prompt.find( accurate_sel ).val()            
          });
        this.set_attributes();          
        this.elements.prompt.remove();
        this._build();
        this.$elem.removeClass('new');
      }
    }

  },
  /**
  * Your standard misc collection of functions. 
  */    
  utils : {
    /* escape the string */
    escape : function (str) {
      return str 
        ? $j('<div/>')
          .text(str.replace(/\\"/g, '"').replace(/\\'/g, "'"))
          .html()
        : '';
    },
    
    first_name : function ( full_name ) {
      if (full_name.indexOf(' ') > -1){
        full_name = full_name.substring(0, full_name.indexOf(' '));
      }
      return full_name;
    },
    
    get_logged_in_user : function () {
      if ( typeof Reflect.current_user == 'undefined' ) {
        Reflect.current_user = $j( '#rf_user_name' ).text();
      }
      return Reflect.current_user;
    },

    get_logged_in_user_id : function () {
      if ( typeof Reflect.current_user_id == 'undefined' ) {
        Reflect.current_user_id = $j( '#rf_user_id' ).text();
      }
      return Reflect.current_user_id;
    },

    badge_tooltip : function ( bullet_obj ) {
      var tip = '<div class="badge_tooltip">',
          rating = bullet_obj.ratings.rating,
          person_str = bullet_obj.ratings[rating] === 1 ? 'person' : 'people';
          
      if ( bullet_obj.ratings ) {
        switch ( rating ) {
          case 'zen':
            tip  +=  'Captures the essence of the comment.';
            break;
          case 'sun':
            tip  +=   'Helps shed light on what the commenter was trying to say.';
            break;
          case 'gold':
            tip  +=   'Uncovers an important point that could easily be missed.';
            break;
          case 'graffiti':
            tip  +=   'Not a summary.';
            break;
          case 'troll':
            tip  +=   'Antagonizing. Suspected trolling.'; 
            break;
          default:
            break;
        }
      }
      if ( !bullet_obj.my_rating ) {
        tip  +=  '<div class="according_to">' + bullet_obj.ratings[rating] + ' ' + person_str + '</div>';        
      } else if ( bullet_obj.my_rating === rating ) {
        var others = '';
        if ( bullet_obj.ratings[rating] === 1 ) { 
          others = ' and one other';
        } else if ( bullet_obj.ratings[rating] > 1 ) {
          others = ' and ' + bullet_obj.ratings[rating] + ' others';
        }
        tip  +=  '<div class="according_to">You' + others + ' agree</div>';
      } else {
        tip  +=  '<div class="according_to">' + bullet_obj.ratings[rating] + ' ' + person_str + '. You disagree</div>';        
      }

      return tip + '</div>';
    }
    
  },
  
  default_third_party_settings : {
    qtip: function ( delay ){
      return {
        show : { delay: delay },
        position : { 
          corner: {
            target: 'bottomRight',
            tooltip: 'topRight'
          }
        },
        style: {
          background: '#efefef',
          color: 'black',
          border: {
            width: 1,
            radius: 0,
            color: '#ccc'
          }
        }
      };
    },
    noblecount: function () {
      return {
        on_negative : Reflect.handle.negative_count,
        on_positive : Reflect.handle.positive_count,
        max_chars : 140
      };
    }
  }
};

$j( document ).ready( Reflect.init );


}(jQuery));

jQuery.fn.disable = function () {
  if ( jQuery().jquery >= '1.6' ) {
    jQuery(this).prop('disabled', true);
  } else {
    jQuery(this).attr('disabled', 'true');
  }
  return jQuery(this);
};

jQuery.fn.enable = function () {
  if ( jQuery().jquery >= '1.6' ) {
    jQuery(this).prop('disabled', false);
  } else {
    jQuery(this).attr('disabled', 'false');
  }
  return jQuery(this);
};