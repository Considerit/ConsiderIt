// modifies code from the below jquery plugins -Travis

/*
 *  Html5 Form Plugin - jQuery plugin
 *  Version 1.5  / English
 *  
 *  Author: by Matias Mancini http://www.matiasmancini.com.ar
 * 
 *  Copyright (c) 2010 Matias Mancini (http://www.matiasmancini.com.ar)
 *  Dual licensed under the MIT (MIT-LICENSE.txt)
 *  and GPL (GPL-LICENSE.txt) licenses.
 *
 *  Built for jQuery library
 *  http://jquery.com
 *
 */

(function($){
  $.fn.html5form = function(options){
    
    $(this).each(function(){
      if ( $(this).hasClass('html5formified')) {
        return false;
      }
      $(this).addClass('html5formified');

      var defaults = {
        async : $(this).attr('data-remote') == 'true',
        method : $(this).attr('method'), 
        responseDiv : null,
        action : $(this).attr('action'),
        messages : 'en',
        emptyMessage : false,
        emailMessage : false,
        allBrowsers : true
      };   
      var opts = $.extend({}, defaults, options);
      
      //Filter modern browsers 
      if( !opts.allBrowsers &&
          //skip if Webkit > 533
          (($.browser.webkit && parseInt($.browser.version) >= 533 && !!window.chrome ) ||
          //skip if Firefox > 4
          ($.browser.mozilla && parseInt($.browser.version) >= 2) ||
          //skip if Opera > 11
          ($.browser.opera && parseInt($.browser.version) >= 11)) ) {
        return false;
      }

      //Private properties
      var form = $(this);
      var required = new Array();
      var email = new Array();

      //Select event handler (just colors)
      $.each($('select', this), function(){
        $(this).css('color', opts.colorOff);
        $(this).change(function(){
          $(this).css('color', opts.colorOn);
        });
      });
      
      var input = $(':input:not([type="hidden"], :file, :button, :submit, :radio, :checkbox, select)', form);
      $.each(input, function(i) {
                
        //Make array of required inputs
        if(this.getAttribute('required')!=null){
          required[i]=$(this);
        }


        
        //Make array of Email inputs         
        if(this.getAttribute('type')=='email'){
          email[i]=$(this);
        }
        
        //Limits content typing to TEXTAREA type fields according to attribute maxlength
        $('textarea').filter(this).each(function(){
          if($(this).attr('maxlength')>0){
            $(this).keypress(function(ev){
              var cc = ev.charCode || ev.keyCode;
              if(cc == 37 || cc == 39) {
                return true;
              }
              if(cc == 8 || cc == 46) {
                return true;
              }
              if(this.value.length >= $(this).attr('maxlength')){
                return false;   
              }
              else{
                return true;
              }
            });
          }
        });
      });
      $.each($('input:submit, input:image, input:button:not(.inputfileproxy)', this), function() {
        $(this).bind('click', function(ev){
          var emptyInput=null;
          var emailError=null;
          //Search for empty fields & value same as placeholder
          //returns first input founded
          //Add messages for multiple languages
          $(required).each(function(key, value) {
            if(value==undefined){
              return true;
            }
            if(($(this).val()==$(this).attr('placeholder')) || ($(this).val()=='')){
              emptyInput=$(this);
              if(opts.emptyMessage){
                //Customized empty message
                $(opts.responseDiv).html('<p>'+opts.emptyMessage+'</p>');
              }
              else if(opts.messages=='es'){
                //Spanish empty message
                $(opts.responseDiv).html('<p>El campo '+$(this).attr('title')+' es requerido.</p>');
              }
              else if(opts.messages=='en'){
                //English empty message
                $(opts.responseDiv).html('<p>The '+$(this).attr('title')+' field is required.</p>');
              }
              else if(opts.messages=='it'){
                //Italian empty message
                $(opts.responseDiv).html('<p>Il campo '+$(this).attr('title')+' &eacute; richiesto.</p>');
              }
              else if(opts.messages=='de'){
                //German empty message
                $(opts.responseDiv).html('<p>'+$(this).attr('title')+' ist ein Pflichtfeld.</p>');
              }
              else if(opts.messages=='fr'){
                //Frech empty message
                $(opts.responseDiv).html('<p>Le champ '+$(this).attr('title')+' est requis.</p>');
              }
              else if(opts.messages=='nl' || opts.messages=='be'){
                //Dutch messages
                $(opts.responseDiv).html('<p>'+$(this).attr('title')+' is een verplicht veld.</p>');
              }
              else if(opts.messages=='br'){
                 //Brazilian empty message
                 $(opts.responseDiv).html('<p>O campo '+$(this).attr('title')+' &eacute; obrigat&oacute;rio.</p>');
              }
              else if(opts.messages=='br'){
                $(opts.responseDiv).html("<p>Insira um email v&aacute;lido por favor.</p>");
              }           
              return false;
            }
          return emptyInput;
          });
            
          //check email type inputs with regular expression
          //return first input founded
          $(email).each(function(key, value) {
            if(value==undefined){
              return true;
            }
            if($(this).val().search(/[\w-\.]{3,}@([\w-]{1,}\.)*([\w-]{2,}\.)[\w-]{2,4}/i)){
              emailError=$(this);
              return false;
            }
          return emailError;
          });
          
          //Submit form ONLY if emptyInput & emailError are null
          //if async property is set to false, skip ajax
          if(!emptyInput && !emailError){
            
            //Clear all empty value fields before Submit 
            $(input).each(function(){
              if($(this).val()==$(this).attr('placeholder')){
                $(this).val('');
              }
            }); 
            //Submit data by Ajax
            if(opts.async){
              var formData=$(form).serialize();
              $.ajax({
                url : opts.action,
                type : opts.method,
                data : formData,
                success : function(data){
                  if(opts.responseDiv){
                    $(opts.responseDiv).html(data);   
                  }
                  //Reset form
                  $(input).val('');
                  $.each(form[0], function(){
                    $('select', form).each(function(){
                      $(this).css('color', opts.colorOff);
                      $(this).children('option:eq(0)').attr('selected', 'selected');
                    });
                    $(':radio, :checkbox', form).removeAttr('checked');
                  });  
                }
              });   
            }
            else{
              $(form).submit();
            }
          }else{
            if(emptyInput){
              $(emptyInput).focus().select();        
            }
            else if(emailError){
              //Customized email error messages (Spanish, English, Italian, German, French, Dutch)
              if(opts.emailMessage){
                $(opts.responseDiv).html('<p>'+opts.emailMessage+'</p>');
              }
              else if(opts.messages=='es'){
                $(opts.responseDiv).html('<p>Ingrese una direcci&oacute;n de correo v&aacute;lida por favor.</p>');
              }
              else if(opts.messages=='en'){
                $(opts.responseDiv).html('<p>Please type a valid email address.</p>');
              }
              else if(opts.messages=='it'){
                $(opts.responseDiv).html("<p>L'indirizzo e-mail non &eacute; valido.</p>");
              }
              else if(opts.messages=='de'){
                $(opts.responseDiv).html("<p>Bitte eine g&uuml;ltige E-Mail-Adresse eintragen.</p>");
              }
              else if(opts.messages=='fr'){
                $(opts.responseDiv).html("<p>Entrez une adresse email valide s&rsquo;il vous plait.</p>");
              }
              else if(opts.messages=='nl' || opts.messages=='be'){
                $(opts.responseDiv).html('<p>Voert u alstublieft een geldig email adres in.</p>');
              }
              $(emailError).select();
            }else{
              alert('Unknown Error');            
            }
          }
          return false;
        });
      });

    });
  } 
})(jQuery);

