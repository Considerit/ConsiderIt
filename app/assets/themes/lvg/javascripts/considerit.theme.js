$j(document).ready(function(){

  // $j('.proposals.horizontal').infiniteCarousel({
  //   speed: 1500,
  //   vertical: false,
  //   total_items: 8,
  //   items_per_page: 8,
  //   loading_from_ajax: false,
  //   dim: 900
  // });

  // $j('.proposal_prompt .proposals.horizontal').infiniteCarousel({
  //   speed: 1500,
  //   vertical: false,
  //   total_items: 8,
  //   items_per_page: 8,
  //   loading_from_ajax: false,
  //   dim: 720
  // });    

  $j(document).on('click', '.assessment a.point_operation', function(){
    $j(this).hide();
    $j(this).siblings('.request_form').show();
  });

  $j(document).on('click', '.assessment .request_form a.cancel', function(){
    $j(this).parents('.request_form').hide();
    $j(this).parents('.request_form').siblings('.point_operation').show();
  });  

  $j(document).on('ajax:success', '.assessment .request_form form', function(){
    $j(this).parents('.request_form').siblings('.already_requested').show();    
    $j(this).parents('.request_form').remove();
  });

});