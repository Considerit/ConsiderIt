#////////////////////////////////////////////////////////////
# Core considerit client code
#////////////////////////////////////////////////////////////



require './element_viewport_positioning'

require './vendor/jquery.ui'  # for the drag+drop
require './vendor/jquery.XDomainRequest' #do we need this?
require './vendor/jquery.form'
require './vendor/jquery.touchpunch'

require './vendor/modernizr' 
require './activerest-m'
require './dock'
require './admin' # for dashes
require './auth'
require './avatar'
require './browser_hacks'
require './react_component_overrides'
require './browser_location'
require './bubblemouth'
require './edit_proposal'
require './customizations'
require './form'
require './histogram'
require './roles'
require './filter'
require './tags'
require './homepage'
require './shared'
require './opinion_slider'
require './state_dash'
require './state_graph'
require './tooltip'
require './development'
require './god'
require './notifications'
require './edit_point'
require './edit_comment'
require './point'
require './translations'
require './proposal_navigation'


## ########################
## Initialize defaults for client data

fetch 'decisionboard',
  docked : false
  
fetch 'root',
  opinions_to_publish : []


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
Proposal = ReactiveComponent
  displayName: 'Proposal'

  render : ->

    doc = fetch('document')
    if doc.title != @proposal.name
      doc.title = @proposal.name
      save doc

    your_opinion = fetch @proposal.your_opinion
    current_user = fetch('/current_user')
    subdomain = fetch '/subdomain'


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
    
    proposal_header = DefaultProposalNavigation()

    draw_handle = (can_opine not in [Permission.DISABLED, \
                          Permission.INSUFFICIENT_PRIVILEGES]) || \
                          your_opinion.published


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
      included_points = fetch(@proposal.your_opinion).point_inclusions
      community_points = (pnt for pnt in community_points when !_.contains(included_points, pnt.key) )
    has_community_points = community_points.length > 0 


    DIV 
      id: "proposal-#{@proposal.id}"
      key: @props.slug
      role: 'main'
      style: 
        paddingBottom: if browser.is_mobile && has_focus == 'edit point' then 200
          # make room for add new point button

      DIV 
        className: 'proposal_header'

        proposal_header

      DIV null,

        ProposalDescription()

        if customization('opinion_filters')
          OpinionFilter
            style: 
              width: BODY_WIDTH()
              margin: '40px auto 20px auto'
              textAlign: 'center'


        #feelings
        DIV
          style:
            width: PROPOSAL_HISTO_WIDTH()
            margin: '0 auto'
            position: 'relative'
            zIndex: 1


          Histogram
            key: namespaced_key('histogram', @proposal)
            proposal: @proposal
            opinions: opinionsForProposal(@proposal)
            width: PROPOSAL_HISTO_WIDTH()
            height: if fetch('histogram-dock').docked then 50 else 170
            enable_selection: true
            draw_base: if fetch('histogram-dock').docked then true else false
            backgrounded: mode == 'crafting'
            on_click_when_backgrounded: ->
              updateProposalMode('results', 'click_histogram')

          Dock
            key: 'slider-dock'
            docked_key: namespaced_key('slider', @proposal)          
            dock_on_zoomed_screens: true
            constraints : ['decisionboard-dock', 'histogram-dock']
            skip_jut: mode == 'results'
            dockable : => 
              mode == 'crafting'
            dummy: get_proposal_mode() == 'crafting'
            dummy2: PROPOSAL_HISTO_WIDTH()
            do =>   
              OpinionSlider
                key: namespaced_key('slider', @proposal)
                width: PROPOSAL_HISTO_WIDTH() - 10
                your_opinion: @proposal.your_opinion
                focused: mode == 'crafting'
                backgrounded: false
                permitted: draw_handle
                pole_labels: [ \
                  [customization("slider_pole_labels.oppose", @proposal),
                   customization("slider_pole_labels.oppose_sub", @proposal) or ''], \
                  [customization("slider_pole_labels.support", @proposal),
                   customization("slider_pole_labels.support_sub", @proposal) or '']]


        #reasons
        DIV 
          className:'reasons_region'
          style : 
            width: REASONS_REGION_WIDTH()    
            minHeight: minheight        
            position: 'relative'
            paddingBottom: '4em' #padding instead of margin for docking
            margin: "#{if draw_handle && !TWO_COL() then '24px' else '0'} auto 0 auto"
            display: if !customization('discussion_enabled', @proposal) then 'none'

          # Border + bubblemouth that is shown when there is a histogram selection
          GroupSelectionRegion()


          if !TWO_COL() && customization('discussion_enabled', @proposal)
            Dock
              key: 'decisionboard-dock'
              docked_key: 'decisionboard'            
              constraints : ['slider-dock']
              dock_on_zoomed_screens: true
              dockable : => 
                mode == 'crafting'

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
              mode == 'crafting'
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
              mode == 'crafting'
            style: 
              visibility: if !TWO_COL() && !has_community_points then 'hidden'



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

    # Description fields are the expandable details that help people drill
    # into the proposal. They are very specific to the type of proposal (e.g. for
    # an LVG ballot measure, one of the fields might be "fiscal impact statement").  
    # We're now storing all these fields in proposal.description_fields
    # as a serialized JSON object of one of the following structures:
    #   [ {"label": "field one", "html": "<p>some details</p>"}, ... ] 
    #   [ {"group": "group name", 
    #      "items": [ {"label": "field one", "html": "<p>some details</p>"}, ... ]}, 
    #   ...]

    if !@local.description_fields
      # Deserialize the description fields. 
      # TODO: Do this on the server.
      # This will fail for proposals that are not using the serialized JSON format; 
      # For now, we'll just catch the error and carry on 
      try 
        @local.description_fields = $.parseJSON(@proposal.description_fields)
        @local.expanded_field = null
      catch
        @local.description_fields = null

    @max_description_height = customization('collapse_proposal_description_at', @proposal)

    DIV           
      style: 
        width: HOMEPAGE_WIDTH()
        position: 'relative'
        margin: 'auto'
        fontSize: 18
        marginBottom: 18


      # Proposal name
      DIV
        id: 'proposal_name'
        style:
          lineHeight: 1.2
          paddingBottom: 15

        H1
          style: 
            fontWeight: 700
            fontSize: 45
          @proposal.name

        if customization('show_proposal_meta_data')
          DIV 
            style: 
              fontSize: 16
              color: "#888"
              fontStyle: 'italic'
              paddingTop: 18

            prettyDate(@proposal.created_at)

            if (editor = proposal_editor(@proposal)) && editor == @proposal.user
              SPAN 
                style: {}

                " by #{fetch(editor)?.name}"

      if !@proposal.active
        SPAN 
          style: 
            display: 'inline-block'
            color: 'rgb(250, 146, 45)'
            padding: '4px 0px'
            marginTop: 10
          I className: 'fa fa-info-circle', style: {paddingRight: 7}
          'Closed to new contributions at this time.'

      # TODO: now that we're accepting user contributed proposals, we need 
      # to SANITIZE the description
      DIV
        className: 'proposal_details'
        style:
          paddingTop: '1em'
          position: 'relative'
          maxHeight: if @local.description_collapsed then @max_description_height
          overflow: if @local.description_collapsed then 'hidden'
        if @local.description_collapsed
          BUTTON
            style:
              backgroundColor: '#f9f9f9'
              width: HOMEPAGE_WIDTH()
              position: 'absolute'
              bottom: 0
              textDecoration: 'underline'
              cursor: 'pointer'
              paddingTop: 10
              paddingBottom: 10
              fontWeight: 600
              textAlign: 'center'
              border: 'none'

            onMouseDown: => 
              @local.description_collapsed = false
              save(@local)

            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                @local.description_collapsed = false
                e.preventDefault()
                document.activeElement.blur()
                save(@local)

            'Expand full text'
        DIV dangerouslySetInnerHTML:{__html: @proposal.description}


      if @local.description_fields
        DIV 
          id: 'description_fields'
          style: 
            marginTop: '1em'
          for item in @local.description_fields
            if item.group
              @renderDescriptionFieldGroup item
            else
              @renderDescriptionField item

      DIV 
        style:
          marginTop: 15
          color: '#666'

      if permit('update proposal', @proposal) > 0
        DIV
          style: 
            marginTop: 5

          A 
            href: "#{@proposal.key}/edit"
            style:
              marginRight: 10
              color: '#999'
              backgroundColor: 'transparent'
              border: 'none'
              padding: 0
            t('edit')

          BUTTON 
            style: 
              marginRight: 10
              color: '#999'              
              backgroundColor: if @local.edit_roles then '#fafafa' else 'transparent'
              border: 'none'
              padding: 0
            onClick: => 
              @local.edit_roles = !@local.edit_roles
              save @local
            t('share')

          if permit('delete proposal', @proposal) > 0
            BUTTON
              style:
                marginRight: 10
                color: '#999'
                backgroundColor: 'transparent'
                border: 'none'
                padding: 0

              onClick: => 
                if confirm('Delete this proposal forever?')
                  destroy(@proposal.key)
                  loadPage('/')
              t('delete')

          # if current_user.is_super_admin
          #   SPAN 
          #     style:
          #       marginRight: 10
          #       color: '#999'

          #     onClick: => 
          #       @local.copy_to_subdomain = !@local.copy_to_subdomain
          #       save @local

          #     A null,
          #       'Copy to subdomain'

          #     if @local.copy_to_subdomain
          #       subdomains = fetch('/subdomains').subs
          #       hues = getNiceRandomHues subdomains?.length
                
          #       UL 
          #         style: {}
          #         for sub, idx in subdomains
          #           LI
          #             style: 
          #               display: 'inline-block'
          #               listStyle: 'none'
          #             A
          #               href: "/proposal/#{@proposal.id}/copy_to/#{sub.id}"
          #               'data-nojax': false
          #               style: 
          #                 padding: "4px 8px"
          #                 fontSize: 18
          #                 backgroundColor: hsv2rgb(hues[idx], .7, .5)
          #                 color: 'white'
          #                 display: 'inline-block'            
          #               sub.name        

      if @local.edit_roles
        DIV 
          style:
            width: HOMEPAGE_WIDTH()
            margin: 'auto'
            backgroundColor: '#fafafa'
            padding: '10px 60px'

          ProposalRoles 
            key: @proposal.key




  componentDidMount : ->
    if (@proposal.description and @max_description_height and @local.description_collapsed == undefined \
        and $('.proposal_details').height() > @max_description_height)
      @local.description_collapsed = true; save(@local)

  componentDidUpdate : ->
    if (@proposal.description and @max_description_height and @local.description_collapsed == undefined \
        and $('.proposal_details').height() > @max_description_height)
      @local.description_collapsed = true; save(@local)


    subdomain = fetch('/subdomain')
    if subdomain.name == 'RANDOM2015' && @local.description_fields && $('#description_fields').find('.MathJax').length == 0
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,"description_fields"])

  renderDescriptionField : (field) ->
    symbol = if field.expanded then 'fa-chevron-down' else 'fa-chevron-right'
    DIV 
      className: 'description_field'
      key: field.label
      style: {padding: '.25em 0'}

      DIV 
        style: {cursor: 'pointer'}
        onClick: => 
          field.expanded = !field.expanded
          save(@local)
          if field.expanded 
            window.writeToLog
              what: 'expand proposal description'
              details: 
                description_type: field.label        
        SPAN 
          className: "fa #{symbol}"
          style: 
            opacity: .7
            position: 'relative'
            left: -3
            paddingRight: 6
            display: 'inline-block'
            width: 20

        SPAN 
          style: {lineHeight: 1.6, fontSize: 18}
          field.label

      if field.expanded
        DIV 
          style: 
            padding: '10px 0'
            overflow: 'hidden'
          dangerouslySetInnerHTML:{__html: field.html}

  renderDescriptionFieldGroup : (group) -> 
    DIV 
      className: 'description_group'
      key: group.group,
      style: 
        position: 'relative'
        marginBottom: 10
        borderLeft: '1px solid #e1e1e1'
        paddingLeft: 20
        left: -20

      DIV 
        style: 
          position: 'absolute'
          width: 200
          left: -217
          textAlign: 'right'
          top: 4
          fontWeight: if browser.high_density_display then 300 else 400

        LABEL null, group.group
      for field in group.items
        @renderDescriptionField field


# TODO: Refactor the below and make sure that the styles applied to the 
#       user generated fields are in sync with the styling in the 
#       wysiwyg editor. 
styles += """
.proposal_details code, .proposal_details pre {
  font-family: "Courier New",Courier,"Lucida Sans Typewriter","Lucida Typewriter",monospace;
},.proposal_details br, .description_field br {
  padding-bottom: 0.5em; }
.proposal_details p, 
.proposal_details ul, 
.description_field ul, 
.proposal_details ol, 
.description_field ol, 
.proposal_details table, 
.description_field p, 
.description_field table {
  margin-bottom: 0.5em; }
.proposal_details td, .description_field td {
  padding: 0 3px; }
.proposal_details li, .description_field li {
  list-style: outside; }
.proposal_details ol li, .proposal_details ol li {
  list-style-type: decimal; }  
.proposal_details ul, .description_field ul,
.proposal_details ol, .description_field ol {
  padding-left: 20px;
  margin-left: 20px; }
.proposal_details a, .description_field a {
  text-decoration: underline; }
.proposal_details blockquote, .description_field blockquote {
  opacity: 0.7;
  padding: 10px 20px; }
.proposal_details table, .description_field table {
  padding: 20px 0px; font-size: 11px; }
"""


##
# DecisionBoard
# Handles the user's list of important points in crafting page. 
DecisionBoard = ReactiveComponent
  displayName: 'DecisionBoard'

  render : ->
    current_user = fetch('/current_user')
    subdomain = fetch('/subdomain')
    hist = fetch(namespaced_key('histogram', @proposal))
    db = fetch('decision_board')
    
    your_opinion = fetch(@proposal.your_opinion)

    if your_opinion.published
      can_opine = permit 'update opinion', @proposal, your_opinion
    else
      can_opine = permit 'publish opinion', @proposal

    enable_opining = can_opine != Permission.INSUFFICIENT_PRIVILEGES && 
                      (can_opine != Permission.DISABLED || your_opinion.published ) && 
                      !(hist.selected_opinions || hist.selected_opinion)

    return DIV null if !enable_opining

    register_dependency = fetch(namespaced_key('slider', @proposal)).value 
                             # to keep bubble mouth in sync with slider

    # if there aren't points in the wings, then we won't bother showing 
    # the drop target
    wing_points = fetch("/page/#{@proposal.slug}").points or [] 
    included_points = fetch(@proposal.your_opinion).point_inclusions
    wing_points = (pnt for pnt in wing_points when !_.contains(included_points, pnt.key) )
    are_points_in_wings = wing_points.length > 0 
    
    decision_board_style =
      borderRadius: 16
      borderStyle: 'dashed'
      borderWidth: 3
      borderColor: focus_blue
      transition: if @last_proposal_mode != get_proposal_mode() || @transitioning  
                    "transform #{TRANSITION_SPEED}ms, " + \
                    "width #{TRANSITION_SPEED}ms, " + \
                    "min-height #{TRANSITION_SPEED}ms"
                  else
                    'none'

    if db.user_hovering_on_drop_target
      decision_board_style.borderStyle = 'solid'

    if get_proposal_mode() == 'results'
      give_opinion_button_width = 200
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
        backgroundColor: focus_blue
        borderBottom: '1px solid rgba(0,0,0,.6)'
        cursor: 'pointer'
        transform: "translate(#{opinion_region_x}px, -18px)"
        minHeight: 32
        width: give_opinion_button_width

    else 
      _.extend decision_board_style,
        transform: "translate(0, 10px)"
        minHeight: if are_points_in_wings then 275 else 170
        width: DECISION_BOARD_WIDTH()
        borderBottom: "#{decision_board_style.borderWidth}px dashed #{focus_blue}"

    if get_proposal_mode() == 'results'
      give_opinion_style = 
        display: 'block'
        color: 'white'
        padding: '.25em 18px'
        margin: 0
        fontSize: 16
        boxShadow: 'none'
        width: '100%'
    else 
      give_opinion_style =
        visibility: 'hidden'

    DIV 
      className:'opinion_region'
      style:
        width: DECISION_BOARD_WIDTH()



      SliderBubblemouth()

      DIV
        'aria-live': 'polite'
        key: 'body' 
        className:'decision_board_body'
        style: css.crossbrowserify decision_board_style
        onClick: => 
          if get_proposal_mode() == 'results' 
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
                points: (p for p in fetch(@proposal.your_opinion).point_inclusions \
                              when fetch(p).is_pro)

              PointsList 
                key: 'your_con_points'
                valence: 'cons'
                rendered_as: 'decision_board_point'
                points_editable: true
                points_draggable: true
                drop_target: are_points_in_wings
                points: (p for p in fetch(@proposal.your_opinion).point_inclusions \
                              when !fetch(p).is_pro)


              DIV style: {clear: 'both'}

          # only shown during crafting, but needs to be present always for animation
          BUTTON
            className: 'give_opinion_button primary_button'
            style: give_opinion_style

            if your_opinion.published 
              t('Update your Opinion')
            else 
              t('Give your Opinion')


      DIV 
        key: 'footer'
        style:
          width: DECISION_BOARD_WIDTH()

        # Big bold button at the bottom of the crafting page
        BUTTON 
          className:'save_opinion_button primary_button'
          style:
            display: 'none'
            backgroundColor: focus_blue
            width: '100%'
          onClick: => saveOpinion(@proposal)
          onKeyDown: (e) => 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              saveOpinion @proposal 
              e.preventDefault()

          if your_opinion.published 
            t('Return to results')
          else 
            t('Save your opinion')

        if !your_opinion.published

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

              t('skip_to_results') 

        else 

          DIV 
            className: 'below_save'
            style: 
              display: 'none'
                      
            BUTTON 
              style: 
                textDecoration: 'underline'
              className:'cancel_opinion_button primary_cancel_button'
              onClick: => 
                your_opinion.published = false 
                save your_opinion
              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  your_opinion.published = false 
                  save your_opinion
                  e.preventDefault()

              'Unpublish opinion'



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
          your_opinion = fetch(@proposal.your_opinion)

          your_opinion.point_inclusions.push(
            ui.draggable.parent().data('id'))
          save(your_opinion)

          window.writeToLog
            what: 'included point'
            details: 
              point: ui.draggable.parent().data('id')

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

window.saveOpinion = (proposal) -> 
  root = fetch('root')
  your_opinion = fetch(proposal.your_opinion)

  if your_opinion.published
    can_opine = permit 'update opinion', proposal, your_opinion
  else
    can_opine = permit 'publish opinion', proposal

  if can_opine > 0
    your_opinion.published = true
    save your_opinion
    updateProposalMode('results', 'save_button')
  else
    if can_opine == Permission.UNVERIFIED_EMAIL
      auth_form = 'verify email'
      current_user.trying_to = 'send_verification_token'
      save current_user
    else if can_opine == Permission.INSUFFICIENT_INFORMATION
      auth_form = 'user questions'
    else
      auth_form = 'create account'

    reset_key 'auth',
      form: auth_form
      goal: 'Save your opinion'
      ask_questions: true

    # We'll need to publish this opinion after auth is completed
    root.opinions_to_publish.push(proposal.your_opinion)

    save root


SliderBubblemouth = ReactiveComponent
  displayName: 'SliderBubblemouth'

  render : -> 
    slider = fetch(namespaced_key('slider', @proposal))
    db = fetch('decision_board')

    w = 34
    h = 24
    stroke_width = 11

    if get_proposal_mode() == 'crafting'
      transform = ""
      fill = 'white'
      if db.user_hovering_on_drop_target
        dash = "none"
      else
        dash = "25, 10"
    else 
      transform = "translate(0, -25px) scale(.5) "
      fill = focus_blue
      dash = "none"

    DIV 
      key: 'slider_bubblemouth'
      style: css.crossbrowserify
        left: 10 + translateStanceToPixelX slider.value, DECISION_BOARD_WIDTH() - w - 20
        top: -h + 10 + 3 # +10 is because of the decision board translating down 10, 3 is for its border
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
        stroke: focus_blue
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
    hist = fetch namespaced_key('histogram', @proposal)

    has_histogram_focus = hist.selected_opinions || hist.selected_opinion
    if has_histogram_focus
      DIV 
        style: 
          width: BODY_WIDTH() + 160
          border: "3px solid #{if get_selected_point() then '#eee' else focus_blue }"
          height: '100%'
          position: 'absolute'
          borderRadius: 16
          marginLeft: -BODY_WIDTH()/2 - 80
          left: '50%'
          top: 18

        # draw a bubble mouth
        if hist.selected_opinions
          w = 40; h = 30
          left = translateStanceToPixelX(hist.selected_opinion_value, BODY_WIDTH()) + 10

          DIV 
            style: cssTriangle 'top', \
                               (if get_selected_point() then '#eee' else focus_blue), \
                               w, h,               
                                  position: 'relative'
                                  top: -32
                                  left: left

            DIV
              style: cssTriangle 'top', 'white', w - 1, h - 1,
                position: 'relative'
                left: -(w - 2)/2
                top: 6

        # draw a name + avatar display for the selected opinion
        else 
          place_avatar_opinion_value = \
               if hist.selected_opinion_value > 0 then .66 else -.8
          left = translateStanceToPixelX(place_avatar_opinion_value, BODY_WIDTH() + 160)

          avatar_size = 80
          user = fetch(fetch(hist.selected_opinion).user)
          name = user.name or 'Anonymous'
          title = "#{name}'#{if name[name.length - 1] != 's' then 's' else ''} Opinion"

          name_width = widthWhenRendered(title, {fontSize: '30px', fontWeight: '600'})

          if hist.selected_opinion_value > 0
            name_style = 
              left: -28 - avatar_size * .5 - name_width 
              borderTopLeftRadius: 16
              paddingRight: avatar_size * .75
              paddingLeft: 18

          else
            name_style = 
              left: avatar_size/4
              borderTopRightRadius: 16
              paddingLeft: avatar_size * .75
              paddingRight: 18
                
          DIV 
            style: 
              left: left
              position: 'absolute'
              zIndex: 1

            DIV null,
              Avatar 
                key: user
                user: user
                hide_tooltip: true
                style: 
                  position: 'absolute'
                  width: avatar_size
                  height: avatar_size
                  top: -avatar_size * .75
                  left: -avatar_size/4
                  zIndex: 99 
                  border: "3px solid #{focus_blue}"

              DIV 
                style: _.extend name_style,
                  position: 'absolute'
                  backgroundColor: focus_blue
                  paddingTop: 8
                  paddingBottom: 8
                  color: 'white'
                  top: -58
                  width: name_width + 10 + 18 + avatar_size * .75 + 10

                SPAN 
                  style: 
                    fontSize: 30
                  title

    else 
      SPAN null



buildPointsList = (proposal, valence, sort_field, filter_included) ->
  sort_field = sort_field or 'score'
  points = fetch("/page/#{proposal.slug}").points or []
  opinions = fetch(proposal).opinions


  # filter out filter users...
  filtered_out = fetch('filtered')
  if filtered_out.users
    filtered = true
    opinions = (o for o in opinions when !(filtered_out.users?[o.user]))

  points = (pnt for pnt in points when pnt.is_pro == (valence == 'pros') )

  if filter_included
    included_points = fetch(proposal.your_opinion).point_inclusions
    points = (pnt for pnt in points when !_.contains(included_points, pnt.key) )

  # Filter down to the points included in the selection opinions, if set. 
  hist = fetch(namespaced_key('histogram', proposal))
  if hist.selected_opinion 
    opinions = [hist.selected_opinion] 
    filtered = true
  else if hist.selected_opinions
    opinions = hist.selected_opinions
    filtered = true

  # order points by resonance to users in view.    
  point_inclusions_per_point = {} # map of points to including users
  _.each opinions, (opinion_key) =>
    opinion = fetch(opinion_key)
    if opinion.point_inclusions
      for point in opinion.point_inclusions
        point_inclusions_per_point[point] ||= 0
        point_inclusions_per_point[point] += 1

  # try enforce k=2-anonymity for hidden points
  if opinions.length < 2
    for point,inclusions of point_inclusions_per_point
      if fetch(point).hide_name
        delete point_inclusions_per_point[point]

  
  points = (pnt for pnt in points when pnt.key of point_inclusions_per_point)

  # Sort points based on resonance with selected users, or custom sort_field
  sort = (pnt) ->
    if filtered
      -point_inclusions_per_point[pnt.key] 
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
        color: focus_blue
        fontSize: 30
      wrapper = @drawYourPoints


    get_heading = (valence) => 
      heading = customization "point_labels.#{header_prefix}_#{valence}_header", @proposal
      if !heading
        heading = customization "point_labels.#{header_prefix}_header", @proposal
          .replace('--valences--', capitalize(customization("point_labels.#{valence}", @proposal)))
          .replace('--valence--', capitalize(customization("point_labels.#{valence.substring(0, 3)}", @proposal)))
      heading

    heading = get_heading(@props.valence)
    other_heading = get_heading(if @props.valence == 'pros' then 'cons' else 'pros')
    # Calculate the other header height so that if they break differently,
    # at least they'll have same height
    header_height = Math.max heightWhenRendered(heading,       header_style), \
                             heightWhenRendered(other_heading, header_style)

    keydown = (e) => 
      if e.which == 32
        els = $('.point_list .points_heading_label')
        for el, idx in els 
          if el == @refs.point_list_heading.getDOMNode()
            i = idx 
            break 
        i--
        if i < 0
          i = els.length - 1 
        els[i].focus()
        e.preventDefault()
        e.stopPropagation()

    wrapper [
      H2 
        ref: 'point_list_heading'
        id: @local.key.replace('/','-')
        className: 'points_heading_label'
        tabIndex: 0           
        onKeyDown: keydown
        style: _.extend header_style,
          textAlign: 'center'
          marginBottom: 18
          marginTop: 7
          height: header_height
        heading 

        DIV 
          className: 'hidden'
          "Cycle through the lists of points with spacebar."

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


      if @props.drop_target
        @drawDropTarget()

      if @props.points_editable
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
    DIV
      className: "point_list points_by_community #{@props.valence}_by_community"
      style: css.crossbrowserify _.defaults (@props.style or {}),
        display: 'inline-block'
        verticalAlign: 'top'
        width: POINT_WIDTH()
        minHeight: (if @page.points.length > 4 then jQuery(window).height() else 400)
        zIndex: if @columnStandsOut() then 6 else 1
        margin: '38px 18px 0 18px'
        position: 'relative'

        transition: "transform #{TRANSITION_SPEED}ms"
        transform: "translate(#{x_pos}px, 0)"

      children

  drawYourPoints: (children) -> 
      
    DIV 
      className: "point_list points_on_decision_board #{@props.valence}_on_decision_board"
      style: _.defaults (@props.style or {}),
        display: 'inline-block'
        verticalAlign: 'top'        
        width: POINT_WIDTH()
        marginTop: 28
        position: 'relative'
        zIndex: if @columnStandsOut() then 6 else 1        
        float: if @props.valence == 'pros' then 'right' else 'left'    
      children

  drawAddNewPoint: -> 
    
    your_points = @data()
    can_add_new_point = permit 'create point', @proposal

    hist = fetch namespaced_key('histogram', @proposal)
    hist_selection = hist.selected_opinions || hist.selected_opinion

    if can_add_new_point != Permission.INSUFFICIENT_PRIVILEGES && !hist_selection
      if !your_points.adding_new_point
        DIV 
          onClick: => 
            if can_add_new_point == Permission.NOT_LOGGED_IN
              reset_key 'auth', 
                form: 'create account'
                goal: 'Write a point'
                ask_questions: true

            else if can_add_new_point == Permission.UNVERIFIED_EMAIL
              reset_key 'auth', 
                form: 'verify email'
                goal: 'Write a point'
                ask_questions: true

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
      else if !browser.is_mobile
        EditPoint
          key: "new_point_#{@props.valence}"
          fresh: true
          valence: @props.valence
          your_points_key: @props.key

  drawAddNewPointInCommunityCol: ->
    DIV 
      id: "add-point-#{@props.valence}"
      style: 
        cursor: 'pointer'
        marginTop: 20


      @drawGhostedPoint
        width: POINT_WIDTH()
        text: "Write a new #{capitalize \
                    if @props.valence == 'pros' 
                      customization('point_labels.pro', @proposal)
                    else 
                      customization('point_labels.con', @proposal)}"

        is_left: @props.valence == 'cons'
        style: {}
        text_style:
          #color: focus_blue
          textDecoration: 'underline'
          fontSize: if browser.is_mobile then 24



  drawAddNewPointInDecisionBoard: -> 
    your_points = @data()
    noun = \
        capitalize \
          if @props.valence == 'pros' 
            customization('point_labels.pro', @proposal)
          else 
            customization('point_labels.con', @proposal)    

    DIV 
      style: 
        padding: '.25em 0'
        marginTop: '1em'
        marginLeft: if @props.drop_target then 20 else 9
        fontSize: POINT_FONT_SIZE()

      if @props.drop_target
        SPAN 
          style: 
            fontWeight: if browser.high_density_display then 300 else 400
          "#{t('or')} "
      SPAN 
        style: 
          padding: if @props.drop_target then '0 6px' else '0 11px 0 0'

        dangerouslySetInnerHTML:{__html: '&bull;'}

      BUTTON 
        className: "write_#{@props.valence}"
        style:
          textDecoration: 'underline'
          color: focus_blue
          padding: 0
          backgroundColor: 'transparent'
          border: 'none'

        t('write_a_new_point', {noun}) 

  drawDropTarget: -> 
    left_or_right = if @props.valence == 'pros' then 'right' else 'left'

    noun = capitalize \
        if @props.valence == 'pros' 
          customization('point_labels.pro', @proposal)
        else 
          customization('point_labels.con', @proposal)

    drop_target_text = t("drag_from_#{left_or_right}", {noun})

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
                  stroke: focus_blue
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
          stroke: focus_blue
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
        fill: '#F9FBFD'  #TODO: somehow make this focus_blue color mixed with white @ .2 opacity
        stroke: focus_blue
        stroke_width: 6
        dash_array: '24, 18'
        style: css.crossbrowserify mouth_style




About = ReactiveComponent
  displayName: 'About'

  componentWillMount : ->
    @local.embed_html_directly = true
    @local.html = null
    @local.save

  componentDidMount : -> @handleContent()
  componentDidUpdate : -> @handleContent()

  handleContent : -> 
    $el = $(@getDOMNode())

    if @local.embed_html_directly
      # have to use appendChild rather than dangerouslysetinnerhtml
      # because scripts in the about page html won't get executed
      # when using dangerouslysetinnerhtml
      if @local.html
        $el.find('.embedded_about_html').html @local.html

    else
      # REACT iframes don't support onLoad, so we need to figure out when 
      #               to check the height of the loaded content ourselves      
      $el.prop('tagName').toLowerCase() == 'iframe'
      iframe = $el[0]
      _.delay ->
        try 
          iframe.height = iframe.contentWindow.document.body.scrollHeight + "px"
        catch e
          iframe.height = "2000px"
          console.error 'http/https mismatch for about page. Should work in production.'
          console.error e
      , 1000


  render : -> 
    subdomain = fetch('/subdomain') 

    if @local.embed_html_directly && !@local.html && subdomain.about_page_url
      # fetch the about page HTML directly
      $.get subdomain.about_page_url, \
            (response) => @local.html = response; save @local

    DIV style: {marginTop: 20},
      if !subdomain.about_page_url
        DIV null, 'No about page defined'
      else if !@local.embed_html_directly
        IFRAME 
          src: subdomain.about_page_url
          width: CONTENT_WIDTH()
          style: {display: 'block', margin: 'auto'}
      else
        DIV className: 'embedded_about_html'



LocationTransition = ReactiveComponent
  displayName: 'locationTransition'
  render : -> 
    loc = fetch 'location'

    if @last_location != loc.url 

      ######
      # Temporary technique for handling resetting root state when switching 
      # between routes. TODO: more elegant approach
      auth = fetch('auth')

      if loc.url == '/edit_profile' && auth.form != 'edit profile'
        reset_key auth, {form: 'edit profile', ask_questions: true}
      else if auth.form
        reset_key auth

      # hist = fetch(namespaced_key('histogram', @proposal))
      # if hist.selected_opinion || hist.selected_opinions || hist.selected_opinion_value
      #   hist.selected_opinion = hist.selected_opinions = hist.selected_opinion_value = null
      #   save hist
      #######

      @last_location = loc.url
    SPAN null


AuthTransition = ReactiveComponent
  # This doesn't actually render anything.  It just processes state
  # changes to current_user for CSRF and logging in and out.
  displayName: 'Computer'
  render : ->
    current_user = fetch('/current_user')
    if current_user.csrf
      arest.csrf(current_user.csrf)

    # Publish pending opinions if we can
    if @root.opinions_to_publish.length > 0

      remaining_opinions = []

      for opinion_key in @root.opinions_to_publish
        opinion = fetch(opinion_key)
        can_opine = permit('publish opinion', opinion.proposal)

        if can_opine > 0 && !opinion.published
          opinion.published = true
          save opinion
        else 
          remaining_opinions.push opinion_key

          # TODO: show some kind of prompt to user indicating that despite 
          #       creating an account, they still aren't permitted to publish 
          #       their opinion.
          # if can_opine == Permission.INSUFFICIENT_PRIVILEGES
          #   ...

      if remaining_opinions.length != @root.opinions_to_publish.length
        @root.opinions_to_publish = remaining_opinions
        save @root

    # users following an email invitation need to complete 
    # registration (name + password)
    if current_user.needs_to_complete_profile
      reset_key 'auth',
        key: 'auth'
        form: 'create account via invitation'
        goal: 'Complete registration'
        ask_questions: true
    else if current_user.needs_to_verify && !window.send_verification_token
      current_user.trying_to = 'send_verification_token'
      save current_user

      window.send_verification_token = true 

      reset_key 'auth',
        key: 'auth'
        form: 'verify email'
        goal: 'confirm you control this email'
        ask_questions: false

    SPAN null


######
# Page
# Decides which page to render by reading state (particularly location and auth). 
# Plays the role of an application router.
#
Page = ReactiveComponent
  displayName: 'Page'
  mixins: [AccessControlled]

  render: ->
    subdomain = fetch('/subdomain')
    loc = fetch('location')
    auth = fetch('auth')

    DIV 
      style: 
        position: 'relative'
        zIndex: 1
        minHeight: if subdomain.name != 'livingvotersguide' then 200
        margin: 'auto'

      if auth.form
        Auth()

      else if !@accessGranted()
        SPAN null 

      else if loc.url.match(/(.+)\/edit/)
        EditProposal 
          key: loc.url.match(/(.+)\/edit/)[1]
          fresh: false
          
      else
        switch loc.url
          when '/'
            Homepage key: 'homepage'
          when '/about'
            About()
          when '/proposal/new'
            EditProposal key: "new_proposal", fresh: true              
          when '/dashboard/email_notifications'
            Notifications 
              key: '/page/dashboard/email_notifications'
          when '/dashboard/assessment'
            FactcheckDash key: "/page/dashboard/assessment"
          when '/dashboard/import_data'
            ImportDataDash key: "/page/dashboard/import_data"
          when '/dashboard/moderate'
            ModerationDash key: "/page/dashboard/moderate"
          when '/dashboard/application'
            AppSettingsDash key: "/page/dashboard/application"
          when '/dashboard/customizations'
            CustomizationsDash key: "/page/dashboard/customizations"
          when '/dashboard/roles'
            SubdomainRoles key: "/page/dashboard/roles"
          when '/dashboard/tags'
            UserTags key: "/page/dashboard/tags"
          else
            if @page?.proposal?
              Proposal key: @page.proposal
            else if @page.result == 'Not found'
              DIV 
                style: 
                  textAlign: 'center'
                  fontSize: 32
                  marginTop: 50

                "There doesn't seem to be a proposal here"

                DIV 
                  style: 
                    color: '#555'
                    fontSize: 16
                  "Check if the url is correct. The author may also have deleted it. Good luck!"

            else 
              LOADING_INDICATOR

Root = ReactiveComponent
  displayName: 'Root'

  render : -> 
    loc = fetch('location')
    app = fetch('/application')
    subdomain = fetch '/subdomain'
    current_user = fetch('/current_user')

    DIV 

      # Track whether the user is currently swipping. Used to determine whether
      # a touchend event should trigger a click on a link.
      # TODO: I'd like to have this defined at a higher level  
      onTouchMove: -> 
        window.is_swipping = true
        true
      onTouchEnd: -> 
        window.is_swipping = false
        true

      style: 
        width: DOCUMENT_WIDTH()
      
      onClick: @resetSelection

      StateDash()
      StateGraph()

      # state transition components
      AuthTransition()
      LocationTransition()

      BrowserLocation()

      if !subdomain.name
        LOADING_INDICATOR

      else 
        

        DIV 
          style:
            backgroundColor: 'white'
            overflowX: 'hidden'

          # Avatars()
          
          BrowserHacks()

          Header(key: 'page_header')       

          Page key: "/page#{loc.url}"

          Footer(key: 'page_footer')

          GoogleTranslate()


      Tooltip()

      if app.dev
        Development()

      if current_user.is_super_admin || app.godmode
        GodMode()

  resetSelection: (e) ->
    # TODO: This is ugly. Perhaps it would be better to have components 
    #       register a callback when a click bubbles all the way to the
    #       top. There are global interdependencies to unwind as well.

    loc = fetch('location')
    page = fetch("/page#{loc.url}")

    if !fetch('auth').form && page.proposal

      hist = fetch namespaced_key('histogram', page.proposal)

      if get_selected_point()
        window.writeToLog
          what: 'deselected a point'
          details:
            point: get_selected_point()

        delete loc.query_params.selected
        save loc

      else if hist.selected_opinions || hist.selected_opinion
        if hist.dragging
          hist.dragging = false
        else
          hist.selected_opinion = null
          hist.selected_opinions = null
          hist.selected_opinion_value = null
        save hist


    wysiwyg_editor = fetch 'wysiwyg_editor'
    if wysiwyg_editor.showing
      # We don't want to close the editor if there was a selection event whose click event
      # bubbled all the way up here.
      
      selected = document.getSelection()

      if selected.isCollapsed
        wysiwyg_editor.showing = false
        save wysiwyg_editor


# exports...
window.Point = Point
window.Comment = Comment
window.Franklin = Root


require './bootstrap_loader'

