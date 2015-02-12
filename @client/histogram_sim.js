/////
// Calculate node radius based on size of area and number of nodes
window.calculateAvatarRadius = function(width, height, opinions) {
  var ratio_filled = .25, r

  r = Math.sqrt(width * height / opinions.length * ratio_filled)/2
  r = Math.min(r, width/2, height/2)

  // When there are lots of opinions, it's nice if they get all
  // grid-like.  We'll adjust the size to make it evenly divide the
  // box into a grid.
  if (opinions.length > 10) {
    // Now round r up until it fits perfectly within height
    var times_fit = height / (2*r)
    r = (height / (Math.floor(times_fit))) / 2 - .001
  }

  return r
}


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
      y_force_mult = height <= 100 ? 2 : 6,
      nodes, force, ticks = 0

  // Initialize positions of each node
  nodes = d3.range(opinions.length).map(function(i) {
    var radius = opinions[i].radius || r

    if(parseFloat(opinions[i].icon.style.width) != radius * 2)
      opinions[i].icon.style.width = opinions[i].icon.style.height = radius*2 + 'px'

    opinions[i].x_target = (opinions[i].stance + 1)/2 * width

    // Travis: I'm finding that different initial conditions work 
    // better at different scales.
    //   - Give large numbers of avatars some good initial spacing
    //   - Small numbers of avatars can be more precisely placed for quick 
    //     convergence with little churn  
    x = opinions.length > 10 ? radius + (width- 2 * radius) * (i / n) : opinions[i].x_target
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
    .on('end', end)
    .gravity(0)
    .charge(0)
    .chargeDistance(0)
    .start()

  // Called after the simulation stops
  function end() {
    total_energy = calculate_global_energy()
    console.log('Simulation complete after ' + ticks + ' ticks. ' + 
                'Energy of system could be reduced by at most ' + total_energy + ' by global sort.')
  }

  // One iteration of the simulation
  function tick(e) {

    var q, i = 0, some_node_moved = false

    //////
    // Repel colliding nodes
    // A quadtree helps efficiently detect collisions
    q = d3.geom.quadtree(nodes)
    while (++i < n)
      q.visit(collide(nodes[i]))

    //////
    // Apply standard forces
    nodes.forEach(function(o, i) {

      // Push node toward its desired x-position
      o.x += e.alpha * (x_force_mult * width  * .001) * (opinions[o.index].x_target - o.x)

      // Push node downwards
      // The last term helps accelerate unimpeded falling nodes
      o.y += e.alpha * y_force_mult * Math.max(o.y - o.py + 1, 1)

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

    ticks += 1

    // Complete the simulation if we've reached a steady state
    if (!some_node_moved) force.stop()

    
  }

  function collide(node) {

    return function(quad, x1, y1, x2, y2) {
      if (quad.leaf && quad.point && quad.point !== node) {
        var dx = node.x - quad.point.x,
            dy = node.y - quad.point.y,
            dist = Math.sqrt(dx * dx + dy * dy),
            combined_r = node.radius + quad.point.radius

        // Transpose two points in the same neighborhood if it would reduce energy of system
        // 10 is not a principled threshold. 
        if ( energy_reduced_by_swap(node, quad.point) > 10) { 
          swap_position(node, quad.point)          
          dx *= -1; dy *= -1
        }

        // repel both points equally in opposite directions if they overlap
        if (dist < combined_r) {
          var separate_by, offset_x, offset_y
          separate_by = dist == 0 ? 1 : ( dist - combined_r ) / dist
          offset_x = dx * separate_by * .6,
          offset_y = dy * separate_by * .6

          node.x -= offset_x
          node.y -= offset_y
          quad.point.x += offset_x
          quad.point.y += offset_y
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

  // Check if system energy would be reduced if two nodes' positions would 
  // be swapped. We square the difference in order to favor large differences 
  // for one vs small differences for the pair.
  function energy_reduced_by_swap(p1, p2) {
    // how much does each point covet the other's location, over their own?
    var p1_jealousy = Math.pow(p1.x - opinions[p1.index].x_target, 2) - 
                      Math.pow(p2.x - opinions[p1.index].x_target, 2),
        p2_jealousy = Math.pow(p2.x - opinions[p2.index].x_target, 2) - 
                      Math.pow(p1.x - opinions[p2.index].x_target, 2)

    return p1_jealousy + p2_jealousy
  }

  // Swaps the positions of two nodes
  var position_props = ['x', 'y', 'px', 'py']
  function swap_position(p1, p2) {
    var swap
    for(var i=0; i < position_props.length; i++){
      swap = p1[position_props[i]]
      p1[position_props[i]] = p2[position_props[i]]
      p2[position_props[i]] = swap
    }
  }

  ///////////////////////////////////////////////////////
  // The rest of these methods are only used for testing
  ///////////////////////////////////////////////////////


  // Calculates the reduction in global energy that a sort would have, 
  // where global energy is the sum across all nodes of the square of their 
  // distance from desired x position. We square the difference in order 
  // to favor large differences for individuals over small differences for
  // many.
  function calculate_global_energy() {
    var energy_unsorted = 0,
        energy_sorted = 0,
        sorted = global_sort(false)

    for (var i = 0; i < nodes.length; i++){
      energy_sorted   += Math.pow(sorted[i].x - opinions[sorted[i].index].x_target, 2)
      energy_unsorted += Math.pow( nodes[i].x - opinions[nodes[i].index].x_target , 2)
    }

    return Math.sqrt(energy_unsorted) - Math.sqrt(energy_sorted)
  }

  //////
  // global_sort
  //
  // Given a set of simulated face positions, reassigns avatars to the positions based on 
  // stance to enforce a global ordering. 
  // This method is visually jarring, so using it to sort nodes in place should be 
  // used as little as possible.
  function global_sort(sort_in_place) {
    if (sort_in_place === undefined) sort_in_place = true

    // Create one node list sorted by x position
    x_sorted_nodes = nodes.slice()
                  .sort(function (a,b) {return a.x-b.x})
    // ... and another sorted by desired x position
    desired_x_sorted_nodes = nodes.slice()
                  .sort(function (a,b) {return opinions[a.index].x_target - opinions[b.index].x_target})

    // Create a new dummy set of nodes optimally arranged
    new_nodes = []
    for (var i = 0; i < nodes.length; i++){
      new_nodes.push({
        // assign the avatar...
        index: desired_x_sorted_nodes[i].index, 
        radius: desired_x_sorted_nodes[i].radius,
        weight: desired_x_sorted_nodes[i].weight,
        // ...to a good position
        x: x_sorted_nodes[i].x,
        y: x_sorted_nodes[i].y,
        px: x_sorted_nodes[i].px,
        py: x_sorted_nodes[i].py
      })
    }

    // Walk through nodes and reassign the faces given
    // the optimal assignments discovered earlier. We
    // can't assign nodes=new_nodes because the layout
    // depends on nodes pointing to the same object.
    if (sort_in_place){
      var props = ['index', 'radius', 'x', 'y', 'px', 'py', 'weight']    
      for (var i = 0; i < nodes.length; i++)
        for (var j = 0; j < props.length; j++)
          nodes[i][props[j]] = new_nodes[i][props[j]]
    }
    return new_nodes
  }


}



