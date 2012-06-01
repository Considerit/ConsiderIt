
(function($j){
  $j(document)
    .on('ajax:success', '.follow form, .unfollow form', function(event, data){
      $j(this).parent().hide().siblings().show(); 
    });

})(jQuery);