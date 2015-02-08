//////
// Uses a d3-based physics simulation to calculate a reasonable layout
// of avatars within a given area.

window.positionAvatars = function(width, height, opinions) {
  width = width || 400
  height = height || 70

  var opinions = opinions.slice()
                   .sort(function (a,b) {return a.stance-b.stance}),
      n = opinions.length, 
      r = calculateAvatarRadius(width, height, opinions), 
      x_force_mult = 2,
      y_force_mult = height <= 100 ? 1 : 4,
      nodes, force

  // Initialize positions of each node
  nodes = d3.range(opinions.length).map(function(i) {
    var radius = opinions[i].radius || r

    if(parseFloat(opinions[i].icon.style.width) != radius * 2)
      opinions[i].icon.style.width = opinions[i].icon.style.height = radius*2 + 'px'

    // I'm finding that different initial conditions work better at different scales
    // Give large numbers of avatars some good initial spacing
    // Small numbers of avatars can be more precisely placed for quick 
    // convergence with little churn  
    x = opinions.length > 10 ? radius + (width- 2 * radius) * (i / n) : x_target(i)
    y = opinions.length == 1 ? height - radius : radius + Math.random() * (height - 2 * radius)

    return {
      index: i, 
      radius: radius,
      x: x,
      y: y
    }
  })

  // see https://github.com/mbostock/d3/wiki/Force-Layout for docs
  force = d3.layout.force()
    .nodes(nodes)
    .on("tick", tick)
    .on('end', function () {console.log('simulation complete')})
    .gravity(0)
    .charge(0)
    .chargeDistance(0)
    .start()

  // translates the opinion stance to a real x position in the bounding box
  function x_target(i) {
    return (opinions[i].stance + 1)/2 * width
  }

  // One iteration of the simulation
  function tick(e) {

    //////
    // Repel colliding nodes
    // A quadtree helps efficiently detect collisions
    var q = d3.geom.quadtree(nodes),
        i = 0, 
        some_node_moved = false
    while (++i < n)
      q.visit(collide(nodes[i]))

    //////
    // Apply standard forces
    nodes.forEach(function(o, i) {

      // Push node toward its desired x-location (e.g. stance)
      o.x += e.alpha * (x_force_mult * width  * .001) * (x_target(o.index) - o.x)

      // Push node downwards
      o.y += e.alpha * y_force_mult

      // Ensure node is still within the bounding box
      o.x = Math.max(o.radius, Math.min(width  - o.radius, o.x))
      o.y = Math.max(o.radius, Math.min(height - o.radius, o.y))

      // Re-position dom element...if it's moved enough      
      if ( !opinions[i].icon.style.left || Math.abs( parseFloat(opinions[i].icon.style.left) - (o.x - o.radius)) > .1 ){
        opinions[i].icon.style.left = o.x - o.radius + 'px'
        some_node_moved = true
      }

      if ( !opinions[i].icon.style.top || Math.abs( parseFloat(opinions[i].icon.style.top) - (o.y - o.radius)) > .1 ) {
        opinions[i].icon.style.top  = o.y - o.radius + 'px'
        some_node_moved = true
      }
    })

    // Complete the simulation if we've reached a steady state
    if (!some_node_moved)
      force.stop()
  }

  function collide(node) {

    return function(quad, x1, y1, x2, y2) {

      // Repel two nodes if they overlap
      if (quad.leaf && quad.point && quad.point !== node) {
        var dx = node.x - quad.point.x,
            dy = node.y - quad.point.y,
            dist = Math.sqrt(dx * dx + dy * dy),
            combined_r = node.radius + quad.point.radius

        if (dist < combined_r) {
          // repel both points equally in opposite directions

          var separate_by, offset_x, offset_y
          separate_by = dist == 0 ? 1 : ( dist - combined_r ) / dist
          offset_x = dx * separate_by * .5,
          offset_y = dy * separate_by * .5

          node.x -= offset_x
          node.y -= offset_y
          quad.point.x += offset_x
          quad.point.y += offset_y
          // Travis: Why doesn't the below converge, but the above does?
          // node.x += offset_x
          // node.y += offset_y
          // quad.point.x -= offset_x
          // quad.point.y -= offset_y

        }
      }

      // Visit subregions if we could possibly have a collision there
      // Travis: I understand what the 16 *does* but not the significance
      //         of the particular value. Does 16 make sense for all
      //         avatar sizes and sizes of the bounding box?
      var neighborhood_radius = node.radius + 16,
          nx1 = node.x - neighborhood_radius,
          nx2 = node.x + neighborhood_radius,
          ny1 = node.y - neighborhood_radius,
          ny2 = node.y + neighborhood_radius

      return x1 > nx2
          || x2 < nx1
          || y1 > ny2
          || y2 < ny1
    }
  }

}

// Calculate node radius based on size of area and number of nodes
window.calculateAvatarRadius = function(width, height, opinions) {
  var ratio_filled = .3, r

  r = Math.sqrt(width * height / opinions.length * ratio_filled)/2
  r = Math.min(r, width/2, height/2)

  // Travis: what's the purpose of this?
  if (opinions.length > 10) {
    // Now round r up until it fits perfectly within height
    var times_fit = height / (2*r)
    r = (height / (Math.floor(times_fit))) / 2 - .001
  }

  return r
}
