@ConsiderIt.module "Theme", (Theme, App, Backbone, Marionette, $, _) ->
  App.addInitializer ->

    #################
    ## LOCAL MEASURES

    fetch_targetable_proposals = (target, initial = false) ->
      $.get Routes.proposals_path(), {target: target}, (data, status, xhr) ->
        ConsiderIt.vent.trigger 'proposals:fetched', data
        ConsiderIt.vent.trigger 'proposals:reset'

        zip = target.split(':')[1]

        if initial
          proposals = data.proposals
          msg = if data.proposals.length > 0 then "#{data.proposals.length} ballot measures for #{zip} are now accessible." else "Sorry, we do not have any local measures on file for #{zip}."
          toastr.success(msg) if initial

        $unlocked = $('.unlocked')
        $unlocked.find('.zipcode').text(zip)
        $('.unlock').hide()
        $unlocked.show()

    current_user = ConsiderIt.request 'user:current'
    tags = current_user.getTags()
    if tags.length > 0
      fetch_targetable_proposals tags[0]

    
    $(document).on 'click', '#t-unlock-measures-button', (ev) ->
      zip = $('#t-unlock-measures-zip').val()
      target = "zip:#{zip}"
      fetch_targetable_proposals(target, true);
      $.post Routes.set_tag_path(), {tags:"#{target}", overwrite_type: true}, (data, status, xhr) ->

    $(document).on 'click', '.t-unlock-local .reset_zip', (ev) ->
      $('.unlocked').hide()
      $('.unlock').show()
      


    ##################

    $(document).on 'mouseenter mouseleave', '#homepage-people .avatar', (e) ->
      if e.type == 'mouseenter'
        to_hover = []
        idx = $(this).index()
        area = 3

        row = parseInt $(this).parent().attr('row')

        first = Math.max(row-area,0) 
        rows = $('#homepage-people').children()

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