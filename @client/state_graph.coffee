#######
# State graph
#
# Reflective visualization for probing component data dependencies & component 
# parent-child relationships. 
#
# TODO:
#   - method of using app itself & the stategraph at same time
#   - make it easier to see node names; hover isn't cutting it
#   - hover over link tooltip; show endpoints
#   - consider a directed graph
#   - stable color assignments

# require './vendor/d3.v3.min'
# require './vendor/d3.tip.js'

##########
# Initialize

fetch 'state_graph',
  on: false
  show_component_parent_child_relations: false
  show_unused_data: false
  show_data_dependencies: true
  removed_nodes: []
  focus: null

document.addEventListener "keypress", (e) -> 
  key = (e and e.keyCode) or e.keyCode

  if key==7 # cntrl-G
    graph = fetch('state_graph')
    graph.on = !graph.on
    save graph

for el of React.DOM
  if !window[el.toUpperCase()] 
    this[el.toUpperCase()] = React.DOM[el]

######
# StateGraph
#
# The visualization. Shows at top of page. Auto refreshes 
# based on statebus data and new React components. 
#
# Can be opened by pressing cntrl-G
#
window.StateGraph = ReactiveComponent
  displayName: 'State Graph'

  render: ->
    graph = fetch 'state_graph'

    if !@local.nodes?
      @local.nodes = {}
      @local.links = {}
      save @local


    if !graph.on
      return SPAN null

    # For displaying a counter...
    num_components = (n for own k,n of @local.nodes when !n.is_key).length.toString()
    num_data_entries = (n for own k,n of @local.nodes when n.is_key).length.toString()
    num_dependencies = (l for own k,l of @local.links \
                          when xor(\
                           @local.nodes[k.split(',')[0]].is_key, \
                           @local.nodes[k.split(',')[1]].is_key)).length.toString()

    pad = (num, len) -> 
      str = num.toString()
      i = 0 
      while i < len - num.toString().length
        str = "0" + str
        i += 1
      str

    max_digits = Math.max num_dependencies.length, \
                          num_components.length, \
                          num_data_entries.length

    counter = [ [pad(num_components,   max_digits), 'components'], \
                [pad(num_data_entries, max_digits), 'data entries'], \
                [pad(num_dependencies, max_digits), 'dependencies'] ]

    instructions = ['Drag/click any node to fix its position', \
                    'Shift+click a fixed node to free it', \
                    'Click a data node to see its values', \
                    'Alt+click a node to remove it']

    controls = [ ['parent-child links', 'show_component_parent_child_relations'], \
                 ['data dependencies', 'show_data_dependencies'], \
                 ['unused_data', 'show_unused_data'] ]

    control_button = (label, prop) -> 
      active = graph[prop]
      SPAN 
        style: 
          borderRadius: 8
          border: "1px solid #{if active then '#88EB39' else 'black'}"
          fontSize: 24
          fontFamily: 'Orbitron, sans-serif'
          padding: '12px 20px 8px 20px'
          color: if active then "#56BA06" else 'black'
          cursor: 'pointer'
          marginRight: 20

        onClick: -> 
          graph[prop] = !graph[prop]
          save graph

        label

    DIV 
      style:
        backgroundColor: 'white'
        zIndex: 9999999
        padding: '20px 5px 20px 50px'

      # header area
      DIV 
        style: 
          position: 'relative'

        # banner
        DIV
          style: 
            fontSize: 65
            color: 'black'
            WebkitTextFillColor: 'white'
            WebkitTextStrokeWidth: 1
            WebkitTextStrokeColor: 'black'
            fontFamily: 'Orbitron, sans-serif'

          'Welcome to State Space'

        # counter + instructions
        DIV 
          style: 
            marginTop: 5

          DIV 
            style: 
              display: 'inline-block'

            for [num, label] in counter
              DIV 
                style: 
                  marginBottom: 15

                for digit in num
                  SPAN
                    style: 
                      border: '1px solid #f4f4f4'
                      boxShadow: '0 1px 1px black'
                      paddingTop: 7
                      fontWeight: 600
                      fontFamily: 'Orbitron, sans-serif'
                      fontSize: 30
                      marginRight: 8
                      width: 36
                      display: 'inline-block'
                      textAlign: 'center'
                    digit
                SPAN
                  style: 
                    marginLeft: 10
                    fontSize: 24
                    marginTop: 10
                    fontFamily: 'Orbitron, sans-serif'
                  label

          DIV           
            style: 
              fontSize: 24
              color: 'black'
              marginLeft: 150
              display: 'inline-block'
              padding: '15px 0'
              fontFamily: 'Orbitron, sans-serif'
              fontSize: 24
              verticalAlign: 'top'

            for inst in instructions

              DIV
                style: 
                  marginBottom: 11

                inst

        # controls
        DIV 
          style: 
            margin: '25px 0'

          for [label, prop] in controls 
            control_button label, prop

          A
            style: 
              textDecoration: 'underline'
              margin: '0 10px'
              fontSize: 24
              fontFamily: 'Orbitron, sans-serif'

            onClick : (e) => 
              e.stopPropagation()
              graph.removed_nodes = []
              graph.focus = null
              for own k,v of @local.nodes
                v.fixed = false
              save graph
            'reset nodes'


      # data for a focus node
      if graph.focus 
        focus = @local.nodes[graph.focus]
        if focus.is_key
          DIV 
            style: 
              position: 'relative'

            DIV 
              style:
                position: 'absolute'
                left: document.body.clientWidth - 290
                top: 10
                backgroundColor: 'white'
                overflow: 'hidden'
                zIndex: 1

              for own k,v of arest.cache[focus.name] #don't call fetch b/c we don't want dependency
                text = pretty_print v
                DIV
                  style: 
                    maxWidth: 230
                    backgroundColor: 'white'
                    marginBottom: 10

                  DIV 
                    style: 
                      fontFamily: 'Orbitron, sans-serif'                          
                    k
                  DIV 
                    style: 
                      paddingLeft: 10
                      fontSize: 12

                    for para,idx in text.split('\n')
                      [if idx > 0
                        BR null
                      SPAN null, para]

      DIV 
        id: 'state_graph'
        ref: 'graph' 
        style: 
          border: '1px solid #eee'

      LINK 
        href: 'http://fonts.googleapis.com/css?family=Orbitron:400,500,700' 
        rel: 'stylesheet' 
        type: 'text/css'


      STYLE null,
        '''
          .tooltip { 
            font-family: Orbitron, sans-serif;
            color: red;
            font-weight: 700;
            font-size: 32px;
            -webkit-text-fill-color: red; /* Will override color (regardless of order) */
            -webkit-text-stroke-width: 1px;
            -webkit-text-stroke-color: white;
          }
          .tooltip.component { 
            color: blue;
            -webkit-text-fill-color: blue;

          }
        '''

  componentDidUpdate : -> 
    graph = fetch 'state_graph'

    if graph.on
      @drawGraph()
      if !@interval 
        @interval = setInterval @drawGraph, 2000

    else 
      if @interval
        clearInterval @interval 

      @force = @interval = null


  drawGraph : -> 
    # TODO: - maintain nodes/links across updates
    #       - resume simulation with particular alpha
    #         given changes in nodes/links
    #       - prevent collisons
    #       - keep in bounds

    graph = fetch 'state_graph'

    # Build our network
    [new_nodes, new_links, stale_nodes, stale_links] = refresh_data @local.nodes, @local.links

    delta = Object.keys(new_nodes).length + \
            Object.keys(new_links).length + \
            stale_nodes.length + \
            stale_links.length 

    hash = @compute_hash()

    return if delta == 0 && @force && @last_hash == hash

    for own k,v of new_nodes
      @local.nodes[k] = v

    for own k,v of new_links
      @local.links[k] = v

    for k in stale_nodes
      delete @local.nodes[k]

    for k in stale_links
      delete @local.links[k]

    [d3_nodes, d3_links] = transform_to_d3 @local.nodes, @local.links
    
    # build the viz
    width = document.body.clientWidth - 300
    height = 700

    if !@force
      @force = d3
        .layout
        .force()
        .charge (d) -> Math.min(-50 * d.weight, -100)
        .chargeDistance 220
        .gravity .01
        .friction .5
        .linkDistance (l) -> nodeSize(l.source) + nodeSize(l.target) + 3
        .size [width, height]

      svg = d3
        .select '#state_graph'
        .append 'svg'
        .attr 'width', width
        .attr 'height', height

      # Tooltip for hovering over a node
      tip = d3.tip()
        .attr 'class', 'd3-tip'
        .offset [-10, 0]
        .html (d) -> 
          "<div class='tooltip #{if d.is_key then 'cache-key' else 'component'}'>" + \
          "#{if d.is_key then 'data' else 'code'}:#{d.name}" + \
          "</div>"
      svg.call tip

    else 
      svg = d3.select '#state_graph svg'

    # Generate some SVG gradients
    d3
      .select '#state_graph_defs'
      .remove()
    defs = svg
      .append 'defs'
      .attr 'id', 'state_graph_defs'
    addSVGDefs defs, d3_nodes

    @force
      .nodes d3_nodes
      .links d3_links
      .start()

    link = svg
      .selectAll '.link'
      .data d3_links

    link
      .enter()
      .append 'line'
      .attr 'class', 'link'
      .style 'stroke-width', 1

    link
      .exit()
      .remove()

    link
      .style 'stroke', (l) => 
        if graph.focus == l.source.graph_key || graph.focus == l.target.graph_key
          "rgb(213, 231, 255)"
        else
          "rgb(240,240,240)"


    drag = @force
      .drag()
      .on "dragstart", (d) -> d.fixed = true

    node = svg
      .selectAll '.node'
      .data d3_nodes

    node
      .enter()
      .append 'rect'
      .attr 'class', (d) -> if d.is_key then 'node cache-key' else 'node component'
      .style 'cursor', 'pointer'
      .on 'mouseover', (d) => tip.show d
      .on 'mouseout', (d) => tip.hide d
      .on 'click', (d) -> 
        if d3.event.altKey
          graph.removed_nodes.push d.graph_key
        else if d3.event.shiftKey && d.fixed
          d.fixed = false
          if graph.focus == d.graph_key 
            graph.focus = null 
        else
          if graph.focus == d.graph_key 
            graph.focus = null 
          else 
            graph.focus = d.graph_key

        save graph
      .call drag

    node
      .exit()
      .remove()

    node
      .attr 'width', (d) -> 2 * nodeSize d
      .attr 'height', (d) -> 2 * nodeSize d
      .attr 'rx', (d) -> if d.is_key then nodeSize(d) else nodeSize(d) / 10
      .attr 'ry', (d) -> if d.is_key then nodeSize(d) else nodeSize(d) / 10
      .style 'fill', (d) -> 
        if !d.is_key 
          "url(#radial-component-#{d.component})" 
        else 
          "url(#radial-cache-key-#{d.prefix})"
      .style 'stroke', (d) -> 
        if graph.focus == d.graph_key || d.fixed
          'black'          
        else 
          'transparent'
      .style 'stroke-width', (d) -> 
        if graph.focus == d.graph_key
          3
        else if d.fixed
          1
        else
          0

    # Sort because z-index doesn't work on SVG elements.
    # We want all links below nodes, and big nodes below
    # small nodes. 
    svg.selectAll('.node, .link').sort (a,b) -> 
      if a.target? && b.target?
        0
      else if a.target?
        -1
      else if b.target
        1
      else
        b.weight - a.weight


    @force.on 'tick', (e) ->

      # handle collisions
      q = d3.geom.quadtree d3_nodes
      for d in d3_nodes
        q.visit collide(d)

        # stay within bounds; repel much farther inwards
        # to help clusters recover from sticking to edges
        if d.x < nodeSize(d)
          d.x = Math.max d.x, nodeSize(d) * 5
        if d.x > width - nodeSize(d)
          d.x = Math.min d.x, width - nodeSize(d) * 5

        if d.y < nodeSize(d)
          d.y = Math.max d.y, nodeSize(d) * 5
        if d.y > height - nodeSize(d)
          d.y = Math.min d.y, height - nodeSize(d) * 5


      link
        .attr 'x1', (d) -> d.source.x
        .attr 'y1', (d) -> d.source.y
        .attr 'x2', (d) -> d.target.x
        .attr 'y2', (d) -> d.target.y
      node
        .attr 'x', (d) -> d.x - nodeSize(d)
        .attr 'y', (d) -> d.y - nodeSize(d)

      return

    @last_hash = @compute_hash()
    save @local

  compute_hash : -> 
    props = {}
    for obj in [@local, fetch('state_graph')]
      for own k,v of obj
        if k != 'links' && k != 'nodes' && k != 'key'
          props[k] = v
    JSON.stringify props

nodeSize = (node) -> Math.sqrt(4 * node.weight) + 3


collide = (node) -> 
  (quad, x1, y1, x2, y2) -> 
    if quad.leaf && quad.point && quad.point != node
      dx = node.x - quad.point.x
      dy = node.y - quad.point.y
      dist = Math.sqrt(dx * dx + dy * dy)
      combined_r = nodeSize(node) + nodeSize(quad.point)

      # repel both points equally in opposite directions if they overlap
      if (dist < combined_r) 
        separate_by = if dist == 0 then 1 else ( dist - combined_r ) / dist
        offset_x = dx * separate_by * .6
        offset_y = dy * separate_by * .6

        node.x -= offset_x
        node.y -= offset_y
        quad.point.x += offset_x
        quad.point.y += offset_y
      
    neighborhood_radius = nodeSize(node) + 16
    nx1 = node.x - neighborhood_radius
    nx2 = node.x + neighborhood_radius
    ny1 = node.y - neighborhood_radius
    ny2 = node.y + neighborhood_radius

    return x1 > nx2 || 
            x2 < nx1 ||
            y1 > ny2 ||
            y2 < ny1


#######
# Identify any new nodes or links; and any now unused
# nodes.  

refresh_data = (nodes, links) ->

  processed_links = {}
  processed_nodes = {}

  new_nodes = {}
  new_links = {}
  stale_nodes = []
  stale_links = []

  # Make a node for each cache key
  for own k,v of arest.cache
    key = "_#{k}"
    if !(key of nodes)      
      new_nodes[key] = 
        name: k
        prefix: k.split('/').filter( (f) -> f != '')[0]
        is_key: true
        graph_key: key
    processed_nodes[key] = 1

  # Make a node for each component.
  for own k,v of arest.components
    if !(k of nodes)
      new_nodes[k] = 
        name: v.name
        component: v.name
        graph_key: k
        is_key: false

    processed_nodes[k] = 1

    # Link each component to its cache dependencies
    for dep in arest.keys_4_component.get(k)
      key = ["_#{dep}", k]
      if !(key of links)
        new_links[ key ] = 1
      processed_links[key] = 1


  # Link each component to its parent component
  for own k,v of arest.components
    if v._owner
      parent = v._owner.local_key
      key = if parent < k then [parent, k] else [k, parent]
      if !(key of links)
        new_links[ key ] = 1
      processed_links[key] = 1

  # remove nodes that no longer exist
  for own k,v of nodes
    if k not of processed_nodes
      stale_nodes.push k

  # remove links that no longer exist
  for own k,v of links
    if k not of processed_links
      stale_links.push k

  [new_nodes, new_links, stale_nodes, stale_links]


# Takes our nodes and links and transforms them into d3-consumable
# data, while also accommodating the current state graph visualization
# configuration. 
transform_to_d3 = (nodes, links) -> 
  graph = fetch 'state_graph'

  show_data = graph.show_data_dependencies
  show_component = graph.show_component_parent_child_relations
  show_unused_data = graph.show_unused_data

  d3_nodes = []
  d3_links = []

  link_enabled = (n1, n2) -> 
    present = "#{n1},#{n2}" of links
    enabled = (show_data      && xor(nodes[n1].is_key, nodes[n2].is_key)) || \
              (show_component && (!nodes[n1].is_key && !nodes[n2].is_key))
    active = !(n1 in graph.removed_nodes) && !(n2 in graph.removed_nodes)

    present && enabled && active

  # Prepare link weights to find orphaned nodes
  if !(show_unused_data && show_data)
    weights = {}

    for own k,v of links
      [k1,k2] = k.split(',')

      if link_enabled k1, k2
        weights[k1] = 1 + (weights[k1] or 0)
        weights[k2] = 1 + (weights[k2] or 0)


  d3_nodes = (nodes[k] for k in Object.keys(nodes) \
              when (show_unused_data && show_data) || k of weights)

  node_idx = {}
  for n,idx in d3_nodes
    node_idx[n.graph_key] = idx

  for n1, i in d3_nodes
    for n2, j in d3_nodes
      if i < j
        if n1.graph_key < n2.graph_key
          key = [n1.graph_key, n2.graph_key]
        else 
          key = [n2.graph_key, n1.graph_key]

        if link_enabled key[0], key[1]

          d3_links.push
            source: node_idx[key[0]]
            target: node_idx[key[1]]
            value: links[key]

  [d3_nodes, d3_links]



################
# SVG helpers

addSVGDefs = (defs, nodes) -> 
  cache_prefixes = {}
  component_names = {}

  for n in nodes
    if n.is_key
      cache_prefixes[n.prefix] = (cache_prefixes[n.prefix] or 0) + 1
    else 
      component_names[n.component] = (component_names[n.component] or 0) + 1

  hues = getNiceRandomHues Object.keys(cache_prefixes).length, .1
  i = 0
  for own k,v of cache_prefixes
    h = hues[i]
    s = .8
    addGradient 'linearGradient', defs, "radial-cache-key-#{k}", hsv2rgb(h,1.0,1.0), hsv2rgb(h,1.0,.8) 
    i += 1

  hues = getNiceRandomHues Object.keys(component_names).length, .5
  i = 0
  for own k,v of component_names
    h = hues[i]
    addGradient 'linearGradient', defs, "radial-component-#{k}", hsv2rgb(h,.8,.6), hsv2rgb(h,.8,.5)
    i += 1

addGradient = (gradient, defs, id, c1, c2) ->

  gradient = defs
    .append gradient
    .attr 'id', id
    .attr 'fx', '25%'
    .attr 'fy', '25%'

  gradient
    .append 'stop'
    .attr 'offset', '10%'
    .attr 'stop-color', c1

  gradient
    .append 'stop'
    .attr 'offset', '95%'
    .attr 'stop-color', c2 



# Utilities

xor = (a,b) -> ( a || b ) && !( a && b )

pretty_print = (obj) -> 
  result = ""
  if Array.isArray(obj)
    if obj.length == 0
      result = "[]"
    else
      result += "[\n"
      for k,idx in obj
        result += "#{pretty_print(k)}"
        result += ', ' if idx != obj.length - 1
      result += "\n]"
  else if obj == null
    result += 'null'
  else if typeof obj == 'object'
    result += "{\n"
    for own k,v of obj
      result += "#{k}: #{pretty_print(v)},"

    result += "\n}\n"
  else if typeof obj == 'string'
    if obj == ''
      result += '""'
    else
      result += obj
  else if typeof obj == 'function'
    result += '[function]'
  else
    result += JSON.stringify(obj)

  return result

