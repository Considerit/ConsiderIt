R = React.DOM

all_users = {}

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



Point = React.createClass
  displayName: 'Point'

  render : -> 
    R.li className: "point closed_point community_point #{@props.valence}", 'data-id':@props.id, 'data-role':'point', 'data-includers': [1,2],
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

CommunityPoints = React.createClass
  displayName: 'CommunityPoints'

  render : ->
    R.div className:"community_#{@props.valence}s_region points_list_region",
      R.div className:"points_by_community #{@props.valence}s_by_community points_layout", 'data-state':@props.state, 'data-prior-state':@props.priorstate,
        R.div className:'points_heading_region',
          R.div className:'points_heading_view',
            R.h1 className:'points_heading_label', 'data-action':'expand-toggle',
              "Others' #{@props.valence.charAt(0).toUpperCase()}#{@props.valence.substring(1)}s"

          R.div className:'points_list_region',
            R.ul className:'point_list_collectionview',
              #for point in (if @props.state=='crafting' then @props.points[0..3] else @props.points[2..5])
              for point in (if @props.state=='crafting' then @props.points else @props.points)
                Point 
                  key: point.id
                  id: point.id
                  nutshell: point.nutshell
                  text: point.text
                  valence: @props.valence
                  comment_count: point.comment_count
                  author: point.user_id

            # R.div className:'points_footer_region',
            #   R.div className:'community_points_footer_view',
            #     R.a className:'toggle_expand_points button', 'data-action':'expand-toggle',
            #       "View all #{@props.points.length} Pros"


window.REACTProposal = React.createClass
  displayName: 'Proposal'
  componentWillMount : ->
    $.ajax
      url: Routes.proposal_path @props.long_id
      dataType: 'json'
      success: (data) =>
        data = @processInitialData data
        console.log 'after', data
        @setState {data: data}
      error: (xhr, status, err) =>
        console.error 'Could not fetch data', status, err.toString()

  componentDidMount : ->
    $('.histogram_base').slider()

  getInitialState : ->
    state : 'crafting',
    priorstate : 'results',
    data :
      proposal : {}
      pro_community_points : []
      con_community_points : []
      opinions : {0:[],1:[],2:[],3:[],4:[],5:[],6:[]}
      users : {}

  toggleState : (ev) ->
    @setState
      state : @state.priorstate, 
      priorstate : @state.state

  processInitialData : (data) ->

    data.users = $.parseJSON data.users

    data.pro_community_points = _.where data.points, {is_pro: true}
    data.con_community_points = _.where data.points, {is_pro: false}

    @num_opinions = data.opinions.length

    biggest_avatar_size = 50
    @avatar_size = biggest_avatar_size / Math.sqrt( (@num_opinions + 1)/10  )

    histogram_width = 684

    @num_small_segments = Math.floor(histogram_width/@avatar_size) - 2 * 3 - 1 #for the additional cols for the extremes+neutral 
    max_slider_val = 2.0


    opinions = {0:[],1:[],2:[],3:[],4:[],5:[],6:[]}
    histogram_small_segments = {}

    for i in [0..@num_small_segments]
      histogram_small_segments[i] = []

    for opinion in data.opinions
      opinions[opinion.stance_segment].push opinion
      small_segment = Math.floor(@num_small_segments * (opinion.stance + 1) / max_slider_val)
      histogram_small_segments[small_segment].push opinion


    data.opinions = opinions
    data.histogram_small_segments = histogram_small_segments

    users = {}
    for user in data.users
      if !user.avatar_file_name
        user.avatar_file_name = {small: '/system/default_avatar/small_default-profile-pic.png', large: '/system/default_avatar/large_default-profile-pic.png'}
      else
        user.avatar_file_name = {small: "/system/avatars/#{user.id}/small/#{user.avatar_file_name}", large: "/system/avatars/#{user.id}/large/#{user.avatar_file_name}"}
      users[user.id] = user

    all_users = users

    data



  render : ->    
    segment_is_extreme_or_neutral = (segment) => 
      segment == 0 || segment == @num_small_segments || segment == Math.floor(@num_small_segments / 2)

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

      #histogram
      R.div className:'proposal_histogram_region',
        R.div className:'histogram_layout', 'data-state':@state.state, 'data-prior-state':@state.priorstate,
          #for segment in [6..0]
          for segment in [@num_small_segments..0]
            R.div className:"histogram_bar #{if segment_is_extreme_or_neutral(segment) then 'extreme_or_neutral' else '' }", id:"segment-#{segment}", 'data-segment':segment, style: {width: if segment_is_extreme_or_neutral(segment) then "#{3 * @avatar_size}px" else "#{@avatar_size}px"},
              R.ul className:'histogram_bar_users',
                for opinion in @state.data.histogram_small_segments[segment] #@state.data.opinions[segment]
                  R.li id:"avatar-#{opinion.user_id}", className:"avatar segment-#{segment}", 'data-action':'user_opinion', 'data-id':opinion.user_id, style:{height:"#{@avatar_size}px", width:"#{@avatar_size}px"}, 'data-tooltip':'user_profile'

          R.div className:'histogram_base'

          R.div className:'feeling_labels', 
            R.h1 className:"histogram_label histogram_label_support",
              if @state.state == 'results' then 'Supporters' else 'Support'
            R.h1 className:"histogram_label histogram_label_oppose",
              if @state.state == 'results' then 'Opposers' else 'Oppose'

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

            #your reasons
            R.div className:'opinion_region',
              R.div className:'decision_board_layout', 'data-state':@state.state, 'data-prior-state':@state.priorstate,
                R.div className:'decision_board_body',
                  if @state.state == 'crafting'
                    R.div className:'decision_board_points_region',
                      R.div className:'decision_board_points_layout',
                        # your pros
                        R.div className:'points_list_region pros_on_decision_board_region',
                          R.div className:'points_on_decision_board pros_on_decision_board points_layout', 'data-state':@state.state,
                            R.div className:'points_heading_region',
                              R.div className:'points_heading_view',
                                R.h1 className:'points_heading_label',
                                  'Your Pros'
                            R.div className:'points_list_region',
                              R.ul className:'point_list_collectionview',
                                for nutshell, idx in []
                                  Point 
                                    nutshell: point.nutshell
                                    text: point.text
                                    valence: 'pro' 
                                    key: point.id
                                    comment_count: point.comment_count
                                    author: point.user_id
                            R.div className:'points_footer_region',
                              R.div className:'decision_board_points_footer_view',
                                R.div className:'add_point_drop_target',
                                  R.img className:'drop_target', src:"/assets/drop_target.png"
                                  R.span className:'drop_prompt',
                                    'Drag pro points from the left that resonate with you. '

                                NewPoint {valence: 'pro'}


                        # your cons
                        R.div className:'points_list_region cons_on_decision_board_region',
                          R.div className:'points_on_decision_board cons_on_decision_board points_layout', 'data-state':@state.state,
                            R.div className:'points_heading_region',
                              R.div className:'points_heading_view',
                                R.h1 className:'points_heading_label',
                                  'Your Cons'
                            R.div className:'points_list_region',
                              R.ul className:'point_list_collectionview',
                                for point in []
                                  Point 
                                    nutshell: point.nutshell
                                    text: point.text
                                    valence: 'con' 
                                    key: point.id
                                    comment_count: point.comment_count
                                    author: point.user_id

                            R.div className:'points_footer_region',
                              R.div className:'decision_board_points_footer_view',
                                R.div className:'add_point_drop_target',
                                  R.img className:'drop_target', src:"/assets/drop_target.png"
                                  R.span className:'drop_prompt',
                                    'Drag con points from the right that resonate with you. '

                                NewPoint {valence: 'con'}

                  else if @state.state == 'results'
                    R.a className:'give_opinion_button', onClick: @toggleState,
                      'Give your Opinion'

            #community cons
            CommunityPoints 
              state: @state.state
              priorstate: @state.priorstate
              points: @state.data.con_community_points
              valence: 'con'



