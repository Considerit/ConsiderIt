

window.DataAnalytics = ReactiveComponent
  displayName: 'DataAnalytics'

  render: -> 
    DIV null, 

      VisitAnalytics()


window.styles += """
  .VisitAnalytics .line {

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
    margin-right: 8px;
    margin-bottom: 0;
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
    grid-template-columns: 2fr 65%;
  }

  .segment_grid>div:nth-child(4n+1),
  .segment_grid>div:nth-child(4n+2) {
    background-color: rgba(31, 119, 180, 0.1);
  }

"""

segment_labels =  
  'referring_domain': 'Referring Domain'
  'referrer': 'Referrer'
  'device_type': 'Device Type'
  'browser': 'Browser'
  'ip': 'IP Prefix'

window.VisitAnalytics = ReactiveComponent
  displayName: 'VisitAnalytics'

  componentDidMount: -> @setWidth()
  componentDidUpdate: -> @setWidth()

  setWidth: -> 
    el = document.querySelector('#DASHBOARD-title')
    return if !el
    w = el.clientWidth
    if @local.width != w 
      @local.width = w 
      save @local 

  render : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    visits = fetch('/visits')
    users = fetch '/users'

    return SPAN null if !subdomain.name || !visits.visits || !@local.width


    segment_by = Object.keys segment_labels
    segments = {}
    for segment in segment_by
      segments[segment] = {}

    visitors = {}

    time_series = []
    earliest_day = 0
    for visit in visits.visits
      days_ago = Math.round (Date.now() - new Date(visit.started_at).getTime()) / 1000 / 60 / 60 / 24
      time_series[days_ago] ?= {visits: [], visits_on_day_by_user: {}}
      time_series[days_ago].visits.push visit
      if earliest_day < days_ago
        earliest_day = days_ago

      for segment in segment_by
        segments[segment][visit[segment]] ?= []
        segments[segment][visit[segment]].push visit

      visitors[visit.user] ?= []
      visitors[visit.user].push visit

    for days_ago in [0..earliest_day]
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

    visitors_per_day = []

    now = Date.now()

    for days_ago in [0..earliest_day]
      num_visitors = Object.keys(time_series[days_ago].visits_on_day_by_user).length

      day = new Date( now - days_ago * 24 * 60 * 60 * 1000 )
      date_str = day.toISOString().split('T')[0]

      visitors_per_day.push [days_ago, date_str, num_visitors]

    visitors_per_day.reverse()

    registered = 0
    for visitor, visits of visitors
      if fetch(visitor).name 
        registered += 1

    DIV 
      className: 'VisitAnalytics'

      H1 
        style: 
          fontSize: 28
          # marginBottom: 12
        "Outreach"


      DIV
        style:
          marginBottom: 12

        "Unique visitors: #{Object.keys(visitors).length}" 
        BR null
        # "Conversion rate: #{(users.users.length / Object.keys(visitors).length * 100).toFixed(1)}%"
        "Registration rate: #{(registered / Object.keys(visitors).length * 100).toFixed(1)}%"

      TimeSeriesAreaGraph
        key: 'visitors'
        time_format: "%Y-%m-%d"
        width: @local.width
        log: 'linear'
        yLabel: 'Unique Visitors Per Day'
        series: [
          {
            id: 'Unique Visitors'
            values: visitors_per_day.map (d) -> [d[1], d[2]]
          }
        ]



      DIV 
        className: 'segments-container'

        LABEL null,
          'Segment by:'

        UL null,

          for segment in segment_by
            do (segment) =>
              LI null,

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

                  segment_labels[segment]


      if @local.segment_by
        @drawSegment @local.segment_by, segments[@local.segment_by]



  drawSegment : (name, segment) ->

    segment_vals = Object.entries segment

    segment_vals.sort (a,b) -> b[1].length - a[1].length

    console.log segment_vals

    DIV null,
      H3 null, 
        segment_labels[name]

      DIV 
        className: 'segment_grid'

        for [val, visitors] in segment_vals
          [
            DIV
              className: 'segment_val_name'

              if val == 'null' 
                '(unknown)'
              else 
                val

            DIV 
              className: 'segment_val_amount'

              visitors.length 
          ]




window.TimeSeriesAreaGraph = ReactiveComponent
  displayName: 'TimeSeriesAreaGraph'

  render: -> 
    DIV
      ref: 'container'

  componentDidMount: -> 
    series = @props.series 


    # Set the dimensions of the canvas / graph
    margin = {top: 40, right: 28, bottom: 50, left: 28}
    width = @props.width - margin.left - margin.right
    height = 250 - margin.top - margin.bottom
    
    # Set the ranges
    x = d3.scaleTime().range([0, width])

    if @props.log == 'log10'
      y = d3.scaleLog()
            .domain([0.1, 100])
            .range([height, 0])
    else 
      y = d3.scaleLinear().range([height, 0])

    z = d3.scaleOrdinal(d3.schemeCategory10)

    formatDate = d3.timeParse(@props.time_format or "%d-%b-%y")

    x.domain [
      d3.min(series, (c) -> d3.min(c.values, (d) -> formatDate(d[0])))
      d3.max(series, (c) -> d3.max(c.values, (d) -> formatDate(d[0])))
    ]

    y_min = d3.min(series, (c) -> d3.min(c.values, (d) -> d[1]))
    y_max = d3.max(series, (c) -> d3.max(c.values, (d) -> d[1]))
    y.domain [
      y_min
      y_max
      
    ] 
    z.domain series.map( (d) -> d.id )

    # Define the axes
    xAxis = d3.axisBottom(x)


    yAxis = d3.axisLeft(y)
              .ticks(Math.min(height / 40, y_max - y_min))    

    if @props.log == 'log10'
      yAxis         
        .ticks(0, ".1s")

    # Define the line
    area = d3.area()
      .curve(d3.curveBasis)  # needs to be upgraded to line.curve
      .x((d) -> x(formatDate(d[0])))
      .y0(y(0))
      .y1((d) -> y(d[1]))

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
      .attr('transform', 'translate(0,' + (height + 16) + ')')
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
                .data(series)
                .enter()
                  .append('g')
                  .attr('class', 'measure')


    measure
      .append('path')
        .attr 'class', 'line'
        .style 'stroke', (d) -> z(d.id)
        .style 'fill', (d) -> z(d.id) + '66'
        .attr('d', (d) -> area(d.values))


