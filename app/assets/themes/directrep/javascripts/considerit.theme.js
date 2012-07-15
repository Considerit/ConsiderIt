
$j(document).ready(function(){
  $j('.homepage #proposals .proposals').infiniteCarousel({
    speed: 1500,
    vertical: false,
    total_items: 3,
    items_per_page: 3,
    loading_from_ajax: false,
    dim: 700
  });    
});
