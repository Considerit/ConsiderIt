$(document).ready(function(){

  $(document).on('mouseenter mouseleave', '#t-intro-people .avatar', function(e){
    if(e.type == 'mouseenter') {
      var to_hover = [];
      var idx = $(this).index();
      var area = 3;

      var row = parseInt($(this).parent().attr('row'));

      var first = Math.max(row-area,0);
      var rows = $('#t-intro-people').children();//.slice(first, row + area + 1);

      for (var i = 0; i < rows.length; i+=1) {
        first = Math.max(idx-area,0);
        var children = $(rows[i]).children().slice(first, idx+area+1);
        for ( var j = 0; j < children.length; j+=1) {
          to_hover.push( children[j] );
        }
      }

      $(to_hover).addClass('hovered');

    } else {
      $(this).parent().parent().find('.avatar.hovered').removeClass('hovered');
    }

  });

});