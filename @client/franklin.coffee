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
require './browser_location'
require './bubblemouth'
require './edit_proposal'
require './customizations'
require './form'
require './histogram'
require './roles'
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

get_selected_point = -> 
  fetch('location').query_params.selected

######
# Expands a key like 'slider' to one that is namespaced to a parent object, 
# like the current proposal. Will return a local key like 'proposal/345/slider' 
window.namespaced_key = (base_key, base_object) ->
  namespace_key = fetch(base_object).key 

  # don't store this on the server
  if namespace_key[0] == '/'
    namespace_key = namespace_key.substring(1, namespace_key.length)
  
  "#{namespace_key}_#{base_key}"

window.proposal_url = (proposal) =>
  # The special thing about this function is that it only links to
  # "?results=true" if the proposal has an opinion.

  proposal = fetch proposal
  result = '/' + proposal.slug
  subdomain = fetch('/subdomain')  

  if TWO_COL() || ((!customization('show_crafting_page_first', proposal) || !proposal.active ) \
     && proposal.top_point)

    result += '?results=true'

  return result

window.isNeutralOpinion = (stance) -> 
  return Math.abs(stance) < 0.05

window.updateProposalMode = (proposal_mode, triggered_by) ->
  toggle = -> 
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

    window.writeToLog
      what: 'toggle proposal mode'
      details: 
        from: get_proposal_mode()
        to: proposal_mode
        triggered_by: triggered_by 


  if proposal_mode == 'results' && $('.histogram').length > 0
    $('.histogram').ensureInView
      offset_buffer: -50
      callback : toggle
  else
    toggle()


window.opinionsForProposal = (proposal) ->       
  filter_func = customization("homie_histo_filter", proposal)
  opinions = fetch('/page/' + proposal.slug).opinions || []
  # We'll only pass SOME opinions to the histogram
  opinions = (opinion for opinion in opinions when \
               !filter_func or filter_func(fetch(opinion.user)))
  opinions

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

    has_focus = \
      if get_selected_point()
        'point'
      else if edit_mode
        'edit point'
      else
        "opinion"

    if @proposal.has_focus != has_focus
      @proposal.has_focus = has_focus
      save @proposal


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
    
    proposal_header = (customization('ProposalNavigation', @proposal))()

    newpoint_threshold = @buildNewPointThreshold()
    draw_handle = (can_opine not in [Permission.DISABLED, \
                          Permission.INSUFFICIENT_PRIVILEGES]) || \
                          your_opinion.published

    DIV key:@props.slug,

      DIV 
        className: 'proposal_header'

        if customization('docking_proposal_header', @proposal)
          Dock
            dock_on_zoomed_screens: false
            skip_jut: true
            proposal_header

        else
          proposal_header

      DIV null,

        ProposalDescription()

        # notifications
        if current_user?.logged_in          
          ActivityFeed()

        #feelings
        DIV
          style:
            width: BODY_WIDTH()
            margin: '0 auto'
            position: 'relative'
            zIndex: 1

          Dock
            key: 'histogram-dock'
            docked_key: namespaced_key('histogram', @proposal)
            dock_on_zoomed_screens: true
            constraints : ['slider-dock']
            dockable : => 
              #mode == 'results'
              false
            start : 170 - 50

            stop : -> 
              $('.reasons_region').offset().top + $('.reasons_region').outerHeight() - 20

            dummy:  if fetch('histogram-dock').docked then 1 else -1
            dummy2: if mode == 'crafting' then 1 else -1
            dummy3: opinionsForProposal(@proposal)
            dummy4: BODY_WIDTH()
                    # TODO: Dummy is a shallow patch for an odd problem. 
                    # If you have a nested component (in this case Histogram) 
                    # which passes a prop based on a Statebus value, then 
                    # that nested component will not be rerendered with 
                    # the new prop unless the parent component (Dock)
                    # is rendered first. By setting a dummy prop on Dock
                    # that corresponds to the prop for the child, we assure
                    # that the parent will properly pass the prop onto the 
                    # child. 

            do =>       

              Histogram
                key: namespaced_key('histogram', @proposal)
                proposal: @proposal
                opinions: opinionsForProposal(@proposal)
                width: BODY_WIDTH()
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
            dummy2: BODY_WIDTH()
            do =>   
              plurality = if mode == 'crafting' then 'individual' else 'group'
              OpinionSlider
                key: namespaced_key('slider', @proposal)
                width: BODY_WIDTH() - 10
                your_opinion: @proposal.your_opinion
                focused: mode == 'crafting'
                backgrounded: false
                permitted: draw_handle
                pole_labels: [ \
                  [customization("slider_pole_labels.#{plurality}.oppose", @proposal),
                   customization("slider_pole_labels.#{plurality}.oppose_sub", @proposal)], \
                  [customization("slider_pole_labels.#{plurality}.support", @proposal),
                   customization("slider_pole_labels.#{plurality}.support_sub", @proposal)]]


        #reasons
        DIV 
          className:'reasons_region'
          style : 
            width: REASONS_REGION_WIDTH()            
            position: 'relative'
            paddingBottom: '4em' #padding instead of margin for docking
            margin: "#{if draw_handle && !TWO_COL() then '24px' else '0'} auto 0 auto"


          # Border + bubblemouth that is shown when there is a histogram selection
          GroupSelectionRegion()

          PointsList 
            key: 'community_cons'
            rendered_as: 'community_point'
            points_editable: TWO_COL()
            valence: 'cons'
            newpoint_threshold: newpoint_threshold
            points_draggable: mode == 'crafting'
            drop_target: false
            points: buildPointsList \
              @proposal, 'cons', \
              (if mode == 'results' then 'score' else 'last_inclusion'), \ 
              mode == 'crafting'

          if !TWO_COL()
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

              DecisionBoard
                key: 'decisionboard'

          #community pros
          PointsList 
            key: 'community_pros'
            rendered_as: 'community_point'
            points_editable: TWO_COL()
            valence: 'pros'
            newpoint_threshold: newpoint_threshold
            points_draggable: mode == 'crafting'
            drop_target: false
            points: buildPointsList \
              @proposal, 'pros', \
              (if mode == 'results' then 'score' else 'last_inclusion'), \ 
              mode == 'crafting'

      if edit_mode && browser.is_mobile
        # full screen edit point mode for mobile
        valence = if edit_mode in ['community_pros', 'your_pro_points'] 
                    'pros' 
                  else 
                    'cons'
        pc = fetch edit_mode

        console.log "PROPOSAL RENDER"
        EditPoint 
          key: if pc.adding_new_point then "new_point_#{valence}" else pc.editing_points[0]
          fresh: pc.adding_new_point
          valence: valence
          your_points_key: edit_mode

      else if !edit_mode
        SaveYourOpinionFooter()

      else if mode == 'results' && 
          your_opinion.published && 
          customization('ThanksForYourOpinion', @proposal)
        customization('ThanksForYourOpinion', @proposal)()

  componentDidUpdate : ->
    $el = $(@getDOMNode())

    # Resizing the reasons region to solve a layout error when 
    # the height of the decision board (which is absolutely positioned) 
    # is taller than either of the wing point columns
    $el.find('.reasons_region').css {minHeight: $el.find('.opinion_region').height() + 100} 


  buildNewPointThreshold : ->
    # Grab the 10th percentile
    points = @page.points || []
    newpoint_threshold = 
      (_.sortBy points, \
                (pnt) => - Date.parse(pnt.created_at))[Math.ceil(points.length / 10)]

    (newpoint_threshold and Date.parse(newpoint_threshold.created_at)) or 
      new Date()


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

    @max_description_height = customization('collapse_descriptions_at', @proposal)

    DIV           
      style: 
        width: BODY_WIDTH()
        position: 'relative'
        margin: 'auto'
        fontSize: 18
        marginBottom: 18


      # Proposal name
      DIV
        id: 'proposal_name'
        style:
          lineHeight: 1.2
          fontWeight: 700
          fontSize: 45
          paddingBottom: 15

        @proposal.name


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
          #overflowY: 'hidden'
          overflowX: 'visible'
        if @local.description_collapsed
          DIV
            style:
              backgroundColor: 'white'
              backgroundColor: '#f9f9f9'
              width: '100%'
              position: 'absolute'
              bottom: 0
              textDecoration: 'underline'
              cursor: 'pointer'
              paddingTop: 10
              paddingBottom: 10
              fontWeight: 600
              textAlign: 'center'
            onMouseDown: => @local.description_collapsed = false; save(@local)
            'Expand full text'
        SPAN dangerouslySetInnerHTML:{__html: @proposal.description}


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

      if permit('update proposal', @proposal) > 0
        DIV null,
          A 
            style: {color: '#888'}
            href: "#{@proposal.key}/edit"
            'Edit'
          A 
            style: 
              color: '#888'
              padding: 10
              backgroundColor: if @local.edit_roles then '#fafafa' else 'transparent'
            onClick: => 
              @local.edit_roles = !@local.edit_roles
              save @local
            'Share'

          if permit('delete proposal', @proposal) > 0
            A
              style: {color: '#888'}
              onClick: => 
                if confirm('Delete this proposal forever?')
                  destroy(@proposal.key)
                  loadPage('/')
              'Delete'

          if current_user.is_super_admin
            SPAN 
              style:
                padding: 10

              onClick: => 
                @local.copy_to_subdomain = !@local.copy_to_subdomain
                save @local

              A
                style: {color: '#888'}
                'Copy to subdomain'

              if @local.copy_to_subdomain
                subdomains = fetch('/subdomains').subs
                hues = getNiceRandomHues subdomains?.length
                
                UL 
                  style: {}
                  for sub, idx in subdomains
                    LI
                      style: 
                        display: 'inline-block'
                        listStyle: 'none'
                      A
                        href: "/proposal/#{@proposal.id}/copy_to/#{sub.id}"
                        'data-nojax': false
                        style: 
                          padding: "4px 8px"
                          fontSize: 18
                          backgroundColor: hsv_to_rgb(hues[idx], .7, .5)
                          color: 'white'
                          display: 'inline-block'            
                        sub.name

      if @local.edit_roles
        DIV 
          style:
            width: BODY_WIDTH()
            margin: 'auto'
            backgroundColor: '#fafafa'
            padding: '10px 60px'

          ProposalRoles 
            key: @proposal.key




  componentDidMount : ->
    if (@max_description_height and @local.description_collapsed == undefined \
        and $('.proposal_details').height() > @max_description_height)
      @local.description_collapsed = true; save(@local)

  componentDidUpdate : ->
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
  padding: 20px 0px; }
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
        minHeight: 275
        width: DECISION_BOARD_WIDTH()
        borderBottom: "#{decision_board_style.borderWidth}px dashed #{focus_blue}"


    # if get_selected_point() && get_proposal_mode() == 'crafting'
    #   if !_.contains(your_opinion.point_inclusions, get_selected_point())
    #     css.grayscale decision_board_style
    #     decision_board_style.opacity = '.4'
    #   else
    #     decision_board_style.borderColor = "#eee"


    if get_proposal_mode() == 'results'
      give_opinion_style = 
        display: 'block'
        color: 'white'
        padding: '.25em 18px'
        margin: 0
        fontSize: 16
        boxShadow: 'none'
    else 
      give_opinion_style =
        visibility: 'hidden'

    DIV 
      className:'opinion_region'
      style:
        width: DECISION_BOARD_WIDTH()

      SliderBubblemouth()

      [DIV
        key: 'body' 
        className:'decision_board_body'
        style: css.crossbrowserify decision_board_style
        onClick: => 
          if get_proposal_mode() == 'results' 
            updateProposalMode('crafting', 'give_opinion_button')

        DIV null, 

          if get_proposal_mode() == 'crafting'
            DIV 
              className: 'your_points'
              style: 
                padding: '0 18px'
                marginTop: -3 # To undo the 3 pixel border

              PointsList 
                key: 'your_con_points'
                valence: 'cons'
                rendered_as: 'decision_board_point'
                points_editable: true
                points_draggable: true
                drop_target: true
                points: (p for p in fetch(@proposal.your_opinion).point_inclusions \
                              when !fetch(p).is_pro)

              PointsList 
                key: 'your_pro_points'
                valence: 'pros'
                rendered_as: 'decision_board_point'
                points_editable: true
                points_draggable: true
                drop_target: true
                points: (p for p in fetch(@proposal.your_opinion).point_inclusions \
                              when fetch(p).is_pro)

              DIV style: {clear: 'both'}


          # only shown during crafting, but needs to be present always for animation
          A 
            className: 'give_opinion_button primary_button'
            style: give_opinion_style

            if your_opinion.published 
              'Update your Opinion' 
            else 
              'Give your Opinion'

      DIV 
        key: 'footer'
        style:
          width: DECISION_BOARD_WIDTH()

        # Big bold button at the bottom of the crafting page
        DIV 
          className:'save_opinion_button primary_button'
          style:
            display: 'none'
            backgroundColor: focus_blue
          onClick: => saveOpinion(@proposal)

          if your_opinion.published 
            'Opinion updated. See the results' 
          else 
            'Save your opinion and see results'

        if !your_opinion.published

          DIV 
            className: 'below_save'
            style: 
              display: 'none'
                      
            A 
              className:'cancel_opinion_button primary_cancel_button'
              onClick: => updateProposalMode('results', 'cancel_button')
              'or just skip to the results' ]
        

  componentDidUpdate : ->
    @transition if !Modernizr.csstransitions then 0 else TRANSITION_SPEED
    @makeDroppable()

  componentDidMount : ->
    @transition 0
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

  transition : (speed) -> 
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

    if @last_proposal_mode != mode && speed > 0
      perform initial_state

      # wait for css transitions to complete
      @transitioning = true
      _.delay => 
        if @isMounted()
          perform final_state
          @transitioning = false
      , speed + 200

    else if !@transitioning
      perform initial_state
      perform final_state

    @last_proposal_mode = mode

saveOpinion = (proposal) -> 
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
      goal: 'Save your Opinion'
      ask_questions: true

    # We'll need to publish this opinion after auth is completed
    root.opinions_to_publish.push(proposal.your_opinion)

    save root

SaveYourOpinionFooter = ReactiveComponent
  displayName: 'SaveYourOpinionFooter'

  render : -> 
    your_opinion = your_opinion = fetch(@proposal.your_opinion)
    slider = fetch namespaced_key('slider', @proposal)

    return SPAN null if (!TWO_COL() && get_proposal_mode() == 'crafting') || \
                        ( your_opinion.published || \
                          (!slider.has_moved && your_opinion.point_inclusions.length == 0)\
                        )
    
    DIV 
      style: 
        position: 'fixed'
        left: 0
        bottom: 0
        width: PAGE_WIDTH()
        backgroundColor: focus_blue
        padding: 10
        color: 'white'
        zIndex: 999
        textAlign: 'center'
        fontSize: 24

      'Your opinion hasn’t been added yet! '

      SPAN 
        style: 
          fontWeight: 700
          textDecoration: 'underline'
        onClick: => saveOpinion(@proposal)

        'Save your opinion'



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
          width: BODY_WIDTH() + 80
          border: "3px solid #{if get_selected_point() then '#eee' else focus_blue }"
          height: '100%'
          position: 'absolute'
          borderRadius: 16
          marginLeft: -BODY_WIDTH()/2 - 40
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
               if hist.selected_opinion_value > 0 then .8 else -.8
          left = translateStanceToPixelX(place_avatar_opinion_value, BODY_WIDTH()) + 20

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
  points = fetch("/page/#{proposal.slug}").points
  opinions = fetch("/page/#{proposal.slug}").opinions

  points = (pnt for pnt in points when pnt.is_pro == (valence == 'pros') )

  if filter_included
    included_points = fetch(proposal.your_opinion).point_inclusions
    points = (pnt for pnt in points when !_.contains(included_points, pnt.key) )

  # Filter down to the points included in the selection opinions, if set. 
  hist = fetch(namespaced_key('histogram', proposal))
  selected_opinions = if hist.selected_opinion 
                        [hist.selected_opinion] 
                      else 
                        hist.selected_opinions
  
  if selected_opinions
    # order points by resonance to those users.    
    point_inclusions_per_point = {} # map of points to including users
    _.each selected_opinions, (opinion_key) =>
      opinion = fetch(opinion_key)
      if opinion.point_inclusions
        for point in opinion.point_inclusions
          if !(point of point_inclusions_per_point)
            point_inclusions_per_point[point] = 1
          else
            point_inclusions_per_point[point] += 1

    points = (pnt for pnt in points when pnt.key of point_inclusions_per_point)

  # Sort points based on resonance with selected users, or custom sort_field
  sort = (pnt) ->
    if selected_opinions
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
        width: POINT_CONTENT_WIDTH()
        fontSize: 30        
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
        width: POINT_CONTENT_WIDTH()
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

    wrapper [
      DIV 
        className:'points_heading_label'
        style: _.extend header_style,
          textAlign: 'center'
          marginBottom: 18
          marginTop: 7
          height: header_height
        heading 

      UL null,
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
                is_new: @props.newpoint_threshold &&
                         Date.parse(point.created_at) > @props.newpoint_threshold
        else
          LI 
            style: 
              marginTop: 50
              fontStyle: 'italic'
              listStyle: 'none'
              textAlign: 'center'
              fontWeight: if browser.high_density_display then '300' else '400'

            "No " + \
            customization('point_labels.' + @props.valence, @proposal ) + \
            " given"

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
      className: "points_by_community #{@props.valence}_by_community"
      style: css.crossbrowserify
        display: 'inline-block'
        verticalAlign: 'top'
        width: POINT_CONTENT_WIDTH()
        minHeight: (if @page.points.length > 4 then jQuery(window).height() else 400)
        zIndex: if @columnStandsOut() then 6 else 1
        margin: '38px 18px 0 18px'
        position: 'relative'

        transition: "transform #{TRANSITION_SPEED}ms"
        transform: "translate(#{x_pos}px, 0)"

      children

  drawYourPoints: (children) -> 
    DIV 
      className: "points_on_decision_board #{@props.valence}_on_decision_board"
      style: 
        display: 'inline-block'
        verticalAlign: 'top'        
        width: POINT_CONTENT_WIDTH()
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
                goal: 'write a point'
            else if can_add_new_point == Permission.UNVERIFIED_EMAIL
              reset_key 'auth', 
                form: 'verify email'
                goal: 'write a point'
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
      style: 
        cursor: 'pointer'
        marginTop: 20

      @drawGhostedPoint
        width: POINT_CONTENT_WIDTH()
        text: "Write a new #{capitalize \
                    if @props.valence == 'pros' 
                      customization('point_labels.pro', @proposal)
                    else 
                      customization('point_labels.con', @proposal)}"

        is_left: @props.valence == 'cons'
        style: {}
        text_style:
          color: focus_blue
          textDecoration: 'underline'


  drawAddNewPointInDecisionBoard: -> 
    your_points = @data()

    DIV 
      style: 
        padding: '.25em 0'
        marginTop: '1em'
        marginLeft: 20
        fontSize: POINT_FONT_SIZE()

      SPAN 
        style: 
          fontWeight: if browser.high_density_display then 300 else 400
        'or '
      SPAN 
        style: {padding: '0 6px'}
        dangerouslySetInnerHTML:{__html: '&bull;'}

      A 
        className: "write_#{@props.valence}"
        style:
          textDecoration: 'underline'
          color: focus_blue

        "Write a new "
        capitalize \
          if @props.valence == 'pros' 
            customization('point_labels.pro', @proposal)
          else 
            customization('point_labels.con', @proposal)    

  drawDropTarget: -> 
    left_or_right = if @props.valence == 'pros' then 'right' else 'left'

    drop_target_text = "Drag a #{capitalize \
                  if @props.valence == 'pros' 
                    customization('point_labels.pro', @proposal)
                  else 
                    customization('point_labels.con', @proposal)} from the #{left_or_right}"

    dt_w = POINT_CONTENT_WIDTH() - 24

    DIV 
      style: 
        marginLeft: if @props.valence == 'cons' then 24 else 0
        marginRight: if @props.valence == 'pros' then 24 else 0
        position: 'relative'
        left: if @props.valence == 'cons' then -18 else 18

      @drawGhostedPoint
        width: POINT_CONTENT_WIDTH() - 24
        text: drop_target_text
        is_left: @props.valence == 'cons'
        style: 
          #padding: "0 #{if @props.valence == 'pros' then '24px' else '0px'} .25em #{if @props.valence == 'cons' then '24px' else '0px'}"        
          opacity: if @proposal.has_focus == 'edit point' then .1
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


    DIV
      style: _.defaults style, 
        position: 'relative'
        opacity: if @proposal.has_focus == 'edit point' then .1

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
        style: _.extend {}, text_style, 
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



##
# Point
# A single point in a list. 
Point = ReactiveComponent
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
              @props.rendered_as == 'decision_board_point' || TWO_COL()
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
              @props.rendered_as == 'decision_board_point' || TWO_COL()
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

Comment = ReactiveComponent
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
          className: 'comment_entry_avatar'
          key: comment.user
          hide_tooltip: true

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

.comment_entry_avatar {
  position: absolute;
  width: 50px;
  height: 50px; }

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

FactCheck = ReactiveComponent
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

EditComment = ReactiveComponent
  displayName: 'EditComment'

  render : -> 
    permitted = permit 'create comment', @proposal

    DIV className: 'comment_entry',

      # Comment author name
      DIV
        style:
          fontWeight: 'bold'
          color: '#666'
        (fetch('/current_user').name or 'You') + ':'

      # Icon
      Avatar
        style:
          position: 'absolute'
          width: 50
          height: 50
          backgroundColor: if permitted < 0 then 'transparent'
          border:          if permitted < 0 then '1px dashed grey'

        key: fetch('/current_user').user
        hide_tooltip: true

      if permitted == Permission.DISABLED
        SPAN 
          style: {position: 'absolute', margin: '14px 0 0 70px'}
          'Comments closed'

      else if permitted == Permission.INSUFFICIENT_PRIVILEGES
        SPAN 
          style: {position: 'absolute', margin: '14px 0 0 70px'}
          'Sorry, you do not have permission to comment'

      else if permitted < 0
        SPAN
          style:
            position: 'absolute'
            margin: '14px 0 0 70px'
            cursor: 'pointer'

          onClick: =>

            if permitted == Permission.NOT_LOGGED_IN
              reset_key 'auth', {form: 'login', goal: 'Write a Comment'}
            else if permitted == Permission.UNVERIFIED_EMAIL
              reset_key 'auth', {form: 'verify email', goal: 'Write a Comment'}
              current_user.trying_to = 'send_verification_token'
              save current_user

          if permitted == Permission.NOT_LOGGED_IN
            DIV null,
              SPAN 
                style: { textDecoration: 'underline', color: focus_blue }
                'Log in to write a comment'
              if '*' not in @proposal.roles.commenter
                DIV style: {fontSize: 11},
                  'Only some email addresses are authorized to comment.'

          else if permitted == Permission.UNVERIFIED_EMAIL
            DIV null,
              SPAN
                style: { textDecoration: 'underline', color: focus_blue }
               'Verify your account'
              SPAN null, 'to write a comment'

      AutoGrowTextArea
        className: 'new_comment'
        placeholder: if permitted > 0 then 'Write a new comment' else ''
        disabled: permitted < 0
        onChange: (e) => @local.new_comment = e.target.value; save(@local)
        defaultValue: if @props.fresh then null else @data().body
        min_height: 60
        style:
          marginLeft: 60
          width: 390
          lineHeight: 1.4
          fontSize: 16
          border: if permitted < 0 then 'dashed 1px'

      if permitted > 0
        DIV style: {textAlign: 'right'},
          Button {'data-action': 'save-comment', style: {marginLeft: 314}}, 'Save comment', (e) =>
            e.stopPropagation()
            if @props.fresh
              comment =
                key: '/new/comment'
                body: @local.new_comment
                user: fetch('/current_user').user
                point: "/point/#{@props.point}"
            else
              comment = @data()
              comment.body = @local.new_comment
              comment.editing = false

            save(comment)
            $(@getDOMNode()).find('.new_comment').val('')


Discussion = ReactiveComponent
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
    



SubmitFactCheck = ReactiveComponent
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
    if current_user.needs_to_set_password
      reset_key auth,
        key: 'auth'
        form: 'create account via invitation'
        goal: 'complete registration'

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
        minHeight: 200
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
          when '/dashboard/roles'
            SubdomainRoles key: "/page/dashboard/roles"
          else
            if @page?.proposal?
              Proposal key: @page.proposal.key
            else
              LOADING_INDICATOR

Root = ReactiveComponent
  displayName: 'Root'

  render : -> 

    subdomain = fetch '/subdomain'
    loc = fetch('location')
    app = fetch('/application')
    current_user = fetch('/current_user')

    DIV 
      style: 
        width: PAGE_WIDTH()
      
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
        auth = fetch('auth')

        DIV 
          style:
            backgroundColor: 'white'
            overflowX: 'hidden'

          Avatars()
          
          BrowserHacks()

          Header() if !auth.form || auth.form == 'edit profile'       

          Page key: "/page#{loc.url}"

          Footer()

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
      selected = if document.all then document.selection.createRange().text else document.getSelection()
      if !document.getSelection() || selected.anchorNode.textContent == ''
        wysiwyg_editor.showing = false
        save wysiwyg_editor


# exports...
window.Point = Point
window.Comment = Comment
window.Franklin = Root


require './bootstrap_loader'

