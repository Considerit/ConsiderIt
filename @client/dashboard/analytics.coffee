
styles += """
.DataAnalytics {
  position: relative;
}

"""

window.DataAnalytics = ReactiveComponent
  displayName: 'DataAnalytics'

  componentDidMount: -> @setWidth(); @loadD3()
  componentDidUpdate: -> @setWidth(); @loadD3()
  loadD3: -> 
    if !@local.loading
      @local.loaded = lazyLoadJavascript "#{fetch('/application').asset_host}/vendor/d3.v7.min.js", 
        onload: => 
          @local.loaded = true 
          @local.loading = false 
          save @local
        onerror: => 
          @local.error = true
          @local.loaded = false 
          @local.loading = false 
          save @local      
      @local.loading = !@local.loaded

  setWidth: -> 
    el = document.querySelector('#DASHBOARD-title')
    return if !el
    w = el.clientWidth
    if @local.width != w 
      @local.width = w 
      save @local



  render: -> 
    return SPAN null unless @local.loaded 

    analytics_state = fetch 'analytics'
    analytics_data_loaded = fetch('analytics_data_loaded')

    if !analytics_state.expanded
      analytics_state.expanded = 'VisitAnalytics'
      save analytics_state

    props =
      name: analytics_state.expanded
      width: @local.width
      cumulative: @local.cumulative

    DIV 
      className: "DataAnalytics" 

      ResponsiveAnalyticsDataset()

      if @local.loaded
        DIV 
          style: 
            display: if !analytics_data_loaded.data_loaded then 'none'
            
          AnalyticsTabs()

          # For commentsdata
          # options_area = @drawOptionsArea [
          #       {attr: 'exclude_hosts', label: 'Exclude Host Comments', default_value: true}
          #     ]

          DIV 
            style: 
              position: 'relative'
            DIV
              className: 'options_area'

              for option in [{attr: 'cumulative', label: 'cumulative', default_value: false}]
                {label, attr, default_value} = option
                if !@local[attr]?
                  @local[attr] = default_value

                LABEL 
                  key: label
                  className: 'toggle'
                  LABEL 
                    className: 'toggle_switch'

                    INPUT 
                      type: 'checkbox'
                      defaultChecked: default_value
                      onChange: (ev) => 
                        @local[attr] = !@local[attr]
                        save @local

                    SPAN 
                      className: 'toggle_switch_circle'

                  SPAN null,
                    label


          switch analytics_state.expanded
            when 'VisitAnalytics'
              VisitAnalytics props
            when 'ParticipantAnalytics'
              ParticipantAnalytics props
            when 'OpinionGraphAnalytics'
              OpinionGraphAnalytics props
            when 'CommentsAnalytics'
              CommentsAnalytics props


styles += """
  .AnalyticsTabs {
    margin-bottom: 40px;
  }
  .AnalyticsTabs ul {
    list-style: none;
    display: flex;
    justify-content: center;
  }
  
  .AnalyticsTabs li {
    display: inline-block;
    padding: 0 18px;
    border-left: 1px solid #f4f4f4;
    border-right: 1px solid #f4f4f4;
  }

  .AnalyticsTabs li:first-child {
    border-left: none;
  }

  .AnalyticsTabs li:last-child {
    border-right: none;
  }

  .AnalyticsTabs li button {
    background-color: transparent;
    border: none;
  }

  .AnalyticsTabs.free-forum li button {
    cursor: default;
  }


  #DASHBOARD-main .AnalyticsTabs [data-widget="UpgradeForumButton"] .btn.big {
    margin-bottom: 0px;
  }

"""

AnalyticsTabs = ReactiveComponent
  displayName: 'AnalyticsTabs'

  render: -> 
    analytics_state = fetch 'analytics'

    analytics_pages = [ 'VisitAnalytics', 'ParticipantAnalytics', 'OpinionGraphAnalytics', 'CommentsAnalytics' ]

    is_premium_forum = (fetch('/subdomain').plan > 0) # || fetch('/current_user').is_super_admin

    DIV 
      className: "AnalyticsTabs #{if !is_premium_forum then 'free-forum'}"

      if !is_premium_forum
        DIV 
          style: 
            position: 'absolute'
            left: 'calc(50% - 80px)'
            zIndex: 99
            top: 24
            display: 'flex'
            alignItems: 'center'


          UpgradeForumButton
            text: 'Upgrade Forum'
            big: true

          SPAN 
            style: 
              paddingLeft: 14
            " to access more data."



      UL null, 
        for name in analytics_pages
          do (name) => 

            active = analytics_state.expanded == name
            args = get_analytics_tab_data name
            if args 
              LI 
                key: name
                style: 
                  opacity: if !is_premium_forum && name != 'VisitAnalytics' then 0.7

                BUTTON
                  onClick: if is_premium_forum then => 
                    analytics_state.expanded = name
                    save analytics_state

                  DIV 
                    key: 'graph_padding'
                    className: 'graph_padding'

                    H1 
                      style: 
                        fontSize: 16
                        textTransform: 'uppercase'
                        color: if active then focus_color() else '#999'
                        textDecoration: if active then 'underline'
                      args.heading

                    DIV 
                      style: 
                        filter: if !is_premium_forum && name != 'VisitAnalytics' then "blur(4px)"
                      DIV
                        style: 
                          fontSize: 22
                          fontWeight: 600

                        args.data[0][1]

                      if args.data[1]

                        DIV
                          key: args.data[1][0] 
                          style:
                            marginBottom: 12
                            fontSize: 13
                            fontWeight: 400

                          "#{args.data[1][0]}: #{args.data[1][1]}"
      



get_analytics_tab_data = (name) ->
  switch name
    when 'VisitAnalytics'
      return null if !fetch('visitation_data').dummy
      {visitors, visits_per_day, segments, total_visits} = visitation_data
      args = 
        heading: "Unique Visitors"
        data: [
          ["Total", Object.keys(visitors).length]
          ["Total visits", "#{total_visits}"]   #(#{(registered / Object.keys(visitors).length * 100).toFixed(1)}%)"]          
        ]
    when 'ParticipantAnalytics'
      return null if !fetch('visitation_data').dummy || !fetch('participation_data').dummy

      {visitors, visits_per_day, segments, total_visits} = visitation_data
      {per_day, participants, segments} = participation_data
      args = 
        heading: "Participants"
        data: [
          ["Total", participants.length]
          ["Conversion rate", "#{(participants.length / Object.keys(visitors).length * 100).toFixed(1)}%"]
        ] 
    when 'OpinionGraphAnalytics'
      return null if !fetch('opinion_data').dummy

      opinions = fetch('/opinions').opinions
      {per_day, participants, segments} = opinions_data
      args =
        heading: "Opinions"
        data: [
          ["Total", opinions.length]
          ["Avg. per participant", (opinions.length / participants.length).toFixed(1)]
        ]
    when 'CommentsAnalytics'
      return null if !fetch('comment_data').dummy

      {per_day, participants, segments, all_comments} = comments_data
      args = 
        heading: 'Comments'
        data: [
          ["Total", all_comments.length]
          ["Avg. per participant", (all_comments.length / participants.length).toFixed(1)]
        ]
  args



# generated at http://jnnnnn.github.io/category-colors-constrained.html with   return J < 80 && J > 50; 
color50scheme = ["#1b70fc", "#fd1105", "#28e207", "#fc90fd", "#74755a", "#29d6e0", "#f6aa0b", "#c8128d", "#c5bab6", "#a62afd", "#a0aefd", "#149103", "#0d8995", "#9b7b9f", "#f4808b", "#b9660b", "#6fb985", "#9a9823", "#a6585e", "#ec07fb", "#10aceb", "#899da8", "#64749d", "#b68b6f", "#27865e", "#bc81fa", "#fa2b71", "#ff7227", "#c0c178", "#d969b2", "#c1a7cf", "#adc80a", "#f6a679", "#846ffe", "#a44ca8", "#9ec7c0", "#1ead9f", "#8a6f10", "#c14024", "#60b636", "#8f9b82", "#90c6ea", "#64787a", "#f1a1c8", "#0fdcb1", "#8263b2", "#5e7f37", "#836c72", "#8f8bc5", "#c68f2d"]



# generated at http://jnnnnn.github.io/category-colors-constrained.html with   return J < 80 && J > 50; 


styles += """
  .DataAnalytics {
    min-height: 2000px;
  }
  .analytics_section {
    position: relative;
  }
  .graph_padding {
    position: relative;
  }

  .segments-container {
    margin-bottom: 36px;
    display: flex;
    justify-content: center;
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

  .options_area {
    position: absolute;
    right: 28px;
    top: -24px;
  } 

  .toggle {
    display: flex;   
    padding-bottom: 8px; 
  }

  .toggle > span {
    font-size: 11px;
    margin-left: 8px;           
  }

  .toggle .toggle_switch {
    width: 36px;
    height: 16px;
  }
  .toggle .toggle_switch .toggle_switch_circle:before {
    height: 12px; 
    width: 12px;
    bottom: 2px;
  }

  .toggle input:checked + .toggle_switch_circle:before {
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
  review_state: (segments) -> 
    analytics_state = fetch 'analytics_state'
    if analytics_state.segment_by not of segments
      analytics_state.segment_by = null

  get_color: (vals) -> 
    vals.sort()
    color = d3.scaleOrdinal vals, color50scheme
    color

  drawSegments: (segment_by, current_segment, color, notice, labels) ->
    return SPAN {key: 'segments'} if segment_by.length == 0 


    analytics_state = fetch 'analytics_state'
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
                    if analytics_state.segment_by == segment
                      analytics_state.segment_by = null 
                    else 
                      analytics_state.segment_by = segment
                    save analytics_state
                  onKeyPress: (e) -> 
                    if e.which == 13 || e.which == 32 # ENTER or SPACE
                      e.target.click()
                      e.stopPropagation()
                      e.preventDefault()              
                  style: 
                    backgroundColor: if analytics_state.segment_by == segment then focus_blue else '#eaeaea'
                    color: if analytics_state.segment_by == segment then 'white' else '#444'

                  labels?[segment] or segment

      if notice
        DIV 
          className: 'notice'
          SPAN null,
            notice

      if analytics_state.segment_by
        @drawSegment (labels?[analytics_state.segment_by] or analytics_state.segment_by), current_segment, color

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
            marginBottom: 8
          name

        DIV 
          className: 'segment_grid'

          for [val, incidents] in segment_vals
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

                if val == 'Eventually registered'
                  participation_data.participants.length # to deal with bot false positives in the visitation dataset
                else    
                  incidents.length 
      DIV 
        style: 
          width: '48%'

        PieChart 
          key: name
          data: segment_vals
          colors: color_vals



                  

visitor_segment_labels =
  'new_vs_returning': 'New vs. Returning'
  'registered_vs_unregistered': 'Registered vs Unregistered'
  'referring_domain': 'Referring Domain'
  # 'referrer': 'Referrer'
  'device_type': 'Device Type'
  'browser': 'Browser'
  'ip': 'IP Prefix'

window.VisitAnalytics = ReactiveComponent
  displayName: 'VisitAnalytics'
  mixins: [GraphSection]
  defaultZ: 'Unique Visitors'

  render : -> 

    return SPAN null if !fetch('visitation_data').dummy
    analytics_state = fetch 'analytics_state'

    {visitors, visits_per_day, segments, total_visits} = visitation_data
    @review_state(segments)

    zDomain = if analytics_state.segment_by then Object.keys(segments[analytics_state.segment_by]) else [@defaultZ]

    time_domain = get_forum_time_domain()

    color = @get_color zDomain

    segment_by = Object.keys visitor_segment_labels

    if time_domain.earliest_visit < time_domain.earliest_opinion # note that time_domain is in "days ago", so less is more
      notice = "* This forum started before Consider.it started tracking visits, so only a subset of visits is represented here."
    else 
      notice = null

    DIV 
      className: 'VisitAnalytics analytics_section'

      DIV null, 
        TimeSeriesAreaGraph
          key: "visitors-#{analytics_state.segment_by}-#{@props.cumulative}"
          time_format: "%Y-%m-%d"
          width: @props.width
          log: 'linear'
          yLabel: '' # 'Unique Visitors Per Day'
          cumulative: @props.cumulative
          name: 'Unique Visitors'
          segment_by: (d) =>
            if analytics_state.segment_by
              d[analytics_state.segment_by]
            else 
              'Unique Visitors'
          data: visits_per_day
          zDomain: zDomain
          color: color

        @drawSegments segment_by, segments[analytics_state.segment_by], color, notice, visitor_segment_labels



getForumParticipants = (additional_items) -> 
  opinions_by_user = get_opinions_by_users()
  for i in (additional_items or [])
    if i.user not of opinions_by_user
      opinions_by_user[i.user] = 1
  participants = ( {u: k} for k, ___ of opinions_by_user )
  participants 

window.ParticipantAnalytics = ReactiveComponent
  displayName: 'ParticipantAnalytics'
  mixins: [GraphSection]
  defaultZ: 'First Opinion Given'

  render : -> 
    return SPAN null if !fetch('participation_data').dummy

    {per_day, participants, segments} = participation_data
    @review_state(segments)
    analytics_state = fetch 'analytics_state'

    if analytics_state.segment_by
      {multi_valued_segment, zDomain, segment_data} = segments[analytics_state.segment_by] 
    else 
      zDomain = [@defaultZ]
      segment_data = {}
      multi_valued_segment = false

    color = @get_color(zDomain)

    attributes = get_participant_attributes()
    segment_by = ( attr.name or attr.key for attr in attributes )

    if multi_valued_segment
      notice = "* This attribute is multi-valued. Some participants are counted in multiple categories."
    else
      notice = null

    DIV 
      className: 'ParticipantAnalytics analytics_section'
       
      DIV null,       
        TimeSeriesAreaGraph
          key: "participants-#{analytics_state.segment_by}-#{@props.cumulative}"
          time_format: "%Y-%m-%d"
          width: @props.width
          log: 'linear'
          yLabel: '' # 'New Participants'
          name: 'New Participants'
          cumulative: @props.cumulative
          segment_by: (d) => 
            if analytics_state.segment_by
              d[analytics_state.segment_by]
            else 
              @defaultZ
          data: per_day
          zDomain: zDomain
          color: color

        @drawSegments segment_by, segment_data, color, notice



window.OpinionGraphAnalytics = ReactiveComponent
  displayName: 'OpinionGraphAnalytics'
  mixins: [GraphSection]

  defaultZ: 'Opinions'


  render : -> 
    opinions = fetch('/opinions').opinions
    return SPAN null if !fetch('opinion_data').dummy
    analytics_state = fetch 'analytics_state'

    {per_day, participants, segments} = opinions_data
    @review_state(segments)

    if analytics_state.segment_by
      {multi_valued_segment, zDomain, segment_data} = segments[analytics_state.segment_by] 
    else 
      zDomain = [@defaultZ]
      segment_data = {}
      multi_valued_segment = false

    color = @get_color(zDomain)

    attributes = get_participant_attributes()
    segment_by = ( attr.name or attr.key for attr in attributes )

    if multi_valued_segment
      notice = "* This attribute is multi-valued. Some participants are counted in multiple categories."
    else
      notice = null
    
    DIV 
      className: 'ParticipantAnalytics analytics_section'

      DIV null, 
        TimeSeriesAreaGraph
          key: "opinions-#{analytics_state.segment_by}-#{@props.cumulative}"
          time_format: "%Y-%m-%d"
          width: @props.width
          log: 'linear'
          name: 'Opinions'
          yLabel: '' # 'Opinions'
          cumulative: @props.cumulative
          segment_by: (d) => 
            if analytics_state.segment_by
              d[analytics_state.segment_by]
            else 
              @defaultZ
          data: per_day
          zDomain: zDomain
          color: color

        @drawSegments segment_by, segment_data, color, notice





window.CommentsAnalytics = ReactiveComponent
  displayName: 'CommentsAnalytics'
  mixins: [GraphSection]

  defaultZ: 'Comments'


  render : -> 
    return SPAN null if !fetch('comment_data').dummy

    {per_day, participants, segments, all_comments} = comments_data
    @review_state(segments)

    analytics_state = fetch 'analytics_state'

    if analytics_state.segment_by
      {multi_valued_segment, zDomain, segment_data} = segments[analytics_state.segment_by] 
    else 
      zDomain = [@defaultZ]
      segment_data = {}
      multi_valued_segment = false

    color = @get_color(zDomain)

    attributes = get_participant_attributes()
    segment_by = ( attr.name or attr.key for attr in attributes )
    segment_by.push 'Comment Type'
    # TODO: should host-contributed comments automatically be excluded?

    if multi_valued_segment
      notice = "* This attribute is multi-valued. Some participants are counted in multiple categories."
    else
      notice = null
    
    DIV 
      className: 'CommentAnalytics analytics_section'

      DIV null, 

        TimeSeriesAreaGraph
          key: "comments-#{analytics_state.segment_by}-#{@props.cumulative}-#{@local.exclude_hosts}-#{@local.include_proposals}-#{@local.include_points}-#{@local.include_comments}-#{all_comments.length}"
          time_format: "%Y-%m-%d"
          width: @props.width
          log: 'linear'
          yLabel: '' # @defaultZ
          name: 'Comments'
          cumulative: @props.cumulative
          segment_by: (d) => 
            if analytics_state.segment_by
              d[analytics_state.segment_by]
            else 
              @defaultZ
          data: per_day
          zDomain: zDomain
          color: color

        @drawSegments segment_by, segment_data, color, notice





styles += """
.d3-tooltip {
  position: absolute;
  text-align: center;
  padding: 6px 12px;
  font: 16px sans-serif;
  background: #000000cc;
  border: none;
  border-radius: 4px;
  pointer-events: none;
  color: white;
}


.d3-tooltip .date {
  font-size: 14px;
}

.d3-tooltip .quantity .amount {
  font-size: 16px;
  font-weight: 700;
}

.d3-tooltip .quantity .type {
  padding-left: 8px;
  font-size: 16px;  
  # font-weight: 700;
}

.d3-tooltip .multi_lines {
  margin-top: 8px;
}

.d3-tooltip .multi_lines .stack-line {
  font-size: 13px;
  display: flex;
  align-items: center;
  min-width: 0;

}

.d3-tooltip .multi_lines .stack-line .amount {
  padding-right: 6px;
  flex-shrink: 0;
}

.d3-tooltip .multi_lines .stack-line .type {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  min-width: 0;
}

.d3-tooltip .multi_lines .stack-color {
  width: 10px;
  height: 10px;
  display: inline-block;
  border-radius: 50%;
  margin-right: 6px;
  flex-shrink: 0;
}


"""

window.TimeSeriesAreaGraph = ReactiveComponent
  displayName: 'TimeSeriesAreaGraph'

  render: -> 
    DIV
      ref: 'container'

  componentDidMount: -> 

    data = @props.data

    # Set the dimensions of the canvas / graph
    margin = {top: 10, right: 28, bottom: 50, left: 48}
    width = @props.width - margin.left - margin.right
    height = 400 - margin.top - margin.bottom
    
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
      #.curve(d3.curveBasis)  # needs to be upgraded to line.curve
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


    # Create a tooltip element with a class of "d3-tooltip"
    tooltip = d3.select('body')
      .append('div')
      .attr('class', 'd3-tooltip')
      .style('opacity', 0)



    
    # Add a transparent rect to the SVG to capture mouse events
    g.append('rect')
      .attr('width', width)
      .attr('height', height)
      .attr('fill', 'none')
      .attr('pointer-events', 'all')
      .on('mousemove', (event) =>
        # Get the mouse position relative to the SVG element
        [xPos, yPos] = d3.pointer(event)
        closest_date = x.invert(xPos)
        search_date = d3.timeFormat(@props.time_format or "%d-%b-%y")(closest_date)
        tooltip_date = d3.timeFormat("%A %B %e, %Y")(closest_date)

        for d in data
          if d[1] == search_date
            pnt = d 
            break


        # Update the tooltip position and content

        # Remove any existing data point
        g.selectAll('.data-point').remove()

        stacks = []

        # Add a new data point at the current mouse position




        r = 4
        current_x = x(new Date(search_date)) + r # / 2
        current_y = 0
        for stack in series
          series_idx = stack[1].length - pnt[0] - 1

          current_y += stack[1][series_idx][1]
          colr = color(stack[0])
          val = stack[1][series_idx][1]
          continue if val == 0
          g.append('circle')
            .attr('class', 'data-point')
            .attr('cx', current_x)
            .attr('cy', y(current_y))
            .attr('r', r)
            .style('fill', colr)

          stacks.push [(if stack[0] == 'null' then '(unknown)' else stack[0]), val, colr]

        multi_lines = null
        if stacks.length > 1 
          multi_lines = "<div class='multi_lines'>"
          for stack in stacks
            if stack[1] > 0
              stack_name = stack[0]
              if stack_name.length > 40
                stack_name = stack_name.substring(0, 38) + '...'
              multi_lines += """
                <div class="stack-line">
                  <span class='stack-color' style='background-color: #{stack[2]}'></span>
                  <span class='amount'>#{stack[1]}</span>
                  <span class='type'>#{stack_name}</span>
                </div>
              """

          multi_lines += '</div>'

        tooltip_html = """
          <div class="analytics_tooltip">
          <div class="date">#{tooltip_date}</div>
          <div class="quantity"><span class="amount">#{current_y}</span><span class="type">#{@props.name} #{if @props.cumulative then ' to date' else ''}</span></div>
          #{if multi_lines then multi_lines else ''}
          </div>
        """        

        tooltip.transition()
          .duration(200)
          .style('opacity', .9)
        tooltip.html(tooltip_html)
          .style('left', (event.pageX + 24) + 'px')
          .style('top', (event.pageY - 64) + 'px')


      )
      .on('mouseleave', ->
        # Hide the tooltip and remove the data point
        tooltip.transition()
          .duration(500)
          .style('opacity', 0)
        g.selectAll('.data-point').remove()
      )


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



get_forum_time_domain = -> 
  fetch 'forum_time_domain'



comments_data = {}
participation_data = {}
opinions_data = {}
visitation_data = {}

ResponsiveAnalyticsDataset = ReactiveComponent
  displayName: 'ResponsiveAnalyticsDataset'

  render: -> 
    requirements_loaded = true
    requirements = [ fetch('/subdomain').name, \
                     fetch('/visits').visits, \
                     fetch('/opinions').opinions, \
                     fetch('/all_comments').comments, \
                     fetch('/users').users, \
                     fetch('/proposals?all_points=true') && arest.cache['/proposals'].proposals \
                   ]

    for req in requirements
      requirements_loaded &&= req

    return SPAN null unless requirements_loaded

    # data_key = ""
    # for req in requirements
    #   data_key += md5(JSON.stringify(req))


    # if data_key != @last_key
    @setForumTimeDomain()
    @setVisitationData()
    @setParticipationData()
    @setOpinionsData()
    @setCommentsData()
    # @last_key = data_key

    analytics_data_loaded = fetch('analytics_data_loaded')
    if !analytics_data_loaded.data_loaded 
      analytics_data_loaded.data_loaded = true
      save analytics_data_loaded

    SPAN null


  setForumTimeDomain: ->
    if !arest.cache['forum_time_domain'] 

      opinions = fetch '/opinions'
      visits = fetch '/visits'
      proposals = fetch '/proposals'
      subdomain = fetch '/subdomain'

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
        u = fetch o.user
        continue if u.key in subdomain.roles.admin || u.key in (customization('organizational_account') or [])

        days_ago = Math.round (now - new Date(o.created_at).getTime()) / 1000 / 60 / 60 / 24
        if earliest_opinion < days_ago
          earliest_opinion = days_ago
        if latest_opinion > days_ago
          latest_opinion = days_ago

      for o in proposals.proposals
        days_ago = Math.round (now - new Date(o.created_at).getTime()) / 1000 / 60 / 60 / 24
        if earliest_opinion < days_ago
          earliest_opinion = days_ago
        if latest_opinion > days_ago
          latest_opinion = days_ago
      
      data_state = {key: 'forum_time_domain'}
      _.extend data_state, {earliest_visit, latest_visit, earliest_opinion, latest_opinion, earliest: earliest_opinion, latest: latest_opinion}
      save data_state
    



  setVisitationData : -> 
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

    is_premium_forum = (subdomain.plan > 0) || fetch('/current_user').is_super_admin

    if !is_premium_forum && 'registered_vs_unregistered' of visitor_segment_labels
      delete visitor_segment_labels.registered_vs_unregistered

    users_seen = {}
    for visit in visits.visits
      days_ago = Math.round (Date.now() - new Date(visit.started_at).getTime()) / 1000 / 60 / 60 / 24
      time_series[days_ago] ?= {visits: [], visits_on_day_by_user: {}}
      time_series[days_ago].visits.push visit

      for segment in segment_by
        if segment == 'referring_domain' && !visit.referring_domain && visit.utm_source == 'digest'
          visit.referring_domain = 'Consider.it activity digest email'
        else if segment == 'new_vs_returning'
          visit.new_vs_returning = if visit.user of users_seen then 'Returning Visitor' else 'New Visitor'
          users_seen[visit.user] = 1 
        else if segment == 'registered_vs_unregistered'
          visit.registered_vs_unregistered = if visit.user of arest.cache then 'Eventually registered' else 'Never registered'
          users_seen[visit.user] = 1 

        segments[segment][visit[segment]] ?= []
        segments[segment][visit[segment]].push visit

      visitors[visit.user] ?= []
      visitors[visit.user].push visit

    # reduce segment visits so a single user doesn't count more than once for a segment value
    for segment in segment_by
      for val, seg_visits of segments[segment]
        seg_users = {}
        for v in seg_visits
          seg_users[v.user] = 1

        segments[segment][val] = Object.keys(seg_users)

    time_domain = get_forum_time_domain()

    for days_ago in [time_domain.latest..time_domain.earliest_visit]
      time_series[days_ago] ?= {visits: [], visits_on_day_by_user: {}}
      if time_series[days_ago].visits.length > 0 
        visits_on_day_by_user = time_series[days_ago].visits_on_day_by_user
        for v in time_series[days_ago].visits
          visits_on_day_by_user[v.user] ?= []
          visits_on_day_by_user[v.user].push v

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


    data_state = {key: 'visitation_data', dummy: Math.random()}
    visitation_data = {visitors, visits_per_day, segments, total_visits:visits.visits.length}
    save data_state

  setParticipationData: -> 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    opinions_by_user = get_opinions_by_users()

    participants = getForumParticipants()

    # segments: 
    #   - each sign-up question
    #   - % who left an opinion
    #   - % who answered at least 50% of the proposals
    #   - % who added a comment, pro or con, or proposal

    # divide participants into segments
    attributes = get_participant_attributes()
    segments = {}


    for attr in attributes
      name = attr.name or attr.key     

      current_segment = segments[name] = 
        zDomain: {'(unknown)': 1}
        segment_data: {} 
        multi_valued_segment: false

      checklist_phantoms = [] # With checklists, a participant can have multiple values for a given attribute.
                              # We want them to count toward both. So we replicate them as phantoms to count
                              # toward each attribute.


      for u in participants
        vals = []
        if u.key != '/user/-1' # skip for anonymity
          for option in attr.options
            current_segment.zDomain[option] = 1
            if (attr.pass? && attr.pass(u.u, option)) || (!attr.pass && attribute_passes(u.u, attr, [option]) )
              vals.push option
              current_segment.segment_data[option] ?= []
              current_segment.segment_data[option].push u

        if vals.length == 0
          option = '(unknown)'
          vals.push option 
          current_segment.segment_data[option] ?= []
          current_segment.segment_data[option].push u


        for val, idx in vals
          if idx > 0 
            uu = {}
            for k,v of u
              uu[k] = v
            checklist_phantoms.push uu
          else 
            uu = u

          uu[name] = val

      current_segment.zDomain = Object.keys current_segment.zDomain

      if checklist_phantoms.length > 0
        # participants = participants.concat checklist_phantoms
        current_segment.multi_valued_segment = true

    time_series = {}

    time_domain = get_forum_time_domain()

    now = Date.now()

    for user in participants
      first_opinion_given = null
      for o in opinions_by_user[user.u]
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

    data_state = {key: 'participation_data', dummy: Math.random()}    
    participation_data = {per_day, participants, segments}
    save data_state

  setOpinionsData: ->
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    by_user = {}
    for user, opinions of get_opinions_by_users()
      by_user[user] = []
      for o in opinions 
        by_user[user].push {key: o.key, o, u: user}

    participants = getForumParticipants()

    {segments, per_day} = @parseUserContributionsAndSegment(participants, by_user)
    
    data_state = {key: 'opinion_data', dummy: Math.random()}    
    opinions_data = {per_day, participants, segments}
    save data_state


  setCommentsData: -> 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
      
    proposals = fetch '/proposals'

    # should_include =
    #   comment: @local.include_comments
    #   point: @local.include_points
    #   proposal: @local.include_proposals

    # exclude_hosts = @local.exclude_hosts

    hosts = {}
    for h in (subdomain.roles.admin or [])
      hosts[h] = 1 
    for h in (subdomain.customizations.organizational_account or [])
      hosts[h] = 1

    by_user = {}
    include_item = (item, type, type_label) ->
      # if should_include[type] && (!exclude_hosts || !hosts[item.user])
      by_user[item.user] ?= []
      by_user[item.user].push {key: item.key, u: item.user, o: item, 'Comment Type': type_label}
      item['Comment Type'] = type_label
      all_comments.push item

    all_comments = []
    for proposal in (proposals.proposals or [])
      proposal = fetch proposal
      include_item proposal, 'proposal', 'Proposal'

      for point in (proposal.points or [])
        point = fetch(point)
        include_item point, 'point', 'Pro or Con Point'

    for comment in (fetch("/all_comments")?.comments or [])
      comment = fetch comment
      include_item comment, 'comment', 'Reply to a Point'

    

    participants = getForumParticipants(all_comments)
    {segments, per_day} = @parseUserContributionsAndSegment(participants, by_user)


    ###########
    # add in comment type
    name = 'Comment Type'     
    current_segment = segments[name] = 
      segment_data: {'Reply to a Point': [], 'Pro or Con Point': [], 'Proposal': []} 
      multi_valued_segment: false
    current_segment.zDomain = Object.keys current_segment.segment_data
    for comment in all_comments
      current_segment.segment_data[comment['Comment Type']].push comment

    ##############


    data_state = {key: 'comment_data', dummy: Math.random()}    
    comments_data = {per_day, participants, segments, all_comments}
    save data_state

  parseUserContributionsAndSegment: (participants, by_user) -> 

    # divide participants into segments
    attributes = get_participant_attributes()
    segments = {}

    for attr in attributes

      name = attr.name or attr.key     

      current_segment = segments[name] = 
        zDomain: {'(unknown)': 1}
        segment_data: {} 
        multi_valued_segment: false

      checklist_phantoms = [] # With checklists, a participant can have multiple values for a given attribute.
                              # We want them to count toward both. So we replicate them as phantoms to count
                              # toward each attribute.
      
      for u in participants
        vals = []
        if u.key != '/user/-1' # skip for anonymity
          for option in attr.options
            current_segment.zDomain[option] = 1
            if (attr.pass? && attr.pass(u.u, option)) || (!attr.pass && attribute_passes(u.u, attr, [option]) )
              vals.push option

        if vals.length == 0
          option = '(unknown)'
          vals.push option 

        items = by_user[u.u] or []

        for val, idx in vals
          if idx > 0             
            for o in items
              oo = {}
              for k,v of o
                oo[k] = v 
              oo[name] = val
              current_segment.segment_data[val] ?= []
              current_segment.segment_data[val].push oo
              checklist_phantoms.push oo
              # by_user[u.u].push oo

          else 
            for o in items
              o[name] = val
              current_segment.segment_data[val] ?= []
              current_segment.segment_data[val].push o

      current_segment.zDomain = Object.keys current_segment.zDomain
      if checklist_phantoms.length > 0
        current_segment.multi_valued_segment = true

    time_series = {}

    time_domain = get_forum_time_domain()

    now = Date.now()

    for user in participants
      for o in (by_user[user.u] or [])
        days_ago = Math.round (now - new Date(o.o.created_at).getTime()) / 1000 / 60 / 60 / 24
        time_series[days_ago] ?= []
        time_series[days_ago].push o

    per_day = []

    for days_ago in [time_domain.latest_opinion..time_domain.earliest]
      day = new Date( now - days_ago * 24 * 60 * 60 * 1000 )
      date_str = day.toISOString().split('T')[0]

      per_day.push [days_ago, date_str, time_series[days_ago] or [] ]

    per_day.reverse()    
    {participants, segments, per_day}

