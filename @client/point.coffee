require './comment'
##
# Point
# A single point in a list. 
window.Point = ReactiveComponent
  displayName: 'Point'

  render : ->
    point = @data()

    is_selected = get_selected_point() == @props.key

    current_user = fetch('/current_user')


    renderIncluders = (draw_all_includers) =>

      if @data().opinions

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
            left_right = if @data().is_pro then 'left' else 'right'
            style = 
              top: top_offset
              position: 'absolute'
              width: 50
              height: 50

            style[left_right] = side_offset

            # Finally draw the guys
            Avatar
              key: includer
              className: "point_includer_avatar"
              style: style
              set_bg_color: true
              anonymous: point.user == includer && point.hide_name



    point_content_style = 
      width: POINT_WIDTH() #+ 6
      borderWidth: 3
      borderStyle: 'solid'
      borderColor: 'transparent'
      top: -3
      position: 'relative'
      zIndex: 1
      outline: 'none'

    if is_selected
      _.extend point_content_style,
        borderColor: focus_color()
        backgroundColor: 'white'

    else if @local.has_focus
      _.extend point_content_style,
        borderColor: '#999'
        backgroundColor: 'white'

    if @props.rendered_as == 'decision_board_point'
      _.extend point_content_style,
        padding: 8
        borderRadius: 8
        top: point_content_style.top - 8
        left: -11
        #width: point_content_style.width + 16

    else if @props.rendered_as == 'community_point'
      _.extend point_content_style,
        padding: 8
        borderRadius: 16
        top: point_content_style.top - 8
        #left: point_content_style.left - 8
        #width: point_content_style.width + 16


    expand_to_see_details = !!point.text

    point_style = 
      position: 'relative'
      listStyle: 'none outside none'


    if @props.rendered_as == 'decision_board_point'
      _.extend point_style, 
        marginLeft: 9
        padding: '0 18px 0 18px'
    else if @props.rendered_as == 'community_point'
      point_style.marginBottom = '0.5em'



    includers_style = 
      position: 'absolute'
      height: 25
      width: 25
      top: 0
    left_or_right = if @data().is_pro && @props.rendered_as != 'decision_board_point'
                      'right' 
                    else 
                      'left'
    ioffset = -50
    includers_style[left_or_right] = ioffset

    draw_all_includers = @props.rendered_as == 'community_point'

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
      'data-id': @props.key
      className: "point #{@props.rendered_as} #{if point.is_pro then 'pro' else 'con'}"
      onClick: @selectPoint
      onTouchEnd: @selectPoint
      onKeyDown: (e) =>
        if (is_selected && e.which == 27) || e.which == 13 || e.which == 32
          @selectPoint(e)
          e.preventDefault()
      style: point_style


      DIV 
        className:'point_content'
        style : point_content_style
        tabIndex: 0
        onBlur: (e) => @local.has_focus = false; save(@local)
        onFocus: (e) => @local.has_focus = true; save(@local)

        if @props.rendered_as != 'decision_board_point'

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
            style: css.crossbrowserify mouth_style

            Bubblemouth 
              apex_xfrac: 0
              width: POINT_MOUTH_WIDTH
              height: POINT_MOUTH_WIDTH
              fill: considerit_gray
              stroke: if is_selected then focus_color() else if @local.has_focus then '#888' else 'transparent'
              stroke_width: if is_selected || @local.has_focus then 20 else 0
              box_shadow:   
                dx: 3
                dy: 0
                stdDeviation: 2
                opacity: .5

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
              id: "engage.point_explanations"
              author: if point.hide_name then anonymous_label() else fetch(point.user).name
              num_positive_opinions: (o for o in @data().opinions when o.stance > 0).length
              comment_count: point.comment_count
              """By {author}. 
                 { num_positive_opinions, plural, =0 {} one {Important to one person.} other {Important to # people.} } 
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
              fontWeight: if browser.high_density_display && !browser.is_mobile then 300 else 400              
              

            DIV 
              style: 
                fontSize: 12

              prettyDate(point.created_at)
              ', '                
              SPAN 
                key: 2 
                style: {whiteSpace: 'nowrap'}

                A 
                  className: 'select_point'

                  translator
                    id: 'engage.link_to_comments'
                    comment_count: point.comment_count 
                    "{comment_count, plural, one {# comment} other {# comments}}"



        if current_user.user == point.user

          DIV null,
            if permit('update point', point) > 0 && 
                (@props.rendered_as == 'decision_board_point')
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
                  points = fetch(@props.your_points_key)
                  points.editing_points.push(@props.key)
                  save(points))
                translator 'engage.edit_button', 'edit'

            if permit('delete point', point) > 0 && 
                (@props.rendered_as == 'decision_board_point')
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
                    destroy @props.key
                translator 'engage.delete_button', 'delete'

      DIV 
        'aria-hidden': true
        className:'includers'
        onMouseEnter: @highlightSupporters
        onMouseLeave: @unhighlightSupporters
        style: includers_style
          
        renderIncluders(draw_all_includers)


      DIV
        style: 
          margin: "8px 0 36px 0"
          
        Slidergram
          width: POINT_WIDTH()
          height: 40
          statement: point
          enable_range_selection: false

      if is_selected
        Discussion
          key:"/comments/#{point.id}"
          point: point.key
          rendered_as: @props.rendered_as

  componentDidMount : ->    
    @ensureDiscussionIsInViewPort()

  componentDidUpdate : -> 
    @ensureDiscussionIsInViewPort()


  # Hack that fixes a couple problems:
  #   - Scroll to the point when following a link from an email 
  #     notification to a point
  #   - Scroll to new point when scrolled down to bottom of long 
  #     discussion & click a new point below it
  ensureDiscussionIsInViewPort : ->
    is_selected = get_selected_point() == @props.key
    if @local.is_selected != is_selected
      if is_selected
        if browser.is_mobile
          $(@getDOMNode()).moveToTop {scroll: false}
        else
          $(@getDOMNode()).ensureInView {scroll: false}
        
        i = setInterval ->
              if $('#open_point').length > 0 
                $('#open_point').focus()
                clearInterval i
            , 10

      @local.is_selected = is_selected
      save @local

  selectPoint: (e) ->
    e.stopPropagation()

    # android browser needs to respond to this via a touch event;
    # all other browsers via click event. iOS fails to select 
    # a point if both touch and click are handled...sigh...
    return unless ( browser.is_mobile && e.type != 'click' ) || \
                  (!browser.is_mobile && e.type == 'click') || \
                  e.type == 'keydown'


    loc = fetch('location')
    if get_selected_point() == @props.key # deselect
      delete loc.query_params.selected
      what = 'deselected a point'

      document.activeElement.blur()
    else
      what = 'selected a point'
      loc.query_params.selected = @props.key

    save loc

    window.writeToLog
      what: what
      details: 
        point: @props.key


  buildIncluders : -> 
    point = @data()

    includers = (o.user for o in point.opinions or [])

    opinion_views = fetch 'opinion_views'
    {weights, salience, groups} = compose_opinion_views null, @proposal

    includers = (i for i in includers when salience[i] == 1 && weights[i] > 0)

    includers = _.without includers, point.user
    includers.push point.user

    _.uniq includers
        

styles += """

/* war! disabled jquery UI draggable class defined with !important */
.point_content.ui-draggable-disabled {
  cursor: pointer !important; }

#{css.grab_cursor('.point_content.ui-draggable')}

.community_point .point_content {
  border-radius: 16px;
  padding: 0.5em 9px;
  background-color: #{considerit_gray};
  box-shadow: #b5b5b5 0 1px 1px 0px;
  min-height: 34px; }

.point_nutshell a { text-decoration: underline; }
.point_details_tease a, .point_details a {
  text-decoration: underline;
  word-break: break-all; }
.point_details a.select_point{text-decoration: none;}

.point_details {
  display: block; }

.point_details_tease {
  cursor: pointer; }
  .point_details_tease a.select_point {
    text-decoration: none; }
    .point_details_tease a.select_point:hover {
      text-decoration: underline; }

.point_details p {
  margin-bottom: 1em; }

.point_details p:last-child {
  margin-bottom: 0; }

.point_includer_avatar {
  width: 50px;
  height: 50px; }

.community_point.con .point_includer_avatar {
  box-shadow: -1px 2px 0 0 #eeeeee; }

.community_point.pro .point_includer_avatar {
  box-shadow: 1px 2px 0 0 #eeeeee; }

.decision_board_point.pro .point_includer_avatar {
  left: -10px; }

"""

