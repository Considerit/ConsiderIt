require '../vendor/d3.v3.min'


smooth = (series, window_l) -> 
  for d,idx in series 
    range = (i for i in [idx - window_l + 1..idx] when i >= 0)
    tot = 0
    for p in range 
      tot += series[p][1]
    d.push tot / range.length

  series

window.Metrics = ReactiveComponent
  displayName: 'Metrics'

  render: -> 
    metrics = fetch '/metrics'

    if !@local.log?
      @local.log = 'linear'

    return loading_indicator if !metrics.daily_active_contributors

    DIV 
      style: 
        margin: 60

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



      LineGraph
        key: "contributors-#{@local.log}"
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
        key: "subs-#{@local.log}"
        data: smooth(metrics.daily_active_subdomains, 30)
        width: WINDOW_WIDTH() - 60 * 2
        log: @local.log

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
        values: data.map( (d) -> [d[0], Math.max(d[1],.1)] )
      }, {
        id: 'monthly'
        values: data.map( (d) -> [d[0], Math.max(d[2],.1)] )
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

    x.domain d3.extent(data, (d) -> formatDate.parse(d[0]))
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


