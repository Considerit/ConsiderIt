$(document).ready(function(){

  // $('.proposals.horizontal').infiniteCarousel({
  //   speed: 1500,
  //   vertical: false,
  //   total_items: 8,
  //   items_per_page: 8,
  //   loading_from_ajax: false,
  //   dim: 900
  // });

  // $('.proposal_prompt .proposals.horizontal').infiniteCarousel({
  //   speed: 1500,
  //   vertical: false,
  //   total_items: 8,
  //   items_per_page: 8,
  //   loading_from_ajax: false,
  //   dim: 720
  // });    

  $(document).on('click', '.assessment a.point_operation', function(){
    $(this).hide();
    $(this).siblings('.request_form').show();
  });

  $(document).on('click', '.assessment .request_form a.cancel', function(){
    $(this).parents('.request_form').hide();
    $(this).parents('.request_form').siblings('.point_operation').show();
  });  

  $(document).on('ajax:success', '.assessment .request_form form', function(){
    $(this).parents('.request_form').siblings('.already_requested').show();    
    $(this).parents('.request_form').remove();
  });

});