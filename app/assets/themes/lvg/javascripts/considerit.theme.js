$j(document).ready(function(){

  $j('.proposals.horizontal').infiniteCarousel({
    speed: 1500,
    vertical: false,
    total_items: 8,
    items_per_page: 8,
    loading_from_ajax: false,
    dim: 900
  });

  // $j('.proposal_prompt .proposals.horizontal').infiniteCarousel({
  //   speed: 1500,
  //   vertical: false,
  //   total_items: 8,
  //   items_per_page: 8,
  //   loading_from_ajax: false,
  //   dim: 720
  // });    

  

});