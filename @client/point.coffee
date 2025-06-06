require "./comment"




##
# Point
# A single point in a list. 
window.Point = ReactiveComponent
  displayName: 'Point'

  render : ->
    point = bus_fetch @props.point

    return SPAN null if !point.proposal

    proposal = bus_fetch point.proposal

    is_selected = get_selected_point() == @props.point

    current_user = bus_fetch('/current_user')



    renderIncluders = (draw_all_includers) =>

      if point.includers

        if draw_all_includers
          includers = @buildIncluders()
        else 
          includers = [point.user]

        s = #includers_style
          rows: 8
          dx: 2
          dy: 5
          col_gap: 8

        if includers.length == 0
          includers = [point.user]

        # Now we'll go through the list from back to front
        i = includers.length

        DIV null,

          for includer in includers
            i -= 1
            curr_column = Math.floor(i / s.rows)
            side_offset = curr_column * s.col_gap + i * s.dx
            top_offset = (i % s.rows) * s.dy 
            left_right = if point.is_pro then 'left' else 'right'
            style = 
              top: top_offset
              position: 'absolute'

            style[left_right] = side_offset

            includer_opinion = _.findWhere proposal.opinions, {user: includer}
            anonymous = includer_opinion?.hide_name || (point.hide_name && point.user == includer)

            avatar includer, 
              key: includer
              className: "point_includer_avatar"
              style: style
              set_bg_color: true
              anonymous: anonymous
    


    point_content_style = {}

    if is_selected
      _.extend point_content_style,
        borderColor: focus_color()
        backgroundColor: 'white'

    else if @local.has_focus
      _.extend point_content_style,
        borderColor: '#999'
        backgroundColor: 'white'

    expand_to_see_details = !!point.text




    includers_style = 
      position: 'absolute'
      height: 25
      width: 25
      top: 0
    left_or_right = if point.is_pro && @props.rendered_as != 'decision_board_point'
                      'right' 
                    else 
                      'left'
    ioffset = -50
    includers_style[left_or_right] = ioffset

    draw_all_includers = @props.rendered_as == 'community_point' || TABLET_SIZE()

    if expand_to_see_details && !is_selected
      append = SPAN 
        key: 1
        style:
          fontSize: 10
          color: '#888'
        " (#{translator({id: "engage.read_more"}, "read more")})"

    else 
      append = null

    LI
      key: "point-#{point.id}"
      'data-id': @props.point
      className: "point #{@props.rendered_as} #{if point.is_pro then 'pro' else 'con'} #{if customization('disable_comments') && !expand_to_see_details then 'commenting-disabled' else ''} #{if is_selected then 'is-selected' else ''}"
      onClick: @selectPoint
      # onTouchEnd: @selectPoint
      onKeyDown: (e) =>
        if (is_selected && e.which == 27) || e.which == 13 || e.which == 32
          @selectPoint(e)
          e.preventDefault()

      if @props.rendered_as == 'decision_board_point'
        DIV 
          style: 
            position: 'absolute'
            left: 0
            top: -2

          if point.is_pro then '•' else '•'

      DIV 
        ref: 'point_content'
        className:'point_content'
        style : point_content_style
        tabIndex: 0
        onBlur: (e) => @local.has_focus = false; save(@local)
        onFocus: (e) => @local.has_focus = true; save(@local)
        draggable: @props.enable_dragging
        "data-point": point.key


        if @props.rendered_as != 'decision_board_point' && !PHONE_SIZE()

          side = if point.is_pro then 'right' else 'left'
          mouth_style = 
            top: 8
            position: 'absolute'

          mouth_style[side] = -POINT_MOUTH_WIDTH + \
            if is_selected || @local.has_focus then 3 else 1
          
          if !point.is_pro
            mouth_style['transform'] = 'rotate(270deg) scaleX(-1)'
          else 
            mouth_style['transform'] = 'rotate(90deg)'

          DIV 
            'role': 'presentation'
            key: 'community_point_mouth'
            style: mouth_style

            PointBubblemouth 
              apex_xfrac: 0
              width: POINT_MOUTH_WIDTH
              height: POINT_MOUTH_WIDTH
              fill: considerit_gray
              stroke: if is_selected then focus_color() else if @local.has_focus then '#888' else 'transparent'
              stroke_width: if is_selected || @local.has_focus then 20 else 0

        DIV 
          style: 
            wordWrap: 'break-word'
            fontSize: POINT_FONT_SIZE()

          DIV 
            className: 'point_nutshell'

            splitParagraphs point.nutshell, append



          DIV 
            id: "point-aria-interaction-#{point.id}"
            className: 'hidden'

            translator
              id: "engage.point_explanation"
              author: if point.hide_name then anonymous_label() else bus_fetch(point.user).name
              num_inclusions: point.includers.length
              comment_count: point.comment_count
              """By {author}. 
                 { num_inclusions, plural, =0 {} one {Important to one person.} other {Important to # people.} } 
                 {comment_count, plural, =0 {} one {Has received one comment.} other {Has received # comments.} }
                 Press ENTER or SPACE for details or discussion."""

          DIV 
            'aria-hidden': true
            className: "point_details" + \
                       if is_selected
                         ''
                       else 
                         '_tease'

            style: 
              wordWrap: 'break-word'
              marginTop: '0.5em'
              fontSize: POINT_FONT_SIZE()
              

            DIV 
              style: 
                fontSize: 12
                color: '#666'

              if !PHONE_SIZE() && !screencasting() && !embedded_demo() && bus_fetch('/subdomain').name != 'galacticfederation'
                [
                  prettyDate(point.created_at)
                  SPAN key: 'padding', style: paddingLeft: 8
                ]

              if !customization('disable_comments')
                SPAN 
                  key: 2 
                  style: {whiteSpace: 'nowrap'}

                  A 
                    className: 'select_point'

                    translator
                      id: 'engage.link_to_comments'
                      comment_count: point.comment_count 
                      "{comment_count, plural, one {# comment} other {# comments}}"

              if PHONE_SIZE()
                SPAN 
                  key: 3
                  style: 
                    float: 'right'

                  "+#{point.includers.length}"

                  



        if current_user.user == point.user
          DIV null,
            if permit('update point', point) > 0 && 
                (@props.rendered_as == 'decision_board_point' || TABLET_SIZE())
              BUTTON
                style:
                  fontSize: if browser.is_mobile then 24 else 14
                  color: focus_color()
                  padding: '3px 12px 3px 0'
                  backgroundColor: 'transparent'
                  border: 'none'

                onTouchEnd: (e) -> e.stopPropagation()
                onClick: ((e) =>
                  e.stopPropagation()
                  points = bus_fetch(@props.your_points_key)
                  points.editing_points.push(@props.point)
                  save(points))
                translator 'engage.edit_button', 'edit'

            if permit('delete point', point) > 0 && 
                (@props.rendered_as == 'decision_board_point' || TABLET_SIZE())
              BUTTON
                'data-action': 'delete-point'
                style:
                  fontSize: if browser.is_mobile then 24 else 14
                  color: focus_color()
                  padding: '3px 8px'
                  backgroundColor: 'transparent'
                  border: 'none'
                onTouchEnd: (e) -> e.stopPropagation()       
                onClick: (e) =>
                  e.stopPropagation()
                  if confirm('Delete this point forever?')
                    destroy @props.point
                translator 'engage.delete_button', 'delete'

      if @props.rendered_as != 'decision_board_point' && !PHONE_SIZE() && @props.in_viewport
        DIV 
          'aria-hidden': true
          className:'includers'
          onMouseEnter: @highlightIncluders
          onMouseLeave: @unHighlightIncluders
          style: includers_style
            
          renderIncluders(draw_all_includers)



      if TABLET_SIZE() || (!TABLET_SIZE() && @props.enable_dragging)
        your_opinion = proposal.your_opinion
        if your_opinion.key 
          bus_fetch your_opinion


        can_opine = canUserOpine proposal          

        included = @included()
        includePoint = (e) => 


          e.stopPropagation()
          e.preventDefault()

          return unless e.type != 'click' || \
                        (!browser.is_android_browser && e.type == 'click')
          if !included
            @include()
          else 

            validate_first = point.user == bus_fetch('/current_user').user && point.includers.length < 2
            if !validate_first || confirm('Are you sure you want to mark your point as unimportant? It will be gone forever.')
              @remove()

        if !TABLET_SIZE() && @props.enable_dragging
          right = (included && point.is_pro) || (!included && !point.is_pro)
          if right 
            sty = 
              right: if !@local.focused_include then 20 else if included then -20 else -40
          else 
            sty = 
              left: if !@local.focused_include then 20 else if included then -20 else -40

          BUTTON
            'aria-label': if included 
                            translator 'engage.uninclude_explanation', 'Mark this point as unimportant and move to next point' 
                          else 
                            translator 'engage.include_explanation', 'Mark this point as important and move to next point'
            style: _.extend sty, 
              position: 'absolute'
              top: 20
              opacity: if !@local.focused_include then 0
              padding: 0
              backgroundColor: 'transparent'
              border: 'none'              
              display: if get_selected_point() then 'none'
            onFocus: (e) => 
              @local.focused_include = true; save @local
            onBlur: (e) => @local.focused_include = false; save @local
            onTouchEnd: includePoint
            onClick: includePoint
            onKeyDown: (e) => 
              if e.which == 13 || e.which == 32
                includePoint(e)
                valence = if point.is_pro then 'pros' else 'cons'

                next = $$.closest(e.target, '.point').nextElementSibling.querySelector('.point_content')
                next.focus()
                e.preventDefault()

            I 
              style: 
                fontSize: if included then 25 else 40
                color: focus_color()
              className: "fa fa-long-arrow-#{if !right then 'left' else 'right'}"

        else
          BUTTON 
            style: 
              border: "1px solid #{ if included || @local.hover_important then focus_color() else '#414141'}"
              borderTopColor: if included then focus_color() else 'transparent'
              color: if included then 'white' else if @local.hover_important then focus_color() else "#414141"
              position: 'relative'
              top: -13
              padding: '8px 5px'
              textAlign: 'center'
              borderRadius: '0 0 16px 16px'
              cursor: 'pointer'
              backgroundColor: if included then focus_color() else 'white'
              fontSize: 16  
              zIndex: 0
              display: if can_opine < 0 then 'none'
              width: '100%'

            onMouseEnter: => 
              @local.hover_important = true
              save @local
            onMouseLeave: => 
              @local.hover_important = false
              save @local

            onTouchEnd: includePoint
            onClick: includePoint

            onKeyDown: (e) => 
              if e.which == 13 || e.which == 32
                includePoint(e)
                e.preventDefault()
                e.stopPropagation()

            I
              className: 'fa fa-thumbs-o-up'
              style: 
                display: 'inline-block'
                marginRight: 10

            translator("engage.include_button", "Important") + "#{if included then '' else '?'}" 


      if is_selected
        Discussion
          key: "/comments/#{point.id}"
          comments: "/comments/#{point.id}"
          point: point.key
          rendered_as: @props.rendered_as

  componentDidMount : ->    
    @ensureDiscussionIsInViewPort()

    if @props.enable_dragging
      @initializeDragging()

  componentDidUpdate : -> 
    @ensureDiscussionIsInViewPort()
    if @props.enable_dragging
      @initializeDragging()

  initializeDragging : ->
    if !@drag_initialized

      @drag_initialized = true 
      point_root = ReactDOM.findDOMNode(@)
      point_width = null

      last_mouse_over_target = null

      @draggable = new Draggable.Draggable point_root,
        draggable: '.point'
        delay: 0
        distance: 1 # don't start drag unless moved a bit, otherwise click event gets swallowed up
        mirror: 
          appendTo: '#content'

      @draggable.on 'drag:start', (evt) =>
        point_width = evt.source.getBoundingClientRect().width

        # if @props.rendered_as != 'decision_board_point'
        #   point_root.closest(".ProposalItem").classList.add 'community-point-is-being-dragged'

      @draggable.on 'mirror:created', (evt) =>        
        evt.mirror.style.width = "#{point_width}px"

      @draggable.on 'drag:move', (evt) =>
        last_mouse_over_target = evt.sensorEvent.target

        if @props.rendered_as != 'decision_board_point' 
          db = last_mouse_over_target?.closest('.DecisionBoard')
          if db
            db.closest(".ProposalItem").classList.add 'community-point-is-being-dragged'
          else 
            point_root.closest(".ProposalItem").classList.remove 'community-point-is-being-dragged'

      @draggable.on 'drag:stop', (evt) =>

        if @props.rendered_as != 'decision_board_point'
          point_root.closest(".ProposalItem").classList.remove 'community-point-is-being-dragged'

          if db = last_mouse_over_target?.closest('.DecisionBoard')
            point = bus_fetch @props.point
            proposal = bus_fetch point.proposal
            your_opinion = proposal.your_opinion

            if !your_opinion.point_inclusions || point.key not in your_opinion.point_inclusions
              your_opinion.key ?= "/new/opinion"
              your_opinion.published = true
              your_opinion.point_inclusions ?= []
              your_opinion.point_inclusions.push point.key
              save your_opinion

              window.writeToLog
                what: 'included point'
                details: 
                  point: point.id

        else # removing decision_board_point by dragging outside
          if last_mouse_over_target?.closest('.points_by_community')
            point = bus_fetch @props.point
            proposal = bus_fetch point.proposal
            your_opinion = proposal.your_opinion

            validate_first = point.user == bus_fetch('/current_user').user && point.includers.length < 2
            if !validate_first || confirm('Are you sure you want to remove your point? It will be gone forever.')
              your_opinion = proposal.your_opinion

              if your_opinion.point_inclusions && point.key in your_opinion.point_inclusions
                idx = your_opinion.point_inclusions.indexOf point.key
                your_opinion.point_inclusions.splice(idx, 1)
                save your_opinion

                window.writeToLog
                  what: 'removed point'
                  details: 
                    point: point.key




  # Hack that fixes a couple problems:
  #   - Scroll to the point when following a link from an email 
  #     notification to a point
  #   - Scroll to new point when scrolled down to bottom of long 
  #     discussion & click a new point below it
  ensureDiscussionIsInViewPort : ->
    is_selected = get_selected_point() == @props.point
    if !!@local.is_selected != !!is_selected
      if is_selected
        
        i = setInterval =>
              discussion = document.getElementById('open_point')
              if discussion 
                if browser.is_mobile
                  $$.moveToTop ReactDOM.findDOMNode(@)
                  discussion.focus()

                else
                  $$.ensureInView discussion,
                    scroll: true
                    offset_buffer: 50 + $$.height(ReactDOM.findDOMNode(@))
                    callback: -> 
                      discussion.focus()

                clearInterval i
            , 10

      @local.is_selected = is_selected
      save @local




  included: -> 
    point = bus_fetch @props.point
    proposal = bus_fetch point.proposal
    your_opinion = proposal.your_opinion
    your_opinion.point_inclusions ?= []
    your_opinion.point_inclusions.indexOf(@props.point) > -1
    
  include: -> 
    point = bus_fetch @props.point 
    proposal = bus_fetch point.proposal

    your_opinion = proposal.your_opinion
    your_opinion.key ?= "/new/opinion"

    your_opinion.published = true 
    your_opinion.point_inclusions ?= []
    your_opinion.point_inclusions.push @props.point
    save(your_opinion)

    window.writeToLog
      what: 'included point'
      details: 
        point: @props.point

  remove: -> 
    point = bus_fetch @props.point 
    proposal = bus_fetch point.proposal

    your_opinion = proposal.your_opinion
    your_opinion.key ?= "/new/opinion"

    idx = your_opinion.point_inclusions.indexOf point.key

    if idx > -1
      your_opinion.point_inclusions.splice(idx, 1)
      save(your_opinion)


  selectPoint: (e) ->
    e.stopPropagation()
    point = bus_fetch @props.point

    return if !point.text && customization('disable_comments')

    # android browser needs to respond to this via a touch event;
    # all other browsers via click event. iOS fails to select 
    # a point if both touch and click are handled...sigh...
    # return unless ( browser.is_mobile && e.type != 'click' ) || \
    #               (!browser.is_mobile && e.type == 'click') || \
    #               e.type == 'keydown'

    loc = bus_fetch('location')
    if get_selected_point() == @props.point # deselect
      delete loc.query_params.selected
      what = 'deselected a point'

      document.activeElement.blur()
    else
      what = 'selected a point'
      loc.query_params.selected = @props.point

    save loc

    window.writeToLog
      what: what
      details: 
        point: @props.point


  ## ##
  # On hovering over a point, highlight the people who included this 
  # point in the Histogram.
  highlightIncluders : -> 
    point = bus_fetch @props.point
    includers = point.includers

    # For point authors who chose not to sign their points, remove them from 
    # the users to highlight. This is particularly important if the author 
    # is the only one who "included" the point. Then it is very eash for 
    # anyone to discover who wrote this point. 
    if point.hide_name
      includers = _.without includers, point.user

    opinion_views = bus_fetch 'opinion_views'
    opinion_views.active_views.point_includers =
      created_by: @props.point 
      point: point.key 
      get_salience: (u, opinion, proposal) ->
        if (u.key or u) in includers 
          1 
        else 
          .1
    save opinion_views


  unHighlightIncluders : -> 
    opinion_views = bus_fetch 'opinion_views'
    if opinion_views.active_views.point_includers
      delete opinion_views.active_views.point_includers
      save opinion_views

  buildIncluders : -> 
    point = bus_fetch @props.point 
    proposal = bus_fetch point.proposal

    includers = point.includers

    opinion_views = bus_fetch 'opinion_views'

    # Don't filter point_includers unless we're in single opinion or region select mode. If we didn't 
    # do that, when you hover over includers in a point, all the other points includers change, which 
    # is confusing for people.
    if !opinion_views.active_views.single_opinion_selected && !opinion_views.active_views.region_selected
      ignore_views = {point_includers: true}
    else 
      ignore_views = null

    {weights, salience, groups} = compose_opinion_views null, proposal, ignore_views

    includers = (i for i in includers when salience[i] == 1 && weights[i] > 0)
    includers = _.without includers, point.user
    includers.push point.user

    _.uniq includers
        

styles += """

  .point {
    position: relative;
    list-style: none outside none;
  }

  .point.decision_board_point {
    margin-left: 9px;
    padding: 0 0 0 18px;
  }

  .point.community_point {
    margin-bottom: 0.5em;
  }

  .point.is-selected {
    z-index: 100;
  }

  @media #{NOT_PHONE_MEDIA} {
    .point.community_point {
      filter: drop-shadow(rgba(0, 0, 0, 0.25) 0px 1px 1px);
    }

  }



  .point_content[draggable="false"] {
    cursor: pointer !important; }

  #{css.grab_cursor('.point_content[draggable="true"]')}


  .point.draggable-mirror {
    z-index: 99999999;
  }
  .point.draggable-mirror .includers, .point.draggable-mirror button {
    display: none;
  }  
  .point.draggable-source--is-dragging {
    transition: opacity 0ms !important;
    opacity: 0.2 !important;
  }
  .point.draggable--original {
    display: none;
  }
    


  .commenting-disabled .point_content[draggable="false"] {
    cursor: auto; }


  .commenting-disabled .point_details_tease {
    cursor: auto;
  }


  .point_content {
    border-width: 3px;
    border-style: solid; 
    border-color: transparent;
    top: -3px;
    position: relative;
    z-index: 1;
    outline: none;
  }

  .decision_board_point .point_content {
    padding: 8px 0px;
    border-radius: 8px;
    top: -11px;
  }

  .community_point .point_content {
    padding: 8px;
    border-radius: 16px;
    top: -11px;
    background-color: #{considerit_gray};
    /* box-shadow: #b5b5b5 0 1px 1px 0px; */
    min-height: 34px; 
  }

  @media #{NOT_LAPTOP_MEDIA} {
    .community_point .point_content {
      border-radius: 16px 16px 0 0;
    }
  }

  .point_nutshell a { text-decoration: underline; }
  .point_details_tease a, .point_details a {
    text-decoration: underline;
    word-break: break-all; }
  .point_details a.select_point{
    text-decoration: none;
    font-weight: 400;
  }

  .point_details {
    display: block; }

  .point_details_tease {
    cursor: pointer; }
    .point_details_tease a.select_point {
      text-decoration: none; 
      font-weight: 400;    
      }
      .point_details_tease a.select_point:hover {
        text-decoration: underline; }

  .point_details p {
    margin-bottom: 1em; }

  .point_details p:last-child {
    margin-bottom: 0; }

  .point_includer_avatar {
    width: 22px;
    height: 22px; }

  .community_point.con .point_includer_avatar {
    box-shadow: -1px 2px 0 0 #eeeeee; }

  .community_point.pro .point_includer_avatar {
    box-shadow: 1px 2px 0 0 #eeeeee; }

  .decision_board_point.pro .point_includer_avatar {
    left: -10px; }

"""
