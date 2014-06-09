#////////////////////////////////////////////////////////////
# Exploratory reimplemenntation of considerit client in React
#////////////////////////////////////////////////////////////

# Ugliness in this prototype: 
#   - Keeping javascript and CSS variables synchronized
#   - Haven't declared prop types for the components
#   - Unclear whether information derived from props should be 
#     stored as state or plain variable (see Proposal.buildHistogramDataFromProps)
#   - I don't like setting data as key in props, would rather 
#     have the specific props be added explicitly
#   - NewPoint CSS/HTML is still bulky, waiting on redesign
#   - Managing top_level_component in Router

# React aliases
R = React.DOM
ReactTransitionGroup = React.addons.TransitionGroup

# Constants
TRANSITION_SPEED = 700   # Speed of transition from results to crafting (and vice versa) 
BIGGEST_POSSIBLE_AVATAR_SIZE = 50
HISTOGRAM_WIDTH = 600    # Width of the slider / histogram base 
MAX_HISTOGRAM_HEIGHT = 200
DECISION_BOARD_WIDTH = 544

####################
# React Components
#
# These are the components and their relationships:
#                       Proposal
#                   /      |           \            \
#    CommunityPoints   DecisionBoard   Histogram    Slider
#               |          |
#               |      YourPoints
#               |    /            \
#              Point             NewPoint

##
# Proposal
# The mega component for a proposal.
# Has proposal description, feelings area (slider + histogram), and reasons area
Proposal = React.createClass
  displayName: 'Proposal'

  ####
  # Component defaults

  getDefaultProps : ->
    state : 'crafting'
    data :  # would rather have each of these data items added to top level props dict
      proposal : {}
      points : {}
      users : {}
      included_points : []
      initial_stance : 0.0
      opinions : []


  # TODO: add prop types here


  ####
  # Lifecycle methods

  componentWillMount : -> 

  componentWillReceiveProps : (next_props) -> 

  componentWillUpdate : (next_props, next_state) ->

  componentDidMount : -> 
    @applyStyles false

  componentDidUpdate : (prev_props, prev_state) ->
    @applyStyles prev_props.state != @props.state

    # Sticky decision board. It is here because the calculation of offset top would 
    # be off if we did it in DidMount before all the data has been fetched from server
    if @props.state == 'crafting'
      _.delay => 
        $el = $(@getDOMNode())
        $cons = $el.find('.cons_by_community')
        $opinion = $el.find('.opinion_region')

        $el.find('.opinion_region').headroom
          offset: $('.opinion_region').offset().top

          onNotTop : -> 
            $cons.hide()
            $cons.css {left: DECISION_BOARD_WIDTH}
            $opinion.css {position: 'fixed', top: 0}
            $cons.show()

          onTop : -> 
            $cons.hide()
            $cons.css {left: ''}
            $opinion.css {position: '', top: ''}
            $cons.show()
      , 200  # delay initialization to let the rest of the dom load so that the offset is calculated properly

  ####
  # State-dependent styling
  applyStyles : (animate = true) ->  
    $el = $(@getDOMNode())
    duration = if animate then TRANSITION_SPEED else 0

    slider_stance =  $el.find('.ui-slider-handle').position().left / $el.find('.slider_base').innerWidth()
    is_opposer = slider_stance > .5

    # Note: Velocity requires properties to be pulled out (e.g. paddingLeft, translateX, rather than using padding or transform)
    # Note: Use velocity even for 0 duration applications to maintain parity of style definition
    switch @props.state
      when 'crafting'
        styles = 
          '.histogram_bar:not(.extreme_or_neutral)': { opacity: .2 }
          '.histogram_bar.extreme_or_neutral':       { opacity: .2 }
          '.opinion_region':                         { translateX: 0, translateY: 0 }
          '.decision_board_body':                    { width: DECISION_BOARD_WIDTH, minHeight: 375}
          '.pros_by_community':                      { translateX: 0 }
          '.cons_by_community':                      { translateX: 0 }
        
        _.each _.keys(styles), (selector) -> $el.find(selector).velocity styles[selector], {duration}

        $el.find('.give_opinion_button')[0].style.visibility = 'hidden'
        _.delay -> 
          $el.find('.your_points')[0].style.display = ''
        , duration

      when 'results'
        opinion_region_x = DECISION_BOARD_WIDTH * slider_stance
        give_opinion_button_width = 186
        opinion_region_x -= give_opinion_button_width / 2 

        styles = 
          '.histogram_bar:not(.extreme_or_neutral)': { opacity: 1 }
          '.histogram_bar.extreme_or_neutral':       { opacity: 1 }
          '.opinion_region':                         { translateX: opinion_region_x, translateY: -18 }
          '.decision_board_body':                    { width: give_opinion_button_width, minHeight: 32}
          '.pros_by_community':                      { translateX:  DECISION_BOARD_WIDTH / 2 }
          '.cons_by_community':                      { translateX: -DECISION_BOARD_WIDTH / 2 }
        
        _.each _.keys(styles), (selector) -> $el.find(selector).velocity styles[selector], {duration}

        $el.find('.your_points')[0].style.display = 'none'
        _.delay -> 
          $el.find('.give_opinion_button')[0].style.visibility = 'visible'
        , duration

  ####
  # Props need to change methods

  onPointShouldBeIncluded : (point_id) ->
    #TODO: activeREST call here...
    #TODO: should probably be managing an opinion, e.g. @props.opinion.included_points
    @props.data.included_points.push point_id
    save @props.data

  onPointShouldBeRemoved : (point_id) ->
    #TODO: activeREST call here...    
    #TODO: should probably be managing an opinion, e.g. @props.opinion.included_points
    #TODO: server might return that the point was actually _deleted_ from 
    #      the system, not just removed from the list...need to handle that
    @props.data.included_points = _.without @props.data.included_points, point_id
    save @props.data

  onPointShouldBeCreated : (data) ->
    #TODO: activeREST call here...
    id = -1
    while _.has @props.data.points, id
      id = -(Math.floor(Math.random() * 999999) + 1)

    point = _.extend data, 
      user_id : -2 #anon user
      comment_count : 0 
      id : id

    @props.data.points[id] = point
    @props.data.included_points.push point.id

    save @props.data

  toggleState : (ev) ->
    route = if @props.state == 'results' then Routes.new_opinion_proposal_path(@props.data.proposal.long_id) else Routes.proposal_path(@props.data.proposal.long_id)
    app_router.navigate route, {trigger : true}

  ####
  # Make this thing!
  render : ->

    stance_names = 
      0 : 'Diehard Supporter'
      6 : 'Diehard Opposer'
      1 : 'Strong Supporter'
      5 : 'Strong Opposer'
      2 : 'Supporter'
      4 : 'Opposer'
      3 : 'Neutral'

    R.div className:'proposal', key:@props.long_id, 'data-state':@props.state,
      
      #description
      R.div className:'description_region',
        Avatar className: 'proposal_proposer', user: @props.data.proposal.user_id, tag: R.img, img_style: 'large'
        R.div className: 'proposal_category', "#{@props.data.proposal.category} #{@props.data.proposal.designator}"
        R.h1 className:'proposal_heading', @props.data.proposal.name
        R.div className:'proposal_details', dangerouslySetInnerHTML:{__html: @props.data.proposal.description}

      #toggle
      R.div className:'toggle_state_region',
        R.h1 className:'proposal_state_primary',
          if @props.state == 'crafting' then 'Give your Opinion' else 'Explore all Opinions'
        R.div className:'proposal_state_secondary', 
          'or '
          R.a onClick: @toggleState,
            if @props.state != 'crafting' then 'Give Own Opinion' else 'Explore all Opinions'
    

      #feelings
      R.div className:'feelings_region',
        Histogram
          state: @props.state
          opinions: @props.data.opinions

        Slider
          initial_stance: @props.data.initial_stance
          stance_names: stance_names 
          state: @props.state

      #reasons
      R.div className:'reasons_region',
        #community pros
        CommunityPoints 
          key: 'pros'
          state: @props.state
          points: @props.data.points
          valence: 'pro'
          included_points : @props.data.included_points
          onPointShouldBeRemoved : @onPointShouldBeRemoved

        #your reasons
        DecisionBoard
          state: @props.state
          points : @props.data.points
          included_points : @props.data.included_points
          onPointShouldBeIncluded : @onPointShouldBeIncluded
          onPointShouldBeCreated : @onPointShouldBeCreated
          toggleState: @toggleState

        #community cons    
        CommunityPoints 
          key: 'cons'
          state: @props.state
          points: @props.data.points
          valence: 'con'
          included_points : @props.data.included_points
          onPointShouldBeRemoved : @onPointShouldBeRemoved

##
# Histogram
Histogram = React.createClass

  getDefaultProps : ->
    opinions: []

  getInitialState : ->
    seven_original_opinion_segments : {}
    histogram_small_segments : {}
    avatar_size : 0
    num_small_segments : 0

  componentWillMount : -> @buildHistogramDataFromProps @props

  componentWillReceiveProps : (next_props) -> @buildHistogramDataFromProps next_props

    ##
    # buildHistogramDataFromProps
    # Split up opinions into segments. For now we'll keep three hashes: 
    #   - all opinions
    #   - high level segments (the seven original segments, strong supporter, neutral, etc)
    #   - small segments that represent individual columns in the histogram, now that 
    #     we do not have wide bars per se
  buildHistogramDataFromProps : (props) ->
    seven_original_opinion_segments = {0:[],1:[],2:[],3:[],4:[],5:[],6:[]}
    for opinion in props.opinions
      seven_original_opinion_segments[opinion.stance_segment].push opinion

    ##
    # Size the avatars. Factor in how evenly distributed the opinions are across the segments. Want to 
    # make the avatar size for (a) smaller than (b) so that the histogram stays a reasonable size
    #                 AA                           
    #                 AA
    #                 AA
    #                 AA_____A_____A          BBBBBBBBBB
    num_opinions = props.opinions.length
    num_opinions_in_max_segment = _.max (x.length for x in _.values(seven_original_opinion_segments))
    avatar_size = Math.min BIGGEST_POSSIBLE_AVATAR_SIZE, BIGGEST_POSSIBLE_AVATAR_SIZE / Math.sqrt( (num_opinions + 1) / 10  )
    if avatar_size * num_opinions_in_max_segment / 3 > MAX_HISTOGRAM_HEIGHT # divide by three for three cols in extremes/neutral segments
      avatar_size = 3 * MAX_HISTOGRAM_HEIGHT / num_opinions_in_max_segment


    # Calculate how many segments columns to put on the histogram. Note that for the extremes and for neutral, we'll hack it 
    # to allow three columns for those segments.
    num_small_segments = Math.floor(HISTOGRAM_WIDTH / avatar_size) - 2 * 3 - 1 #for the additional cols for the extremes+neutral 

  
    histogram_small_segments = {}
    histogram_small_segments[i] = [] for i in [0..num_small_segments]

    max_slider_variance = 2.0 # Slider stances vary from -1.0 to 1.0. 

    for opinion in props.opinions
      small_segment = Math.floor(num_small_segments * (opinion.stance + 1) / max_slider_variance)
      histogram_small_segments[small_segment].push opinion

    @setState {seven_original_opinion_segments, avatar_size, num_small_segments, histogram_small_segments}

  segment_is_extreme_or_neutral : (segment) -> 
    segment == 0 || segment == @state.num_small_segments || segment == Math.floor(@state.num_small_segments / 2)

  render : ->

    R.div className: 'histogram',
      for segment in [@state.num_small_segments..0]
        R.ul className:"histogram_bar #{if @segment_is_extreme_or_neutral(segment) then 'extreme_or_neutral' else '' }", id:"segment-#{segment}", key:"#{segment}", style: {width: (if @segment_is_extreme_or_neutral(segment) then 3 * @state.avatar_size else @state.avatar_size)},
          for opinion in @state.histogram_small_segments[segment]
            Avatar tag: R.li, key:"#{opinion.user_id}", user: opinion.user_id, 'data-segment':segment, style:{height:"#{@state.avatar_size}px", width:"#{@state.avatar_size}px"}


##
# Slider
# Manages the slider and the UI elements attached to it. 
Slider = React.createClass
  displayName: 'Slider'

  getInitialState : ->
    stance_segment : @getStanceSegmentFromSliderValue(@props.initial_stance)

  componentDidMount : -> 
    @applyStyles false
    @setSlidability()

  componentDidUpdate : (prev_props, prev_state) ->
    @applyStyles prev_props.state != @props.state
    @setSlidability()

  # We have a separate applyStyle here from Proposal because the Slider component
  # gets rerendered more frequently than the Proposal component (i.e. when the 
  # slider is being slid...forcing the entire Propoosal component to rerender
  # causes terrible performance).
  applyStyles : (animate = false) ->
    duration = if animate then TRANSITION_SPEED else 0
    $el = $(@getDOMNode())

    mouth_scaler = if @state.stance_segment <= 3 then -1 else 1
    mouth_x = if @state.stance_segment == 3 then 0 else -7.5

    switch @props.state
      when 'crafting'
        styles = 
          '.bubblemouth': { scaleX: mouth_scaler * 1.5, scaleY: 1.5, translateY: 4.35, translateX: mouth_x * 1.5  }
          '.the_handle':  { scale: 2.5, translateY: -8 }

      when 'results'
        styles = 
          '.bubblemouth': { scaleX: mouth_scaler, scaleY: 1, translateY: -8, translateX: mouth_x  }
          '.the_handle':  { scale: 1, translateY: -9 }

    _.each _.keys(styles), (selector) -> $el.find(selector).velocity styles[selector], {duration}

  ##
  # setSlidability
  # Inits jQuery UI slider and enables/disables it between states
  setSlidability : ->
    $slider_base = $(@getDOMNode()).find('.slider_base')
    if $slider_base.hasClass "ui-slider"
      $slider_base.slider(if @props.state == 'results' then 'disable' else 'enable') 
    else
      $slider_base.slider
        disabled: @props.state == 'results'
        min: -1
        max: 1
        step: .01
        value: @props.initial_stance
        slide: (ev, ui) => 
          # update the stance segment if it has changed. This facilitates the feedback atop
          # the slider changing from e.g. 'strong supporter' to 'neutral'
          segment = @getStanceSegmentFromSliderValue ui.value
          if @state.stance_segment != segment
            @setState
              stance_segment : segment
              stance : ui.value

  getSliderValue : -> $(@getDOMNode()).find('.ui-slider-handle').position().left / $el.find('.slider_base').innerWidth()

  render : ->
    R.div className: 'slider',
      R.div className:'slider_base', 
        R.div className:'ui-slider-handle', #jquery UI slider will pick an el with this class name up
          R.div className: 'the_handle'
          R.img className:'bubblemouth', src: if @state.stance_segment == 3 then '/assets/bubblemouth_neutral.png' else '/assets/bubblemouth.png'
          R.div className:'slider_feedback', 
            R.div className:'slider_feedback_label', "You are#{if @state.stance_segment == 3 then '' else ' a'}"
            R.div className:'slider_feedback_result', @props.stance_names[@state.stance_segment]
            R.div className:'slider_feedback_instructions', 'drag to change'

      R.div className:'slider_labels', 
        R.h1 className:"histogram_label histogram_label_support", 'Support'
        R.h1 className:"histogram_label histogram_label_oppose", 'Oppose'

  getStanceSegmentFromSliderValue : (value) ->
    if value == -1
      return 0
    else if value == 1
      return 6
    else if value <= 0.05 && value >= -0.05
      return 3
    else if value >= 0.5
      return 5
    else if value <= -0.5
      return 1
    else if value >= 0.05
      return 4
    else if value <= -0.05
      return 2

##
# DecisionBoard
# Handles the user's list of important points in crafting state. 
DecisionBoard = React.createClass
  displayName: 'DecisionBoard'

  componentDidMount : ->
    # make this a drop target
    $el = $(@getDOMNode()).parent()
    $el.droppable
      accept: ".community_point .point_content"
      drop : (ev, ui) =>
        ui.draggable.parent().velocity 'fadeOut', 200, => 
          @props.onPointShouldBeIncluded ui.draggable.parent().data('id')
        $el.removeClass "user_is_hovering_on_a_drop_target"
      out : (ev, ui) => $el.removeClass "user_is_hovering_on_a_drop_target"
      over : (ev, ui) => $el.addClass "user_is_hovering_on_a_drop_target"

  render : ->
    R.div className:'opinion_region', 
      R.div className:'decision_board_body',

        # only shown during crafting, but needs to be present always for animation
        R.div className: 'your_points',
          # your pros
          YourPoints
            state: @props.state
            points : @props.points         
            included_points: @props.included_points
            valence: 'pro'
            onPointShouldBeCreated: @props.onPointShouldBeCreated

          # your cons
          YourPoints
            state: @props.state
            points : @props.points 
            included_points: @props.included_points
            valence: 'con'
            onPointShouldBeCreated: @props.onPointShouldBeCreated

        # only shown during results, but needs to be present always for animation
        R.a className:'give_opinion_button', onClick: @props.toggleState, 'Give your Opinion'


##
# YourPoints
# List of important points for the active user. 
# Two instances used for Pro and Con columns. Shown as part of DecisionBoard. 
# Creates NewPoint instances.
YourPoints = React.createClass
  displayName: 'YourPoints'

  render : ->

    R.div className:"points_on_decision_board #{@props.valence}s_on_decision_board",
      R.h1 className:'points_heading_label',
        "Your #{@props.valence.charAt(0).toUpperCase()}#{@props.valence.substring(1)}s"

      R.ul null,
        for point_id in @props.included_points
          point = @props.points[point_id]
          if point.is_pro == (@props.valence == 'pro')
            Point 
              key: point.id
              id: point.id
              nutshell: point.nutshell
              text: point.text
              valence: @props.valence
              comment_count: point.comment_count
              author: point.user_id
              state: @props.state
              location_class: 'decision_board_point'

        R.div className:'add_point_drop_target',
          R.img className:'drop_target', src:"/assets/drop_target.png"
          R.span className:'drop_prompt',
            "Drag #{@props.valence} points from the #{if @props.valence == 'pro' then 'left' else 'right'} that resonate with you."

        NewPoint 
          valence: @props.valence
          onPointShouldBeCreated: @props.onPointShouldBeCreated

##
# CommunityPoints
# List of points contributed by others. 
# Shown in wing during crafting, in middle on results. 
CommunityPoints = React.createClass
  displayName: 'CommunityPoints'

  componentDidMount : ->
    # make this a drop target to facilitate removal of points
    $el = $(@getDOMNode())
    $el.droppable
      accept: ".decision_board_point.#{@props.valence} .point_content"
      drop : (ev, ui) =>
        ui.draggable.parent().velocity 'fadeOut', 200, => 
          @props.onPointShouldBeRemoved ui.draggable.parent().data('id')
          $el.removeClass "user_is_hovering_on_a_drop_target"
      out : (ev, ui) => $el.removeClass "user_is_hovering_on_a_drop_target"
      over : (ev, ui) => $el.addClass "user_is_hovering_on_a_drop_target"

  render : ->

    #filter to pros or cons & down to points that haven't been included
    points = _.filter _.values(@props.points), (pnt) =>
      is_correct_valence = pnt.is_pro == (@props.valence == 'pro')
      has_not_been_included = @props.state == 'results' || !_.contains(@props.included_points, pnt.id)
      is_correct_valence && has_not_been_included

    R.div className:"points_by_community #{@props.valence}s_by_community",
      R.h1 className:'points_heading_label',
        "Others' #{@props.valence.charAt(0).toUpperCase()}#{@props.valence.substring(1)}s"

      R.ul null, 
        for point in points
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
# Point
# A single point in a list. 
Point = React.createClass
  displayName: 'Point'

  setDraggability : ->
    # Ability to drag include this point if a community point, 
    # or drag remove for point on decision board
    # also: disable for results page

    $point_content = $(@getDOMNode()).find '.point_content'
    if $point_content.hasClass "ui-draggable"
      $point_content.draggable(if @props.state == 'results' then 'disable' else 'enable') 
    else
      $point_content.draggable
        revert: "invalid"
        disabled: @props.state == 'results'


  componentDidMount : -> @setDraggability()
  componentDidUpdate : -> @setDraggability()

  render : -> 
    R.li className: "point closed_point #{@props.location_class} #{@props.valence}", 'data-id':@props.id, 'data-role':'point', 'data-includers': [1,2],
      Avatar tag: R.a, user: @props.author, className:"point_author_avatar"
      
      R.div className:'point_content',
        R.div className:'point_nutshell',
          @props.nutshell
          if @props.text
            R.span className: 'point_details_tease', 
              @props.text[0..50]
              ' ...'

        R.a className:'open_point_link',
          "#{@props.comment_count} comment#{if @props.comment_count != 1 then 's' else ''}"

##
# NewPoint
# Handles adding a new point into the system. Only rendered when proposal is in Crafting state. 
# Manages whether the user has clicked "add a new point". If they have, show new point form. 
NewPoint = React.createClass
  displayName: 'NewPoint'

  getInitialState : ->
    editMode : false

  handleAddPointBegin : (ev) ->
    @setState { editMode : true }

  handleAddPointCancel : (ev) ->
    @setState { editMode : false }

  handleSubmitNewPoint : (ev) ->
    $form = $(@getDOMNode())
    @props.onPointShouldBeCreated
      nutshell : $form.find('#nutshell').val()
      text : $form.find('#text').val()
      is_pro : @props.valence == 'pro'
    @setState { editMode : false }

  render : ->
    #TODO: refactor HTML/CSS for new point after we get better sense of new point redesign
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
            R.textarea id:'nutshell', className:'newpoint_nutshell is_counted', cols:'28', maxLength:"140", name:'nutshell', pattern:'^.{3,}', placeholder:'Summarize your point (required)', required:'required'
            R.span className: 'count', 140
          R.div className:'newpoint_description_wrap',
            R.textarea id:'text', className:'newpoint_description', cols:'28', name:'text', placeholder:'Write a longer description (optional)', required:'required'
          R.div className:'newpoint_hide_name',
            R.input className:'newpoint-anonymous', type:'checkbox', id:"hide_name-#{@props.valence}", name:"hide_name-#{@props.valence}"
            R.label for:"hide_name-#{@props.valence}", title:'We encourage you not to hide your name from other users. Signing your point with your name lends it more weight to other participants.', 
              'Conceal your name'
          R.div className:'newpoint-submit',
            R.a className:'newpoint-cancel', onClick: @handleAddPointCancel,
              'cancel'
            R.input className:'button', action:'submit-point', type:'submit', value:'Done', onClick: @handleSubmitNewPoint

##
# Avatar
# Displays a user's avatar
# Supports straight up img src, or using the CSS-embedded b64 for each user
Avatar = React.createClass
  displayName: 'Avatar'

  getDefaultProps : ->
    user: -1 # defaults to anonymous user
    tag: R.img
    img_style: null #null will default to using the css-based b64 embedded images
    className: ''

  componentWillMount : ->
    derived_state = 
      className : "#{@props.className} avatar"
      id : "avatar-#{@props.user}"

    if @props.img_style
      user = fetch {url: "users/#{@props.user}?partial"}
      if !user || !user.avatar_file_name
        derived_state.filename = "/system/default_avatar/#{@props.img_style}_default-profile-pic.png"
      else
        derived_state.filename = "/system/avatars/#{user.id}/#{@props.img_style}/#{user.avatar_file_name}"

    @setState derived_state

  render : ->
    attrs = { className: @state.className, id: @state.id } 
    attrs.src = @state.filename if @props.img_style

    @transferPropsTo @props.tag attrs 


#####
# Mocks for activeREST
all_users = {} 

fetch = (options, callback, error_callback) ->
  if options.url[0..3] == 'user'
    return all_users[options.url]

  error_callback ||= (xhr, status, err) -> console.error 'Could not fetch data', status, err.toString()

  $.ajax
    url: options.url
    dataType: 'json'
    success: (data) =>
      if options.type == 'proposal' || true #assume fetching proposal
        # Build hash of user information
        data.users = $.parseJSON data.users
        for user in data.users
          all_users["users/#{user.id}?partial"] = user

        all_points = {}

        #TODO: return from server as a hash already?
        for point in data.points
          all_points[point.id] = point

        data.points = all_points

      console.log data
      callback data

    error: error_callback

#save assumes that data is a proposal page
save = (data) -> top_level_component.setProps data

##########################
## Application area

##
# load users' pictures
$.get Routes.get_avatars_path(), (data) -> $('head').append data

##
# Backbone routing
# Note: not committed to backbone. Want to experiment with other routing techniques too.
top_level_component = null
Router = Backbone.Router.extend

  routes :
    #"(/)" : "root"      
    ":proposal(/)": "proposal"
    ":proposal/results(/)": "results"
    #":proposal/points/:point(/)" : "openPoint"

  proposal : (long_id, state = 'crafting') ->

    if !top_level_component
      top_level_component = React.renderComponent Proposal({state : state}), document.getElementById('l_content_main_wrap')
      fetch {url: Routes.proposal_path long_id}, (data) => save {data}
    else
      top_level_component.setProps
        state : state

  results : (long_id) -> @proposal long_id, 'results'

app_router = new Router()

$(document).ready -> Backbone.history.start {pushState: true}
