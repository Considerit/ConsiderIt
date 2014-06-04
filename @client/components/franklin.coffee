#////////////////////////////////////////////////////////////
# Exploratory reimplemenntation of considerit client in React
#////////////////////////////////////////////////////////////

# Ugliness in this prototype: 
#   - ReactTransitionGroup based animations force defining custom components
#     when I'd rather just keep them in the parent component. 
#   - State transition javascript animations sometimes require setting css (e.g. width or transform), 
#     which are duplicated in the CSS itself to accommodate navigating directly to that state.
#   - Keeping javascript and CSS variables synchronized
#      * transition_speed
#      * slider width
#   - Not clear where to handle splitting up opinions into segments
#   - Sticky decision board requires hacks to CSS of community cons to get them to stay to the right
#   - Haven't declared prop types for the components
#   - Some animations are living in places that access DOM not managed by them

# React aliases
R = React.DOM
ReactTransitionGroup = React.addons.TransitionGroup

# Variables that need to be kept synchronized with CSS
transition_speed = 700   # Speed of transition from results to crafting (and vice versa)
histogram_width = 636    # Width of the slider / histogram base


#####
# Responsibilities that will later be managed by ActiveREST
all_users = {} 
all_points = {}

parseProposal = (data) ->
  # Build hash of user information
  data.users = $.parseJSON data.users
  for user in data.users
    if !user.avatar_file_name
      user.avatar_file_name = {small: '/system/default_avatar/small_default-profile-pic.png', large: '/system/default_avatar/large_default-profile-pic.png'}
    else
      user.avatar_file_name = {small: "/system/avatars/#{user.id}/small/#{user.avatar_file_name}", large: "/system/avatars/#{user.id}/large/#{user.avatar_file_name}"}
    all_users[user.id] = user

  ####
  # Make points an hash of id => point
  # separate pro and con points
  data.pro_community_points = []
  data.con_community_points = []

  for point in data.points
    all_points[point.id] = point
    if point.is_pro 
      data.pro_community_points.push point.id
    else
      data.con_community_points.push point.id

  data.user_opinion = 
    included_cons: []
    included_pros: []

  for included_point in data.included_points
    if data.points[included_point].is_pro
      data.user_opinion.included_pros.push included_point
    else
      data.user_opinion.included_cons.push included_point

  # data.user_opinion.included_cons = data.pro_community_points[3..6]
  # data.user_opinion.included_pros = data.con_community_points[1..2]

  ##
  # Split up opinions into segments. For now we'll keep three hashes: 
  #   - all opinions
  #   - high level segments (the seven original segments, strong supporter, neutral, etc)
  #   - small segments that represent individual columns in the histogram, now that 
  #     we do not have wide bars per se
  num_opinions = data.opinions.length

  # an initial function for sizing avatars
  biggest_possible_avatar_size = 50
  data.avatar_size = biggest_possible_avatar_size / Math.sqrt( (num_opinions + 1)/10  )

  # Calculate how many segments columns to put on the histogram. Note that for the extremes and for neutral, we'll hack it 
  # to allow three columns for those segments. 
  data.num_small_segments = Math.floor(histogram_width/data.avatar_size) - 2 * 3 - 1 #for the additional cols for the extremes+neutral 

  seven_original_opinion_segments = {0:[],1:[],2:[],3:[],4:[],5:[],6:[]}

  histogram_small_segments = {}
  histogram_small_segments[i] = [] for i in [0..data.num_small_segments]

  max_slider_variance = 2.0 # In old system, opinion stances varied from -1.0 to 1.0. 

  for opinion in data.opinions
    seven_original_opinion_segments[opinion.stance_segment].push opinion
    small_segment = Math.floor(data.num_small_segments * (opinion.stance + 1) / max_slider_variance)
    histogram_small_segments[small_segment].push opinion

  data.seven_original_opinion_segments = seven_original_opinion_segments
  data.histogram_small_segments = histogram_small_segments

  data

fetch = (options, callback, error_callback) ->
  error_callback ||= (xhr, status, err) -> console.error 'Could not fetch data', status, err.toString()

  $.ajax
    url: options.url
    dataType: 'json'
    success: (data) =>
      if options.type == 'proposal'
        data = parseProposal data
      console.log data
      callback data

    error: error_callback




####################
# REACT COMPONENTS #
####################

# These are the components and their relationships:
#                       Proposal
#                   /      |            \ 
#    CommunityPoints   DecisionBoard      GiveOpinionButton
#               |          | 
#               |      YourPoints
#               |    /            \
#              Point             NewPoint

# DecisionBoard and GiveOpinionButton exist only for the sake of the particular way
# React affords animations right now. See ReactTransitionGroup below. 


##
# NewPoint
# Handles adding a new point into the system. Only rendered when proposal is in Crafting state. 
# Manages whether the user has clicked "add a new point". If they have, show new point form. 
NewPoint = React.createClass
  displayName: 'NewPoint'

  getInitialState : ->
    editMode : false

  handleAddPointBegin : (ev) ->
    @setState
      editMode : true

  handleAddPointCancel : (ev) ->
    @setState
      editMode : false

  handleSubmitNewPoint : (ev) ->
    console.log 'submitting new point'

  render : ->
    valence_capitalized = "#{@props.valence.charAt(0).toUpperCase()}#{@props.valence.substring(1)}"

    R.div className:'newpoint',
      if !@state.editMode
        R.div className:'newpoint_prompt',
          R.span className:'qualifier', 
            'or '
          R.span className:'newpoint_bullet', dangerouslySetInnerHTML:{__html: '&bull;'}
          R.a className:'newpoint_link', 'data-action':'write-point', onClick: @handleAddPointBegin,
            "Write a new #{valence_capitalized}"
      else
        R.div className:'newpoint_form',
          R.input id:'is_pro', name: 'is_pro', type: 'hidden', value: "#{@props.valence == 'pro'}"
          R.div className:'newpoint_nutshell_wrap',
            R.textarea id:'nutshell', classname:'newpoint_nutshell is_counted', cols:'28', maxLength:"140", name:'nutshell', pattern:'^.{3,}', placeholder:'Summarize your point (required)', required:'required'
            R.span className: 'count', 140
          R.div className:'newpoint_description_wrap',
            R.textarea id:'text', classname:'newpoint_description', cols:'28', name:'text', placeholder:'Write a longer description (optional)', required:'required'
          R.div className:'newpoint_hide_name',
            R.input className:'newpoint-anonymous', type:'checkbox', id:"hide_name-#{@props.valence}", name:"hide_name-#{@props.valence}"
            R.label for:"hide_name-#{@props.valence}", title:'We encourage you not to hide your name from other users. Signing your point with your name lends it more weight to other participants.', 
              'Conceal your name'
          R.div className:'newpoint-submit',
            R.a className:'newpoint-cancel', onClick: @handleAddPointCancel,
              'cancel'
            R.input className:'button', action:'submit-point', type:'submit', value:'Done', onClick: @handleSubmitNewPoint


##
# Point
# A single point in a list. 
Point = React.createClass
  displayName: 'Point'

  setDraggability : ->
    return if @props.location_class != 'community_point'

    # TODO: possible efficiency would be to only make draggable when first mouse over a point
    $el = $(@getDOMNode()).find('.point_content')
    if $el.hasClass "ui-draggable"
      $el.draggable(if @props.state == 'results' then 'disable' else 'enable') 
    else
      $el.draggable
        revert: "invalid"
        disabled: @props.state == 'results'

  componentDidMount : -> @setDraggability()
  componentDidUpdate : -> @setDraggability()

  render : -> 
    R.li className: "point closed_point #{@props.location_class} #{@props.valence}", 'data-id':@props.id, 'data-role':'point', 'data-includers': [1,2],
      R.a className:"avatar point_author_avatar", id:"avatar-#{@props.author}", 'data-action':'user_opinion', 'data-id':@props.author, 'data-tooltip':'user_profile'
      R.div className:'point_content',
        R.div className:'close_open_point',
          R.i className:'fa fa-times-circle'
        R.div className:'point_summary_region', 'data-action':'open-point', 'data-id':@props.id,
          R.div className:'point_summary_view',
            R.div className:'point_nutshell',
              @props.nutshell
              if @props.text
                R.span className: 'point_details_tease', 
                  @props.text[0..50]
                  ' ...'

            R.div className:'point_operations',
              R.a className:'open_point_link',
                @props.comment_count
                ' comments'

##
# CommunityPoints
# List of points contributed by others. 
# Shown in wing during crafting, in middle on results. 
CommunityPoints = React.createClass
  displayName: 'CommunityPoints'

  render : ->
    points = @props.points
    if @props.state=='crafting'
      #filter down to points that haven't been included
      points = _.reject points, (pnt) => _.contains(@props.included_points, pnt)

    R.div className:"community_#{@props.valence}s_region points_list_region",
      R.div className:"points_by_community #{@props.valence}s_by_community points_layout", 'data-state':@props.state, 'data-prior-state':@props.priorstate,
        R.div className:'points_heading_region',
          R.div className:'points_heading_view',
            R.h1 className:'points_heading_label', 'data-action':'expand-toggle',
              "Others' #{@props.valence.charAt(0).toUpperCase()}#{@props.valence.substring(1)}s"

          R.div className:'points_list_region',
            R.ul className:'point_list_collectionview',
              #for point in (if @props.state=='crafting' then @props.points[0..3] else @props.points[2..5])
              for point_id in points
                point = all_points[point_id]
                Point 
                  key: point.id
                  id: point.id
                  nutshell: point.nutshell
                  text: point.text
                  valence: @props.valence
                  comment_count: point.comment_count
                  author: point.user_id
                  state: @props.state
                  location_class : 'community_point'

##
# YourPoints
# List of important points for the active user. 
# Two instances used for Pro and Con columns. Shown as part of DecisionBoard. 
# Creates NewPoint instances.
YourPoints = React.createClass
  displayName: 'YourPoints'

  render : ->
    R.div className:"points_list_region #{@props.valence}s_on_decision_board_region",
      R.div className:"points_on_decision_board #{@props.valence}s_on_decision_board points_layout", 'data-state':@props.state,
        R.div className:'points_heading_region',
          R.div className:'points_heading_view',
            R.h1 className:'points_heading_label',
              'Your Pros'
        R.div className:'points_list_region',
          R.ul className:'point_list_collectionview',
            for point_id in @props.points
              point = all_points[point_id]
              Point 
                key: point.id
                nutshell: point.nutshell
                text: point.text
                valence: 'pro' 
                comment_count: point.comment_count
                author: point.user_id
                state: @props.state
                location_class: 'decision_board_point'

        R.div className:'points_footer_region',
          R.div className:'decision_board_points_footer_view',
            R.div className:'add_point_drop_target',
              R.img className:'drop_target', src:"/assets/drop_target.png"
              R.span className:'drop_prompt',
                "Drag #{@props.valence} points from the #{if @props.valence == 'pro' then 'left' else 'right'} that resonate with you."

            NewPoint {valence: @props.valence}

##
# DecisionBoard
# Handles the user's list of important points in crafting state. 
# Primary motivation for pulling this out separately is to 
# animate between results and crafting states using the 
# ReactTransitionGroup interface.
DecisionBoard = React.createClass
  displayName: 'DecisionBoard'

  componentDidMount : ->
    
    # make this a drop target
    $el = $(@getDOMNode())
    valenceOfDroppedPoint = (ui) -> if ui.draggable.parent().is('.pro') then 'pro' else 'con'

    $el.droppable
      accept: ".community_point .point_content"
      drop : (ev, ui) =>
        valence = valenceOfDroppedPoint ui
        ui.draggable.parent().fadeOut()

        @props.pointIncludedCallback ui.draggable.parent().data('id')
        $el.removeClass "user_is_hovering_on_a_drop_target_#{valence} user_is_dragging_a_#{valence}"

      out : (ev, ui) =>
        valence = valenceOfDroppedPoint ui
        $el.removeClass "user_is_hovering_on_a_drop_target_#{valence}"

      over : (ev, ui) =>
        valence = valenceOfDroppedPoint ui
        $el.addClass "user_is_hovering_on_a_drop_target_#{valence}"

      activate : (ev, ui) =>
        valence = valenceOfDroppedPoint ui
        $el.addClass "user_is_dragging_a_#{valence}"

      deactivate : (ev, ui) =>
        valence = valenceOfDroppedPoint ui
        $el.removeClass "user_is_dragging_a_#{valence}"


  componentWillEnter : (callback) ->
    # Don't display the pro/con columns immediately, 
    # otherwise they won't fit side by side as the 
    # area animates the width
    $(@getDOMNode()).hide()
    _.delay =>
      $(@getDOMNode()).show()
      callback()
    , transition_speed

  componentWillLeave : (callback) ->
    $(@getDOMNode()).hide()
    callback()
    # $(@getDOMNode()).slideUp transition_speed / 4, ->
    #   callback()

  render : ->
    R.div className:'decision_board_points_layout',
      # your pros
      YourPoints
        state: @props.state
        priorstate: @props.priorstate
        points: @props.included_pros
        valence: 'pro'

      # your cons
      YourPoints
        state: @props.state
        priorstate: @props.priorstate
        points: @props.included_cons
        valence: 'con'

##
# GiveOpinionButton
# Displays the give opinion button which toggles to crafting state. 
# Primary motivation for pulling this out separately is to 
# animate between results and crafting states using the 
# ReactTransitionGroup interface.
GiveOpinionButton = React.createClass
  displayName: 'GiveOpinionButton'

  # Moves the GiveOpinionButton under the slider handle
  place: ->
    left = $('.ui-slider-handle').offset().left - $('.opinion_region').offset().left 
    
    if @props.currentOpinion > 50 # position right justified when opposing
      # 120 is based on width of give opinion button, which can't be checked here b/c this is before animation is complete
      left -= 120 

    # Ugly to manipulate the opinion region here
    # Problem: This code will not run when results is directly accessed.
    $('.opinion_region').css
      transform: "translate(#{left}, -18px)"
      '-webkit-transform': "translate(#{left}px, -18px)"

  componentWillEnter: (callback) ->
    @place()

    # wait a slight bit before showing "give your opinion" when moving from crafting to results
    $(@getDOMNode()).hide()
    _.delay =>
      $(@getDOMNode()).show()
      callback()
    , 100

  componentWillLeave: (callback) -> 
    $('.opinion_region').css
      transform: "translate(0,0)"
      '-webkit-transform': "translate(0,0)"
    callback()

  render : ->
    R.a className:'give_opinion_button', onClick: @props.toggleState,
      'Give your Opinion'


##
# Proposal
# The mega component for a proposal.
# Has proposal description, feelings area (slider + histogram), and reasons area
window.REACTProposal = React.createClass
  displayName: 'Proposal'

  pointIncludedCallback : (point_id) ->
    #TODO: active rest call here...

    point = all_points[point_id]
    if point.is_pro 
      included_points = @state.data.user_opinion.included_pros
      included_points.push point_id
      @setState { data: _.extend(@state.data, 
        _.extend(@state.data.user_opinion, {
          included_pros : included_points
        })
      )}


    else
      included_points = @state.data.user_opinion.included_cons
      included_points.push point_id

      @setState { data: _.extend(@state.data, 
        _.extend(@state.data.user_opinion, {
          included_cons : included_points
        })
      )}

    console.log 'included point ', point_id

  setSlidability : ->

    $el = $(@getDOMNode()).find('.histogram_base')
    if $el.hasClass "ui-slider"
      $el.slider(if @state.state == 'results' then 'disable' else 'enable') 
    else
      $el.slider
        disabled: @state.state == 'results'

  componentWillMount : ->
    fetch {type: 'proposal', url: Routes.proposal_path @props.long_id}, (proposal_data) =>
      @setState {data: _.extend(@state.data, proposal_data)}

  componentDidMount : -> @setSlidability()
  componentDidUpdate : ->
    @setSlidability()

    # Sticky decision board. It is here because the calculation of offset top would 
    # be off if we did it in DidMount before all the data has been fetched from server
    $('.opinion_region').headroom
      offset: $('.opinion_region').offset().top #+ $('.opinion_region').height()
      classes:
        top : "normal_place"
        notTop : "scrolling_with_user"
      
      onNotTop : -> 
        $('.four_columns_of_points .community_cons_region').css
          transition: 'none'
          '-webkit-transition': 'none'
          transform: 'translateX(500px)'
          '-webkit-transform': 'translateX(550px)'

        # $('.four_columns_of_points').addClass('pinned')

      onTop : ->
        $('.four_columns_of_points .community_cons_region').css
          transform: ''
          '-webkit-transform': ''

        _.delay ->
          $('.four_columns_of_points .community_cons_region').css
            transition: ''
            '-webkit-transition': ''
        , 100
        # $('.four_columns_of_points').removeClass('pinned')

  getInitialState : ->
    state : 'crafting',
    priorstate : 'results',
    data :
      proposal : {}
      pro_community_points : []
      con_community_points : []
      seven_original_opinion_segments : {}
      histogram_small_segments : {}
      users : {}
      user_opinion :
        included_pros : []
        included_cons : []
        stance : null
        stance_segment : 3


  toggleState : (ev) ->
    @setState
      state : @state.priorstate, 
      priorstate : @state.state

  render : ->
    current_opinion = $('.histogram_base').slider('value')

    segment_is_extreme_or_neutral = (segment) => 
      segment == 0 || segment == @state.data.num_small_segments || segment == Math.floor(@state.data.num_small_segments / 2)

    R.div className:'proposal_layout', key:@props.long_id, 'data-role':'proposal', 'data-activity':'proposal-has-activity', 'data-status':'proposal-inactive', 'data-visibility':'published', 'data-state':@state.state, 'data-prior-state':@state.priorstate,
      
      #description
      R.div className:'proposal_description_region', 
        R.div className:'proposal_description_view',
          R.div className:'proposal_proposer',
            R.a 'data-action':'user_profile_page', 'data-id':@state.data.proposal.user_id, 'data-tooltip':'user_profile',
              if all_users[@state.data.proposal.user_id]
                R.img src:all_users[@state.data.proposal.user_id].avatar_file_name.large
          R.div className:'proposal_description_main',
            if @state.data.proposal.category 
              R.div className: 'proposal_category',
                @state.data.proposal.category
                ' '
                @state.data.proposal.designator

            R.h1 className:'proposal_heading',
              @state.data.proposal.name
            R.div className:'proposal_details',
              R.div className:'proposal_description_body', dangerouslySetInnerHTML:{__html: @state.data.proposal.description}

      #toggle
      R.div className:'toggle_proposal_state_region',
        R.div className:'toggle_proposal_state_view', 'data-state':@state.state, 'data-updating':false, 'data-prior-state':@state.priorstate,
          R.h1 className:'proposal_state_primary',
            if @state.state == 'crafting'
              'Give your Opinion'
            else 
              'Explore all Opinions'
          R.div className:'proposal_state_secondary', 
            'or '
            R.a onClick: @toggleState,
              if @state.state != 'crafting'
                'Give Own Opinion'
              else 
                'Explore all Opinions'

      #feelings
      R.div className:'proposal_histogram_region',
        R.div className:'histogram_layout', 'data-state':@state.state, 'data-prior-state':@state.priorstate,
          #for segment in [6..0]
          for segment in [@state.data.num_small_segments..0]
            R.div key:"#{segment}", className:"histogram_bar #{if segment_is_extreme_or_neutral(segment) then 'extreme_or_neutral' else '' }", id:"segment-#{segment}", 'data-segment':segment, style: {width: if segment_is_extreme_or_neutral(segment) then "#{3 * @state.data.avatar_size}px" else "#{@state.data.avatar_size}px"},
              R.ul className:'histogram_bar_users',
                for opinion in @state.data.histogram_small_segments[segment] #@state.data.opinions[segment]
                  R.li key:"#{opinion.user_id}", id:"avatar-#{opinion.user_id}", className:"avatar segment-#{segment}", 'data-action':'user_opinion', 'data-id':opinion.user_id, style:{height:"#{@state.data.avatar_size}px", width:"#{@state.data.avatar_size}px"}, 'data-tooltip':'user_profile'

          R.div className:'histogram_base', 
            R.div className:'feeling_slider ui-slider-handle',
              R.img className:'bubblemouth', src:'assets/bubblemouth.png'
              if @state.state == 'crafting'
                R.div className:'feeling_feedback', 
                  R.div className:'feeling_feedback_label', 'You are a'
                  R.div className:'feeling_feedback_result', 'Supporter'
                  R.div className:'feeling_feedback_instructions', 'drag to change'

          R.div className:'feeling_labels', 
            R.h1 className:"histogram_label histogram_label_support",
              'Support'
              # if @state.state == 'results' then 'Supporters' else 'Support'
            R.h1 className:"histogram_label histogram_label_oppose",
              # if @state.state == 'results' then 'Opposers' else 'Oppose'
              'Oppose'

      #reasons
      R.div className:'proposal_reasons_region',
        R.div className:'reasons_layout', 'data-state':@state.state, 'data-prior-state':@state.priorstate, style:{minHeight:'567px'},
          R.div className:'four_columns_of_points',

            #community pros
            CommunityPoints 
              state: @state.state
              priorstate: @state.priorstate
              points: @state.data.pro_community_points
              valence: 'pro'
              included_points : @state.data.user_opinion.included_pros

            #your reasons
            R.div className:'opinion_region',
              R.div className:'decision_board_layout', 'data-state':@state.state, 'data-prior-state':@state.priorstate,

                ReactTransitionGroup className:'decision_board_body', transitionName: 'state_change', component: R.div, style: {minHeight: '32px'},

                  if @state.state == 'crafting'
                    DecisionBoard
                      key: 1
                      state: @state.state
                      priorstate: @state.priorstate
                      included_pros : @state.data.user_opinion.included_pros
                      included_cons : @state.data.user_opinion.included_cons
                      pointIncludedCallback : @pointIncludedCallback

                  else if @state.state == 'results'
                    GiveOpinionButton
                      key: 2
                      toggleState: @toggleState
                      currentOpinion: current_opinion

            #community cons
            CommunityPoints 
              state: @state.state
              priorstate: @state.priorstate
              points: @state.data.con_community_points
              valence: 'con'
              included_points : @state.data.user_opinion.included_cons



