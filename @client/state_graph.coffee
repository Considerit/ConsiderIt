




for el of React.DOM
  this[el.toUpperCase()] = React.DOM[el]



window.StateGraph = ReactiveComponent
  displayName: 'State Graph'

  render: ->
    graph = @fetch('state_graph')
    location = @fetch('location')

    DIV 
      style:
        backgroundColor: 'black'

      if graph.on
        [DIV 
          style: 
            fontSize: 50
            color: 'white'
            fontFamily: 'lobster'

          'State Constellation'

        DIV 
          id: 'state_graph'
          ref: 'graph' 

        STYLE null,
          '''
            .sun { 
              -webkit-filter: drop-shadow( 0px 1px 2px #000 );
                      filter: drop-shadow( 0px 1px 2px #000 );
              -webkit-svg-shadow: 0px 1px 2px #000;           
            }
          '''

        ]

  componentDidUpdate : -> 
    graph = @fetch('state_graph')

    return if !graph.on

    node = @refs.graph.getDOMNode()
    while node.firstChild
      node.removeChild node.firstChild


    nodeSize = (weight) -> 2 * weight + 3
    weight = (node) -> 
      if node.name of data.weights then data.weights[node.name] else 1
    is_key = (node) -> 
      node.name.indexOf(']') == -1

    data = generate_data()
    console.log data
    
    width = document.body.clientWidth
    height = 1500
    color = d3.scale.category20()

    force = d3
      .layout
      .force()
      .charge(-320)
      .gravity(.5)
      .linkDistance( (l) -> nodeSize( weight(l.source)) + nodeSize(weight(l.target)))
      .size([width, height])

    svg = d3
      .select('#state_graph')
      .append('svg')
      .attr('width', width)
      .attr('height', height)

    force
      .nodes(data.nodes)
      .links(data.links)
      .start()

    link = svg
      .selectAll('.link')
      .data(data.links)
      .enter()
      .append('line')
      .attr('class', 'link')
      .style('stroke-width', (l) -> if is_key(l.source) && is_key(l.target) then 0 else 1 )
      .style('stroke', "rgb(50,50,50)" )

    node = svg
      .selectAll('.node')
      .data(data.nodes)
      .enter()
      .append('circle')
      .attr('class', (n) -> if is_key(n) then 'sun' else 'planet')
      .attr('r', (d) -> nodeSize( weight(d) ))
      .style('fill', (d) -> if d.group == 1 then 'rgb(155,155,155)' else 'rgb(255,225,180)')
      .style('z-index', (d) -> 999999 - weight(d))
      .call(force.drag)

    node.append('title').text (d) -> d.name

    force.on 'tick', ->
      link
        .attr('x1', (d) -> d.source.x)
        .attr('y1', (d) -> d.source.y)
        .attr('x2', (d) -> d.target.x)
        .attr('y2', (d) -> d.target.y)
      node
        .attr('cx', (d) -> d.x)
        .attr('cy', (d) -> d.y)

      return

generate_data = -> 
  nodes = []
  node_idx = {}
  links = []
  weights = {}

  # Make a node for each cache key
  for own k,v of arest.cache
    node = 
      name: k
      group: 2

    node_idx["#{k}-k"] = nodes.length
    nodes.push node

  # Make a node for each component.
  # Link each component to its cache dependencies
  for own k,v of arest.components
    node = 
      name: "#{v.name} [#{k}]"
      group: 1

    node_idx["#{k}-c"] = nodes.length
    nodes.push node   

    for dep in arest.keys_4_component.get(k)
      link = 
        target: node_idx["#{dep}-k"]
        source: node_idx["#{k}-c"]
        value: 1
      links.push link

      if dep of weights
        weights[dep] += 1
      else 
        weights[dep] = 1

      weights["#{v.name} [#{k}]"] = 1

  # Link each weighty cache key with other keys so that we can make
  # sure they don't overlap each other
  i = 0
  for own k,v of arest.cache
    j = 0
    for own k2,v2 of arest.cache
      if j > i && (weights[k] + weights[k2] > 10)
        link = 
          target: node_idx["#{k2}-k"]
          source: node_idx["#{k}-k"]
          value: 0
        links.push link

      j += 1

    i += 1


  return {
    nodes: nodes
    links: links
    weights: weights
  }



fetch 'state_graph',
  on: false


document.addEventListener "keypress", (e) -> 
  key = (e and e.keyCode) or event.keyCode

  if key==7 # cntrl-G
    graph = fetch('state_graph')
    graph.on = !graph.on
    console.log graph
    save graph

