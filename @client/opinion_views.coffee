require './shared'
require './customizations'



save 
  key: 'opinion_views'
  active_views: {}




window.compose_opinion_views = (opinions, proposal, opinion_views) -> 
  opinion_views ?= fetch('opinion_views')
  opinion_views.active_views ?= {}
  active_views = opinion_views.active_views

  if !opinions
    opinions = opinionsForProposal(proposal)

  weights = {}
  salience = {}
  groups = {}

  has_groups = false
  for view_name, view of active_views
    has_groups ||= view.get_group?

  for o in opinions
    weight = 1
    min_salience = 1

    if has_groups
      u_groups = []

    u = o.user.key or o.user

    for view_name, view of active_views
      if view.get_salience?
        s = view.get_salience(u, o, proposal)
        if s < min_salience
          min_salience = s
      if view.get_weight?
        weight *= view.get_weight(u, o, proposal)
      if has_groups && view.get_group?
        ggg = view.get_group(u, o, proposal)
        if Array.isArray(ggg)
          u_groups = u_groups.concat ggg
        else 
          u_groups.push ggg
    weights[u] = weight
    salience[u] = min_salience
    if has_groups      
      groups[u] = u_groups

  {weights, salience, groups}
  

window.get_opinions_for_proposal = (opinions, proposal, weights) ->
  if !opinions
    opinions = opinionsForProposal proposal
  if !weights
    {weights, salience, groups} = compose_opinion_views(opinions, proposal)

  (o for o in opinions when weights[o.user] > 0)


window.get_user_groups_from_views = (groups) ->
  has_groups = Object.keys(groups).length > 0
  if has_groups
    group_set = new Set()
    for u, u_groups of groups
      for g in u_groups 
        group_set.add g
    Array.from group_set
  else 
    null 

window.group_colors = {}
window.get_color_for_groups = (group_array) ->
  if 'Unreported' not in group_array
    group_array = group_array.slice()
    group_array.push 'Unreported'
  colors = getColors(group_array.length)

  for color,idx in colors 
    if group_array[idx] not of group_colors
      if group_array[idx] == 'Unreported'
        color = 'black'
      group_colors[group_array[idx]] = color
  group_colors

window.get_color_for_group = (val) ->
  group_colors[val]


  # num_groups = group_array.length
  # hues = getNiceRandomHues num_groups
  # colors = group_colors
  # for hue,idx in hues 
  #   if group_array[idx] not of group_colors
  #     group_colors[group_array[idx]] = hsv2rgb hue, Math.random() / 2 + .5, Math.random() / 2 + .5
  # group_colors






default_filters = 
  everyone: 
    key: 'everyone'
    name: 'everyone'
    pass: (u) -> true 

  just_you: 
    key: 'just_you'
    name: 'Just you'
    pass: (u) -> 
      user = fetch(u)
      user.key == fetch('/current_user').user

  by_date: 
    key: 'date'
    name: 'By date'
    pass: (u) ->
      true
    options: ['Today', 'Past week', 'Custom']


window.influence_network = {}
window.influencer_scores = {}
influencer_scores_initialized = false 
add_influence = (influenced, influencer, amount) ->
  amount ?= 1
  influence_network[influenced] ?=
    influenced_by: {}
    influenced: {}
  influence_network[influencer] ?=
    influenced_by: {}
    influenced: {}

  influence_network[influencer].influenced[influenced] ?= 0
  influence_network[influencer].influenced[influenced] += amount

  influence_network[influenced].influenced_by[influencer] ?= 0
  influence_network[influenced].influenced_by[influencer] += amount


build_influencer_network = ->
  proposals = fetch '/proposals'
  points = fetch '/points'

  if !points.points || !proposals.proposals 
    return

  for point in points.points
    for user in point.includers or []
      continue if (user.key or user) == point.user
      add_influence user, point.user


  for proposal in proposals.proposals 
    opinions = opinionsForProposal proposal
    for opinion in opinions  
      continue if opinion.stance < 0.1

      add_influence opinion.user, proposal.user, opinion.stance

  max_influence = 0 
  for user, influence of influence_network
    num_influenced = Object.keys(influence.influenced).length
    total_influence = 0
    for u, amount of influence.influenced
      total_influence += amount
    if num_influenced + total_influence > max_influence
      max_influence = num_influenced + total_influence

    influencer_scores[user] = num_influenced + total_influence

  for user, influence of influence_network
    influencer_scores[user] /= Math.sqrt(max_influence)



  influencer_scores_initialized = true



default_weights = 

  weighed_by_substantiated: 
    key: 'weighed_by_substantiated'
    name: 'Gave reasons'
    label: 'Add weight to opinions that explained their stance with pro and/or con reasons.'
    weight: (u, opinion, proposal) ->
      point_inclusions = Math.min(8,opinion.point_inclusions?.length or 0) 
      .1 + point_inclusions
    icon: (color) -> 
      color ?= 'black'
      SVG
        width: 14
        height: 14
        viewBox: "0 0 23 23"
        dangerouslySetInnerHTML: __html: """
          <g id="Group-8" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
              <polygon id="Rectangle" stroke="#{color}" points="0 0 23 0 23 17.8367347 11.5 17.8367347 6.41522296 23 6.41522296 17.8367347 0 17.8367347"></polygon>
              <ellipse id="Oval" fill="#{color}" cx="4.66666683" cy="8.43750016" rx="1.5333335" ry="1.43750016"></ellipse>
              <line stroke="#{color}" x1="8.37575758" y1="8.5" x2="17.7575758" y2="8.5" id="Line-5" stroke="#979797" stroke-linecap="square"></line>
              <ellipse id="Oval" fill="#{color}" cx="4.66666683" cy="3.43750016" rx="1.5333335" ry="1.43750016"></ellipse>
              <line stroke="#{color}" x1="8.37575758" y1="3.5" x2="17.7575758" y2="3.5" id="Line-5" stroke="#979797" stroke-linecap="square"></line>
              <ellipse id="Oval" fill="#{color}" cx="4.66666683" cy="13.4375002" rx="1.5333335" ry="1.43750016"></ellipse>
              <line stroke="#{color}" x1="8.37575758" y1="13.5" x2="17.7575758" y2="13.5" id="Line-5" stroke="#979797" stroke-linecap="square"></line>
          </g>
        """    

  weighed_by_deliberative: 
    key: 'weighed_by_deliberative'
    name: 'Weighed tradeoffs'
    label: 'Add weight to opinions that acknowledge both pro and con tradeoffs.'
    weight: (u, opinion, proposal) ->
      point_inclusions = opinion.point_inclusions
      has_pro = false 
      has_con = false  
      for inc in point_inclusions or []
        pnt = fetch(inc)
        has_pro ||= pnt.is_pro
        has_con ||= !pnt.is_pro
      if has_con && has_pro
        2
      else 
        .1
    icon: (color) -> 
      color ?= 'black'
      SVG
        width: 14
        height: 14
        viewBox: "0 0 23 23"
        dangerouslySetInnerHTML: __html: """
          <g id="weigh" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
              <path fill="#{color}" d="M22.9670971,20.1929176 L22.9670971,20.1683744 C22.9815886,20.1324736 22.9922265,20.0943011 22.9987304,20.0548621 C22.9987304,20.0548621 22.9987304,20.0548621 22.9987304,20.0548621 C23.0004232,20.0293408 23.0004232,20.0036859 22.9987304,19.9781646 C22.9987304,19.9781646 22.9987304,19.9566893 22.9987304,19.9444177 C22.9987304,19.9321461 22.9987304,19.9229424 22.9987304,19.9137387 C22.9949502,19.8726516 22.9867644,19.8324016 22.9743971,19.7940906 L22.9743971,19.7940906 L18.9399256,8.02562631 C18.9506738,7.99615751 18.9588334,7.96529502 18.9642589,7.93358931 C18.9781664,7.81275485 18.9534152,7.68990536 18.8954544,7.59208741 C18.8374936,7.49426946 18.7510753,7.42950274 18.6552252,7.41204631 L13.4527523,6.45792942 C13.4151172,5.40049872 12.8144155,4.50934755 11.9927506,4.29199205 L11.9927506,0.460184995 C11.9927506,0.20603184 11.8293343,0 11.6277502,0 C11.426166,0 11.2627497,0.20603184 11.2627497,0.460184995 L11.2627497,4.29199205 C10.6280528,4.45682465 10.10874,5.03001236 9.89521475,5.80139883 L4.44940823,4.80126344 C4.35356714,4.78372914 4.25612781,4.81493501 4.1785425,4.88801078 C4.1009572,4.96108654 4.04958681,5.07004101 4.03574107,5.19088674 C4.03155491,5.23059483 4.03155491,5.27082675 4.03574107,5.31053484 L0.025602933,16.9992337 L0.025602933,16.9992337 C0.0132356207,17.0375447 0.00504978749,17.0777948 0.00126957058,17.1188818 C0.00126957058,17.1188818 0.00126957058,17.1403571 0.00126957058,17.1495608 C0.00126957058,17.1587645 0.00126957058,17.1710361 0.00126957058,17.1833077 C-0.000423190195,17.208829 -0.000423190195,17.2344839 0.00126957058,17.2600052 C0.00126957058,17.2600052 0.00126957058,17.2600052 0.00126957058,17.2600052 C0.00774547506,17.2994541 0.0183845876,17.3376312 0.0329029418,17.3735175 L0.0329029418,17.3980607 C0.0488060712,17.4339253 0.0684473538,17.4669431 0.0913030117,17.4962335 L0.699637073,18.2632085 C2.75983325,20.8606357 6.10004983,20.8606357 8.160246,18.2632085 L8.76858006,17.4962335 C8.79161354,17.465998 8.81126198,17.431936 8.82698013,17.3949928 L8.82698013,17.3704496 C8.84147172,17.3345488 8.85210954,17.2963764 8.85861351,17.2569373 C8.85861351,17.2569373 8.85861351,17.2569373 8.85861351,17.2569373 C8.86030627,17.231416 8.86030627,17.2057611 8.85861351,17.1802398 C8.85861351,17.1802398 8.85861351,17.1587645 8.85861351,17.1464929 C8.85861351,17.1342213 8.85861351,17.1250176 8.85861351,17.1158139 C8.85483329,17.0747269 8.84664746,17.0344768 8.83428014,16.9961658 L8.83428014,16.9961658 L5.01394224,5.83207783 L9.80274797,6.71256512 C9.85757198,7.80370794 10.5108448,8.69745358 11.3689468,8.85528909 C12.2270488,9.0131246 13.0556206,8.39194297 13.3554189,7.36602781 L18.1320579,8.2434472 L14.1584198,19.7879548 L14.1584198,19.7879548 C14.1460238,19.8262538 14.1378369,19.8665089 14.1340865,19.9076029 C14.1340865,19.9076029 14.1340865,19.9290782 14.1340865,19.9382819 C14.1340865,19.9474856 14.1340865,19.9597572 14.1340865,19.9720288 C14.1323937,19.9975501 14.1323937,20.023205 14.1340865,20.0487263 C14.1340865,20.0487263 14.1340865,20.0487263 14.1340865,20.0487263 C14.1405624,20.0881752 14.1512015,20.1263523 14.1657199,20.1622386 L14.1657199,20.1867818 C14.1816474,20.2226264 14.2012863,20.2556402 14.2241199,20.2849546 L14.832454,21.0519296 C16.8926502,23.6493568 20.2328667,23.6493568 22.2930629,21.0519296 L22.901397,20.2849546 C22.9264857,20.2581473 22.9485857,20.2271881 22.9670971,20.1929176 Z M15.0490209,19.5087759 L18.5627585,9.26505789 L22.0959627,19.5087759 L15.0490209,19.5087759 Z M0.916203999,16.7200548 L4.44940823,6.48247262 L7.96314577,16.7200548 L0.916203999,16.7200548 Z M1.24227106,17.6404248 L7.63707871,17.6404248 C5.86694476,19.8538124 3.01240501,19.8538124 1.24227106,17.6404248 L1.24227106,17.6404248 Z M11.6277502,7.95813251 C11.02159,7.94807762 10.5340258,7.32653669 10.5327488,6.56223802 C10.5327488,6.51928742 10.5327488,6.48247262 10.5327488,6.43952202 C10.5385866,6.42154559 10.5434641,6.40309702 10.5473489,6.38429982 C10.5510895,6.34660935 10.5510895,6.308478 10.5473489,6.27078753 C10.6654865,5.57212652 11.1829331,5.09866324 11.7464056,5.17365144 C12.3098781,5.24863963 12.7375156,5.84787683 12.7373515,6.56223802 C12.7373515,6.60518862 12.7373515,6.64507132 12.7373515,6.68802192 C12.7187894,6.74960828 12.7113093,6.81562397 12.7154515,6.88129962 C12.5971458,7.51670329 12.1454062,7.96392904 11.6277502,7.95813251 L11.6277502,7.95813251 Z M15.375088,20.4291459 L21.7698956,20.4291459 C19.9997617,22.6425334 17.1452219,22.6425334 15.375088,20.4291459 L15.375088,20.4291459 Z" id="Shape" fill-rule="nonzero"></path>
          </g>
          """    

  weighed_by_influence: 
    key: 'weighed_by_influence'
    name: 'Influence'
    label: 'Add weight to the opinions of people who have contributed proposals and arguments that other people have found valuable.'
    weight: (u, opinion, proposal) ->
      if !influencer_scores_initialized
        build_influencer_network()

      if !influencer_scores_initialized
        return 1 # still waiting for data to be fetched

      u = u.key or u 
      .1 + (influencer_scores[u] or 0)
    icon: (color) -> 
      color ?= 'black'
      SVG
        width: 14
        height: 14
        viewBox: "0 0 23 23"
        dangerouslySetInnerHTML: __html: """
          <g id="influence" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
              <ellipse id="Oval" fill="#{color}" fill-rule="nonzero" transform="translate(11.364066, 2.300000) scale(-1, 1) translate(-11.364066, -2.300000) " cx="11.3640662" cy="2.3" rx="2.39243499" ry="2.3"></ellipse>
              <path d="M12.5828538,4.6 L11.3640662,4.6 L10.1452786,4.6 C7.83466033,4.6 5.98108747,6.46815021 5.98108747,8.79694019 L5.98108747,13.403338 C5.98108747,13.940751 6.41274142,14.3502086 6.92056961,14.3502086 C7.4537892,14.3502086 7.86005174,13.9151599 7.86005174,13.403338 L7.86005174,8.7201669 C7.86005174,8.54102921 7.98700879,8.41307371 8.16474865,8.41307371 C8.34248851,8.41307371 8.46944556,8.54102921 8.46944556,8.7201669 L8.46944556,13.2753825 L8.46944556,22.0531293 C8.46944556,22.5905424 8.90109951,23 9.4089277,23 C9.94214729,23 10.3484098,22.5649513 10.3484098,22.0531293 L11.0085865,13.2753825 L11.6687631,13.2753825 L12.3797226,22.0531293 C12.3797226,22.5905424 12.8113765,23 13.3192047,23 C13.8524243,23 14.2586868,22.5649513 14.2586868,22.0531293 L14.2586868,13.2497914 L14.2586868,8.7201669 C14.2586868,8.54102921 14.3856439,8.41307371 14.5633837,8.41307371 C14.7411236,8.41307371 14.8680806,8.54102921 14.8680806,8.7201669 L14.8680806,13.403338 C14.8680806,13.940751 15.2997346,14.3502086 15.8075628,14.3502086 C16.3407824,14.3502086 16.7470449,13.9151599 16.7470449,13.403338 L16.7470449,8.79694019 C16.7470449,6.49374131 14.8934721,4.6 12.5828538,4.6 Z" id="Path" fill="#{color}" fill-rule="nonzero" transform="translate(11.364066, 13.800000) scale(-1, 1) translate(-11.364066, -13.800000) "></path>
              <path d="M22.3105861,0 L18.7361296,0 C18.35544,0 18.0468076,0.283811841 18.0468076,0.633885886 C18.0468076,0.983959931 18.35544,1.26777177 18.7361296,1.26777177 L20.6463788,1.26777177 L16.9489473,4.66785115 C16.6797441,4.91540471 16.6797441,5.31678126 16.9489473,5.56433482 C17.2181506,5.81188839 17.6546293,5.81188839 17.9238325,5.56433482 L21.621264,2.16425545 L21.6213559,3.92088002 C21.6213559,4.27095406 21.9299884,4.5547659 22.310678,4.5547659 C22.6913675,4.5547659 23,4.27095406 23,3.92088002 L23,0.633885886 C22.9999081,0.283727323 22.6912756,0 22.3105861,0 Z" id="Path" fill="#{color}" fill-rule="nonzero"></path>
              <path d="M5.56354114,0 L1.98908469,0 C1.60839511,0 1.29976266,0.283811841 1.29976266,0.633885886 C1.29976266,0.983959931 1.60839511,1.26777177 1.98908469,1.26777177 L3.89933392,1.26777177 L0.201902425,4.66785115 C-0.0673008082,4.91540471 -0.0673008082,5.31678126 0.201902425,5.56433482 C0.471105657,5.81188839 0.907584371,5.81188839 1.1767876,5.56433482 L4.8742191,2.16425545 L4.87431101,3.92088002 C4.87431101,4.27095406 5.18294346,4.5547659 5.56363305,4.5547659 C5.94432263,4.5547659 6.25295508,4.27095406 6.25295508,3.92088002 L6.25295508,0.633885886 C6.25286317,0.283727323 5.94423072,0 5.56354114,0 Z" id="Path" fill="#{color}" fill-rule="nonzero" transform="translate(3.126478, 2.875000) scale(-1, 1) translate(-3.126478, -2.875000) "></path>
              <path d="M22.3105861,16.1 L18.7361296,16.1 C18.35544,16.1 18.0468076,16.3838118 18.0468076,16.7338859 C18.0468076,17.0839599 18.35544,17.3677718 18.7361296,17.3677718 L20.6463788,17.3677718 L16.9489473,20.7678511 C16.6797441,21.0154047 16.6797441,21.4167813 16.9489473,21.6643348 C17.2181506,21.9118884 17.6546293,21.9118884 17.9238325,21.6643348 L21.621264,18.2642555 L21.6213559,20.02088 C21.6213559,20.3709541 21.9299884,20.6547659 22.310678,20.6547659 C22.6913675,20.6547659 23,20.3709541 23,20.02088 L23,16.7338859 C22.9999081,16.3837273 22.6912756,16.1 22.3105861,16.1 Z" id="Path" fill="#{color}" fill-rule="nonzero" transform="translate(19.873522, 18.975000) scale(1, -1) translate(-19.873522, -18.975000) "></path>
              <path d="M5.56354114,16.1 L1.98908469,16.1 C1.60839511,16.1 1.29976266,16.3838118 1.29976266,16.7338859 C1.29976266,17.0839599 1.60839511,17.3677718 1.98908469,17.3677718 L3.89933392,17.3677718 L0.201902425,20.7678511 C-0.0673008082,21.0154047 -0.0673008082,21.4167813 0.201902425,21.6643348 C0.471105657,21.9118884 0.907584371,21.9118884 1.1767876,21.6643348 L4.8742191,18.2642555 L4.87431101,20.02088 C4.87431101,20.3709541 5.18294346,20.6547659 5.56363305,20.6547659 C5.94432263,20.6547659 6.25295508,20.3709541 6.25295508,20.02088 L6.25295508,16.7338859 C6.25286317,16.3837273 5.94423072,16.1 5.56354114,16.1 Z" id="Path" fill="#{color}" fill-rule="nonzero" transform="translate(3.126478, 18.975000) scale(-1, -1) translate(-3.126478, -18.975000) "></path>
          </g>
        """

toggle_group = (view, replace_existing) ->
  _activate_opinion_view(view, 'group', replace_existing)


toggle_weight = (view, replace_existing) -> 
  _activate_opinion_view(view, 'weight', replace_existing)

toggle_opinion_filter = (view, replace_existing) -> 
  _activate_opinion_view(view, 'filter', replace_existing)

set_opinion_date_filter = (view) -> 
  _activate_opinion_view(view, 'date-filter', true)


_activate_opinion_view = (view, view_type, replace_existing) ->  
  opinion_views = fetch('opinion_views')
  opinion_views.active_views ?= {}
  active_views = opinion_views.active_views

  view_name = view.key or view.label

  if view_name of active_views && !replace_existing
    delete active_views[view_name] #activating an active view toggles it off
  else 
    if view_type == 'filter'
      if view_name == default_filters.just_you.key
        to_delete = []
        for k,v of active_views
          if v.view_type == view_type
            to_delete.push k 
        for k in to_delete
          delete active_views[k]
      else if active_views[default_filters.just_you.key]
        delete active_views[default_filters.just_you.key]

    active_views[view_name] = 
      key: view.key
      name: view.name 
      view_type: view_type
      get_salience: (u, opinion, proposal) ->
        if view.salience?
          view.salience u, opinion, proposal
        else if !view.pass? || view.pass(u, opinion, proposal)
          1
        else if opinion_views.enable_comparison 
          .1
        else 
          0
      get_weight: (u, opinion, proposal) ->
        if view.weight?
          view.weight(u, opinion, proposal)
        else if opinion_views.enable_comparison || (!view.pass? || view.pass?(u, opinion, proposal))
          1
        else 
          0

      get_group: if view.group? then (u, opinion, proposal) -> 
        view.group(u, opinion, proposal) or 'Unreported'
      options: if view.group? then view.options


  # invalidate_proposal_sorts()
  save opinion_views




FilterOpinionsIcon = (opts) ->
  if opts.height && !opts.width 
    opts.width = opts.height * 72 / 61

  SVG 
    dangerouslySetInnerHTML: __html: '<g id="filter2" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><circle id="Oval" fill="#FFFFFF" cx="12" cy="16" r="9"></circle><circle id="Oval" fill="#FFFFFF" cx="35" cy="16" r="9"></circle><circle id="Oval" fill="#FFFFFF" cx="35" cy="47" r="9"></circle><circle id="Oval" fill="#FFFFFF" cx="59" cy="16" r="9"></circle><line x1="6.5" y1="31.5" x2="67.5" y2="32.5" id="Line" stroke="#FFFFFF" stroke-width="3" stroke-linecap="square" stroke-dasharray="0,5"></line></g>'
    height: opts.height or 61
    width: opts.width or 72
    viewBox: "0 0 72 61" 

WeighOpinionsIcon = (opts) ->
  if opts.height && !opts.width 
    opts.width = opts.height * 72 / 61

  SVG 
    dangerouslySetInnerHTML: __html: '<g id="weigh" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><circle id="Oval" fill="#FFFFFF" cx="10" cy="40" r="7"></circle><circle id="Oval" fill="#FFFFFF" cx="61" cy="38" r="10"></circle><circle id="Oval" fill="#FFFFFF" cx="34" cy="29" r="18"></circle><line x1="1.5" y1="48.5" x2="70.5" y2="48.5" id="Line" stroke="#FFFFFF" stroke-width="2" stroke-linecap="square"></line></g>'
    height: opts.height or 61
    width: opts.width or 72
    viewBox: "0 0 72 61" 








OpinionViews = ReactiveComponent
  displayName: 'OpinionViews'

  render : -> 

    clear_all = ->
      to_remove = []
      for k,v of opinion_views.active_views
        if v.view_type in ['filter', 'weight'] || k == 'group_by'
          to_remove.push v
      for view in to_remove
        toggle_opinion_filter view

      for attr in ['group_by', 'selected_vals_for_attribute', 'visible_attributes']
        if opinion_views_ui[attr]
          delete opinion_views_ui[attr]
      save opinion_views_ui

    has_other_filters = get_participant_attributes().length > 0
    opinion_views = fetch 'opinion_views'
    opinion_views_ui = fetch 'opinion_views_ui'
    view_buttons = [ 
      {
        label: 'All opinions'
        callback: clear_all
      }
      {
        label: 'Just you'
        callback: ->
          clear_all()
          toggle_opinion_filter default_filters.just_you
      }, 
      {
        label: 'More views'
        callback: (item, previous_state) -> 
          if previous_state == 'More views'
            opinion_views_ui.active = 'All opinions'
            save opinion_views_ui
          clear_all()
      }
    ]

    DIV 
      style: (@props.style or {})
      className: 'filter_opinions_to'

      DIV 
        style: 
          marginTop: 0
          lineHeight: 1

        if customization('verification-by-pic') 
          VerificationProcessExplanation()

        ToggleButtons view_buttons, opinion_views_ui

      if opinion_views_ui.active == 'More views'
        needs_expansion = @props.additional_width && @props.style?.width
        width = 0
        if needs_expansion 
          if has_other_filters 
            width = @props.style.width + @props.additional_width 
          else 
            width = Math.min(660, @props.style.width + @props.additional_width)

        DIV 
          style: 
            width: if width then width
            maxWidth: if !has_other_filters then 660
            position: 'relative'
            right: if needs_expansion then width - @props.style.width 
            border: '1px solid #B6B6B6'
            borderRadius: 8
            marginTop: 18
            padding: '18px 24px'

          DIV 
            style: 
              position: 'absolute'
              left: (document.querySelector('[data-view-state="More views"]')?.offsetLeft or 60) + 35 - (if needs_expansion then (@props.style.width + @props.additional_width - width ) else 0)
              top: -17

            dangerouslySetInnerHTML: __html: """<svg width="25px" height="13px" viewBox="0 0 25 13" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g id="Page-2" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g id="Artboard" transform="translate(-1086.000000, -586.000000)" fill="#FFFFFF" stroke="#979797"><polyline id="Path" points="1087 599 1098.5 586 1110 599"></polyline></g></g></svg>"""

          DIV 
            style: 
              display: 'flex'

            OpinionFilters()
            OpinionWeights()



DateFilters = ->
  opinion_views = fetch 'opinion_views'

  cb = (activated) ->
    pass = (u, opinion, proposal) -> 
      date = new Date(opinion.updated_at).getTime()
      now = Date.now()

      earliest = latest = null
      if activated.label != 'Custom'
        clear_custom_date()

      if activated.label == 'Today'
        earliest = now - 1000 * 60 * 60 * 24

      else if activated.label == 'Past week'
        earliest = now - 1000 * 60 * 60 * 24 * 7

      else if activated.label == 'Custom'

        if date_toggle_state.start
          earliest = date_toggle_state.start

        if date_toggle_state.end 
          latest = date_toggle_state.end

      (earliest == null || earliest <= date) && (latest == null || latest >= date) 

    view = 
      key: 'date-filter'
      salience: (u, opinion, proposal) -> if pass(u, opinion, proposal) then 1 else .1
      weight:   (u, opinion, proposal) -> if pass(u, opinion, proposal) then 1 else .1

    set_opinion_date_filter view

  clear_custom_date = ->
    date_toggle_state.start = null
    date_toggle_state.end = null
    save date_toggle_state


  has_other_filters = get_participant_attributes().length > 0


  date_toggle_state = fetch 'opinion-date-filter'
  date_options = [
    {
      label: 'All'
      callback: ->
        clear_custom_date()
        if opinion_views.active_views['date-filter']
          delete opinion_views.active_views['date-filter']
          save opinion_views
    }
    { label: 'Today', callback: cb }
    { label: 'Past week', callback: cb }
    { label: 'Custom', callback: cb }
  ]

  DIV 
    className: 'grays' # for toggle buttons
    SPAN 
      className: 'opinion_view_name'
      style: 
        paddingRight: 8
      'Filter opinions by date:'

    ToggleButtons date_options, date_toggle_state, 
      display: if has_other_filters then 'inline-block'
      marginTop: if !has_other_filters then 8

    if date_toggle_state.active == 'Custom'

      DIV 
        className: 'opinion-date-filter'

        LABEL null,
          'From:'
        INPUT 
          type: 'date'
          id: 'start'
          name: 'opinion-start'
          onChange: (e) ->
            date_toggle_state.start = new Date(e.target.value).getTime()
            save date_toggle_state
            cb date_options[3]            
            e.preventDefault()

        LABEL null,
          'To:'
        INPUT 
          type: 'date'
          id: 'end'
          name: 'opinion-end'
          onChange: (e) ->
            date_toggle_state.end = new Date(e.target.value).getTime()
            save date_toggle_state
            cb date_options[3]
            e.preventDefault()


# Attributes are additional filters that can distinguish amongst all 
# participants. We take them from legacy opinion views, and from 
# qualifying user_tags
window.get_participant_attributes = -> 
  attributes = [] 
  is_admin = fetch('/current_user').is_admin
  show_others = !customization('hide_opinions') || is_admin
  custom_filters = customization 'opinion_views'
  user_tags = customization 'user_tags'

  if show_others
    if custom_filters
      for filter in custom_filters
        if filter.visibility == 'open' || is_admin
          if filter.pass
            attributes.push _.extend {}, filter, 
              name: filter.label
              options: [true, false]

    if user_tags
      for tag in user_tags 
        name = tag.key
        if (tag.visibility == 'open' || is_admin) && \
           (tag.self_report?.input in ['dropdown', 'boolean', 'checklist']) && \
           !tag.no_opinion_view # set in the user_tags customization to prevent an opinion view from automatically getting created

          attributes.push 
            key: name
            name: tag.view_name or tag.name or tag.self_report?.question or name
            pass: do(name) -> (u, value) -> 
              u.tags[name] == value
            options: tag.self_report.options or (if tag.self_report.input == 'boolean' then [true, false])
            input_type: tag.self_report?.input

  attributes


OpinionFilters = ReactiveComponent
  displayName: 'OpinionFilters'
  render: -> 

    opinion_views = fetch 'opinion_views'
    opinion_views_ui = fetch 'opinion_views_ui'

    is_admin = fetch('/current_user').is_admin
    show_others = !customization('hide_opinions') || is_admin

    attributes = get_participant_attributes()

    active_filters = {}
    for k,v of opinion_views.active_views
      if v.view_type == 'filter'
        active_filters[k] = v 

    if !opinion_views_ui.initialized      
      initial_filter = null 

      if !show_others
        toggle_opinion_filter default_filters.just_you
      # else if dfault = customization('opinion_filters_default')
      #   for filter in filters 
      #     if filter.label == dfault 
      #       toggle_opinion_filter filter 
      #       break 
      opinion_views_ui.initialized = true 
      save opinion_views_ui


    update_view_for_attribute = (attribute) ->
      if attribute.key 
        attribute = attribute.key

      # having no selections for an attribute paradoxically means that all values are valid.
      has_one_enabled = false 
      for val,enabled of opinion_views_ui.selected_vals_for_attribute[attribute]
        has_one_enabled ||= enabled
      if !has_one_enabled
        opinion_views_ui.selected_vals_for_attribute[attribute] = {}

      pass = (u) -> 
        user = fetch(u)
        val_for_user = user.tags[attribute]
        is_array = Array.isArray(val_for_user)

        passing_vals = (val for val,enabled of opinion_views_ui.selected_vals_for_attribute[attribute] when enabled)

        passes = false
        for passing_val in passing_vals
          if passing_val == 'true'
            passing_val = true 
          else if passing_val == 'false'
            passing_val = false
          passes ||= val_for_user == passing_val || (is_array && passing_val in val_for_user)

        passes 

      view = 
        key: attribute
        # pass: pass
        salience: (u) -> if pass(u) then 1 else .1
        weight:   (u) -> if pass(u) then 1 else .1

      toggle_opinion_filter view, has_one_enabled

    show_all_not_available = !show_others

    if attributes.length > 0
      opinion_views_ui.visible_attributes ?= {}
      opinion_views_ui.selected_vals_for_attribute ?= {}

    for attribute, cnt in attributes
      opinion_views_ui.selected_vals_for_attribute[attribute.key] ?= {}

    toggle_attribute_visible = (attribute) ->
      opinion_views_ui.visible_attributes[attribute.key] = !opinion_views_ui.visible_attributes[attribute.key]
      if !opinion_views_ui.visible_attributes[attribute.key] && opinion_views_ui.group_by == attribute.key
        toggle_group opinion_views.active_views.group_by
        opinion_views_ui.group_by = null
      save opinion_views_ui

    if opinion_views_ui.group_by
      all_groups = opinion_views.active_views.group_by.options
      group_colors = get_color_for_groups all_groups






    DIV 
      style:
        flex: 1
        paddingRight: 24



      DateFilters()


      if attributes.length > 0 
        DIV 
          style: 
            marginTop: 18



          DIV 
            style: 
              display: 'flex'
            SPAN 
              className: 'opinion_view_name'
              style: 
                paddingRight: 16
                whiteSpace: 'nowrap'
              'More filters:'


            UL 
              style: 
                listStyle: 'none'
                display: 'inline'


              for attribute, cnt in attributes
                continue if opinion_views_ui.visible_attributes[attribute.key]
                do (attribute) ->
                  LI 
                    style: 
                      display: 'inline-block'
                    BUTTON
                      className: 'filter opinion_view_button' 
                      onClick: -> toggle_attribute_visible(attribute)
                      onKeyDown: (e) => 
                        if e.which == 13 || e.which == 32 # ENTER or SPACE
                          toggle_attribute_visible(attribute)
                          e.preventDefault()

                      "+ #{attribute.name}"


          for attribute, cnt in attributes
            continue if !opinion_views_ui.visible_attributes[attribute.key]
            do (attribute) => 

              DIV 
                className: 'attribute_group'

                BUTTON
                  className: 'attribute_group_header'
                  onClick: -> toggle_attribute_visible(attribute)
                  onKeyDown: (e) => 
                    if e.which == 13 || e.which == 32 # ENTER or SPACE
                      toggle_attribute_visible(attribute)
                      e.preventDefault()

                  "#{attribute.name}"

                  SPAN 
                    style: 
                      float: 'right'
                    'x'

                if attribute.render 
                  attribute.render()
                else 
                  UL 
                    className: 'attribute_container' 

                    for val in attribute.options
                      is_grouped = opinion_views_ui.group_by == attribute.key
                      checked = !!opinion_views_ui.selected_vals_for_attribute[attribute.key][val]

                      do (val) => 
                        LI 
                          style: 
                            display: 'inline-block'
                          LABEL 
                            className: "attribute_value_selector"

                            SPAN
                              className: if is_grouped then 'toggle_switch' else ''

                              INPUT 
                                type: 'checkbox'
                                # className: 'bigger'
                                value: val
                                checked: checked
                                onChange: (e) ->
                                  # create a view on the fly for this attribute
                                  opinion_views_ui.selected_vals_for_attribute[attribute.key][val] = e.target.checked
                                  save opinion_views_ui
                                  update_view_for_attribute(attribute)

                              if is_grouped
                                SPAN 
                                  className: 'toggle_switch_circle'
                                  style: 
                                    backgroundColor: if checked then group_colors[val]

                            SPAN 
                              className: 'attribute_value_value'
                              "#{val}"

      if attributes.length > 0 
        cur_val = -1
        for attr, idx in attributes
          if opinion_views_ui.group_by == attr.key 
            cur_val = idx
        DIV 
          style: 
            marginTop: 18

          LABEL 
            style: 
              display: 'flex'
              alignItems: 'center'

            SPAN 
              className: 'opinion_view_name'
              style: 
                paddingRight: 16

              "Group opinions by:"  

            SELECT 
              style: 
                maxWidth: '100%'
                marginRight: 12
                borderColor: '#bbb'
                backgroundColor: '#f9f9f9'
                borderRadius: 2

              onChange: (ev) -> 
                if ev.target.value != null
                  attribute = attributes[ev.target.value]
                  opinion_views_ui.group_by = attribute?.key
                else 
                  opinion_views_ui.group_by = null

                if opinion_views_ui.group_by && (!opinion_views_ui.visible_attributes[opinion_views_ui.group_by] ||  \
                                    (o for o,val of opinion_views_ui.selected_vals_for_attribute[opinion_views_ui.group_by] when val).length == 0)
                              # if no attribute value is selected, which mean all are enabled, select them all
                  opinion_views_ui.visible_attributes[opinion_views_ui.group_by] = true 
                  for option in attribute.options 
                    opinion_views_ui.selected_vals_for_attribute[attribute.key][option] = true
                save opinion_views_ui

                if opinion_views_ui.group_by
                  view = 
                    key: 'group_by'
                    name: attribute.name
                    group: (u, opinion, proposal) -> 
                      group_val = fetch(u).tags[opinion_views_ui.group_by] or 'Unreported'
                      if attribute.input_type == 'checklist'
                        group_val.split(',')
                      else 
                        group_val
                    options: attribute.options

                  toggle_group view, true

                else 
                  delete opinion_views.active_views.group_by
                  save opinion_views


              value: cur_val

              OPTION 
                value: null
                ""
              for attribute,idx in attributes 
                do (attribute) =>
                  OPTION 
                    value: idx 
                    attribute.name or attribute.question

            HelpIcon 'Opinions will be colorized based on this attribute so you can see differences between groups.'


OpinionWeights = ReactiveComponent
  displayName: 'OpinionWeights'
  render: ->
    opinion_views = fetch 'opinion_views'

    activated_weights = {}
    for k,v of opinion_views.active_views
      if v.view_type == 'weight'
        activated_weights[k] = v 

    DIV 
      style: 
        paddingLeft: 36
        borderLeft: '1px solid #DEDDDD' 

      DIV 
        className: 'opinion_view_name'
        style: 
          textAlign: 'center'
          marginBottom: 12
        'Weigh opinions'

      UL 
        style: 
          listStyle: 'none'

        for k,v of default_weights
          do (k,v) ->
            LI 
              style: 
                marginBottom: 8
                display: 'flex'
                alignItems: 'center'

              BUTTON 
                className: "weight opinion_view_button #{if activated_weights[k] then 'active' else ''}"
                onClick: ->
                  toggle_weight v
                onKeyDown: (e) -> 
                  if e.which == 13 || e.which == 32 # ENTER or SPACE
                    toggle_weight v
                    e.preventDefault()


                if v.icon
                  v.icon if activated_weights[k] then 'white'

                SPAN 
                  style: 
                    paddingLeft: if v.icon then 10

                  v.name

              HelpIcon v.label,
                width: 18
                height: 18



VerificationProcessExplanation = ReactiveComponent
  displayName: 'VerificationProcessExplanation'
  render: -> 
    users = fetch '/users'
    callout = "about verification"
    DIV 
      style: 
        position: 'absolute'
        right: -sizeWhenRendered(callout, {fontSize: 12}).width
        top: -14

      SPAN 
        style: 
          color: "#aaa"
          fontSize: 14

        SPAN 
          style: 
            textDecoration: 'underline'
            cursor: 'pointer'
            color: if @local.describe_process then logo_red
          onClick: => 
            @local.describe_process = !@local.describe_process
            save @local
          callout

      if @local.describe_process
        para = 
          marginBottom: 20

        DIV 
          style: 
            textAlign: 'left'
            position: 'absolute'
            right: 0
            top: 40
            width: 650
            zIndex: 999
            padding: "20px 40px"
            backgroundColor: '#eee'
            #boxShadow: '0 1px 2px rgba(0,0,0,.3)'
            fontSize: 18

          SPAN 
            style: cssTriangle 'top', '#eee', 16, 8,
              position: 'absolute'
              right: 50
              top: -8


          DIV style: para,

            """Filters help us understand the opinions of the stakeholder groups. \
               Filters are conjunctive: only users that pass all active filters are shown.
               These are the filters:"""

          DIV style: para,
            SPAN 
              style:
                fontWeight: 700
              'Users'
            """. Verified users have emailed us a verification image to validate their account.  
               We have also verified a few other people via other media channels, like Reddit. """
            SPAN style: fontStyle: 'italic', 
              "Verification results shown below."

          DIV style: para,
            SPAN 
              style:
                fontWeight: 700
              'Miners'

            ". Miners are "
            OL 
              style: 
                marginLeft: 20 
              LI null,
                'Users who control a mining pool with > 1% amount of hashrate'
              LI null,
                'Users who control > 1% amount of hashrate'
            'We verify hashrate by consulting '
            A 
              href: 'https://blockchain.info/pools'
              target: '_blank'
              style: 
                textDecoration: 'underline'

              'https://blockchain.info/pools'
            '.'

          DIV style: para,
            SPAN 
              style:
                fontWeight: 700
              'Developers'

            """. Bitcoin developers self-report by editing their user profile. If we recognize 
               someone as a committer or maintainer of Core or XT, we assign it. 
               We aren’t satisfied by our criteria for developer. We hope to work with 
               the community to define a more robust standard for 'reputable technical voice'.""" 

          DIV style: para,
            SPAN 
              style:
                fontWeight: 700
              'Businesses'

            """. Bitcoin businesses self-report by editing their user profile. Business accounts
               are either users who operate the business or an account that will represent that 
               businesses' official position.""" 

          DIV style: para,
            "These filters aren’t perfect. If you think there is a problem, email us at "
            A
              href: "mailto:admin@consider.it"
              style: 
                textDecoration: 'underline'
              'admin@consider.it'

            ". We will try to make a more trustless process in the future."

          DIV 
            style: {}

            DIV 
              style: 
                fontWeight: 600
                fontSize: 26

              'Verification status'

            for user in users.users 
              user = fetch user 
              if user.tags.verified && user.tags.verified.toLowerCase() not in ['no', 'false']
                DIV 
                  style:
                    marginTop: 20

                  DIV 
                    style: 
                      fontWeight: 600

                    user.name


                  if user.tags.verified?.indexOf('http') == 0
                    IMG 
                      src: user.tags.verified
                      style: 
                        width: 400
                  else 
                    DIV 
                      style: 
                        fontStyle: 'italic'

                      user.tags.verified



styles += """

  button.opinion_view_button {
    border: 1px solid #E0E0E0;
    border-bottom-color: #aaa;
    background-color: #F0F0F0;
    // box-shadow: inset 0 -1px 1px 0 rgba(0,0,0,0.62);
    border-radius: 8px;    
    font-size: 12px;
    color: #000000;
    font-weight: 400;
  }
  button.opinion_view_button.filter {
    padding: 4px 12px;
    margin: 0 8px 8px 0;

  }
  button.opinion_view_button.weight {
    width: 100%;
    display: flex;
    padding: 4px 12px 4px 12px;
    text-align: left;
    align-items: center;
    margin-right: 12px;

  }

  button.opinion_view_button.active {
    background-color: #{focus_blue};
    color: white;
  }

  .opinion_view_label input.opinion_view_checker {
    position: relative;
    top: 3px;
  }
  .opinion_view_label .opinion_view_label_block {
    width: 90%;
    padding-left: 12px;
    display: inline-block;
    cursor: pointer;
  }
  .opinion_view_name {
    font-size: 14px;
    font-weight: 600;
  } 

  .attribute_group {
    margin-top: 8px;
  }

  .attribute_container {
    border: 1px solid #D9D9D9;
    border-top: none;
    padding: 2px 4px 4px 4px;
    border-radius: 0 0 8px 8px;
  }
  .attribute_group .attribute_group_header {
    background: #F0F0F0;
    border: 1px solid #E0E0E0;
    border-radius: 8px 8px 0 0;
    font-size: 12px;
    width: 100%;
    padding: 4px 12px;
    text-align: left;
  }

  .attribute_value_selector {
    display: block; 
    cursor: pointer;
    margin-right: 18px;
  }
  .attribute_value_selector input {
    position: relative;
    top: 2px;
  }
  .attribute_value_selector .attribute_value_value {
    padding-left: 8px;
    font-size: 12px;
    font-weight: 400;
    font-family: 'Fira Sans Condensed';
  }

  .opinion-date-filter {
    margin-top: 8px;
  }
  .opinion-date-filter label {
    padding: 0 8px 0 18px;
    color: #666;
    font-size: 12px;
  }
  
  .opinion-date-filter input {
    font-size: 12px;
    width: 128px;
  }

"""

# window.opinion_trickle = -> 
#   filter_out = fetch 'filtered'
  
#   proposals = fetch '/proposals'

#   users = {}
#   for prop in proposals.proposals
#     for o in prop.opinions
#       users[o.user] = o.created_at or o.updated_at

#   users = ([k,v] for k,v of users)
#   users.sort (a,b) -> 
#     i = new Date(a[1])
#     j = new Date(b[1])
#     i.getTime() - j.getTime()

#   users = (u[0] for u in users)
#   cnt = users.length

#   steps = 1
#   tick = (interval) => 
#     if cnt >= 0
#       setTimeout => 
#         filter_out.users = {}
#         for user, idx in users
#           filter_out.users[user] = 1
#           break if idx > cnt 

#         cnt--
#         #cnt -= Math.ceil(steps / 2)
#         #tick(interval * .9)
#         tick(interval * .9)
#         steps++
#         dirty = true
#         setTimeout -> 
#           if dirty
#             save filter_out
#             dirty = false
#         , 2000
#       , interval

#   tick 1000


styles += """
  .toggle_buttons {
    list-style: none;
    margin: auto;
    text-align: center
  }
  .toggle_buttons li {
    display: inline-block;
  }
  button.sort_proposals {
    border-radius: 8px;
  }
  button.sort_proposals, .toggle_buttons button {
    background-color: white;
    color: #{focus_blue};
    font-weight: 600;
    font-size: 12px;
    border: 1px solid;
    border-color: #{focus_blue};
    border-right: none;
    padding: 4px 16px;
  }  
  .toggle_buttons li:first-child button {
    border-radius: 8px 0 0 8px;
    border-right: none;
  }
  .toggle_buttons li:last-child button {
    border-radius: 0px 8px 8px 0px;
    border-right: 1px solid;
  }

  button.sort_proposals, .toggle_buttons .active button {
    background-color: #{focus_blue};
    color: white;
  }

  .grays .toggle_buttons button {
    color: #444;
    border-color: #444;
  }
  .grays .toggle_buttons .active button {
    background-color: #444;
    color: white;
  }
"""

window.ToggleButtons = (items, view_state, style) ->
  toggle_state = fetch view_state 
  toggle_state.active ?= items[0]?.label

  toggled = (e, item) ->
    prev = view_state.active
    view_state.active = item.label
    save view_state

    item.callback?(item, prev)

  UL 
    key: 'toggle buttons'
    className: 'toggle_buttons'
    style: style or {}

    for item in items
      do (item) =>
        LI 
          className: if view_state.active == item.label then 'active'
          'data-view-state': item.label
          BUTTON
            onClick: (e) -> toggled(e, item) 
            onKeyDown: (e) -> 
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                toggled(e, item)
                e.preventDefault()

            item.label

window.OpinionViews = OpinionViews
