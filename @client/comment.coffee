window.Comment = ReactiveComponent
  displayName: 'Comment'

  render: -> 
    comment = fetch @props.comment
    current_user = fetch '/current_user'

    if comment.editing
      # Sharing keys, with some non-persisted client data getting saved...
      EditComment 
        fresh: false
        point: comment.point
        key: comment.key
        proposal: fetch(comment.point).proposal

    else

      DIV 
        key: comment.key
        "data-id": comment.key
        className: 'comment_entry'

        # Comment author name
        DIV className: 'comment_entry_name',
          fetch(comment.user).name + ':'

        # Comment author icon
        Avatar
          key: comment.user
          hide_popover: true
          set_bg_color: true
          style: 
            position: 'absolute'
            width: 50
            height: 50

        # Comment body
        DIV className: 'comment_entry_body',
          splitParagraphs(comment.body)

        # Delete/edit button
        if current_user.user == comment.user
          if permit('update comment', comment) > 0
            comment_action_style = 
              color: '#444'
              textDecoration: 'underline'
              cursor: 'pointer',
              padding: '0 10px 0 0'
              backgroundColor: 'transparent'
              border: 'none'
            DIV style: { marginLeft: 60}, 
              BUTTON
                'data-action' : 'delete-comment'
                style: comment_action_style
                onClick: do (key = comment.key) => (e) =>
                  e.stopPropagation()
                  if confirm('Delete this comment forever?')
                    destroy(key)

                translator('engage.delete_button', 'delete')

              BUTTON
                style: comment_action_style
                onClick: do (key = comment.key) => (e) =>
                  e.stopPropagation()
                  comment.editing = true
                  save comment
                translator('engage.edit_button', 'edit')

# edit comments, comments...
styles += """
.comment_entry {
  margin-bottom: 25px;
  min-height: 60px;
  position: relative; }

.comment_entry_name {
  font-weight: 600;
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




window.Discussion = ReactiveComponent
  displayName: 'Discussion'

  render : -> 

    point = fetch @props.point
    proposal = fetch point.proposal
    is_pro = point.is_pro

    your_opinion = proposal.your_opinion
    if your_opinion.key 
      fetch your_opinion
    your_opinion.point_inclusions ?= []
    point_included = _.contains(your_opinion.point_inclusions, point.key)
    in_wings = get_proposal_mode() == 'crafting' && !point_included

    comments = fetch(@props.comments).comments
    
    comments.sort (a,b) -> a.created_at > b.created_at

    discussion_style =
      width: DECISION_BOARD_WIDTH() #+ POINT_WIDTH() / 2
      border: "3px solid #{focus_color()}"
      position: 'absolute'
      zIndex: 100
      padding: '20px 40px'
      borderRadius: 16
      backgroundColor: 'white'
      outline: 'none' #'1px dotted #ccc'
      boxShadow: if @local.has_focus then "0 0 7px #{focus_color()}"

    # Reconfigure discussion board position
    side = if is_pro then 'right' else 'left'
    if in_wings
      discussion_style[side] = POINT_WIDTH() + 13
      discussion_style['top'] = 20
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

    close_point = (e) ->
      loc = fetch('location')
      delete loc.query_params.selected
      save loc
      e.preventDefault()
      e.stopPropagation()

    HEADING = if @props.rendered_as != 'decision_board_point' then H4 else H5
    SECTION 
      id: 'open_point'
      style: discussion_style
      tabIndex: 0
      onClick: (e) -> e.stopPropagation()
      onTouchEnd: (e) -> e.stopPropagation()
      onKeyDown: (e) => 
        if e.which == 27 # ESC
          close_point e 
      onBlur: (e) => @local.has_focus = false; save @local 
      onFocus: (e) => @local.has_focus = true; save @local

      DIV 
        style: mouth_style

        Bubblemouth 
          apex_xfrac: 1.1
          width: 36
          height: 28
          fill: 'white', 
          stroke: focus_color(), 
          stroke_width: 11

      BUTTON
        'aria-label': 'close point' 
        onClick: close_point


        style: 
          position: 'absolute'
          right: 8
          top: 8
          fontSize: 24
          color: '#aaa'
          backgroundColor: 'transparent'
          border: 'none'
        'x'

      if point.text?.length > 0 
        SECTION 
          style: 
            marginBottom: 24
            marginTop: 10

          HEADING
            style:
              textAlign: 'left'
              fontSize: 24
              color: focus_color()
              fontWeight: 600
              marginBottom: 10
            #t('Author’s Explanation')
            translator 'engage.author_explanation', 'Author’s Explanation'

          DIV 
            className: 'point_details'
            splitParagraphs(point.text)
          

      if !customization('disable_comments')
        SECTION null,
          HEADING
            style:
              textAlign: 'left'
              fontSize: 24
              color: focus_color()
              marginBottom: 25
              marginTop: 10
              fontWeight: 600

            translator "engage.point_details_heading", 'Discuss this Point'

          DIV className: 'comments',
            for comment in comments
              Comment 
                key: comment.key
                comment: comment.key

          # Write a new comment
          EditComment 
            key: "fresh-comment-#{comments.length}"
            fresh: true
            point: arest.key_id(@props.comments)
            proposal: proposal.key

  # HACK! Save the height of the open point, which will be added 
  # to the min height of the reasons region to accommodate the
  # absolutely positioned element. 

  componentDidUpdate : -> 
    @setHeight()

  componentDidMount : -> 
    @setHeight()

  setHeight : -> 
    s = fetch('reasons_height_adjustment')

    el = ReactDOM.findDOMNode(@)

    dist_from_parent = $$.offset(el).top - $$.offset(document.querySelector('.reasons_region')).top
    open_point_height = $$.height(el) + dist_from_parent
    if s.open_point_height != open_point_height
      s.open_point_height = open_point_height
      save s



