

window.DataAnalytics = ReactiveComponent
  displayName: 'DataAnalytics'

  componentDidMount: -> @setWidth()
  componentDidUpdate: -> @setWidth()

  setWidth: -> 
    el = document.querySelector('#DASHBOARD-title')
    return if !el
    w = el.clientWidth
    if @local.width != w 
      @local.width = w 
      save @local

  render: -> 
    DIV 
      className: "DataAnalytics" 

      VisitAnalytics
        width: @local.width

      ParticipantAnalytics
        width: @local.width
        cumulative_default: true

      OpinionGraphAnalytics
        width: @local.width
        cumulative_default: true


# generated at http://jnnnnn.github.io/category-colors-constrained.html with   return J < 80 && J > 50; 
color50scheme = ["#1b70fc", "#fd1105", "#28e207", "#fc90fd", "#74755a", "#29d6e0", "#f6aa0b", "#c8128d", "#c5bab6", "#a62afd", "#a0aefd", "#149103", "#0d8995", "#9b7b9f", "#f4808b", "#b9660b", "#6fb985", "#9a9823", "#a6585e", "#ec07fb", "#10aceb", "#899da8", "#64749d", "#b68b6f", "#27865e", "#bc81fa", "#fa2b71", "#ff7227", "#c0c178", "#d969b2", "#c1a7cf", "#adc80a", "#f6a679", "#846ffe", "#a44ca8", "#9ec7c0", "#1ead9f", "#8a6f10", "#c14024", "#60b636", "#8f9b82", "#90c6ea", "#64787a", "#f1a1c8", "#0fdcb1", "#8263b2", "#5e7f37", "#836c72", "#8f8bc5", "#c68f2d"]


get_forum_time_domain = ->
  opinions = fetch '/opinions'
  visits = fetch '/visits'

  if !window.forum_time_domain && opinions.opinions && visits.visits

    earliest_visit = 0
    latest_visit = Infinity
    now = Date.now()
    for visit in visits.visits
      days_ago = Math.round (now - new Date(visit.started_at).getTime()) / 1000 / 60 / 60 / 24
      if earliest_visit < days_ago
        earliest_visit = days_ago
      if latest_visit > days_ago
        latest_visit = days_ago


    earliest_opinion = 0
    latest_opinion = Infinity
    for o in opinions.opinions
      days_ago = Math.round (now - new Date(o.created_at).getTime()) / 1000 / 60 / 60 / 24
      if earliest_opinion < days_ago
        earliest_opinion = days_ago
      if latest_opinion > days_ago
        latest_opinion = days_ago

    window.forum_time_domain = {earliest_visit, latest_visit, earliest_opinion, latest_opinion, earliest: Math.max(earliest_visit, earliest_opinion), latest: Math.min(latest_visit, latest_opinion)}

  window.forum_time_domain




styles += """
  .DataAnalytics {
    min-height: 2000px;
  }
  .analytics_section {
    position: relative;
  }
  .graph_padding {
    padding: 0 28px 0 36px;
  }

  .segments-container {
    margin-bottom: 36px;  
  }

  .segments-container label {
    margin-right: 16px;
    font-size: 12px;
  }
  .segments-container ul {
    list-style: none;
    padding: 0;
    display: inline;
    margin: 0;
  }

  .segments-container li {
    display: inline-block;
    margin: 4px;
  }

  .segments-container li button {
    display: inline-block;
    font-size: 14px;
    border-radius: 8px;
    padding: 4px 12px;
    font-weight: 400;
    background-color: #eaeaea;
    color: #333;
    border: 1px solid #dadada;
  }

  .segment_grid {
    display: grid; 
    grid-template-columns: 10% 65% 25%;
    grid-row-gap: 8px;
  }

  .grid-row-wrapper {
    display: contents;
  }

  .grid-row-wrapper > div {
    padding-left: 18px;
  }

  .segment_val_name {
    overflow-wrap: anywhere;
  }
  .segment_val_amount {
    text-align: right;
    padding-right: 12px;
  }

  .cumulative_toggle {
    display: flex;
    position: absolute;
    right: 28px;
  } 

  .cumulative_toggle > span {
    font-size: 11px;
    margin-left: 8px;           
  }

  .cumulative_toggle .toggle_switch {
    width: 36px;
    height: 16px;
  }
  .cumulative_toggle .toggle_switch .toggle_switch_circle:before {
    height: 12px; 
    width: 12px;
    bottom: 2px;
  }

  .cumulative_toggle input:checked + .toggle_switch_circle:before {
    transform: translateX(18px);
  }

  .analytics_section .notice {
    margin-bottom: 14px;
    text-align: center
  }
  .analytics_section .notice > span {
    background-color: #fffadb;
    font-size: 13px;
  }

"""

GraphSection =    

  get_color: (vals) -> 
    console.log {vals}
    if false && vals.length <= 10
      color = d3.scaleOrdinal vals, d3.schemeTableau10
    else 
      color = d3.scaleOrdinal vals, color50scheme
    color


  drawCumulativeToggle: -> 
    if !@local.cumulative?
      @local.cumulative = @props.cumulative_default

    LABEL 
      className: 'cumulative_toggle '
      LABEL 
        className: 'toggle_switch'

        INPUT 
          type: 'checkbox'
          defaultChecked: @props.cumulative_default
          onChange: (ev) => 
            @local.cumulative = !@local.cumulative
            save @local

        SPAN 
          className: 'toggle_switch_circle'

      SPAN null,
        "cumulative"

  drawSegments: (segment_by, current_segment, color, labels) ->
    return SPAN {key: 'segments'} if segment_by.length == 0 

    DIV 
      className: 'segments graph_padding'

      DIV 
        className: 'segments-container'

        # LABEL null,
        #   'Segment by:'

        UL null,

          for segment in segment_by
            do (segment) =>

              LI 
                key: segment

                BUTTON 

                  onClick: (e) =>
                    if @local.segment_by == segment
                      @local.segment_by = null 
                    else 
                      @local.segment_by = segment
                    save @local
                  onKeyPress: (e) -> 
                    if e.which == 13 || e.which == 32 # ENTER or SPACE
                      e.target.click()
                      e.stopPropagation()
                      e.preventDefault()              
                  style: 
                    backgroundColor: if @local.segment_by == segment then focus_blue else '#eaeaea'
                    color: if @local.segment_by == segment then 'white' else '#444'

                  labels?[segment] or segment


      if @local.segment_by
        @drawSegment (labels?[@local.segment_by] or @local.segment_by), current_segment, color

  drawSegment : (name, segment, colors) ->
    segment_vals = Object.entries segment

    segment_vals.sort (a,b) -> b[1].length - a[1].length

    color_vals = []

    DIV 
      style: 
        display: 'flex'

      DIV
        style: 
          width: '50%'

        H3 
          style: 
            marginLeft: 'calc(18px + 10%)'
          name

        DIV 
          className: 'segment_grid'

          for [val, visitors] in segment_vals
            color_vals.push colors(val) + '66'

            DIV 
              key: val
              className: 'grid-row-wrapper'

              DIV 
                style: 
                  backgroundColor: colors(val)

              DIV
                className: 'segment_val_name'
                style: 
                  backgroundColor: colors(val) + '66'

                if val == 'null' 
                  '(unknown)'
                else 
                  val

              DIV 
                className: 'segment_val_amount'
                style: 
                  backgroundColor: colors(val) + '66'

                visitors.length 
      DIV 
        style: 
          width: '48%'

        PieChart 
          key: name
          data: segment_vals
          colors: color_vals




visitor_segment_labels =
  'referring_domain': 'Referring Domain'
  # 'referrer': 'Referrer'
  'device_type': 'Device Type'
  'browser': 'Browser'
  'ip': 'IP Prefix'

window.VisitAnalytics = ReactiveComponent
  displayName: 'VisitAnalytics'
  mixins: [GraphSection]

  getData : -> 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    visits = fetch('/visits')
    users = fetch '/users'

    segment_by = Object.keys visitor_segment_labels
    segments = {}
    for segment in segment_by
      segments[segment] = {}

    visitors = {}

    time_series = []

    for visit in visits.visits
      days_ago = Math.round (Date.now() - new Date(visit.started_at).getTime()) / 1000 / 60 / 60 / 24
      time_series[days_ago] ?= {visits: [], visits_on_day_by_user: {}}
      time_series[days_ago].visits.push visit

      for segment in segment_by
        segments[segment][visit[segment]] ?= []
        segments[segment][visit[segment]].push visit

      visitors[visit.user] ?= []
      visitors[visit.user].push visit

    time_domain = get_forum_time_domain()

    for days_ago in [time_domain.latest..time_domain.earliest_visit]
      time_series[days_ago] ?= {visits: [], visits_on_day_by_user: {}}
      if time_series[days_ago].visits.length > 0 
        visits_on_day_by_user = time_series[days_ago].visits_on_day_by_user
        for v in time_series[days_ago].visits
          visits_on_day_by_user[v.user] ?= []
          visits_on_day_by_user[v.user].push v


    # reduce segment visits so a single user doesn't count more than once for a segment value
    for segment in segment_by
      for val, seg_visits of segments[segment]
        seg_users = {}
        for v in seg_visits
          seg_users[v.user] = 1
        segments[segment][val] = Object.keys(seg_users)

    visits_per_day = [] # filtered to first visit per user per day
    now = Date.now()

    for days_ago in [time_domain.latest..time_domain.earliest_visit]
      visits_this_day = []
      for user, user_visits of time_series[days_ago].visits_on_day_by_user
        visits_this_day.push user_visits[0]

      day = new Date( now - days_ago * 24 * 60 * 60 * 1000 )
      date_str = day.toISOString().split('T')[0]

      visits_per_day.push [days_ago, date_str, visits_this_day]

    visits_per_day.reverse()

    registered = 0
    for visitor, visits of visitors
      if fetch(visitor).name 
        registered += 1
        console.log 'REGISTERED:', fetch(visitor).name

    zDomain = if @local.segment_by then Object.keys(segments[@local.segment_by]) else ['Unique Visitors']

    return {zDomain, registered, visitors, visits_per_day, segments}

  render : -> 

    return SPAN null if !fetch('/subdomain').name || !fetch('/visits').visits || !fetch('/users').users || !@props.width

    {zDomain, registered, visitors, visits_per_day, segments} = @getData()

    time_domain = get_forum_time_domain()

    color = @get_color zDomain

    segment_by = Object.keys visitor_segment_labels

    DIV 
      className: 'VisitAnalytics analytics_section'

      DIV 
        className: 'graph_padding'
        H1 
          style: 
            fontSize: 28
            # marginBottom: 12
          "Visits"

        DIV
          style:
            marginBottom: 12

          "Unique visitors: #{Object.keys(visitors).length}" 
          BR null
          "Registered: #{registered} (#{(registered / Object.keys(visitors).length * 100).toFixed(1)}%)"

        if time_domain.earliest_visit < time_domain.earliest_opinion # note that time_domain is in "days ago", so less is more
          DIV 
            className: 'notice'
            SPAN null,
              "* This forum started before Consider.it started tracking visits, so only a subset of visits is represented here."


        @drawCumulativeToggle()

      TimeSeriesAreaGraph
        key: "visitors-#{@local.segment_by}-#{@local.cumulative}"
        time_format: "%Y-%m-%d"
        width: @props.width
        log: 'linear'
        yLabel: 'Unique Visitors Per Day'
        cumulative: @local.cumulative
        segment_by: (d) => 
          if @local.segment_by
            d[@local.segment_by]
          else 
            'Unique Visitors'
        data: visits_per_day
        zDomain: zDomain
        color: color

      @drawSegments segment_by, segments[@local.segment_by], color, visitor_segment_labels



styles += """
  .analytics_section {
    margin-bottom:  48px;
  }

"""



window.ParticipantAnalytics = ReactiveComponent
  displayName: 'ParticipantAnalytics'
  mixins: [GraphSection]

  defaultZ: 'First Opinion Given'

  getData : -> 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    opinions_by_user = get_opinions_by_users()

    participants = ( {key: u} for u,o of opinions_by_user)

    # segments: 
    #   - each sign-up question
    #   - % who left an opinion
    #   - % who answered at least 50% of the proposals
    #   - % who added a comment, pro or con, or proposal

    # divide participants into segments
    attributes = get_participant_attributes()
    segment_by = ( attr.name or attr.key for attr in attributes )

    if @local.segment_by
      zDomain = {}
    else 
      zDomain = [@defaultZ]

    current_segment = {}

    checklist_phantoms = [] # With checklists, a participant can have multiple values for a given attribute.
                            # We want them to count toward both. So we replicate them as phantoms to count
                            # toward each attribute. 
    for attr in attributes
      name = attr.name or attr.key     
      console.log {attr}, @local.segment_by, name

      continue if @local.segment_by != name

      for u in participants
        vals = []
        for option in attr.options
          if (attr.pass? && attr.pass(u.key, option)) || (!attr.pass && attribute_passes(u.key, attr, [option]) )
            vals.push option
            current_segment[option] ?= []
            current_segment[option].push u

        if vals.length == 0
          option = '(unknown)'
          vals.push option 
          current_segment[option] ?= []
          current_segment[option].push u

        for val, idx in vals
          if idx > 0 
            uu = {}
            for k,v of u
              uu[k] = v
            checklist_phantoms.push uu
          else 
            uu = u

          uu[name] = val
          zDomain[val] = 1
      zDomain = Object.keys zDomain


    if checklist_phantoms.length > 0
      participants = participants.concat checklist_phantoms

    time_series = {}

    time_domain = get_forum_time_domain()

    now = Date.now()

    for user in participants
      first_opinion_given = null
      for o in opinions_by_user[user.key]
        if !first_opinion_given || o.created_at < first_opinion_given
          first_opinion_given = o.created_at

      days_ago = Math.round (now - new Date(first_opinion_given).getTime()) / 1000 / 60 / 60 / 24
      time_series[days_ago] ?= []
      time_series[days_ago].push user

    per_day = [] # filtered to first visit per user per day

    for days_ago in [time_domain.latest_opinion..time_domain.earliest]
      day = new Date( now - days_ago * 24 * 60 * 60 * 1000 )
      date_str = day.toISOString().split('T')[0]

      per_day.push [days_ago, date_str, time_series[days_ago] or [] ]

    per_day.reverse()

    multi_valued_segment = checklist_phantoms.length > 0 

    {per_day, participants, zDomain, current_segment, multi_valued_segment}



  render : -> 

    return SPAN null if !fetch('/subdomain').name || !fetch('/users').users || !fetch('/opinions').opinions || !@props.width

    {per_day, participants, zDomain, current_segment, multi_valued_segment} = @getData()
    console.log {zDomain}
    color = @get_color(zDomain)

    attributes = get_participant_attributes()
    segment_by = ( attr.name or attr.key for attr in attributes )

    DIV 
      className: 'ParticipantAnalytics analytics_section'

      DIV 
        key: 'graph_padding'
        className: 'graph_padding'

        H1 
          style: 
            fontSize: 28
            # marginBottom: 12
          "Participants"

        DIV
          style:
            marginBottom: 12

          "Total: #{participants.length}"

        @drawCumulativeToggle()
      
      TimeSeriesAreaGraph
        key: "participants-#{@local.segment_by}-#{@local.cumulative}"
        time_format: "%Y-%m-%d"
        width: @props.width
        log: 'linear'
        yLabel: 'New Participants'
        cumulative: @local.cumulative
        segment_by: (d) => 
          if @local.segment_by
            d[@local.segment_by]
          else 
            @defaultZ
        data: per_day
        zDomain: zDomain
        color: color

      if multi_valued_segment
        DIV 
          className: 'notice'
          SPAN null,
            "* This attribute is multi-valued. Some participants are counted in multiple categories."


      @drawSegments segment_by, current_segment, color



window.OpinionGraphAnalytics = ReactiveComponent
  displayName: 'OpinionGraphAnalytics'
  mixins: [GraphSection]

  defaultZ: 'Opinions'

  getData : -> 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    opinions_by_user = {}
    for user, opinions of get_opinions_by_users()
      opinions_by_user[user] = []
      for o in opinions 
        opinions_by_user[user].push {key: o.key, o, u: user}

    participants = ( {key: u} for u,o of opinions_by_user)
    data = []


    # divide participants into segments
    attributes = get_participant_attributes()
    segment_by = ( attr.name or attr.key for attr in attributes )

    if @local.segment_by
      zDomain = {}
    else 
      zDomain = [@defaultZ]

    current_segment = {}

    checklist_phantoms = [] # With checklists, a participant can have multiple values for a given attribute.
                            # We want them to count toward both. So we replicate them as phantoms to count
                            # toward each attribute. 
    for attr in attributes
      name = attr.name or attr.key      
      continue if @local.segment_by != name

      for u in participants
        vals = []
        for option in attr.options
          if (attr.pass? && attr.pass(u.key, option)) || (!attr.pass && attribute_passes(u.key, attr, [option]) )
            vals.push option

        if vals.length == 0
          option = '(unknown)'
          vals.push option 

        items = opinions_by_user[u.key] or []

        for val, idx in vals
          if idx > 0             
            for o in items
              oo = {}
              for k,v of o
                oo[k] = v 
              oo[name] = val
              current_segment[val] ?= []
              current_segment[val].push oo
              checklist_phantoms.push oo
              opinions_by_user[u.key].push oo

          else 
            for o in items
              o[name] = val
              current_segment[val] ?= []
              current_segment[val].push o

          zDomain[val] = 1



      zDomain = Object.keys zDomain


    # if checklist_phantoms.length > 0
    #   participants = participants.concat checklist_phantoms

    time_series = {}

    time_domain = get_forum_time_domain()

    now = Date.now()

    for user in participants
      # first_opinion_given = null
      for o in (opinions_by_user[user.key] or [])
        # if !first_opinion_given || o.created_at < first_opinion_given
        #   first_opinion_given = o.created_at

        days_ago = Math.round (now - new Date(o.o.created_at).getTime()) / 1000 / 60 / 60 / 24
        time_series[days_ago] ?= []
        time_series[days_ago].push o

    per_day = []

    for days_ago in [time_domain.latest_opinion..time_domain.earliest]
      day = new Date( now - days_ago * 24 * 60 * 60 * 1000 )
      date_str = day.toISOString().split('T')[0]

      per_day.push [days_ago, date_str, time_series[days_ago] or [] ]

    per_day.reverse()

    console.log {per_day}
    multi_valued_segment = checklist_phantoms.length > 0 

    {per_day, data, participants, zDomain, current_segment, multi_valued_segment}



  render : -> 
    opinions = fetch('/opinions').opinions
    return SPAN null if !fetch('/subdomain').name || !fetch('/users').users || !opinions || !@props.width

    {per_day, participants, zDomain, current_segment, multi_valued_segment} = @getData()
    color = @get_color(zDomain)

    attributes = get_participant_attributes()
    segment_by = ( attr.name or attr.key for attr in attributes )
    
    DIV 
      className: 'ParticipantAnalytics analytics_section'

      DIV 
        key: 'graph_padding'
        className: 'graph_padding'

        H1 
          style: 
            fontSize: 28
          "Opinions"

        DIV
          style:
            marginBottom: 12

          "Total: #{opinions.length}"

        DIV
          style:
            marginBottom: 12

          "Average # opinions per participant: #{(opinions.length / participants.length).toFixed(1)}"

        @drawCumulativeToggle()
      
      TimeSeriesAreaGraph
        key: "opinions-#{@local.segment_by}-#{@local.cumulative}"
        time_format: "%Y-%m-%d"
        width: @props.width
        log: 'linear'
        yLabel: 'Opinions'
        cumulative: @local.cumulative
        segment_by: (d) => 
          if @local.segment_by
            d[@local.segment_by]
          else 
            @defaultZ
        data: per_day
        zDomain: zDomain
        color: color

      if multi_valued_segment
        DIV 
          className: 'notice'
          SPAN null,
            "* This attribute is multi-valued. Some participants are counted in multiple categories."


      @drawSegments segment_by, current_segment, color







window.TimeSeriesAreaGraph = ReactiveComponent
  displayName: 'TimeSeriesAreaGraph'

  render: -> 
    DIV
      ref: 'container'

  componentDidMount: -> 
    data = @props.data

    # Set the dimensions of the canvas / graph
    margin = {top: 40, right: 28, bottom: 50, left: 36}
    width = @props.width - margin.left - margin.right
    height = 250 - margin.top - margin.bottom
    
    # Set the ranges
    x = d3.scaleTime().range([0, width])
    y = d3.scaleLinear().range([height, 0])
    # z = d3.scaleOrdinal(d3.schemeCategory10)

    formatDate = d3.timeParse(@props.time_format or "%d-%b-%y")

    x.domain [
      d3.min([data], (c) -> d3.min(c, (d) -> formatDate(d[1])))
      d3.max([data], (c) -> d3.max(c, (d) -> formatDate(d[1])))
    ]

    y_areas = []
    y_min = Infinity
    y_max = -Infinity

    # get all possible segments
    zDomain = @props.zDomain
    if !zDomain
      zDomain = {}
      for day in data
        for incident in day[2]
          zDomain[@props.segment_by(incident)] = 1
      zDomain = Object.keys zDomain

    color = @props.color or d3.scaleOrdinal(zDomain, d3.schemeTableau10)

    # build up series data with each segment
    series = {}
    for day, idx in data
      for segment in zDomain
        series[segment] ?= []
        starting_val = 0 
        if @props.cumulative && idx > 0
          starting_val = series[segment][idx - 1][1]
        else
          starting_val = 0 

        series[segment].push [day[1], starting_val]

      for incident in day[2]
        segment_val = @props.segment_by(incident)
        # console.log {data, zDomain, incident, segment_val, s: @props.segment_by}
        series[segment_val][idx][1] += 1


    series = Object.entries(series)

    # order series so that the most frequent areas are on the bottom
    totals = {}
    for [id, values] in series
      y_area = []
      totals[id] = 0      
      for [t, yy], entry in values
        totals[id] += yy
    series.sort (a,b) -> totals[b[0]] - totals[a[0]]


    # convert to stacked representation by getting the y extent for each area
    idx = 0 
    for [id, values] in series
      y_area = []
      for [t, yy], entry in values
        if idx == 0
          start = 0
        else 
          start = y_areas[idx - 1].values[entry][2]
        end = start + yy

        if end > y_max 
          y_max = end
        if start < y_min
          y_min = start

        y_area.push [t, start, end, idx, entry]

      y_areas.push {id, values: y_area}
      idx += 1



    y.domain [
      y_min
      y_max
    ] 

    # Define the axes
    xAxis = d3.axisBottom(x)


    yAxis = d3.axisLeft(y)
              .ticks(Math.min(height / 40, y_max - y_min))    

    # Define the line
    area = d3.area()
      .curve(d3.curveBasis)  # needs to be upgraded to line.curve
      .x((d) -> x(formatDate(d[0])))
      .y0((d) -> y(d[1]))
      .y1((d) -> y(d[2]))

    # Adds the svg canvas
    container = d3.select(ReactDOM.findDOMNode(@))
    svg = container.append('svg')
            .attr('width', width + margin.left + margin.right)
            .attr('height', height + margin.top + margin.bottom)

    g = svg.append('g')
          .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')

    # Add the X Axis
    g.append('g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(0,' + (height) + ')')
      .call xAxis

    # Add the Y Axis
    g.append('g')
      .attr('class', 'y axis')
      .call yAxis

    g.append("g")
      .call(yAxis)
      .call (g) -> g.select(".domain").remove()
      .call (g) -> 
        g.selectAll(".tick line").clone()
          .attr("x2", width)
          .attr("stroke-opacity", 0.1)    
      .call (g) => 
        g.append("text")
          .attr("font-size", 16)
          .attr("x", 0)
          .attr("y", -10)
          .attr("fill", "currentColor")
          .attr("text-anchor", "start")
          .text "#{@props.yLabel}"


    measure = g.selectAll('.measure')
                .data(y_areas)
                .enter()
                  .append('g')
                  .attr('class', 'measure')


    measure
      .append('path')
        .attr 'class', 'line'
        .style 'stroke', (d) -> color(d.id)
        .style 'fill', (d) -> color(d.id) + '66'
        .attr('d', (d) -> area(d.values))
        .attr 'data-tooltip', (d) -> d.id
      .append("title")
        .text (d) -> d.id










window.PieChart = ReactiveComponent
  displayName: 'PieChart'

  render: -> 
    DIV
      ref: 'container'

  componentDidMount: -> 
    _PieChart @props.data, @refs.container, @props

  componentDidUpdate: -> 
    _PieChart @props.data, @refs.container, @props




# The following _PieChart component derives from the below copyrighted code
# Copyright 2021 Observable, Inc.
# Released under the ISC license.
# https://observablehq.com/@d3/pie-chart
_PieChart = (data, container, args = {}) ->

  title = args.title
  names = args.names 
  colors = args.colors
  name = args.name or ([x, y]) -> x  # given d in data, returns the (ordinal) label
  value = args.value or ([x, y]) -> if Array.isArray(y) then y.length else y # given d in data, returns the (quantitative) value
  width = args.width or 640 # outer width, in pixels
  height = args.height or 400 # outer height, in pixels
  innerRadius = args.innerRadius or 0 # inner radius of pie, in pixels (non-zero for donut)
  outerRadius = args.outerRadius or Math.min(width, height) / 2 # outer radius of pie, in pixels
  labelRadius = args.labelRadius or (innerRadius * 0.2 + outerRadius * 0.8) # center radius of labels
  format = args.format or "," # a format specifier for values (in the label)
  stroke = args.stroke or if innerRadius > 0 then "none" else "white" # stroke separating widths
  strokeWidth = args.strokeWidth or 1 # width of stroke separating wedges
  strokeLinejoin = args.strokeLinejoin or "round" # line join of stroke separating wedges
  padAngle = args.padAngle or if stroke == "none" then 1 / outerRadius else 0 # angular separation between wedges

  # Compute values.
  N = d3.map(data, name)
  V = d3.map(data, value)
  I = d3.range(N.length).filter (i) -> !isNaN(V[i])

  # Unique the names.
  if !names? 
    names = N
  names = new d3.InternSet(names)

  # Chose a default color scheme based on cardinality.
  if !colors? 
    colors = d3.schemeSpectral[names.size]
  if !colors?
    colors = d3.quantize ((t) -> d3.interpolateSpectral(t * 0.8 + 0.1)), names.size

  # Construct scales.
  color = d3.scaleOrdinal(names, colors)

  # Compute titles.
  if !title?
    formatValue = d3.format(format)
    title = (i) -> "#{N[i]}\n#{formatValue(V[i])}"
  else
    O = d3.map(data, (d) -> d)
    T = title
    title = (i) -> T(O[i], i, data)


  # Construct arcs.
  arcs = d3.pie().padAngle(padAngle).sort(null).value((i) -> V[i])(I)
  arc = d3.arc().innerRadius(innerRadius).outerRadius(outerRadius)
  arcLabel = d3.arc().innerRadius(labelRadius).outerRadius(labelRadius)
  
  container = d3.select(ReactDOM.findDOMNode(container))

  svg = container.append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", [-width / 2, -height / 2, width, height])
      .attr("style", "max-width: 100%; height: auto; height: intrinsic;")

  svg.append("g")
      .attr("stroke", stroke)
      .attr("stroke-width", strokeWidth)
      .attr("stroke-linejoin", strokeLinejoin)
    .selectAll("path")
    .data(arcs)
    .join("path")
      .attr("fill", (d) -> color(N[d.data]))
      .attr("d", arc)
    .append("title")
      .text((d) -> title(d.data))

  if args.draw_labels
    svg.append("g")
        .attr("font-family", "sans-serif")
        .attr("font-size", 14)
        .attr("text-anchor", "middle")
      .selectAll("text")
      .data(arcs)
      .join("text")
        .attr("transform", (d) -> "translate(#{arcLabel.centroid(d)})")
      .selectAll("tspan")
      .data( (d) -> 
        lines = title(d.data).split(/\n/)
        if (d.endAngle - d.startAngle) > 0.25 then lines else lines.slice(0, 1)
      )
      .join("tspan")
        .attr("x", 0)
        .attr("y", (_, i) -> "#{i * 1.1}em")
        .attr("font-weight", (_, i) -> if i then null else "bold")
        .text((d) -> d)


  Object.assign(svg.node(), {scales: {color}})

