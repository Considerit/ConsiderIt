/*********************************************
 For the ConsiderIt project.
 Copyright (C) 2010 - 2012 by Travis Kriplean.
 Licensed under the AGPL for non-commercial use.
 See https://github.com/tkriplean/ConsiderIt/ for details.
*********************************************/

(function($j){
  $j(document)
    .on('ajax:success', '.follow form, .unfollow form', function(event, data){
      $j(this).parent().addClass('hide').siblings('.follow, .unfollow').removeClass('hide'); 
    });

})(jQuery);