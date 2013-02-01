/*********************************************
 For the ConsiderIt project.
 Copyright (C) 2010 - 2012 by Travis Kriplean.
 Licensed under the AGPL for non-commercial use.
 See https://github.com/tkriplean/ConsiderIt/ for details.
*********************************************/

(function($){
  $(document)
    .on('ajax:success', '.follow form, .unfollow form', function(event, data){
      $(this).parent().addClass('hide').siblings('.follow, .unfollow').removeClass('hide'); 
    });

})(jQuery);