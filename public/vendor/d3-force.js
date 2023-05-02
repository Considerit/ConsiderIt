// Modified from: 

// Copyright 2021 Observable, Inc.
// Released under the ISC license.
// https://observablehq.com/@d3/force-directed-graph
function ForceGraph({
  nodes, // an iterable of node objects (typically [{id}, …])
  links // an iterable of link objects (typically [{source, target}, …])
}, {
  nodeId = d => d.id, // given d in nodes, returns a unique identifier (string)
  // nodeGroup, // given d in nodes, returns an (ordinal) value for color
  // nodeGroups, // an array of ordinal values representing the node groups
  nodeTitle, // given d in nodes, a title string
  nodeFill = "currentColor", // node stroke fill (if not using a group color encoding)
  nodeStroke = "#fff", // node stroke color
  nodeStrokeWidth = 1.5, // node stroke width, in pixels
  nodeStrokeOpacity = 1, // node stroke opacity
  nodeRadius = 50, // node radius, in pixels
  nodeStrength,
  linkSource = ({source}) => source, // given d in links, returns a node identifier string
  linkTarget = ({target}) => target, // given d in links, returns a node identifier string
  linkStroke = "#999", // link stroke color
  linkStrokeOpacity = 0.6, // link stroke opacity
  linkStrokeWidth = 1.5, // given d in links, returns a stroke width in pixels
  linkStrokeLinecap = "round", // link stroke linecap
  linkStrength,
  colors = d3.schemeTableau10, // an array of color strings, for the node groups
  width = 640, // outer width, in pixels
  height = 400, // outer height, in pixels
  invalidation, // when this promise resolves, stop the simulation
  ticker
} = {}) {
  // Compute values.
  const N = d3.map(nodes, nodeId).map(intern);
  const LS = d3.map(links, linkSource).map(intern);
  const LT = d3.map(links, linkTarget).map(intern);
  if (nodeTitle === undefined) nodeTitle = (_, i) => N[i];
  const T = nodeTitle == null ? null : d3.map(nodes, nodeTitle);
  // const G = nodeGroup == null ? null : d3.map(nodes, nodeGroup).map(intern);
  const W = typeof linkStrokeWidth !== "function" ? null : d3.map(links, linkStrokeWidth);
  const L = typeof linkStroke !== "function" ? null : d3.map(links, linkStroke);

  // Replace the input nodes and links with mutable objects for the simulation.
  nodes = d3.map(nodes, (_, i) => ({id: N[i], image: _.image, slug: _.id}));
  links = d3.map(links, (_, i) => ({id: _.id, source: LS[i], target: LT[i]}));

  // Compute default domains.
  // if (G && nodeGroups === undefined) nodeGroups = d3.sort(G);

  // Construct the scales.
  // const color = nodeGroup == null ? null : d3.scaleOrdinal(nodeGroups, colors);

  // Construct the forces.
  const forceNode = d3.forceManyBody();
  const forceLink = d3.forceLink(links).id(({index: i}) => nodes[i].id);
  if (nodeStrength !== undefined) forceNode.strength(nodeStrength);
  if (linkStrength !== undefined) forceLink.strength(linkStrength);

  window.reset = false;
  const simulation = d3.forceSimulation(nodes)
      .force("link", forceLink)
      .force("charge", forceNode.strength(-30))
      .force("center",  d3.forceCenter().strength(.1))
      .force('collision', d3.forceCollide().radius(nodeRadius))     
      .on("tick", ticked);  

  
  const svg = d3.create("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", [-width / 2, -height / 2, width, height])
      .attr("style", "max-width: 100%; height: auto; height: intrinsic;");


  // var link = svg.append("g")
  //     .attr("stroke", typeof linkStroke !== "function" ? linkStroke : null)
  //     .attr("stroke-opacity", linkStrokeOpacity)
  //     .attr("stroke-width", typeof linkStrokeWidth !== "function" ? linkStrokeWidth : null)
  //     .attr("stroke-linecap", linkStrokeLinecap)
  //   .selectAll("line")
  //   .data(links)
  //   .join("line");

  const link_g = svg.append("g")
  const borders_g = svg.append("g")
  const node_g = svg.append("g")

  var link_colors = {}

  def = node_g.append("defs")
  // clips = def.selectAll("clipPath")
  // //   .data(nodes)
  // //   .join("clipPath")    
  // //     .attr('id', function(d){return 'circlemask' + d.slug})
  // //     .append("circle")
  // //       .attr("cx", nodeRadius)
  // //       .attr("cy", nodeRadius)
  // //       .attr("r", nodeRadius)
  // //       .attr("fill", 'white')

  // node = g.selectAll("image")

  restart()


  if (ticker) {
    var my_ticker = ticker(nodes, links, restart, width, height)
    d3.interval(my_ticker.func, my_ticker.interval, my_ticker.time)
  } 

  // if (W) link.attr("stroke-width", ({index: i}) => W[i]);
  // if (L) link.attr("stroke", ({index: i}) => L[i]);
  // if (G) node.attr("fill", ({index: i}) => color(G[i]));
  // if (T) node.append("title").text(({index: i}) => T[i]);
  // if (invalidation != null) invalidation.then(() => simulation.stop());


  function restart(mult) {
    if (!mult) mult = 1


    if (mult == 1)
      simulation.alphaDecay(1 - Math.pow(simulation.alphaMin(), 1 / 5))
    else 
      simulation.alphaDecay(1 - Math.pow(simulation.alphaMin(), 1 / 2))


    clips = def.selectAll("clipPath")
      .data(nodes, d => d.id)
      .join(
        enter => enter     
          // .interrupt()
          .append("clipPath")    
          .attr('id', function(d){return 'circlemask' + d.slug})
          .append("circle")       
            .attr("cx", nodeRadius)
            .attr("cy", nodeRadius)
            .attr("r", nodeRadius)
            .attr("fill", 'white'),
        update => update,
        exit => exit
                  // .transition() // and apply changes to all of them
                  // .duration(200)                          
                  // .selectChild('circle')
                  //   .attr("r", 0)  
                  .remove()        

      )

    // Apply the general update pattern to the links.
    link = link_g.selectAll("line")
      .data(links, d => d.id)
      .join(
        enter => enter.append("line")
          .attr('stroke', l => {
            var key = l.source + "-" + l.target
            if (!link_colors[key]) {
              link_colors[key] = d3.interpolateRainbow(Math.random())
            }

            return link_colors[key]
          })
          .attr('stroke-width', d => d.value),
        update => update.attr('stroke-width', d => d.value),
        exit => exit                  
                  .transition() // and apply changes to all of them
                  .duration(100)
                  .attr("opacity", 0)
                  .remove()

      )

    // Apply the general update pattern to the nodes.

    circles = borders_g.selectAll("circle")
      .data(nodes, d => d.id)
      .join(
        enter => enter
                  .interrupt()
                  .append("circle")
                  .attr("r", nodeRadius + 3)
                  .attr("fill", "magenta"),
        update => update.attr("fill-opacity", d => d.fillOpacity),
        exit => exit
                  .transition() // and apply changes to all of them
                  .duration(200)
                  .attr("r", 0)
                  .remove()
      )


    node = node_g.selectAll("image")
      .data(nodes, d => d.id)
      .join(
        enter => enter
                  .interrupt()
                  .append("image")
                  .attr("href", function(d){return d.image})
                  .attr("width", nodeRadius * 2)
                  .attr("height", nodeRadius * 2)
                  .attr("clip-path", function(d){return "url(#circlemask" + d.slug +")"})
                  .append("title").text(d => d.id),
        update => update,
        exit => exit
                  .transition() // and apply changes to all of them
                  .duration(200)
                  .attr("width", 0)
                  .attr("height", 0)
                  .remove()
      )





    // console.log("STARTING!", nodes, links)
    // Update and restart the simulation.
    simulation.nodes(nodes);
    simulation.force("link").links(links);
    simulation.force('charge').strength(-2000 * mult)
    simulation.force('center').strength(.1 * mult)
    simulation.force('collision')
    simulation.alpha(1).restart();
    // console.log("before")
    // nodes.forEach( d => console.log(d.id, d.x, d.y, d.vx, d.vy))
    window.reset = true

  }

  function intern(value) {
    return value !== null && typeof value === "object" ? value.valueOf() : value;
  }

  function ticked() {
    // if (reset) {    
    //   console.log("after")
    //   nodes.forEach( d => console.log(d.id, d.x, d.y, d.vx, d.vy))
    // }

    link
      .attr("x1", d => d.source.x)
      .attr("y1", d => d.source.y)
      .attr("x2", d => d.target.x)
      .attr("y2", d => d.target.y);

    node
      .attr("x", d => d.x - nodeRadius)
      .attr("y", d => d.y - nodeRadius);

    circles
      .attr("cx", d => d.x)
      .attr("cy", d => d.y);


    def.selectAll("clipPath > circle")
      .attr("cx", d => d.x)
      .attr("cy", d => d.y);
  }

  function drag(simulation) {    
    function dragstarted(event) {
      if (!event.active) simulation.alphaTarget(0.3).restart();
      event.subject.fx = event.subject.x;
      event.subject.fy = event.subject.y;
    }
    
    function dragged(event) {
      event.subject.fx = event.x;
      event.subject.fy = event.y;
    }
    
    function dragended(event) {
      if (!event.active) simulation.alphaTarget(0);
      event.subject.fx = null;
      event.subject.fy = null;
    }
    
    return d3.drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended);
  }
  return svg.node()
  // return Object.assign(svg.node(), {scales: {color}});
}

window.ForceGraph = ForceGraph