## ########################
## Initialize defaults for client data

fetch 'decisionboard',
  docked : false
  


#######
# State stored in query params
# TODO: eliminate
window.get_proposal_mode = -> 
  loc = fetch('location')
  if loc.url == '/'
    return null
  else if loc.query_params?.results || TWO_COL()
    'results' 
  else 
    'crafting'

window.get_selected_point = -> 
  fetch('location').query_params.selected


window.updateProposalMode = (proposal_mode, triggered_by) ->
  loc = fetch('location')

  if proposal_mode == 'results' && loc.query_params.results ||
      proposal_mode == 'crafting' && !loc.query_params.results
    return

  if proposal_mode == 'results'
    loc.query_params.results = true
  else
    delete loc.query_params.results

  delete loc.query_params.selected

  save loc

  if proposal_mode == 'results' && $('.histogram').length > 0
    $('.histogram').ensureInView
      offset_buffer: -50

  window.writeToLog
    what: 'toggle proposal mode'
    details: 
      from: get_proposal_mode()
      to: proposal_mode
      triggered_by: triggered_by 
  


#####################
# These are some of the major components and their relationships 
# when viewing a proposal. 
#
# Open the state graph in a running application by pressing cntrl-G to 
# examine relationships with live code. 
#
#                         Root
#                          |
#                         Page 
#                          |
#                       Proposal
#                   /      |           \            \
#    CommunityPoints   DecisionBoard   Histogram   OpinionSlider
#               |          |
#               |      YourPoints
#               |    /            \
#              Point             EditPoint


##
# Proposal
# Has proposal description, feelings area (slider + histogram), and reasons area
window.Proposal = ReactiveComponent
  displayName: 'Proposal'

  render : ->
    doc = fetch('document')
    proposal = fetch @proposal
    page = fetch @page

    if doc.title != @proposal.name
      doc.title = @proposal.name
      save doc

    your_opinion = @proposal.your_opinion
    if your_opinion.key 
      fetch your_opinion
    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    return DIV(null) if !proposal.roles


    point_cols = ['your_con_points', 'your_pro_points', 'community_cons', 'community_pros']
    edit_mode = false
    for pc in point_cols
      col = fetch(pc)
      if col.adding_new_point || col.editing_points?.length > 0
        edit_mode = pc
        break

    local_proposal = fetch shared_local_key(@proposal)

    has_focus = \
      if get_selected_point()
        'point'
      else if edit_mode
        'edit point'
      else
        "opinion"

    if local_proposal.has_focus != has_focus
      local_proposal.has_focus = has_focus
      save local_proposal

    mode = get_proposal_mode()

    if your_opinion.published
      can_opine = permit 'update opinion', @proposal, your_opinion
    else
      can_opine = permit 'publish opinion', @proposal

    # change to results page if user entered crafting page when it is not permitted
    if mode == 'crafting' && 
        !(can_opine in [Permission.PERMITTED, Permission.UNVERIFIED_EMAIL, \
                        Permission.NOT_LOGGED_IN, Permission.INSUFFICIENT_INFORMATION] || 
         (can_opine == Permission.DISABLED && your_opinion.published))
      updateProposalMode('results', 'permission not granted for crafting')
    


    # A number of elements controlled by other components are absolutely 
    # positioned within the reasons region (e.g. discussions, decision
    # board, new point). We need to set a minheight that is large enough to 
    # encompass these elements. 
    adjustments = fetch('reasons_height_adjustment')
    minheight = 100 + (adjustments.opinion_region_height || 0)
    if get_selected_point()
      minheight += adjustments.open_point_height
    if adjustments.edit_point_height
      minheight += adjustments.edit_point_height

    # if there aren't community_points, then we won't bother showing them
    community_points = fetch("/page/#{@proposal.slug}").points or []
    if mode == 'crafting'
      included_points = (pnt for pnt in community_points when pnt.your_opinion.published)
      community_points = (pnt for pnt in community_points when !pnt.your_opinion.published)
    has_community_points = community_points.length > 0 


    if get_selected_point() && !@local.show_all_points
      @local.show_all_points = true 
      save @local
    

    opinion_views = fetch 'opinion_views'
    has_selection = opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected

    show_all_points = @local.show_all_points || mode == 'crafting' || community_points.length < 8 || has_selection

    is_loading = !page.proposal || !@proposal.name?

    just_you = opinion_views.active_views['just_you']

    draw_handle = can_opine != Permission.INSUFFICIENT_PRIVILEGES && 
                    (can_opine != Permission.DISABLED || your_opinion.published ) && 
                    !(!current_user.logged_in && '*' not in @proposal.roles.participant)

    ARTICLE 
      id: "proposal-#{@proposal.id}"
      "data-proposal": @proposal.key
      key: @props.slug
      style: 
        paddingBottom: if browser.is_mobile && has_focus == 'edit point' then 200
          # make room for add new point button

      DIV null,

        ProposalDescription()

        ParticipationStatus({can_opine})

        if (customization('opinion_callout')?[@proposal.cluster] or (customization('opinion_callout') && _.isFunction(customization('opinion_callout'))))
          (customization('opinion_callout')?[@proposal.cluster] or customization('opinion_callout'))()
        else 
          H1
            style: _.defaults {}, customization('list_title_style'),
              fontSize: 36
              fontWeight: 700
              textAlign: 'center'
              marginTop: 48

            if mode == 'crafting' || (just_you && current_user.logged_in)
              TRANSLATE
                id: "engage.opinion_header"
                'What do you think?'
            else 
              TRANSLATE
                  id: "engage.opinion_header_results"
                  'Opinions about this proposal'



        OpinionViews
          more_views_positioning: 'centered'
          style: 
            width: if get_participant_attributes().length > 0 then HOMEPAGE_WIDTH() else Math.max(660,PROPOSAL_HISTO_WIDTH()) # REASONS_REGION_WIDTH()
            margin: '8px auto 20px auto'
            position: 'relative'

        if mode != 'crafting'
          DIV 
            style: 
              width: PROPOSAL_HISTO_WIDTH()
              margin: 'auto'
              position: 'relative'

            DIV 
              style: 
                position: 'absolute'
                left: '100%'
                marginLeft: 30
                top: if fetch('histogram-dock').docked then 50 else 170

              HistogramScores
                proposal: @proposal

        if is_loading
          LOADING_INDICATOR

        if !is_loading
          DIV 
            style: 
              position: 'relative' 


            if mode == 'crafting' && can_opine in [Permission.NOT_LOGGED_IN, Permission.UNVERIFIED_EMAIL]
              DIV 
                style: 
                  width: '100%'
                  height: '100%'
                  position: 'absolute'
                  left: 0 
                  top: 0
                  zIndex: 99999
                  backgroundColor: 'rgba(255,255,255,.8)'
                DIV 
                  style: 
                    marginTop: 26
                  
                  AuthCallout()


            # feelings
            SECTION
              style:
                width: PROPOSAL_HISTO_WIDTH()
                margin: '0 auto'
                position: 'relative'
                zIndex: 1

              H2
                className: 'hidden'

                translator
                  id: "engage.opinion_spectrum_explanation"
                  negative_pole: get_slider_label("slider_pole_labels.oppose", @proposal)
                  positive_pole: get_slider_label("slider_pole_labels.support", @proposal)
                  proposal_name: @proposal.name
                  "Evaluations on spectrum from {negative_pole} to {positive_pole} of the proposal {proposal_name}"


              Histogram
                key: namespaced_key('histogram', @proposal)
                statement: @proposal
                opinions: opinions_for_statement(@proposal)
                width: PROPOSAL_HISTO_WIDTH()
                height: if fetch('histogram-dock').docked then 50 else 170
                enable_individual_selection: true
                enable_range_selection: true
                draw_base: if fetch('histogram-dock').docked then true else false
                backgrounded: mode == 'crafting'
                draw_base: true
                draw_base_labels: true
                base_style: "2px solid #{if mode == 'crafting' then focus_color() else '#414141'}"
                label_style: 
                  fontSize: 14
                  fontWeight: 300
                  color: 'black'
                  bottom: -28

                on_click_when_backgrounded: ->
                  updateProposalMode('results', 'click_histogram')

              Dock
                key: 'slider-dock'
                docked_key: namespaced_key('slider', @proposal)          
                dock_on_zoomed_screens: true
                constraints : ['decisionboard-dock', 'histogram-dock']
                skip_jut: mode == 'results'
                dockable : => 
                  mode == 'crafting' && can_opine > 0
                dummy: get_proposal_mode() == 'crafting'
                dummy2: PROPOSAL_HISTO_WIDTH()
                do =>   
                  OpinionSlider
                    key: namespaced_key('slider', @proposal)
                    width: PROPOSAL_HISTO_WIDTH() - 10
                    your_opinion: your_opinion
                    focused: mode == 'crafting'
                    backgrounded: false
                    permitted: draw_handle
                    pole_labels: [ \
                      get_slider_label("slider_pole_labels.oppose", @proposal),
                      get_slider_label("slider_pole_labels.support", @proposal)]
          

            DIV 
              style: 
                position: 'relative'
                top: -8
                overflowY: if !show_all_points then 'hidden'  
                overflowX: if !show_all_points then 'auto' 

              #reasons
              SECTION 
                className:'reasons_region'
                style : 
                  width: REASONS_REGION_WIDTH()    
                  minHeight: if show_all_points then minheight     
                  position: 'relative'
                  paddingBottom: '4em' #padding instead of margin for docking
                  margin: "#{if draw_handle && !TWO_COL() then '24px' else '0'} auto 0 auto"
                  display: if !customization('discussion_enabled', @proposal) then 'none'



                H2
                  className: 'hidden'

                  translator
                    id: "engage.reasons_section_explanation"
                    'Why people think what they do about the proposal'

                # Border + bubblemouth that is shown when there is a histogram selection
                GroupSelectionRegion()

                if !TWO_COL() && customization('discussion_enabled', @proposal)
                  Dock
                    key: 'decisionboard-dock'
                    docked_key: 'decisionboard'            
                    constraints : ['slider-dock']
                    dock_on_zoomed_screens: true
                    dockable : => 
                      mode == 'crafting' && can_opine > 0

                    start: -24

                    stop : -> 
                      $('.reasons_region').offset().top + $('.reasons_region').outerHeight() - 20

                    style: 
                      position: 'absolute'
                      width: DECISION_BOARD_WIDTH()
                      zIndex: 0 #so that points being dragged are above opinion region
                      display: 'inline-block'
                      verticalAlign: 'top'
                      left: '50%'
                      marginLeft: -DECISION_BOARD_WIDTH() / 2

                    DecisionBoard
                      key: 'decisionboard'

                DIV 
                  style: 
                    height: if !show_all_points then 500

                  PointsList 
                    key: 'community_cons'
                    rendered_as: 'community_point'
                    points_editable: TWO_COL()
                    valence: 'cons'
                    points_draggable: mode == 'crafting'
                    drop_target: false
                    points: buildPointsList \
                      @proposal, 'cons', \
                      (if mode == 'results' then 'score' else 'last_inclusion'), \ 
                      mode == 'crafting' && !TWO_COL(), \
                      mode == 'crafting' || TWO_COL() || (just_you && mode == 'results')
                    style: 
                      visibility: if !TWO_COL() && !has_community_points then 'hidden'


                  #community pros
                  PointsList 
                    key: 'community_pros'
                    rendered_as: 'community_point'
                    points_editable: TWO_COL()
                    valence: 'pros'
                    points_draggable: mode == 'crafting'
                    drop_target: false
                    points: buildPointsList \
                      @proposal, 'pros', \
                      (if mode == 'results' then 'score' else 'last_inclusion'), \ 
                      mode == 'crafting' && !TWO_COL(), \
                      mode == 'crafting' || TWO_COL() || (just_you && mode == 'results')
                    style: 
                      visibility: if !TWO_COL() && !has_community_points then 'hidden'

              if !show_all_points
                BUTTON 
                  style: 
                    backgroundColor: "#eee"
                    padding: '12px 0'
                    fontSize: 24
                    textAlign: 'center'
                    textDecoration: 'underline'
                    border: 'none'
                    #border: '1px solid rgba(0,0,0,.5)'                
                    cursor: 'pointer'
                    display: 'block'
                    width: POINT_WIDTH() * 2 + 18 * 2 + 100 * 2
                    margin: 'auto'
                    position: 'relative'
                    zIndex: 1

                  onClick: => 
                    @local.show_all_points = true 
                    save @local
                  onKeyPress: (e) => 
                    if e.which in [13,32]
                      @local.show_all_points = true 
                      save @local

                  TRANSLATE
                    id: "engage.show_all_thoughts"
                    "Show All Reasons"


      if mode == 'results'
        w = 600
        DIV   
          style: 
            margin: '70px auto 48px auto'
            width: w


          (customization('ProposalNavigation') or GroupedProposalNavigation) # or NextProposals)
            width: w
            proposal: @proposal


      if edit_mode && browser.is_mobile
        # full screen edit point mode for mobile
        valence = if edit_mode in ['community_pros', 'your_pro_points'] 
                    'pros' 
                  else 
                    'cons'
        pc = fetch edit_mode

        EditPoint 
          key: if pc.adding_new_point then "new_point_#{valence}" else pc.editing_points[0]
          fresh: pc.adding_new_point
          valence: valence
          your_points_key: edit_mode








##
# ProposalDescription
#
ProposalDescription = ReactiveComponent
  displayName: 'ProposalDescription'

  render : ->    
    current_user = fetch('/current_user')
    subdomain = fetch '/subdomain'

    @max_description_height = customization('collapse_proposal_description_at', @proposal)

    editor = proposal_editor(@proposal)


    title = @proposal.name 
    body = @proposal.description 

    title_style = _.defaults {}, customization('list_title_style'),
      fontSize: 36
      fontWeight: 700

    body_style = 
      paddingTop: '1em'
      position: 'relative'
      maxHeight: if @local.description_collapsed then @max_description_height
      overflow: if @local.description_collapsed then 'hidden'
      fontSize: 18

    wrapper_style = {}
    if @proposal.banner
      wrapper_style = 
        background: "url(#{@proposal.banner}) no-repeat center top fixed"
        backgroundSize: 'cover'
        paddingTop: 240
    else 
      wrapper_style = 
        paddingTop: 36


    anonymized = !customization('show_proposer_icon', "list/#{@proposal.cluster}") || customization('anonymize_everything')
    show_proposal_meta_data = customization('show_proposal_meta_data') && !customization('anonymize_everything')

    DIV 
      style: wrapper_style

      DIV           
        style: 
          width: HOMEPAGE_WIDTH()
          position: 'relative'
          margin: '0px auto 12px auto'
          fontSize: 18
          marginBottom: 18 

             

        BUBBLE_WRAP 
          user: if !@proposal.pic && !customization('anonymize_everything') then editor
          pic: if @proposal.pic then @proposal.pic
          width: HOMEPAGE_WIDTH()
          mouth_style: 
            width: 24
            display: if anonymized then 'none'
            bottom: 28
            top: 'auto'
            transform: 'rotate(-90deg)'
          bubble_style: 
            padding: '12px 24px'
            borderRadius: 42
          avatar_style: 
            display: if anonymized then 'none'
            width: 124
            height: 124
            left: -28 - 124
            bottom: -30 
            top: 'auto'
            boxShadow: if @proposal.pic then 'none'
          mouth_shadow:
            dx: -3


          
          DIV 
            style: 
              wordWrap: 'break-word'

            DIV 
              style: _.defaults {}, (title_style or {}),
                fontSize: POINT_FONT_SIZE()
                lineHeight: 1.2

              className: 'statement'

              title


            
            DIV 
              style: 
                marginTop: 4
                fontSize: 14
                color: "black"

              if @proposal.cluster 
                SPAN null, 
                  "##{@proposal.cluster or 'proposals'}"

                  if show_proposal_meta_data
                    SPAN 
                      style: 
                        padding: '0 8px'
                      '|'
              if show_proposal_meta_data
                TRANSLATE 
                  id: "engage.proposal_meta_data"
                  timestamp: prettyDate(@proposal.created_at)
                  author: fetch(editor)?.name
                  "submitted {timestamp} by {author}"

            if @proposal.under_review 
              DIV 
                style: 
                  color: 'white'
                  backgroundColor: 'orange'
                  fontSize: 14
                  padding: 2
                  marginTop: 8
                  display: 'inline-block'

                TRANSLATE 
                  id: 'engage.proposal_in_moderation_notice'
                  'Under review (like all new proposals)'


            DIV 
              className: 'wysiwyg_text'
              style:
                maxHeight: if @local.description_collapsed then @max_description_height
                overflowY: if @local.description_collapsed then 'hidden'

              if body 

                DIV 
                  className: "statement"

                  style: _.defaults {}, (body_style or {}),
                    wordWrap: 'break-word'
                    marginTop: '0.5em'
                    fontSize: POINT_FONT_SIZE()
                    #fontWeight: 300

                  if cust_desc = customization('proposal_description')
                    if typeof(cust_desc) == 'function'
                      cust_desc(@proposal)
                    else if cust_desc[@proposal.cluster] # is associative, indexed by list name


                      result = cust_desc[@proposal.cluster] {proposal: @proposal} # assumes ReactiveComponent. No good reason for the assumption.

                      if typeof(result) == 'function' && /^function \(props, children\)/.test(Function.prototype.toString.call(result))  
                                       # if this is a ReactiveComponent; this code is bad partially
                                       # because of customizations backwards compatibility. Hopefully 
                                       # cleanup after refactoring.
                        result = cust_desc[@proposal.cluster]() {proposal: @proposal}
                      else 
                        result

                    else 
                      DIV dangerouslySetInnerHTML:{__html: body}

                  else 
                    DIV dangerouslySetInnerHTML:{__html: body}


            if @local.description_collapsed
              BUTTON
                id: 'expand_full_text'
                style:
                  textDecoration: 'underline'
                  cursor: 'pointer'
                  padding: '24px 0 10px 0'
                  fontWeight: 600
                  textAlign: 'left'
                  border: 'none'
                  width: '100%'
                  backgroundColor: 'transparent'

                onMouseDown: => 
                  @local.description_collapsed = false
                  save(@local)

                onKeyDown: (e) =>
                  if e.which == 13 || e.which == 32 # ENTER or SPACE
                    @local.description_collapsed = false
                    e.preventDefault()
                    document.activeElement.blur()
                    save(@local)

                TRANSLATE 
                  id: 'engage.show_full_proposal_description'
                  'Expand full text'




        if permit('update proposal', @proposal) > 0
          DIV
            style: 
              marginTop: 5


            A 
              href: "#{@proposal.key}/edit"
              style:
                marginRight: 10
                color: '#999'
                backgroundColor: 'white'
                border: 'none'
                padding: 0
              TRANSLATE 'engage.edit_button', 'edit'

            if permit('delete proposal', @proposal) > 0
              BUTTON
                style:
                  marginRight: 10
                  color: '#999'
                  backgroundColor: 'white'
                  border: 'none'
                  padding: 0

                onClick: => 
                  if confirm('Delete this proposal forever?')
                    destroy(@proposal.key)
                    loadPage('/')
                TRANSLATE 'engage.delete_button', 'delete'



  componentDidMount : ->
    if (@proposal.description and @max_description_height and @local.description_collapsed == undefined \
        and $('.wysiwyg_text').height() > @max_description_height)
      @local.description_collapsed = true; save(@local)

  componentDidUpdate : ->
    if (@proposal.description and @max_description_height and @local.description_collapsed == undefined \
        and $('.wysiwyg_text').height() > @max_description_height)
      @local.description_collapsed = true; save(@local)

ParticipationStatus = ReactiveComponent
  displayName: 'ParticipationStatus'
  render: -> 
    can_opine = @props.can_opine

    return SPAN null if can_opine > 0 || can_opine == Permission.NOT_LOGGED_IN

    DIV 
      style: 
        textAlign: 'center'

      DIV
        style: 
          backgroundColor: attention_orange
          color: 'white'
          margin: 'auto'
          display: 'inline-block'
          padding: '4px 6px'
          fontWeight: 700

        if can_opine == Permission.DISABLED
          TRANSLATE
            id: 'engage.proposal_closed'
            'Closed to new contributions at this time.'

        else if can_opine == Permission.INSUFFICIENT_PRIVILEGES
          TRANSLATE
            id: 'engage.permissions.read_only'
            "Sorry, this proposal is read-only for you. The forum hosts specify who can participate."

        else if can_opine == Permission.UNVERIFIED_EMAIL
          A
            style:
              cursor: 'pointer'

            onTouchEnd: (e) => 
              e.stopPropagation()

            onClick: (e) =>
              e.stopPropagation()

              reset_key 'auth', 
                form: 'verify email'
                goal: 'To participate, please demonstrate you control this email.'
                
              current_user.trying_to = 'send_verification_token'
              save current_user

            translator 'engage.permissions.verify_account_to_participate', "Verify your account to participate"


##
# DecisionBoard
# Handles the user's list of important points in crafting page. 
DecisionBoard = ReactiveComponent
  displayName: 'DecisionBoard'

  render : ->
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')

    db = fetch('decision_board')
    
    your_opinion = @proposal.your_opinion
    if your_opinion.key
      fetch your_opinion

    if your_opinion.published
      can_opine = permit 'update opinion', @proposal, your_opinion
    else
      can_opine = permit 'publish opinion', @proposal

    opinion_views = fetch 'opinion_views'
    has_selection = opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected

    enable_opining = can_opine != Permission.INSUFFICIENT_PRIVILEGES && 
                      (can_opine != Permission.DISABLED || your_opinion.published ) && 
                      !has_selection &&
                      !(!current_user.logged_in && '*' not in @proposal.roles.participant)

    return DIV null if !enable_opining

    register_dependency = fetch(namespaced_key('slider', @proposal)).value 
                             # to keep bubble mouth in sync with slider

    # if there aren't points in the wings, then we won't bother showing 
    # the drop target
    points = fetch("/page/#{@proposal.slug}").points or [] 

    included_points = (pnt for pnt in points when pnt.your_opinion.published)
    wing_points = (pnt for pnt in points when !pnt.your_opinion.published)

    are_points_in_wings = wing_points.length > 0 
    
    decision_board_style =
      borderRadius: 16
      borderStyle: 'dashed'
      borderWidth: 3
      borderColor: focus_color()
      transition: if @last_proposal_mode != get_proposal_mode() || @transitioning  
                    "transform #{TRANSITION_SPEED}ms, " + \
                    "width #{TRANSITION_SPEED}ms, " + \
                    "min-height #{TRANSITION_SPEED}ms"
                  else
                    'none'

    if db.user_hovering_on_drop_target
      decision_board_style.borderStyle = 'solid'

    if get_proposal_mode() == 'results'
      give_opinion_button_width = 232
      slider = fetch namespaced_key('slider', @proposal)
      gutter = .1 * give_opinion_button_width

      opinion_slider_width = BODY_WIDTH() - 10
      stance_position = (slider.value + 1) / 2 * opinion_slider_width / BODY_WIDTH()
      opinion_region_x = -gutter + stance_position * \
                         (DECISION_BOARD_WIDTH() - \
                          give_opinion_button_width + \
                          2 * gutter)


      _.extend decision_board_style,
        borderStyle: 'solid'
        backgroundColor: focus_color()
        # borderBottom: '1px solid rgba(0,0,0,.6)'
        cursor: 'pointer'
        transform: "translate(#{opinion_region_x}px, -10px)"
        minHeight: 32
        width: give_opinion_button_width

    else 
      _.extend decision_board_style,
        transform: "translate(0, 10px)"
        minHeight: if are_points_in_wings then 275 else 170
        width: DECISION_BOARD_WIDTH()
        borderBottom: "#{decision_board_style.borderWidth}px dashed #{focus_color()}"
        backgroundColor: 'white'
        
    if get_proposal_mode() == 'results'
      give_opinion_style = 
        backgroundColor: focus_color()
        display: 'block'
        color: 'white'
        padding: '.25em 18px'
        margin: 0
        fontSize: 16
        width: '100%'
        borderRadius: 16
        boxShadow: 'none'
    else 
      give_opinion_style =
        visibility: 'hidden'



    SECTION 
      className:'opinion_region'
      style:
        width: DECISION_BOARD_WIDTH()

      H3 
        className: 'hidden'
        style: 
          display: if !TWO_COL() && get_proposal_mode() == 'results' then 'none'

        translator 
          id: "engage.opinion_crafting_explanation" 
          proposal_name: @proposal.name
          "Craft your opinion using pros and cons about {proposal_name}"

      SliderBubblemouth()

      DIV
        'aria-live': 'polite'
        key: 'body' 
        className:'decision_board_body'
        style: css.crossbrowserify decision_board_style
        onClick: => 
          if get_proposal_mode() == 'results' 

            if your_opinion.published
              can_opine = permit 'update opinion', @proposal, your_opinion
            else
              can_opine = permit 'publish opinion', @proposal

            if can_opine > 0
              updateProposalMode('crafting', 'give_opinion_button')
              $('.the_handle')[0].focus()
            else
              # trigger authentication
              reset_key 'auth',
                form: 'create account'
                goal: 'To participate, please introduce yourself.'
                after: =>
                  updateProposalMode('crafting', 'give_opinion_button')
                  $('.the_handle')[0].focus()




        DIV null, 

          if get_proposal_mode() == 'crafting'
            DIV 
              className: 'your_points'
              style: 
                padding: '0 18px'
                marginTop: -3 # To undo the 3 pixel border

              PointsList 
                key: 'your_pro_points'
                valence: 'pros'
                rendered_as: 'decision_board_point'
                points_editable: true
                points_draggable: true
                drop_target: are_points_in_wings
                points: (p for p in included_points \
                              when fetch(p).is_pro)

              PointsList 
                key: 'your_con_points'
                valence: 'cons'
                rendered_as: 'decision_board_point'
                points_editable: true
                points_draggable: true
                drop_target: are_points_in_wings
                points: (p for p in included_points \
                              when !fetch(p).is_pro)


              DIV style: {clear: 'both'}

          # only shown during results, but needs to be present always for animation
          BUTTON
            className: 'give_opinion_button btn'
            style: give_opinion_style

            # if !current_user.logged_in
            #   translator 
            #     id: "engage.log_in_to_give_your_opinion_button"
            #     'Log in to Give your Opinion'

            if your_opinion.published 
              translator 
                id: "engage.update_your_opinion_button"
                'Update your Opinion'
            else 
              translator 
                id: "engage.give_your_opinion_button"
                'Give your Opinion'


      DIV 
        key: 'footer'
        style:
          width: DECISION_BOARD_WIDTH()

        # Big bold button at the bottom of the crafting page
        BUTTON 
          className:'save_opinion_button btn'
          style:
            # display: 'none'
            backgroundColor: focus_color()
            width: '100%'
            marginTop: 14
            borderRadius: 16
            fontSize: 24
          onClick: => updateProposalMode('results', 'save_button') 
          onKeyDown: (e) => 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              updateProposalMode('results', 'save_button')  
              e.preventDefault()
          'aria-label': translator 'engage.update_opinion_button', 'Show the results'

          translator 'engage.update_opinion_button', 'Show the results'

        
        if !your_opinion.published || (your_opinion.key && permit('update opinion', @proposal, your_opinion) < 0)

          DIV 
            className: 'below_save'
            style: 
              display: 'none'
                      
            BUTTON 
              className:'cancel_opinion_button primary_cancel_button'
              onClick: => updateProposalMode('results', 'cancel_button')
              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  updateProposalMode('results', 'cancel_button')
                  e.preventDefault()

              

        if your_opinion.published && permit('update opinion', @proposal, your_opinion) > 0
          remove_opinion = -> 
            destroy your_opinion.key

          DIV 
            className: 'below_save'
                      
            BUTTON 
              style: 
                textDecoration: 'underline'
              className:'cancel_opinion_button primary_cancel_button'
              onClick: remove_opinion
              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  remove_opinion()
                  e.preventDefault()

              translator "engage.remove_my_opinion", 'Remove my opinion'



  componentDidUpdate : ->
    @transition()
    @makeDroppable()

  componentDidMount : ->
    @transition()
    @makeDroppable()

  makeDroppable: -> 
    db = fetch('decision_board')

    $el = $(@getDOMNode())

    return if $el.is('.ui-droppable')

    $el.droppable
      accept: ".point_content"
      drop : (ev, ui) =>
        if ui.draggable.parent().is('.community_point')
          your_opinion = @proposal.your_opinion
          your_opinion.key ?= "/new/opinion"
          your_opinion.published = true
          save your_opinion

          point_id = ui.draggable.parent().data('id')
          po =
            key: "/new/opinion"
            statement: point_id
            stance: 0.5
          save po

          window.writeToLog
            what: 'included point'
            details: 
              point: point_id

          db.user_hovering_on_drop_target = false
          save db

      out : (ev, ui) => 
        if ui.draggable.parent().is('.community_point')
          db.user_hovering_on_drop_target = false
          save db

      over : (ev, ui) => 
        if ui.draggable.parent().is('.community_point')
          db.user_hovering_on_drop_target = true
          save db

  update_reasons_height: -> 
    s = fetch('reasons_height_adjustment')
    s.opinion_region_height = $(@getDOMNode()).height()
    save s

  transition : -> 
    return if @is_waiting()

    speed = if !Modernizr.csstransitions || !@last_proposal_mode then 0 else TRANSITION_SPEED
    mode = get_proposal_mode()


    perform = (transitions) => 
      for own k,v of transitions
        $(@getDOMNode()).find(k).css(v)

    initial_state = 
      '.give_opinion_button':
        visibility: 'hidden'
      '.your_points, .save_opinion_button, .below_save': 
        display: 'none'

    final_state = JSON.parse JSON.stringify initial_state
    if mode == 'results'
      final_state['.give_opinion_button'].visibility = ''
    else
      final_state['.your_points, .save_opinion_button, .below_save'].display = ''

    

    if @last_proposal_mode != mode 

      if speed > 0      
        perform initial_state

        # wait for css transitions to complete
        @transitioning = true
        _.delay => 
          if @isMounted()
            perform final_state
            @transitioning = false

            @update_reasons_height()
        , speed + 200

      else if !@transitioning

        perform initial_state
        perform final_state

        @update_reasons_height()
            
      @last_proposal_mode = mode


SliderBubblemouth = ReactiveComponent
  displayName: 'SliderBubblemouth'

  render : -> 
    slider = fetch(namespaced_key('slider', @proposal))
    db = fetch('decision_board')

    w = 34
    h = 24
    stroke_width = 11

    if get_proposal_mode() == 'crafting'
      transform = "translate(0, -4px) scale(1,.7)"
      fill = 'white'
      if db.user_hovering_on_drop_target
        dash = "none"
      else
        dash = "25, 10"
    else 
      transform = "translate(0, -25px) scale(.5,.5) "
      fill = focus_color()
      dash = "none"

    DIV 
      key: 'slider_bubblemouth'
      style: css.crossbrowserify
        left: 10 + translateStanceToPixelX slider.value, DECISION_BOARD_WIDTH() - w - 20
        top: -h + 18 + 3 # +10 is because of the decision board translating down 18, 3 is for its border
        position: 'absolute'
        width: w
        height: h 
        zIndex: 10
        transition: "transform #{TRANSITION_SPEED}ms"
        transform: transform

      Bubblemouth 
        apex_xfrac: (slider.value + 1) / 2
        width: w
        height: h
        fill: fill
        stroke: focus_color()
        stroke_width: if get_proposal_mode() == 'crafting' then stroke_width else 0
        dash_array: dash

####
# GroupSelectionRegion
#
# Draws a border around the selected opinion(s)
# Shows a bubble mouth for selected opinions or 
# a user name + avatar display if we've selected
# an individual opinion.
GroupSelectionRegion = ReactiveComponent
  displayName: 'GroupSelectionRegion'

  render : -> 

    opinion_views = fetch 'opinion_views'
    single_opinion_selected = opinion_views.active_views.single_opinion_selected
    region_selected = opinion_views.active_views.region_selected
    has_histogram_focus = single_opinion_selected || region_selected
    return SPAN null if !has_histogram_focus

    wrapper_width = BODY_WIDTH() + 160

    # draw a bubble mouth
    w = 36; h = 24

    margin = wrapper_width - PROPOSAL_HISTO_WIDTH()
    stance = (region_selected or single_opinion_selected).opinion_value
    if region_selected
      left = translateStanceToPixelX(1 / 0.75 * stance, PROPOSAL_HISTO_WIDTH()) + margin / 2 - w / 2
    else 
      avatar_in_histo = document.querySelector("[data-opinion='#{single_opinion_selected.opinion}'")
      left = margin / 2 + avatar_in_histo.getBoundingClientRect().left - avatar_in_histo.parentElement.getBoundingClientRect().left

    DIV 
      style: 
        width: wrapper_width
        border: "3px solid #{if get_selected_point() then '#eee' else focus_color() }"
        height: '100%'
        position: 'absolute'
        borderRadius: 16
        marginLeft: -BODY_WIDTH()/2 - 80
        left: '50%'
        top: 4 #18


      DIV 
        style: cssTriangle 'top', \
                           (if get_selected_point() then '#eee' else focus_color()), \
                           w, h,               
                              position: 'relative'
                              top: -26
                              left: left

        DIV
          style: cssTriangle 'top', 'white', w - 1, h - 1,
            position: 'relative'
            left: -(w - 2)/2
            top: 6


      if single_opinion_selected
        # display a name for the selected opinion


        avatar_height = avatar_in_histo.offsetHeight

        name_style = 
          fontSize: 30
          fontWeight: 600

        user = fetch(fetch(single_opinion_selected.opinion).user)
        name = user.name or anonymous_label()
        title = "#{name}'#{if name[name.length - 1] != 's' then 's' else ''} Opinion"
        name_width = widthWhenRendered(title, name_style)
        DIV
          style: _.extend name_style,
            position: 'absolute'
            top: -(avatar_height + 172)
            color: focus_color()
            left: Math.min(wrapper_width - name_width - 10, Math.max(0, left - name_width / 2))
          title 
  


buildPointsList = (proposal, valence, sort_field, filter_included, show_all_points) ->
  sort_field = sort_field or 'score'
  points = fetch("/page/#{proposal.slug}").points or []
  opinions = fetch(proposal).opinions


  if !show_all_points
    filtered = true
    opinions = get_opinions_for_proposal opinions, proposal


  points = (pnt for pnt in points when pnt.is_pro == (valence == 'pros') )


  included_points = (pnt for pnt in points when pnt.your_opinion.published)

  if filter_included
    points = (pnt for pnt in points when !pnt.your_opinion.published)
  else 
    for pnt in included_points
      point = fetch pnt 
      continue if pnt.is_pro != (valence == 'pros')
      if points.indexOf(point) == -1
        points.push point 


  # Filter down to the points included in the selected opinions, if set. 
  opinion_views = fetch('opinion_views')
  if opinion_views.active_views.single_opinion_selected
    opinions = [opinion_views.active_views.single_opinion_selected.opinion] 
    filtered = true
  else if opinion_views.active_views.region_selected || (key for key,view of opinion_views.active_views when view.view_type == 'filter' && key != 'just_you').length > 0
    {weights, salience, groups} = compose_opinion_views opinions, proposal
    opinions = (o for o in opinions when salience[o.user.key or o.user] == 1)
    filtered = true

  # order points by resonance to users in view.    
  opinions_per_point = {} # map of points to including users
  for point in points
    opinions_per_point[point.key] ?= 0
    for o in point.opinions or []
      opinions_per_point[point.key] += o.stance

  # try enforce k=2-anonymity for hidden points
  # if opinions.length < 2
  #   for point,inclusions of point_inclusions_per_point
  #     if fetch(point).hide_name
  #       delete point_inclusions_per_point[point]

  points = (pnt for pnt in points when (pnt.key of opinions_per_point) || (TWO_COL() && pnt.key in included_points))

  # Sort points based on resonance with selected users, or custom sort_field
  sort = (pnt) ->
    if filtered
      -opinions_per_point[pnt.key] 
    else
      -pnt[sort_field]


  points = _.sortBy points, sort

  (pnt.key for pnt in points)


PointsList = ReactiveComponent
  displayName: 'PointsList'

  render: -> 
    points = (fetch(pnt) for pnt in @props.points)

    mode = get_proposal_mode()

    your_points = @data()



    if @props.points_editable && !your_points.editing_points
      _.extend your_points,
        editing_points : []
        adding_new_point : false
      save your_points

    if @props.rendered_as == 'community_point'
      header_prefix = if mode == 'results' then 'top' else "other"
      header_style = 
        width: POINT_WIDTH()
        fontSize: 30       
        fontWeight: 400 
        position: 'relative'
        left: if @props.valence == 'cons' then -20 else 20
          # Mike: I wanted the headers to be centered over the ENTIRE
          # points including avatars, not just bubbles.  But the
          # avatars are sticking out on their own, so I simulated
          # a centered look with these -20px and +20px offsets
      wrapper = @drawCommunityPoints
    else
      header_prefix = 'your' 
      header_style = 
        width: POINT_WIDTH()
        fontWeight: 700
        color: focus_color()
        fontSize: 30
      wrapper = @drawYourPoints


    get_heading = (valence) => 
      point_labels = customization("point_labels", @proposal)


      heading = point_labels["#{header_prefix}_header"]


      plural_point = get_point_label valence, @proposal

      heading_t = translator
                    id: "point_labels.header_#{header_prefix}.#{heading}"
                    key: if point_labels.translate then "/translations" else "/translations/#{fetch('/subdomain').name}"
                    arguments: capitalize(plural_point)
                    heading

      heading_t

    heading = get_heading(@props.valence)
    other_heading = get_heading(if @props.valence == 'pros' then 'cons' else 'pros')
    # Calculate the other header height so that if they break differently,
    # at least they'll have same height
    header_height = Math.max heightWhenRendered(heading,       header_style), \
                             heightWhenRendered(other_heading, header_style)

    HEADING = if @props.rendered_as == 'community_point' then H3 else H4 


    wrapper [


      HEADING 
        ref: 'point_list_heading'
        id: @local.key.replace('/','-')
        className: 'points_heading_label'
        style: _.extend header_style,
          textAlign: 'center'
          marginBottom: 18
          marginTop: 7
          height: header_height
        heading 

      UL 
        'aria-labelledby': @local.key.replace('/','-')
        if points.length > 0 || @props.rendered_as == 'decision_board_point'
          for point in points
            if @props.points_editable && \
               point.key in your_points.editing_points && \
               !browser.is_mobile
              EditPoint 
                key: point.key
                fresh: false
                valence: @props.valence
                your_points_key: @props.key
            else
              Point
                key: point.key
                rendered_as: @props.rendered_as
                your_points_key: @props.key
                enable_dragging: @props.points_draggable


      if @props.drop_target && permit('create point', @proposal) > 0
        @drawDropTarget()

      if @props.points_editable && permit('create point', @proposal) > 0 
        @drawAddNewPoint()
      ] 


  columnStandsOut: -> 
    your_points = @data()

    contains_selection = get_selected_point() && \
                         fetch(get_selected_point()).is_pro == (@props.valence == 'pros')
    is_editing = @props.points_editable && \
                 (your_points.editing_points.length > 0 || your_points.adding_new_point)

    contains_selection || is_editing


  drawCommunityPoints: (children) -> 
    x_pos = if @props.points_draggable
              if @props.valence == 'cons' then 0 else DECISION_BOARD_WIDTH()
            else if !TWO_COL()
              DECISION_BOARD_WIDTH() / 2
            else
              0

    # TODO: The minheight below is not a principled or complete solution to two
    #       sizing issues: 
    #           1) resizing the reasons region when the height of the decision board 
    #              (which is absolutely positioned) grows taller the wing points
    #           2) when filtering the points on result page to a group of opinions 
    #              with few inclusions, the document height can jarringly fluctuate
    SECTION
      className: "point_list points_by_community #{@props.valence}_by_community"
      style: css.crossbrowserify _.defaults (@props.style or {}),
        display: 'inline-block'
        verticalAlign: 'top'
        width: POINT_WIDTH()
        minHeight: (if @page.points.length > 4 && get_proposal_mode() == 'crafting' then jQuery(window).height() else 100)
        zIndex: if @columnStandsOut() then 6 else 1
        margin: '38px 18px 0 18px'
        position: 'relative'

        transition: "transform #{TRANSITION_SPEED}ms"
        transform: "translate(#{x_pos}px, 0)"
      if get_proposal_mode() == 'crafting' && !TWO_COL()

        [A
          className: 'hidden'
          href: "##{@props.valence}_on_decision_board"
          'data-nojax': true
          onClick: (e) => 
            e.stopPropagation()
            document.activeElement?.blur()
            $("[name='#{@props.valence}_on_decision_board']").focus()

          "Skip to Your points."
        A name: "#{@props.valence}_by_community"]

      children


  drawYourPoints: (children) -> 
      
    SECTION 
      className: "point_list points_on_decision_board #{@props.valence}_on_decision_board"
      style: _.defaults (@props.style or {}),
        display: 'inline-block'
        verticalAlign: 'top'        
        width: POINT_WIDTH()
        marginTop: 28
        position: 'relative'
        zIndex: if @columnStandsOut() then 6 else 1        
        float: if @props.valence == 'pros' then 'right' else 'left'    
      A name: "#{@props.valence}_on_decision_board"
      children

  drawAddNewPoint: -> 
    
    your_points = @data()
    can_add_new_point = permit 'create point', @proposal

    opinion_views = fetch 'opinion_views'
    hist_selection = opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected


    if can_add_new_point != Permission.INSUFFICIENT_PRIVILEGES && !hist_selection
      if !your_points.adding_new_point
        DIV null,

          DIV 
            onClick: => 
              if can_add_new_point == Permission.NOT_LOGGED_IN
                reset_key 'auth', 
                  form: 'create account'
                  goal: 'To access this forum, please introduce yourself below.'

              else if can_add_new_point == Permission.UNVERIFIED_EMAIL
                reset_key 'auth', 
                  form: 'verify email'
                  goal: 'To participate, please demonstrate you control this email.'

                save auth
                current_user.trying_to = 'send_verification_token'
                save current_user

              else
                your_points.adding_new_point = true
                save your_points

              writeToLog {what: 'click new point'}

            if @props.rendered_as == 'decision_board_point'
              @drawAddNewPointInDecisionBoard()
            else 
              @drawAddNewPointInCommunityCol()

          if @props.rendered_as == 'decision_board_point'

            if @props.valence == 'pros' 
              noun = get_point_label 'pro', @proposal 
            else 
              noun = get_point_label 'con', @proposal 

            noun = capitalize noun   

            A
              className: 'hidden'
              href: "##{@props.valence}_by_community"
              'data-nojax': true
              onClick: (e) => 
                e.stopPropagation()
                document.activeElement?.blur()
                $("[name='#{@props.valence}_by_community']").focus()

              "Skip to #{noun} points by others to vote on important ones."

      else if !browser.is_mobile
        EditPoint
          key: "new_point_#{@props.valence}"
          fresh: true
          valence: @props.valence
          your_points_key: @props.key

  drawAddNewPointInCommunityCol: ->
    if @props.valence == 'pros' 
      point_label = get_point_label 'pro', @proposal 
    else 
      point_label = get_point_label 'con', @proposal 

    button_text = translator 
                    id: "engage.add_a_point"
                    pro_or_con: point_label 
                    "Add a new {pro_or_con}"

    DIV 
      id: "add-point-#{@props.valence}"
      style: 
        cursor: 'pointer'
        marginTop: 20


      @drawGhostedPoint
        width: POINT_WIDTH()
        text: button_text
        is_left: @props.valence == 'cons'
        style: {}
        text_style:
          #color: focus_color()
          textDecoration: 'underline'
          fontSize: if browser.is_mobile then 24



  drawAddNewPointInDecisionBoard: -> 
    your_points = @data()

    if @props.valence == 'pros' 
      point_label = get_point_label 'pro', @proposal 
    else 
      point_label = get_point_label 'con', @proposal 


    DIV 
      style: 
        padding: '.25em 0'
        marginTop: '1em'
        marginLeft: if @props.drop_target then 20 else 9
        fontSize: POINT_FONT_SIZE()

      if @props.drop_target
        SPAN 
          'aria-hidden': true
          style: 
            fontWeight: if browser.high_density_display then 300 else 400
          "#{t('or')} "
      # SPAN
      #   'aria-hidden': true
      #   style: 
      #     padding: if @props.drop_target then '0 6px' else '0 11px 0 0'

      #   dangerouslySetInnerHTML:{__html: '&bull;'}

      BUTTON 
        className: "write_#{@props.valence} btn"
        style: 
          marginLeft: 8
          backgroundColor: focus_color()

        TRANSLATE 
          id: "engage.add_a_point"
          pro_or_con: point_label 
          "Add a new {pro_or_con}" 

  drawDropTarget: -> 
    left_or_right = if @props.valence == 'pros' then 'right' else 'left'

    if @props.valence == 'pros' 
      point_label = get_point_label 'pro', @proposal 
    else 
      point_label = get_point_label 'con', @proposal 

    drop_target_text = TRANSLATE 
                         id: "engage.drag_point.#{left_or_right}"
                         pro_or_con: point_label 
                         left_or_right: left_or_right
                         "Drag a {pro_or_con} from the #{left_or_right}"


    dt_w = POINT_WIDTH() - 24
    local_proposal = fetch shared_local_key(@proposal)

    DIV 
      'aria-hidden': true
      style: 
        marginLeft: if @props.valence == 'cons' then 24 else 0
        marginRight: if @props.valence == 'pros' then 24 else 0
        position: 'relative'
        left: if @props.valence == 'cons' then -18 else 18

      @drawGhostedPoint
        width: POINT_WIDTH() - 24
        text: drop_target_text
        is_left: @props.valence == 'cons'
        style: 
          #padding: "0 #{if @props.valence == 'pros' then '24px' else '0px'} .25em #{if @props.valence == 'cons' then '24px' else '0px'}"        
          opacity: if local_proposal.has_focus == 'edit point' then .1
        text_style: {}


  drawGhostedPoint: (props) ->     
    text_style = props.text_style or {}
    style = props.style or {}
    width = props.width
    text = props.text
    is_left = props.is_left

    w = width
    padding_x = 18
    padding_y = 12
    text_height = heightWhenRendered(text, {'font-size': POINT_FONT_SIZE(), 'width': w - 2 * padding_x})
    stroke_width = 1
    h = Math.max text_height + 2 * padding_y, 85
    s_w = 8
    s_h = 6

    mouth_style = 
      top: 8
      position: 'absolute'
    
    if is_left
      mouth_style['transform'] = 'rotate(270deg) scaleX(-1)'
      mouth_style['left'] = -POINT_MOUTH_WIDTH + stroke_width + 1
    else 
      mouth_style['transform'] = 'rotate(90deg)'
      mouth_style['right'] = -POINT_MOUTH_WIDTH  + stroke_width + 1

    local_proposal = fetch shared_local_key(@proposal)

    DIV
      style: _.defaults style, 
        position: 'relative'
        opacity: if local_proposal.has_focus == 'edit point' then .1

      SVG 
        width: w
        height: h
        

        DEFS null,
          PATTERN 
            id: "drop-stripes-#{is_left}-#{width}"
            width: s_w
            height: s_h 
            patternUnits: "userSpaceOnUse"

            RECT 
              width: '100%'
              height: '100%'
              fill: 'white'

            do => 
              if is_left
                cross_hatch = [ 
                  [-s_w/2,    0, s_w,   1.5 * s_h], 
                  [0,    -s_h/2,   1.5 * s_w, s_h]]
              else 
                cross_hatch = [ 
                  [1.5 * s_w,    0, 0,   1.5 * s_h], 
                  [s_w,    -s_h/2,   -s_w/2, s_h]]                  

              for [x1, y1, x2, y2], idx in cross_hatch

                LINE 
                  x1: x1
                  y1: y1
                  x2: x2 
                  y2: y2 
                  stroke: focus_color()
                  strokeWidth: 1
                  strokeOpacity: .2

        RECT
          width: w - 2 * stroke_width
          height: h - 2 * stroke_width
          x: stroke_width
          y: stroke_width
          rx: 16
          ry: 16
          fill: "url(#drop-stripes-#{is_left}-#{width})"
          stroke: focus_color()
          strokeWidth: stroke_width
          strokeDasharray: '4, 3'

      SPAN 
        style: _.defaults {}, text_style, 
          fontSize: POINT_FONT_SIZE()
          position: 'absolute'
          top: padding_y
          left: padding_x #+ if is_left then 24 else 0
          width: w - 2 * padding_x
          # padding: """0 
          #             #{if @props.valence == 'cons' then 18 else 18+24}px 
          #             0 
          #             #{if @props.valence == 'pros' then 18 else 18+24}px"""
          
        text



      Bubblemouth 
        apex_xfrac: 0
        width: POINT_MOUTH_WIDTH
        height: POINT_MOUTH_WIDTH
        fill: '#F9FBFD'  #TODO: somehow make this focus_color() color mixed with white @ .2 opacity
        stroke: focus_color()
        stroke_width: 6
        dash_array: '24, 18'
        style: css.crossbrowserify mouth_style
