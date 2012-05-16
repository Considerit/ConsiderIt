// ...
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require_directory ./third_party
//= require javascripts/reflect
//= require_self

(function($) {
  var subdirectory = '';
  reflect_server_settings = {
    media_dir: subdirectory + '/reflect/media',
    reflectPath: subdirectory + '/reflect_commenting',
    servicesPath: subdirectory + '/reflect',
  };
  var $j = jQuery.noConflict();

  Reflect.config.study = false;
  Reflect.config.view.enable_rating = false;
  
  $j.extend(Reflect.config.api, {
    media_dir: reflect_server_settings.media_dir //these settings need to be stored in Reflect.config.api... - Travis
  });
  
  $j.extend(Reflect.config.contract, {
    components: [{
      comment_identifier: '.comment',
      comment_offset:8,
      comment_text:'.comment_body',
      get_commenter_name: function(comment_id){return $j.trim( $j.trim($j('#comment-'+comment_id+ ' .username:first').text()).substring(2));}
    }]
  });

  Reflect.Contract = Reflect.Contract.extend({
    user_name_selector : function(){return '';},
    modifier: function(){},
    get_comment_thread: function(){
        return $j('body');
    }
  });

  Reflect.api.DataInterface = Reflect.api.DataInterface.extend({
    init: function(config) {
      this._super(config);
      this.api_loc = reflect_server_settings.servicesPath;
    },
    get_templates: function(callback) {
      $j.get(reflect_server_settings.servicesPath + '/get_templates', callback);
    },
    get_current_user: function() {
      var user = $j.trim($j('#nav-user .triangle .settings:visible').text());
      if(!user || user == '')
        user = 'Anonymous';
      return user;
    },

    post_bullet: function(settings){
      if (settings.params.bullet_id) {
        if (settings.params['delete']) { 
          loc = '/bullet_delete';
        } else{
          loc = '/bullet_update';       
        }
      }
      else {
        loc = '/bullet_new';
      }
        $j.ajax({
          url: reflect_server_settings.servicesPath + loc,
          type: 'POST',
          data: settings.params,
          error: function(data){
            var json_data = JSON.parse(data);
            settings.error(json_data);
          },
          success: function(data){
            settings.success(data);
          }
        });
      },
    post_response: function(settings){
      if (settings.params.response_id) {
        if (settings.params['delete']) { 
          loc = '/response_delete';
        } else{
          loc = '/response_update';       
        }

      }
      else {
        loc = '/response_new';
      }   
        $j.ajax({url:reflect_server_settings.servicesPath + loc,
              type:'POST',
              data: settings.params,
              error: function(data){
                  var json_data = JSON.parse(data);
                  settings.error(json_data);
              },
              success: function(data){
              settings.success(data);
          }
        });
      },    

    get_data: function(params, callback){
        $j.getJSON(reflect_server_settings.servicesPath + '/data', params, callback);
    }
    
  });
})(jQuery);