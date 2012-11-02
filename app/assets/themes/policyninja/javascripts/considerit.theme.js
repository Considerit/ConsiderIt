$j(document).ready(function(){
  document.getElementById('header_logo').src = 'assets/policyninja/images/logo_large.png';  
  per_request();
  $j(document).ajaxComplete(function(e, xhr, settings) {
    per_request();
  });

  function per_request(){
    $j('#points_on_board_pro .pro_header img').attr('src', '/assets/policyninja/images/pro_header.png');
    $j('#points_on_board_con .con_header img').attr('src', '/assets/policyninja/images/con_header.png');

  }
});