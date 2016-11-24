require '../vendor/d3.v3.min'


smooth = (series, window_l) -> 
  for d,idx in series 
    range = (i for i in [idx - window_l + 1..idx] when i >= 0)
    tot = 0
    for p in range 
      tot += series[p][2]
    d.push tot / range.length

  series

window.Metrics = ReactiveComponent
  displayName: 'Metrics'

  render: -> 
    m = fetch '/metrics'

    if !@local.log?
      @local.log = 'linear'
      @local.time_frame = 'all time'

    if !m.daily_active_contributors
      return DIV 
                style: 
                  margin: '100px auto'
                  fontSize: 36
                  width: 400
                  textAlign: 'center'
                'Loading metrics, might be a minute' 

    if @local.time_frame == 'all time'
      metrics = m 
    else 
      metrics = _.extend m,
        daily_active_contributors: (d for d in m.daily_active_contributors when d[0] < 365)
        daily_active_subdomains: (d for d in m.daily_active_subdomains when d[0] < 365)


    DIV 
      style: 
        margin: 60
        minHeight: window.innerHeight
      STYLE null,
        """
          .axis path,
          .axis line {
            fill: none;
            stroke: #000;
            shape-rendering: crispEdges;
          }

          .line {
            fill: none;
            stroke: steelblue;
            stroke-width: 1.5px;
          }

          .line2 {
            fill: none;
            stroke: magenta;
            stroke-width: 1.5px;
          }


          .tick line{
              opacity: 0.1;
            }

          .tick text{
              font-size: 12px;
            }            
        """


      DIV 
        style: 
          fontSize: 24
          textAlign: 'center'

        "Daily unique contributors"

        SPAN
          style: 
            fontSize: 14
            border: '1px solid #ccc'
            padding: '2px 4px'
            cursor: 'pointer'
            borderRadius: 8
            display: 'inline-block'
            marginLeft: 10

          onClick: => 
            if @local.log == 'linear'
              @local.log = 'log10'
            else 
              @local.log = 'linear'

            save @local 

          @local.log 

        SPAN
          style: 
            fontSize: 14
            border: '1px solid #ccc'
            padding: '2px 4px'
            cursor: 'pointer'
            borderRadius: 8
            display: 'inline-block'
            marginLeft: 10

          onClick: => 
            if @local.time_frame == 'all time'
              @local.time_frame = 'past 365 days'
            else 
              @local.time_frame = 'all time'

            save @local 

          @local.time_frame 



      LineGraph
        key: "contributors-#{@local.log}-#{@local.time_frame }"
        data: smooth(metrics.daily_active_contributors, 30)
        width: WINDOW_WIDTH() - 60 * 2  
        log: @local.log


      DIV 
        style: 
          fontSize: 24
          marginTop: 40
          textAlign: 'center'

        "Daily active subdomains"

      LineGraph
        key: "subs-#{@local.log}-#{@local.time_frame }"
        data: smooth(metrics.daily_active_subdomains, 30)
        width: WINDOW_WIDTH() - 60 * 2
        log: @local.log


      DIV 
        style: 
          fontSize: 24
          marginTop: 40
          textAlign: 'center'

        "Total Usage (sum of Daily Unique Contributors)"

        do => 

          contributions = []
          for subdomain, contributors of metrics.contributors_per_subdomain when contributors.lifetime > 1
            contributions.push [subdomain, contributors]

          if !@local.sort_contributions_by?
            @local.sort_contributions_by = 'year'

          contributions.sort (a,b) => 
            if @local.sort_contributions_by in ['opinions_per_subdomain', 'opinions_and_inclusions_per_subdomain']
              metrics[@local.sort_contributions_by][b[0]] - metrics[@local.sort_contributions_by][a[0]]
            else 
              b[1][@local.sort_contributions_by] - a[1][@local.sort_contributions_by]

          sort_on_click = (e) =>
            @local.sort_contributions_by = e.currentTarget.getAttribute('data-time')
            save @local

          td_style =
            padding: '0 8px'
          th_style =
            padding: '2px 8px'
            fontWeight: 'bold'
            cursor: 'pointer'
            borderBottom: '1px solid #999'

          TABLE style: {margin: 'auto'}, TBODY null,
            TR null,
              TH 
                style: _.extend {}, th_style, 
                  textAlign: 'right'
                  cursor: 'default'
                'Name'
              TH onClick: sort_on_click, 'data-time': 'opinions_per_subdomain', style: th_style, 'Opinions'
              TH onClick: sort_on_click, 'data-time': 'opinions_and_inclusions_per_subdomain', style: th_style, '+inclusions'              
              TH onClick: sort_on_click, 'data-time': 'active', style: th_style, 'Days active'
              TH onClick: sort_on_click, 'data-time': 'lifetime', style: th_style, 'Lifetime'
              TH onClick: sort_on_click, 'data-time': 'year', style: th_style, 'Past year'
              TH onClick: sort_on_click, 'data-time': 'month', style: th_style, 'Past month'
              TH onClick: sort_on_click, 'data-time': 'week', style: th_style, 'Past week'
              TH onClick: sort_on_click, 'data-time': 'day', style: th_style, 'Past day'

            for cont in contributions 
              [subdomain, contributors] = cont
              TR null, 
                TD 
                  style: _.extend {}, td_style, 
                    textAlign: 'right'

                  A 
                    href: "https://#{fetch("/subdomain/#{subdomain}").name}.consider.it"
                    title: fetch("/subdomain/#{subdomain}").name 
                    style: 
                      color: focus_blue
                      textDecoration: 'underline'
                      display: 'inline-block'
                      maxWidth: 200
                      overflow: 'hidden'
                    fetch("/subdomain/#{subdomain}").name 

                TD style: td_style, metrics.opinions_per_subdomain[subdomain]
                TD style: td_style, metrics.opinions_and_inclusions_per_subdomain[subdomain]
                TD style: td_style, contributors.active
                TD style: td_style, contributors.lifetime
                TD style: td_style, contributors.year
                TD style: td_style, contributors.month
                TD style: td_style, contributors.week
                TD style: td_style, contributors.day

LineGraph = ReactiveComponent
  displayName: 'LineGraph'

  render: -> 
    DIV
      ref: 'container'

  componentDidMount: -> 
    data = @props.data

    # Set the dimensions of the canvas / graph
    margin = {top: 20, right: 50, bottom: 30, left: 50}
    width = @props.width - margin.left - margin.right
    height = 250 - margin.top - margin.bottom
    
    # Set the ranges
    x = d3.time.scale().range([0, width])

    if @props.log == 'log10'
      y = d3.scale.log()
            .domain([0.1, 100])
            .range([height, 0])
    else 
      y = d3.scale.linear().range([height, 0])

    z = d3.scale.category10()


    # Define the axes
    xAxis = d3.svg
              .axis()
              .scale(x)
              .orient('bottom')
              #.ticks(5)
              # .innerTickSize(-height)
              # .outerTickSize(0)
              # .tickPadding(10)              

    yAxis = d3.svg
              .axis()
              .scale(y)
              .orient('left')
              #.ticks(5)
              .innerTickSize(-width)
              .outerTickSize(0)
              .tickPadding(10)
    if @props.log == 'log10'
      yAxis         
        .ticks(0, ".1s")

    yAxis_right = d3.svg
              .axis()
              .scale(y)
              .outerTickSize(0)              
              .orient('right')

    if @props.log == 'log10'
      yAxis_right         
        .ticks(0, ".1s")

    formatDate = d3.time.format("%d-%b-%y")

    series = [
      {
        id: 'daily'
        values: data.map( (d) -> [d[1], Math.max(d[2],.1)] )
      }, {
        id: 'monthly'
        values: data.map( (d) -> [d[1], Math.max(d[3],.1)] )
      }
    ]


    # Define the line
    valueline = d3.svg.line()
      .interpolate("basis")
      .x((d) -> x(formatDate.parse(d[0])))
      .y((d) -> y(d[1]))

    # Adds the svg canvas
    container = d3.select(@getDOMNode())
    svg = container.append('svg')
            .attr('width', width + margin.left + margin.right)
            .attr('height', height + margin.top + margin.bottom)

    g = svg.append('g')
          .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')

    x.domain d3.extent(data, (d) -> formatDate.parse(d[1]))
    y.domain [
      d3.min(series, (c) -> d3.min(c.values, (d) -> d[1]))
      d3.max(series, (c) -> d3.max(c.values, (d) -> d[1]))
    ] 
    z.domain data.map( (d) -> d.id )


    # Add the X Axis
    g.append('g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(0,' + height + ')')
      .call xAxis

    # Add the Y Axis
    g.append('g')
      .attr('class', 'y axis')
      .call yAxis

    g.append('g')
      .attr('class', 'y axis')
      .attr("transform", "translate(" + width + " ,0)")           
      .call yAxis_right


    measure = g.selectAll('.measure')
                .data(series)
                .enter()
                  .append('g')
                  .attr('class', 'measure')

    measure
      .append('path')
        .attr('class', 'line')
        .attr('d', (d) -> valueline(d.values))
        .style 'stroke', (d) -> z(d.id)


