$(document).ready ->

  #################
  ## LOCAL MEASURES

  fetch_targetable_proposals = (target) ->
    $.get Routes.proposals_path(), {target: target}, (data, status, xhr) ->
      ConsiderIt.vent.trigger 'proposals:fetched', data
      ConsiderIt.vent.trigger 'proposals:reset'

  current_user = ConsiderIt.request('user:current');
  if current_user
    tags = current_user.getTags()
    if tags.length > 0
      fetch_targetable_proposals tags[tags.length-1]

  
  $(document).on 'click', '#t-unlock-measures-button', (ev) ->
    target = "zip:#{$('#t-unlock-measures-zip').val()}"
    fetch_targetable_proposals(target);
    $.post Routes.set_tag_path(), {tags:"#{target}"}, (data, status, xhr) ->
      console.log data

  ##################

  $(document).on 'mouseenter mouseleave', '#t-intro-people .avatar', (e) ->
    if e.type == 'mouseenter'
      to_hover = []
      idx = $(this).index()
      area = 3

      row = parseInt $(this).parent().attr('row')

      first = Math.max(row-area,0) 
      rows = $('#t-intro-people').children()

      for i in [0..rows.length-1]
        first = Math.max(idx-area,0)
        children = $(rows[i]).children().slice(first, idx+area+1)
        for j in [0..children.length-1]
          to_hover.push children[j]

      $(to_hover).addClass 'hovered'

    else
      $(this)
        .parent().parent()
        .find('.avatar.hovered')
        .removeClass('hovered')