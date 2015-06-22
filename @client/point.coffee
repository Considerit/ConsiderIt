
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

      if @data().includers

        if !draw_all_includers
          includers = [point.user]
        else 
          includers = @buildIncluders()

        s = #includers_style
          rows: 8
          dx: 2
          dy: 5
          col_gap: 8

        if includers.length == 0
          includers = [point.user]

        # Now we'll go through the list from back to front
        i = includers.length

        for includer in includers
          i -= 1
          curr_column = Math.floor(i / s.rows)
          side_offset = curr_column * s.col_gap + i * s.dx
          top_offset = (i % s.rows) * s.dy 
          left_right = if @data().is_pro && @props.rendered_as != 'under_review' then 'left' else 'right'
          style = 
            top: top_offset
            position: 'absolute'

          style[left_right] = side_offset

          # Finally draw the guys
          Avatar
            key: includer
            className: "point_includer_avatar"
            style: style
            hide_tooltip: @props.rendered_as == 'under_review' 
            anonymous: point.user == includer && point.hide_name

    renderNewIndicator = =>
      if @data().includers
        side_offset = 48
        left_right = if @data().is_pro then 'right' else 'left'
        style = 
          position: 'absolute'
          color: 'rgb(255,22,3)'
          fontSize: '11px'
          top: -14
          #backgroundColor: 'white'
          zIndex: 5
          fontVariant: 'small-caps'
          fontWeight: 'bold'

        style[left_right] = "#{-side_offset}"
        SPAN {style: style}, '-new-'


    point_content_style = 
      width: POINT_CONTENT_WIDTH() #+ 6
      borderWidth: 3
      borderStyle: 'solid'
      borderColor: 'transparent'
      top: -3
      position: 'relative'
      zIndex: 1

    if is_selected
      _.extend point_content_style,
        borderColor: focus_blue
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
        borderRadius: if TWO_COL() then "16px 16px 0 0" else 16
        top: point_content_style.top - 8
        #left: point_content_style.left - 8
        #width: point_content_style.width + 16

    else if @props.rendered_as == 'under_review'
      _.extend point_content_style, {width: 500}


    expand_to_see_details = point.text && 
                             (point.nutshell.length + point.text.length) > 210

    select_enticement = []


    if expand_to_see_details
      select_enticement.push DIV key: 1,
        if is_selected
          "read less"
        else
          [SPAN key: 1, dangerouslySetInnerHTML: {__html: '&hellip;'}
          #' ('
          A key: 2, className: 'select_point',
            "read more"
          #')'
          ]

    if point.comment_count > 0 || !expand_to_see_details
      select_enticement.push DIV key: 2, style: {whiteSpace: 'nowrap'},
        #" ("
        A 
          className: 'select_point'
          point.comment_count 
          " comment"
          if point.comment_count != 1 then 's' else ''
        #")"

    if point.assessment
      select_enticement.push DIV key: 3,
        I
          className: 'fa fa-search'
          title: 'Click to read a fact-check of this point'
          style: 
            color: '#5E6B9E'
            fontSize: 14
            cursor: 'help'
            paddingLeft: 4


    point_style = 
      position: 'relative'
      listStyle: 'none outside none'



    if @props.rendered_as == 'decision_board_point'
      _.extend point_style, 
        marginLeft: 9
        padding: '0 18px 0 18px'
    else if @props.rendered_as in ['community_point', 'under_review']
      point_style.marginBottom = '0.5em'



    includers_style = 
      position: 'absolute'
      height: 25
      width: 25
    left_or_right = if @data().is_pro && !(@props.rendered_as in ['decision_board_point', 'under_review'])
                      'right' 
                    else 
                      'left'
    ioffset = if @props.rendered_as in ['under_review'] then -10 else -50
    includers_style[left_or_right] = ioffset

    draw_all_includers = @props.rendered_as == 'community_point'
    LI
      key: "point-#{point.id}"
      'data-id': @props.key
      className: "point #{@props.rendered_as} #{if point.is_pro then 'pro' else 'con'}"
      onClick: @selectPoint
      onTouchEnd: @selectPoint
      style: point_style

      if @props.rendered_as == 'community_point' && @props.is_new
        renderNewIndicator()

      if @props.rendered_as == 'decision_board_point'
        DIV 
          style: 
            position: 'absolute'
            left: 0
            top: 0

          if @data().is_pro then '•' else '•'

      else
        DIV 
          className:'includers'
          onMouseEnter: @highlightIncluders
          onMouseLeave: @unHighlightIncluders
          style: includers_style
            
          renderIncluders(draw_all_includers)

      DIV className:'point_content', style : point_content_style,

        if @props.rendered_as != 'decision_board_point'

          side = if point.is_pro && @props.rendered_as != 'under_review' then 'right' else 'left'
          mouth_style = 
            top: 8
            position: 'absolute'

          mouth_style[side] = -POINT_MOUTH_WIDTH + \
            if is_selected || @props.rendered_as == 'under_review' then 3 else 0
          
          if !point.is_pro || @props.rendered_as == 'under_review'
            mouth_style['transform'] = 'rotate(270deg) scaleX(-1)'
          else 
            mouth_style['transform'] = 'rotate(90deg)'

          DIV 
            key: 'community_point_mouth'
            style: css.crossbrowserify mouth_style

            Bubblemouth 
              apex_xfrac: 0
              width: POINT_MOUTH_WIDTH
              height: POINT_MOUTH_WIDTH
              fill: considerit_gray
              stroke: if is_selected then focus_blue else 'transparent'
              stroke_width: if is_selected then 20 else 0
              box_shadow:   
                dx: '3'
                dy: '0'
                stdDeviation: "2"
                opacity: .5

        DIV 
          style: 
            wordWrap: 'break-word'
            fontSize: POINT_FONT_SIZE()
          splitParagraphs point.nutshell

          DIV 
            className: "point_details" + \
                       if is_selected || @props.rendered_as == 'under_review' 
                         ''
                       else 
                         '_tease'

            style: 
              wordWrap: 'break-word'
              marginTop: '0.5em'
              fontSize: POINT_FONT_SIZE()
              fontWeight: if browser.high_density_display then 300 else 400

            if point.text && point.text.length > 0
              if is_selected || 
                  !expand_to_see_details || 
                  @props.rendered_as == 'under_review'
                splitParagraphs(point.text)
              else 
                $("<span>#{point.text[0..210-point.nutshell.length]}</span>").text()

            if select_enticement && @props.rendered_as != 'under_review'
              DIV 
                style: 
                  fontSize: 12

                select_enticement

        DIV null,
          if permit('update point', point) > 0 && 
              (@props.rendered_as == 'decision_board_point' || TWO_COL())
            A
              style:
                fontSize: if browser.is_mobile then 18 else 14
                color: focus_blue
                padding: '3px 12px 3px 0'

              onClick: ((e) =>
                e.stopPropagation()
                points = fetch(@props.your_points_key)
                points.editing_points.push(@props.key)
                save(points))
              SPAN null, 'edit'

          if permit('delete point', point) > 0 && 
              (@props.rendered_as == 'decision_board_point' || TWO_COL())
            A 
              'data-action': 'delete-point'
              style:
                fontSize: if browser.is_mobile then 18 else 14
                color: focus_blue
                padding: '3px 8px'
              onClick: (e) =>
                e.stopPropagation()
                if confirm('Delete this point forever?')
                  destroy @props.key
              SPAN null, 'delete'

      if TWO_COL() && @props.rendered_as != 'under_review'
        included = @included()
        DIV 
          style: 
            border: "1px solid #{ if included || @local.hover_important then focus_blue else '#414141'}"
            borderTopColor: if included then focus_blue else 'transparent'
            color: if included then 'white' else if @local.hover_important then focus_blue else "#414141"
            position: 'relative'
            top: -13
            padding: '8px 5px'
            textAlign: 'center'
            borderRadius: '0 0 16px 16px'
            cursor: 'pointer'
            backgroundColor: if included then focus_blue else 'white'
            fontSize: 18  
            zIndex: 0


          onMouseEnter: => 
            @local.hover_important = true
            save @local
          onMouseLeave: => 
            @local.hover_important = false
            save @local

          onClick: (e) => 
            if included
              @remove()
            else 
              @include()

            e.stopPropagation()

          I
            className: 'fa fa-thumbs-o-up'
            style: 
              display: 'inline-block'
              marginRight: 10

          "Important point#{if included then '' else '?'}" 


      if is_selected
        Discussion
          key:"/comments/#{point.id}"
          point: point


  componentDidMount : ->    
    @setDraggability()
    @ensureDiscussionIsInViewPort()

  componentDidUpdate : -> 
    @setDraggability()
    @ensureDiscussionIsInViewPort()

  # Hack that fixes a couple problems:
  #   - Scroll to the point when following a link from an email 
  #     notification to a point
  #   - Scroll to new point when scrolled down to bottom of long 
  #     discussion & click a new point below it
  ensureDiscussionIsInViewPort : ->
    if get_selected_point() == @props.key

      if browser.is_mobile
        $(@getDOMNode()).moveToTop {scroll: false}
      else
        $(@getDOMNode()).ensureInView {scroll: false}

  setDraggability : ->
    # Ability to drag include this point if a community point, 
    # or drag remove for point on decision board
    # also: disable for results page

    return if @props.rendered_as == 'under_review'

    $point_content = $(@getDOMNode()).find('.point_content')
    revert = 
      if @props.rendered_as == 'community_point' 
        'invalid' 
      else (valid) =>
        if !valid
          @remove()
        valid

    if $point_content.hasClass "ui-draggable"
      $point_content.draggable(if @props.enable_dragging then 'enable' else 'disable' ) 
    else
      $point_content.draggable
        revert: revert
        disabled: !@props.enable_dragging

  included: -> 
    your_opinion = fetch(@proposal.your_opinion)
    your_opinion.point_inclusions.indexOf(@props.key) > -1

  remove: -> 
    your_opinion = fetch(@proposal.your_opinion)
    your_opinion.point_inclusions = _.without your_opinion.point_inclusions, \
                                              @props.key
    save(your_opinion)
    window.writeToLog
      what: 'removed point'
      details: 
        point: @props.key

  include: -> 
    your_opinion = fetch(@proposal.your_opinion)

    your_opinion.point_inclusions.push @data().key
    save(your_opinion)

    window.writeToLog
      what: 'included point'
      details: 
        point: @data().key


  selectPoint: (e) ->
    # android browser needs to respond to this via a touch event;
    # all other browsers via click event. iOS fails to select 
    # a point if both touch and click are handled...sigh...
    return unless browser.is_android_browser || e.type == 'click'

    return if @props.rendered_as == 'under_review'

    e.stopPropagation()

    loc = fetch('location')

    if get_selected_point() == @props.key # deselect
      delete loc.query_params.selected
      what = 'deselected a point'
    else
      what = 'selected a point'
      loc.query_params.selected = @props.key

    save loc

    window.writeToLog
      what: what
      details: 
        point: @props.key


  ## ##
  # On hovering over a point, highlight the people who included this 
  # point in the Histogram.
  highlightIncluders : -> 
    point = @data()
    includers = point.includers

    # For point authors who chose not to sign their points, remove them from 
    # the users to highlight. This is particularly important if the author 
    # is the only one who "included" the point. Then it is very eash for 
    # anyone to discover who wrote this point. 
    if point.hide_name
      includers = _.without includers, point.user
    hist = fetch namespaced_key('histogram', @proposal)
    if hist.highlighted_users != includers
      hist.highlighted_users = includers
      save(hist)

  unHighlightIncluders : -> 
    hist = fetch namespaced_key('histogram', @proposal)
    hist.highlighted_users = null
    save(hist)

  buildIncluders : -> 
    point = @data()
    author_has_included = _.contains point.includers, point.user

    includers = point.includers

    hist = fetch(namespaced_key('histogram', @proposal))
    selected_opinions = if hist.selected_opinion
                          [hist.selected_opinion] 
                        else 
                          hist.selected_opinions

    if selected_opinions?.length > 0      
      # only show includers from the current opinion selection
      selected_users = (fetch(o).user for o in selected_opinions)
      includers = _.intersection includers, selected_users
      author_has_included = _.contains selected_users, point.user

    if author_has_included 
      includers = _.without includers, point.user
      includers.push point.user

    _.uniq includers
        

styles += """

/* war! disabled jquery UI draggable class defined with !important */
.point_content.ui-draggable-disabled {
  cursor: pointer !important; }

#{css.grab_cursor('.point_content.ui-draggable')}

.community_point .point_content, .under_review .point_content {
  border-radius: 16px;
  padding: 0.5em 9px;
  background-color: #{considerit_gray};
  box-shadow: #b5b5b5 0 1px 1px 0px;
  min-height: 34px; }

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

.under_review .point_includer_avatar {
  top: 0px;
  width: 50px;
  height: 50px;
  left: -73px;
  box-shadow: -1px 2px 0 0 #eeeeee; }

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


window.Comment = ReactiveComponent
  displayName: 'Comment'

  render: -> 
    comment = @data()

    if comment.editing
      # Sharing keys, with some non-persisted client data getting saved...
      EditComment fresh: false, point: comment.point, key: comment.key

    else

      DIV className: 'comment_entry',

        # Comment author name
        DIV className: 'comment_entry_name',
          fetch(comment.user).name + ':'

        # Comment author icon
        Avatar
          key: comment.user
          hide_tooltip: true
          style: 
            position: 'absolute'
            width: 50
            height: 50

        # Comment body
        DIV className: 'comment_entry_body',
          splitParagraphs(comment.body)

        # Delete/edit button
        if permit('update comment', comment) > 0 && !@props.under_review
          comment_action_style = 
            color: '#444'
            textDecoration: 'underline'
            cursor: 'pointer',
            paddingRight: 10
          DIV style: { marginLeft: 60}, 
            SPAN
              'data-action' : 'delete-comment'
              style: comment_action_style
              onClick: do (key = comment.key) => (e) =>
                e.stopPropagation()
                if confirm('Delete this comment forever?')
                  destroy(key)
              'delete'

            SPAN
              style: comment_action_style
              onClick: do (key = comment.key) => (e) =>
                e.stopPropagation()
                comment.editing = true
                save comment
              'edit'          

# fact-checks, edit comments, comments...
styles += """
.comment_entry {
  margin-bottom: 45px;
  min-height: 60px;
  position: relative; }

.comment_entry_name {
  font-weight: bold;
  color: #666666; }

.comment_entry_body {
  margin-left: 60px;
  word-wrap: break-word;
  position: relative; }
  .comment_entry_body a {
    text-decoration: underline; }
  .comment_entry_body strong {
    font-weight: 600; }
  .comment_entry_body p {
    margin-bottom: 1em; }
"""

window.FactCheck = ReactiveComponent
  displayName: 'FactCheck'

  render : -> 
    assessment = @data()
    DIV className: 'comment_entry',

      # Comment author name
      DIV className: 'comment_entry_name',
        'Seattle Public Library Fact check:'

      # Comment author icon
      DIV className: 'magnifying_glass',
        I className: 'fa fa-search'

      # Comment body
      DIV className: 'comment_entry_body',
        DIV style: {margin: '10px 0 20px 0'},
          "A citizen requested research into the claims made by this point. "
          SPAN style: {fontSize: 12},
            A 
              style: {fontWeight: 700}
              href: '/about#fact_check'
              'Learn more'
            ' about the service.'

        for claim in assessment.claims
          claim = fetch(claim.key)
          verdict = fetch(claim.verdict)

          [DIV style: {margin: '10px 0'}, 
            IMG 
              style: {position: 'absolute', width: 25, left: -40}, 
              src: verdict.icon
            'Claim: '
            SPAN style: {fontWeight: 600}, claim.claim_restatement
          DIV null, 
            SPAN null,
              'Rating: '
              SPAN style: {fontStyle: 'italic'}, verdict.name
              SPAN 
                style: 
                  marginLeft: 20
                  fontSize: 12
                  textDecoration: 'underline'
                  cursor: 'help'
                title: verdict.desc
                'help'
          DIV 
            style: {margin: '10px 0'}
            dangerouslySetInnerHTML:{__html: claim.result}]

styles += """
.magnifying_glass {
  position: absolute;
  width: 50px;
  height: 50px;
  font-size: 50px;
  margin-top: -2px;
  color: #5e6b9e; }
"""


window.Discussion = ReactiveComponent
  displayName: 'Discussion'

  render : -> 

    point = fetch @props.point
    proposal = fetch point.proposal
    is_pro = point.is_pro

    your_opinion = fetch(proposal.your_opinion)
    point_included = _.contains(your_opinion.point_inclusions, point.key)
    in_wings = get_proposal_mode() == 'crafting' && !point_included

    comments = @discussion.comments
    if @discussion.assessment
      comments = comments.slice()
      comments.push @discussion.assessment
    
    comments.sort (a,b) -> a.created_at > b.created_at

    discussion_style =
      width: DECISION_BOARD_WIDTH()
      border: "3px solid #{focus_blue}"
      position: 'absolute'
      zIndex: 100
      padding: '20px 40px'
      borderRadius: 16
      backgroundColor: 'white'

    # Reconfigure discussion board position
    side = if is_pro then 'right' else 'left'
    if in_wings
      discussion_style[side] = POINT_CONTENT_WIDTH() + 10
      discussion_style['top'] = 44
    else
      discussion_style[side] = if is_pro then -23 else -30
      discussion_style['marginTop'] = 18

    # Reconfigure bubble mouth position
    mouth_style =
      position: 'absolute'

    if in_wings
      mouth_style[side] = -29

      trans_func = 'rotate(270deg)'
      if is_pro
        trans_func += ' scaleY(-1)'

      _.extend mouth_style, 
        transform: trans_func
        top: 19

    else
      _.extend mouth_style, 
        left: if is_pro then 335 else 100
        top: -28
        transform: if !is_pro then 'scaleX(-1)'

    DIV style: discussion_style, onClick: ((e) -> e.stopPropagation()),

      DIV 
        style: css.crossbrowserify mouth_style

        Bubblemouth 
          apex_xfrac: 1.1
          width: 36
          height: 28
          fill: 'white', 
          stroke: focus_blue, 
          stroke_width: 11

      H1
        style:
          textAlign: 'left'
          fontSize: 38
          color: focus_blue
          marginLeft: 60
          marginBottom: 25
          marginTop: 24
          fontWeight: 600
        'Discuss this Point'
      
      SubmitFactCheck()

      DIV className: 'comments',
        for comment in comments
          if comment.key.match /(comment)/
            Comment key: comment.key
          else 
            FactCheck key: comment.key

      # Write a new comment
      EditComment fresh: true, point: arest.key_id(@props.key)

  # HACK! Insert a placeholder to add enough height to accommodate the 
  # overlaid point. And if it is a point on the decision board,
  # also add the space to the decision board (so that scrolling
  # to bottom of discussion can occur)
  componentDidUpdate : -> @fixBodyHeight()
  componentDidMount : -> @fixBodyHeight()
  
  componentWillUnmount : -> 
    @clear_placeholder()

  clear_placeholder : -> 
    $body = $('.reasons_region')
    $body.find('.discussion_placeholder').remove()

  fixBodyHeight : -> 
    @clear_placeholder()

    $body = $('.reasons_region')
    height_of_discussion = $(@getDOMNode()).height()
    placeholder = "<div class='discussion_placeholder' style='height: " + \
                    height_of_discussion + "px'></div>"
    $body.append(placeholder)
    if $(@getDOMNode()).parents('.opinion_region').length > 0
      $('.decision_board_body').append placeholder
    



window.SubmitFactCheck = ReactiveComponent
  displayName: 'SubmitFactCheck'

  # States
  # - Blank
  # - Clicked request
  # - Contains request from you already
  # - Contains a verdict

  render: ->
    return SPAN(null) if !@proposal.assessment_enabled

    logged_in = fetch('/current_user').logged_in

    request_a_fact_check = =>
      [
        DIV null,
          'You can'
        DIV
          style:
            fontSize: 22
            fontWeight: 600
            textDecoration: 'underline'
            color: '#474747'
            marginTop: -4
            marginBottom: -1
            cursor: 'pointer'
          onClick: (=>
            if @local.state == 'blank slate'
              @local.state = 'clicked'
            else if @local.state == 'clicked'
              @local.state = 'blank slate'
            save(@local))
          'Request a Fact Check'
        DIV null,
          'from The Seattle Public Library'
      ]

    a_librarian_will_respond = (width) =>
      DIV style: {maxWidth: width},
        'A '
        A
          style: {textDecoration: 'underline'}
          href: '/about/#fact_check'
          'librarian will respond'
        ' to your request within 48 hours'

    request_a_factcheck = =>
      if permit('request factcheck', @proposal) > 0
        [
          DIV style: {marginTop: 12},
            'What factual claim do you want researched?'
          AutoGrowTextArea
            className: 'new_request'
            style:
              width: 390
              height: 60
              lineHeight: 1.4
              fontSize: 16
            placeholder: (logged_in and 'Your research question') or ''
            disabled: not logged_in
            onChange: (e) =>
              @local.research_question = e.target.value
              save(@local)
          Button
            style: {float: 'right'}
            onClick => (e) =>
              e.stopPropagation()
              request =
                key: '/new/request'
                suggestion: @local.research_question
                point: "/point/#{arest.key_id(@discussion.key)}"
              save(request)
              $(@getDOMNode()).find('.new_request').val('')
            'submit'

          a_librarian_will_respond(255)
        ]
      else
        DIV
          onClick: =>
            reset_key 'auth', {form: 'login', goal: 'Request a Fact Check'}
            save(auth)
          style:
            marginTop: 14
            textDecoration: 'underline'
            color: focus_blue
            cursor: 'pointer'
          'Log in to request a fact check'


    top_message_style = {maxWidth: 274, marginBottom: 10}
    request_in_progress = =>
      DIV null,
        DIV style: top_message_style,
          'You have requested a Fact Check from The Seattle Public Library'
        a_librarian_will_respond()
          
    request_completed = =>
      overall_verdict = fetch(@discussion.assessment.verdict)

      [
        DIV style: top_message_style,
          'This point has been Fact-Checked by The Seattle Public Library'
        DIV style: {marginBottom: 10},
          switch overall_verdict.id
            when 1
              "They found some claims inconsistent with reliable sources."
            when 2
              "They found some sources that agreed with claims and some that didn't."
            when 3
              "They found the claims to be consistent with reliable sources."
            when 4
              '''Unfortunately, the claims made are outside the research scope of 
              the fact-checking service.'''

        DIV style: {marginBottom: 10},
          A style: {textDecoration: 'underline'},
            ''
          "See the details"
          " of the librarians' research below."
      ]


    # Determine our current state
    @local.state = @local.state or 'blank slate'
    your_requests = (r for r in @discussion.requests or [] \
                     when r.user == fetch('/current_user').user)
    fact_check_completed = @discussion.claims?.length > 0
    if fact_check_completed
      @local.state = 'verdict'
    else if your_requests.length > 0
      @local.state = 'requested'


    show_request = @local.state != 'blank slate'
    
    request_style = if show_request then { marginBottom: 45, minHeight: 60 } else {}

    # Now let's draw
    DIV style: request_style,

      # Magnifying glass
      if show_request

        DIV className: 'magnifying_glass',
          I
            className: 'fa fa-search'

      # Text to the right
      DIV
        style:
          marginLeft: 60
        switch @local.state
          when 'blank slate'
            request_a_fact_check()
          when 'clicked'
            [request_a_fact_check()
            request_a_factcheck()]
          when 'requested'
            request_in_progress()
          when 'verdict'
            request_completed()
