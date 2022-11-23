histo_queue = []
histo_running = null 

if window? 
  top_level = window 
else 
  top_level = DedicatedWorkerGlobalScope

top_level.enqueue_histo_layout = (opts) -> 
  histo_queue.push opts 
  process_next_layout()

write_layout = (opts, positions) ->
  # write message back about positions
  postMessage {opts, positions}


layout_complete = (opts, positions) -> 
  histo_running = null 
  write_layout(opts, positions)
  process_next_layout()

process_next_layout = -> 
  if !histo_running && histo_queue.length > 0
    histo_running = histo_queue.shift()
    positionAvatarsWithJustLayout histo_running 





#####
# Physics engine for reasonable layout of avatars within area
#

positionAvatarsWithJustLayout = (opts) ->
  layout_params = opts.layout_params

  if layout_params.verbose
    t0 = performance.now()

  placer = Placer opts  
  nodes = placer.pixelated_layout()
  while !nodes && opts.r > 0 # continuously reduce the avatar radius until we can place all of them
    console.error("At least one avatar couldn't be placed with base radius #{opts.r}. Trying again with base radius=#{opts.r - 1}")
    opts.r -= 1
    placer = Placer opts  
    nodes = placer.pixelated_layout()

  

  # sort so we can optimize by knowing that bodies are ordered by x_target
  nodes.sort (a,b) -> a.x_target - b.x_target

  placer.sweep_all_for_position_swaps (a,b) ->
    tmpx = a.x
    tmpy = a.y
    a.x = b.x 
    a.y = b.y 
    b.x = tmpx 
    b.y = tmpy
    true 
  , nodes

  if opts.groups
    placer.sweep_all_for_group_swaps (a,b) ->
      tmpx = a.x
      tmpy = a.y
      a.x = b.x 
      a.y = b.y 
      b.x = tmpx 
      b.y = tmpy
      true 
    , opts.groups, opts.all_groups, nodes


  opinions = opts.o
  positions = {}
  for n in nodes
    r = n.radius
    positions[n.user] = [ Math.round((n.x - r) * 10) / 10, Math.round((n.y - r) * 10) / 10, r]


  if layout_params.verbose 
    global_running_state = fetch 'histo-timing'
    running_state = fetch opts.running_state

    global_running_state[layout_params.param_hash] ?=
      tick_time: 0 
      truth: 0
      visibility: 0
      stability: 0
      cnt: 0

    evaluator = EvaluateLayout opts, nodes, placer

    evaluator.evaluate_layout()

    running_state.layout_time = performance.now() - t0
    global_running_state[layout_params.param_hash].tick_time += running_state.layout_time
    save running_state
    save global_running_state


  layout_complete opts, positions 


#####
# Calculate node radius based on the largest density of avatars in an 
# area (based on a moving average of # of opinions, mapped across the
# width and height)
top_level.calculateAvatarRadius = (width, height, opinions, weights, {fill_ratio}) -> 
  fill_ratio ?= .25

  if !width || !height 
    return 0

  opinions.sort (a,b) -> a.stance - b.stance

  # find most dense region of opinions
  avg_inc = .025

  candidate_r = []

  for window_size in [.05, .10, .2]
    opinion_space = 0
    idx = 0
    stance = -1.0 

    while stance <= 1.0 + window_size

      o = idx
      area = 0
      current_window = []
      while o < opinions.length

        if opinions[o].stance < stance - window_size
          idx = o
        else if opinions[o].stance > stance + window_size
          break
        else 
          weight = weights[opinions[o].user] or 1
          current_window.push weight
          area += weight 

        o += 1

      if area > opinion_space
        opinion_space = area
        densest_window = current_window 

      stance += avg_inc

    # Calculate the avatar radius we'll use. It is based on 
    # trying to fill fill_ratio of the densest area of the histogram
    if opinion_space > 0 
      area = fill_ratio * width * 2 * window_size * height # what size avatars will fit in this area?

      r = 1
      while true
        area_at_radius = 0 
        for weight in densest_window
          area_at_radius += weight * 4 * r * r #weight * Math.PI * r * r

        if area_at_radius > area

          if r > 1
            r = Math.round r * area / area_at_radius
          break 

        r += 1

    else 
      r = Math.sqrt(width * height / opinions.length * fill_ratio) / 2

    candidate_r.push r


  sum = (a,b) -> a + b
  r = candidate_r.reduce(sum, 0) / candidate_r.length


  if r > width / 2 || r > height / 2 
    r = Math.min width / 2, height / 2

  Math.max 1, Math.round r

Placer = (opts, bodies) -> 
  opinions = opts.o
  width = Math.round opts.w
  height = Math.round opts.h
  layout_params = opts.layout_params
  base_radius = opts.r
  weights = opts.weights
  cleanup_overlap = layout_params.cleanup_overlap or 2
  if layout_params.verbose 
    running_state = fetch opts.running_state
    histo_layout_explorer_options = fetch('histo_layout_explorer_options')

  save_snapshots = layout_params.verbose && histo_layout_explorer_options.show_explorer

  opinion_density = null
  window_sizes = [.1,.25,.4]
  get_opinion_density = (body) ->
    if !opinion_density
      # find opinion density across the spectrum, so we can do things like increase jostle
      # in dense regions, and spread out avatars in sparse areas to prevent towers
      opinion_density = {}
      sorted_opinions = opinions.slice()
      sorted_opinions.sort (a,b) -> a.stance - b.stance

      avg_inc = .01

      for window_size in window_sizes
        idx = 0
        stance = -1.0 + window_size

        opinion_density[window_size] = densities = []
        max_density = 0
        while stance <= 1.0 - window_size

          o = idx
          area = 0
          while o < sorted_opinions.length
            if sorted_opinions[o].stance < stance - window_size
              idx = o
            else if sorted_opinions[o].stance > stance + window_size
              break
            else 
              area += weights[sorted_opinions[o].user] or 1 
            o += 1
          if max_density < area 
            max_density = area 
          densities.push area
          stance += avg_inc
        if max_density > 0 
          for area,idx in densities
            densities[idx] /= max_density

    if !body.opinion_density_at_target
      density = 0
      for window_size, densities of opinion_density
        density += densities[ Math.round(body.x_target / (width - body.radius) * (densities.length - 1)) ]
      density /= window_sizes.length
      body.opinion_density_at_target = density

    return body.opinion_density_at_target


  pixelated_layout = ->

    laid_out = []
    return laid_out if opinions.length == 0 

    for o in opinions
      weight = weights[o.user] or 1
      o.radius = Math.round Math.sqrt(weight) * base_radius  # circle area of avatar grows linearly with weight 
      if o.radius < 1
        o.radius = 1
      radius = o.radius
      adjusted_stance = (o.stance + 1) / 2
      o.x_target = adjusted_stance * (width - 2 * radius) + radius


    # order strategically, placing bigger bodies first, then ordered from the poles inward
    opinions.sort (a,b) ->
      diff = Math.abs(b.stance - a.stance)
      # if diff < .02 && weights[b.user] != weights[a.user]
      if weights[b.user] != weights[a.user]        
        weights[b.user] - weights[a.user]
      else if layout_params.rando_order && diff < layout_params.rando_order && Math.abs(b.stance) < 1 - layout_params.rando_order
        # Introduce some randomness to the sort when two bodies are close to one another. 
        # This helps make it look less machine laid out. Without it, you get these leaning
        # towers. With the randomness, you still get some unstable towers, but they look a 
        # bit more like the people in the stack are trying to counterbalance each other.
        Math.random() - 0.5

      else 
        # The most common areas of dense clusters of opinion are the two poles, followed 
        # by the middle. So we want to greedily lay those areas out first. To do so, we 
        # can generally sort by the magnitude of the stance, as the stance is in [-1,1]. 
        # To get at the middle of the spectrum, we change the sort so that the middle is 
        # first when both opinions being compared is near the middle. 
        b_abs = Math.abs(b.stance)
        a_abs = Math.abs(a.stance)        

        b_abs - a_abs

    # For tracking valid placements of bodies' centroids
    openings = Openings()

    
    moves_within = [Math.round(width * .125), Math.round(width * .5), width]

    topple_towers = layout_params.topple_towers
    place_body = (o,idx) ->
      radius = o.radius
      x_target = o.x_target
      xt = Math.round(x_target)

      if save_snapshots
        occupancy_map = build_occupancy_map(laid_out)

      placed = false 
      for move_within in moves_within

        for consider_only_prime_positions in [true, false]
          options = openings.get_openings(radius, consider_only_prime_positions)

          max_score = -999999
          top_candidate = null
          x = Math.max(radius - 1, xt - move_within)

          while x <= Math.min(width - radius, xt + move_within) 
            if options[x] > 0
              # Higher score the closer to the target this position is
              score =  1 / (Math.abs(x_target - x) / width + 1) 
              
              if topple_towers
                # the denser the target region, the less the height impacts the score
                sparsity = 1 - get_opinion_density(o)
                elevation = (options[x] / height + 1)
                score = ( (1 - topple_towers) - sparsity * topple_towers) * score  + (topple_towers + sparsity * topple_towers) * elevation

              if score > max_score
                top_candidate = x 
                max_score = score 

            x += 1

          if top_candidate != null
            
            x = top_candidate
            y = options[x]

 
            if layout_params.jostle
              x_dist = x_target - x 
              y_dist = ( height - radius ) - y
              x_dist *= 2

              total_dist = Math.abs(x_dist) + Math.abs(y_dist)
              if total_dist > 1
                sag = base_radius * layout_params.jostle * Math.random()
                if layout_params.density_modified_jostle
                  sag *= (1 - layout_params.density_modified_jostle) + layout_params.density_modified_jostle * get_opinion_density(o)
                sag += .5
                x += sag * x_dist / total_dist 
                y += sag * y_dist / total_dist

            b =
              radius: radius
              x: x
              y: y
              x_target: x_target
              user: o.user 
            
            laid_out.push b

            openings.add_body b 

            placed = true 
            break 

          if !placed && consider_only_prime_positions == false && move_within == width
            console.error("Could not place", xt, o)
            return false
        break if placed 

      if save_snapshots
        current_cleanup.push 
          body: JSON.parse JSON.stringify {x: b.x, y: b.y, radius: b.radius, x_target: b.x_target}
          from: {x, y}
          to: {x: b.x, y: b.y}
          candidates: [] # candidates
          openings: openings.by_radii[radius].open_spots.slice() # build_openings()
          occupancy: occupancy_map
          prime_positions: options.slice()
          unstable_bodies: []
          bodies: JSON.parse JSON.stringify ({user: b.user, neighbors: b.neighbors, x: b.x, y: b.y, radius: b.radius, x_target: b.x_target} for b in laid_out)
          iteration: 0
      true

    if save_snapshots
      current_cleanup = []

    if !layout_params.show_histogram_layout
      for o,idx in opinions 
        success = place_body o,idx
        if !success
          return false

      if save_snapshots
        running_state.cleanup ?= []
        running_state.cleanup.push current_cleanup
        save running_state        
    else 

      idx = 0
      run_next = ->

        place_body opinions[idx], idx

        positions = {}
        for body in laid_out
          r = body.radius

          positions[body.user] = \
            [Math.round((body.x - r) * 10) / 10, Math.round((body.y - r) * 10) / 10, r]


        write_layout opts, positions

        idx += 1
        setTimeout -> 
          if idx < opinions.length
            run_next()
          else if save_snapshots
            running_state.cleanup ?= []
            running_state.cleanup.push current_cleanup
            save running_state
        , 25


      run_next()

    laid_out



  # Returns array representing a 2d width x height map of which pixels are occupied
  # by avatars. Each cell has the number of avatars occupying that space.
  build_occupancy_map = (bodies, additional_r, r_mult = 1) -> 
    occupancy_map = new Int32Array width * height 
    additional_r ?= 0

    for body in bodies
      r = Math.round(additional_r + body.radius * r_mult) - 1

      mask = get_mask(r)
      imprint_body_on_map occupancy_map, body, 1, r 

    occupancy_map

  Openings = (to_map) ->
    mapped = []

    radii = []
    by_radii = {}

    point_dist = (a,b) -> 
      Math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))


    add_body = (body) ->
      x = Math.round(body.x); y = Math.round(body.y)
      b_r = body.radius
      body_pos = {x, y}

      for radius in radii
        dirty_r = Math.round( (b_r + radius) * (cleanup_overlap - 1) ) - 1

        openings_for_radius = by_radii[radius].open_spots
        imprint_body_on_map openings_for_radius, body_pos, 1, dirty_r

        # dirty the flattened openings for this body
        col = x - dirty_r
        dirty = by_radii[radius].dirty
        while col < x + dirty_r
          dirty[col] = 1
          col += 1

      mapped.push body

    # Instead of laboriously computing the stability of all possible positions for unstable
    # bodies to be moved to, we exploit the shape of the lower most openings to heuristically 
    # eliminate unstable positions. Because the avatars are circles, unstable positions are 
    # those where the y position of an opening is rising or falling (putting something on top
    # at those places would be slippery).
    get_openings = (target_radius, filter_to_prime_positions) ->
      radius = target_radius or base_radius

      # if radius not present, create and update for all bodies
      if !by_radii[radius]
        by_radii[radius] = 
          open_spots: new Int32Array width * height
          flattened_openings: new Int32Array width + 1
          initialized: false 
          dirty: {}
        radii.push radius 

        open_spots = by_radii[radius].open_spots
        for b in mapped
          imprint_body_on_map open_spots, b, 1, Math.round(  (b.radius + radius) * (cleanup_overlap - 1)  ) - 1

      {open_spots, initialized, dirty, flattened_openings} = by_radii[radius]

      # Find the first opening from bottom up in each col. These are candidate
      # stable positions to move an unstable body.
      build_flattened_init = ->
        col = 0
        while col < width
          y = 0
          if col >= radius - 1 && col <= width - radius
            row = height - radius
            while row >= 0
              if open_spots[ row * width + col ] == 0               
                y = row 
                break 
              row -= 1
          flattened_openings[col] = y
          col += 1
        by_radii[radius].initialized = true

      build_flattened = ->
        for k,v of dirty
          col = parseInt(k)
          y = 0
          if col >= radius - 1 && col <= width - radius
            row = flattened_openings[col]
            row ?= height - radius
            while row >= 0
              if open_spots[ row * width + col ] == 0               
                y = row 
                break 
              row -= 1

          flattened_openings[col] = y
        by_radii[radius].dirty = {}
      
      if initialized
        build_flattened()
      else 
        build_flattened_init()

      return flattened_openings if !filter_to_prime_positions 

      candidates = []
      r_long = Math.round(radius * layout_params.cleanup_overlap) - 1
      dist = Math.floor(radius/2)

      i = 0
      while i < width 
        y = flattened_openings[i] #[0]

        y_prev = flattened_openings[i-dist] #[0]
        y_next = flattened_openings[i+dist] #[0]

        hypo_pos =
          y: y + r_long
          x: i

        if y_next?
          disjoint_next = hypo_pos.y < y_next
          radius_next = point_dist(hypo_pos, {x: i+dist, y: y_next}) - r_long   # If this point is tracing the side of a circular body, 
                                                                               # it will be less than or equal to r_long long (the 
        if y_prev?
          disjoint_prev = hypo_pos.y < y_prev 
          radius_prev = point_dist(hypo_pos, {x: i-dist, y: y_prev}) - r_long

        if ((!y_next? || (!disjoint_next && radius_next > -1)) && \
            (!y_prev? || (!disjoint_prev && radius_prev > -1))) || \
           (!disjoint_prev && !disjoint_next && Math.abs(radius_next) < 1 && Math.abs(radius_prev) < 1 && Math.abs(radius_next + radius_prev) < 0.5) # trying to account for rounding errors with small r
          candidates.push y
        else 
          candidates.push 0
        i += 1

      return candidates


    return {get_openings, add_body, by_radii}




  # build a mask for the square around the body that shows which pixels
  # in the square are covered by the circle
  avatar_mask = {} # keys are radii  
  get_mask = (r) -> 
    mask = avatar_mask[r]
    if !mask
      mask = avatar_mask[r] = new Int32Array 4 * r * r
      col = row = 0 
      while row < 2 * r
        while col < 2 * r
          if Math.sqrt( ( r - .5 - row) * ( r - .5 - row ) + ( r - .5 - col ) * ( r - .5 - col ) ) < r
            mask[ row * 2 * r + col ] = 1    # the .5 in the distance calculation is to move to the true center of the circle
          col += 1
        row += 1
        col = 0
    mask

  imprint_body_on_map = (occupancy_map, body, increment = 1, radius = null) ->
    # imprint the body's mask on the occupancy map
    # get the start offset of the occupancy map at which to start imprinting
    r = Math.round(radius or body.radius)
    x = Math.round body.x 
    y = Math.round body.y

    mask = get_mask(r)
    row = y - r 
    col = x - r
    mask_row = mask_col = 0 
    while mask_row < 2 * r
      offset_row = row + mask_row 
      
      if offset_row >= 0 && offset_row < height
        while mask_col < 2 * r
          offset_col = col + mask_col 

          if offset_col >= 0 && offset_col < width && mask[ mask_row * 2 * r + mask_col ]
            # imprint
            occupancy_map[offset_row * width + offset_col] += increment

          mask_col += 1


      mask_row += 1
      mask_col = 0


  # Compares each body to each other body to determine if the pairs should be swapped, and if so, swaps them
  sweep_all_for_position_swaps = (attempt_swap, nodes) ->

    # for node, idx in nodes 
    #   if idx > 0 
    #     console.assert node.x_target >= nodes[idx - 1].x_target

    num = nodes.length 
    num_swaps = 1
    while num_swaps > 0

      num_swaps = 0 
      i = 0 
      while i < num
        body = nodes[i] 
        j = i + 1 
        while j < num 
          if j == i
            j += 1
            continue 
          body2 = nodes[j]

          if body.radius == body2.radius && ((body.x > body2.x && body.x_target < body2.x_target) || (body.x < body2.x && body.x_target > body2.x_target)) 
            result = attempt_swap(body, body2)
            if result 
              num_swaps += 1
              # break 
          j += 1
        i += 1


  # try to put bodies with the same group in sedimentary layers so it is easier to see patterns in groups
  sweep_all_for_group_swaps = (attempt_swap, groups, all_groups, nodes) -> 
    group_idx = {}
    for g,idx in all_groups
      group_idx[g] = idx 

    num = nodes.length 
    num_swaps = 1
    while num_swaps > 0

      num_swaps = 0 
      i = 0 
      while i < num
        body = nodes[i] 
        j = i + 1 

        body_g_idx = Math.min.apply null, (group_idx[g] for g in groups[body.user])
        while j < num 
          if j == i
            j += 1
            continue 
          body2 = nodes[j]

          body2_g_idx = Math.min.apply null, (group_idx[g] for g in groups[body2.user])
  

          if body.radius == body2.radius && Math.abs(body.x_target - body2.x_target) < (body.radius + body2.radius) && ((body.y < body2.y && body_g_idx < body2_g_idx) || (body.y > body2.y && body_g_idx > body2_g_idx))
            result = attempt_swap(body, body2)
            if result 
              num_swaps += 1
              # break 
          j += 1
        i += 1


  {Openings, sweep_all_for_position_swaps, sweep_all_for_group_swaps, pixelated_layout, get_mask, imprint_body_on_map}

EvaluateLayout = (opts, bodies, placer) -> 
  opinions = opts.o
  width = opts.w
  height = opts.h
  layout_params = opts.layout_params
  base_radius = opts.r
  weights = opts.weights

  cleanup_overlap = layout_params.cleanup_overlap or 2

  if layout_params.verbose 
    global_running_state = fetch 'histo-timing'
    running_state = fetch opts.running_state

  #   running_state = fetch opts.running_state
  #   histo_layout_explorer_options = fetch('histo_layout_explorer_options')

  # save_snapshots = layout_params.verbose && histo_layout_explorer_options.show_explorer


  # Determines which bodies are adjacent to a body. For each body, sets the angle {0, 360º} which represents 
  # the angle at which the body is touched by the other body. 
  # 0 is the right, 90º is the middle bottom, 180º is the left, 270º is the middle top.
  # 
  # epsilon is a little extra that will help bodies that are *almost* touching to be considered touching.

  a90  = Math.PI / 2
  a180 = Math.PI
  a270 = 3 * Math.PI / 2
  a360 = 2 * Math.PI

  find_neighbors = (epsilon = 1) -> 
    n = bodies.length

    for body in bodies 
      body.neighbors = []

    i = 0 
    while i < n 
      j = i + 1
      a = bodies[i]

      while j < n     
        b = bodies[j]

        if b.y < a.y || (b.y == a.y && a.x > b.x) 
          aa = bodies[j]; bb = bodies[i] # make sure a is always at least as high as b; for ease in computing angles
        else 
          aa = bodies[i]; bb = bodies[j]

        a_x = aa.x; a_y = aa.y 
        b_x = bb.x; b_y = bb.y
        a_r = aa.radius; b_r = bb.radius

        if (a_x - b_x) * (a_x - b_x) + (a_y - b_y) * (a_y - b_y) <= (a_r + b_r) * (a_r + b_r) + epsilon

          if a_y == b_y 
            a_angle = 0
            b_angle = a180
          else if a_x == b_x 
            a_angle = a90
            b_angle = a270
          else 
            angle = Math.atan( Math.abs(a_x - b_x) / Math.abs(a_y - b_y) )
            if a_x < b_x
              a_angle = a90 - angle
              b_angle = a180 + (a90 - angle)
            else 
              a_angle = a90 + angle
              b_angle = a360 - (a90 - angle)

          aa.neighbors.push [bb.body_index, a_angle]
          bb.neighbors.push [aa.body_index, b_angle]

        j += 1
      i += 1



  #############################
  # Metrics evaluating layouts

  # How stable is this body?
  # We'll consider the angles of any bodies or edges this body is touching, if any. 
  # The greatest stability is when the maximum angle between touch points in the lower 
  # half circle is just under PI / 2. The worst -- free fall -- is when there are no touch points
  # in the lower half circle, which is simply PI. If the body is resting on the surface,
  # the max angle is PI / 2. Thus stability = 1 - (max_arc - best ) / best, which
  # is 0 for free fall and 1 for resting comfortably. 

  calc_stability = (body, blacklist = {}) -> 
    x = Math.round body.x
    y = Math.round body.y
    r = body.radius

    # resting on the ground
    return 1 if y + r + 1 >= height 

    adj_angle = 0
    neighbors = body.neighbors.slice()

    stabilizing_neighbors = (angle for [other_idx, angle] in neighbors when angle < Math.PI && angle > 0 && !blacklist[other_idx])

    # body in freefall
    return 0 if stabilizing_neighbors.length == 0 

    # find the neighbor most centrally below the body
    most_stable = 2 * Math.PI
    for angle in stabilizing_neighbors
      if Math.abs(Math.PI / 2 - angle) < most_stable
        most_stable = angle

    stabilizing_neighbors.sort()

    if x <= r
      neighbors.unshift ['left edge', Math.PI + adj_angle]
    else if x >= width - r
      neighbors.unshift ['right edge', adj_angle]

    # search for a counterbalancing body. A counterbalancing body will be within π radians on the lower half circle formed
    # from the most stable angle
    for n in neighbors when !blacklist[n[0]]
      n_angle = n[1]
      if n_angle > Math.PI * 3 / 2
        n_angle -= Math.PI * 2
      angle_between = n_angle - most_stable
      if (most_stable < Math.PI / 2 && angle_between > 0 && angle_between < Math.PI) || \
         (most_stable > Math.PI / 2 && angle_between < 0 && angle_between > -Math.PI)

        return 1 # has counterbalancing stabilizing body
    

    # The below will be 1 if there's a stabilizing body directly under it, 
    # and 0 if there's one almost directly to its side
    deviation_from_stable = Math.abs(most_stable - Math.PI / 2)


    1 - deviation_from_stable / (Math.PI / 2)

  evaluate_body_position = (body, occupancy_map) ->

    occupancy_map ?= build_occupancy_map()

    ####################
    # How truthful is the location based on the user's intended position?
    dist = Math.abs(body.x - body.x_target)
    dist /= width 

    truth = Math.pow 1 - dist, 2
    body.truth = truth

    ####################
    # How visible? Is it covered up at all?
    r = body.radius
    mask = placer.get_mask(r)
    x = Math.round body.x
    y = Math.round body.y

    left = x - r 
    top = y - r
    overlapped_pixels = 0 
    total_pixels = 0 
    for row in [0..2 * r]
      for col in [0..2 * r]
        if mask[row * 2 * r + col] > 0
          pixel = occupancy_map[(top + row) * width + (left + col)]
          total_pixels += 1
          if pixel > 1
            overlapped_pixels += 1

    percent_visible = 1 - overlapped_pixels / total_pixels
    body.visibility = percent_visible


    body.stability = calc_stability body



    #####################
    # How much space below?
    row = y + r + 2 # +2 instead of +1 to give a little grace
    col = x         # considering the imprecise rounding when
                    # translating into pixel space
    space_below = 0 
    while true 
      break if row >= height 
      pixel = occupancy_map[row * width + col]

      break if pixel > 0  
      space_below += 1
      row += 1

    # We'll levy a much greater penalty for space if this body could simply
    # have been moved straight down
    if space_below > 1                                  
      could_free_fall = true
      row = y + r + 2 # +2 instead of +1 to give a little grace

      for ccol in [col - r .. col + r]
        continue if ccol < 0 || ccol >= width
        could_free_fall &&= occupancy_map[row * width + ccol] == 0
        break if !could_free_fall

      if could_free_fall
        space_below = Math.pow space_below, 3

    body.space_below = space_below

  evaluate_layout = ->
    find_neighbors()

    occupancy_map = build_occupancy_map()

    # judge truth by the *least* well positioned avatar
    truth = 1

    # judge visibility by the *most* hidden avatar
    visibility = 1

    # Judge how stability the layout is based on the sum of the space below the *middle* of each body
    stability = 0

    for body in bodies 
      evaluate_body_position body, occupancy_map

      if body.truth < truth
        truth = body.truth

      if body.visibility < visibility
        visibility = body.visibility

      if body.stability?
        stability += Math.pow body.stability, 2 # body.space_below

    stability /= bodies.length 
    _.extend running_state, {truth, visibility, stability}

    global_running_state[layout_params.param_hash].truth += truth
    global_running_state[layout_params.param_hash].visibility += visibility
    global_running_state[layout_params.param_hash].stability += stability
    global_running_state[layout_params.param_hash].cnt += 1    

  # Returns array representing a 2d width x height map of which pixels are occupied
  # by avatars. Each cell has the number of avatars occupying that space.
  build_occupancy_map = (additional_r, r_mult = 1) -> 
    occupancy_map = new Int32Array width * height 
    additional_r ?= 0

    for body in bodies
      r = Math.round(additional_r + body.radius * r_mult) - 1

      mask = placer.get_mask(r)
      placer.imprint_body_on_map occupancy_map, body, 1, r 

    occupancy_map

  {calc_stability, evaluate_layout}
