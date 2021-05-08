
window.layoutAvatars = (opts) -> 
  histo_queue.push opts 
  if !histo_running
    histo_run_next_job()



histo_queue = []
histo_running = null 
histo_run_next_job = (completed) -> 
  if histo_running == completed 
    histo_running = null

  if !histo_running && histo_queue.length > 0
    histo_running = histo_queue.shift()

    if histo_running.layout_params.engine == 'matterjs'
      positionAvatarsWithMatterJS histo_running
    else if histo_running.layout_params.engine == 'd3'
      positionAvatarsWithD3 histo_running
    else 
      positionAvatarsWithJustLayout histo_running 



initialize_positions = (opts) -> 
  targets = {}
  opinions = opts.o.slice()
  width = opts.w or 400
  height = opts.h or 70
  layout_params = opts.layout_params
  r = opts.r

  if layout_params.initial_layout == 'classic_at_top' 
    nodes = classic_layout(opinions, width, height, r, targets, at_top: true)
  else if layout_params.initial_layout == 'classic_at_bottom'
    nodes = classic_layout(opinions, width, height, r, targets, at_top: false)
  else if layout_params.initial_layout == 'tiled' || !layout_params.initial_layout
    nodes = tiled_layout(opinions, width, height, r, targets) 
  else if layout_params.initial_layout == 'tiled-with-wiggle'
    nodes = tiled_layout(opinions, width, height, r, targets, wiggle: 1) 
  else if layout_params.initial_layout == 'tiled-with-wiggle-2'
    nodes = tiled_layout(opinions, width, height, r, targets, wiggle: .5) 
  else if layout_params.initial_layout == 'tiled-with-jostle'
    nodes = tiled_layout(opinions, width, height, r, targets, wiggle: 1, scale: .9) 

  else if layout_params.initial_layout == 'packed-tile'
    nodes = packed_tiled_layout(opinions, width, height, r, targets, wiggle: false) 

  else if layout_params.initial_layout == 'packed-tile-with-wiggle'
    nodes = packed_tiled_layout(opinions, width, height, r, targets, wiggle: true) 

  else if layout_params.initial_layout == 'packed-tile-with-wiggle-jostle'
    nodes = packed_tiled_layout(opinions, width, height, r, targets, wiggle: true, scale: .9) 

  else if layout_params.initial_layout == 'packed-tile-with-jostle'
    nodes = packed_tiled_layout(opinions, width, height, r, targets, wiggle: false, scale: .9) 

  {nodes, targets, opinions, width, height, r}


classic_layout = (opinions, width, height, r, targets, {at_top}) -> 
  opinions.map (o, i) ->
    x_target = (o.stance + 1) / 2 * width

    if targets[x_target]
      if x_target > .98
        x_target -= .1 * Math.random() 
      else if x_target < .02
        x_target += .1 * Math.random() 

    targets[x_target] = 1

    x = x_target
    if at_top
      y = r
    else 
      y = height - r

    return {
      index: i
      radius: r
      x: x
      y: y
      x_target: x_target
    }

tiled_layout = (opinions, width, height, r, targets, params) -> 
  MAX_DISTURBANCE = 1 * width # how far away from its target is an opinion allowed to start?
  laid_out = []
  return laid_out if opinions.length == 0 

  wiggle = params?.wiggle
  scale = params?.scale or 1

  find_split = (start, end, iterations) ->
    halfway = Math.round((end - start) / 2) + start
    if iterations > 4
      return halfway

    if opinions[start].stance < 0 && opinions[halfway].stance < 0
      return find_split(halfway, end, iterations + 1)
    else 
      return find_split(start, halfway, iterations + 1)

  split_idx = find_split(0, opinions.length - 1, 0)
  num_cols = Math.round(width / (2 * r))
  num_rows = Math.round(height / (2 * r))
  grid = []
  current_row = []

  col = 0 
  while col < num_cols
    grid[col] = []
    current_row[col] = 0
    row = 0 
    while row < num_rows
      grid[col][row] = 0
      row +=1
    col += 1

  idx = 0 
  while idx < split_idx
    x_target = (opinions[idx].stance + 1) / 2 * width

    target_col = Math.round( (opinions[idx].stance + 1) / 2 * num_cols   )

    if target_col >= num_cols
      target_col = num_cols - 1
    else if target_col < 0 
      target_col = 0 

    col = target_col

    # find a good position for this node
    assigned = false 
    cnt_in_target = grid[target_col][0]
    while (col - target_col) * 2 * r < MAX_DISTURBANCE && col < num_cols
      if grid[col][current_row[col]] < cnt_in_target
        row = current_row[col]
        assigned = true 
        break
      col += 1

    if !assigned
      col = target_col 
      row = 0 

    grid[col][row] += 1
    if row == num_rows - 1
      current_row[col] = 0
    else 
      current_row[col] += 1

    x = col * 2 * r + r
    y = height - (row * 2 * r) - r

    laid_out.push {
      index: idx
      radius: r * scale * Math.round(1 + Math.random())
      x: x
      y: y
      x_target: x_target
    }
    idx += 1

  idx = opinions.length - 1
  while idx >= split_idx
    x_target = (opinions[idx].stance + 1) / 2 * width

    target_col = Math.round( (opinions[idx].stance + 1) / 2 * num_cols   ) - 1

    if target_col >= num_cols
      target_col = num_cols - 1
    else if target_col < 0 
      target_col = 0 

    col = target_col

    # find a good position for this node
    assigned = false 
    cnt_in_target = grid[target_col][0]
    while (target_col - col) * 2 * r < MAX_DISTURBANCE && col >= 0 
      if grid[col][current_row[col]] < cnt_in_target
        row = current_row[col]
        assigned = true 
        break
      col -= 1

    if !assigned
      col = target_col 
      row = 0 

    grid[col][row] += 1
    if row == num_rows - 1
      current_row[col] = 0
    else 
      current_row[col] += 1

    x = col * 2 * r + r
    y = height - (row * 2 * r) - r

    laid_out.push {
      index: idx
      radius: r * scale * Math.round(1 + Math.random())
      x: x
      y: y
      x_target: x_target
    }
    idx -= 1

  if wiggle
    for n in laid_out
      n.x += (Math.random() - .5) * r * wiggle
      # n.y += (Math.random() - .5) * r
      if n.x + r > width 
        n.x = width - r 
      else if n.x < r 
        n.x = r 
      if n.y + r > height
        n.y = height - r 
      else if n.y < r
        n.y = r 


  laid_out.sort (a,b) -> a.index - b.index
  laid_out

# packed_tiled_layout
# Calculated initial position of each avatar by laying them out in a grid as close to their 
# intended position as possible, starting from the poles and working to the middle.
# This is "packed" because it leverages the avatars being circles to make each column 
# less than 2*r wide. Each cicle only needs to have their centroid 2*r away from each other one,
# so if we alternate the initial y position of each column by r, we can actually use spacing
# r + (sqrt(2) * r) / 2 rather than 2*r. This may sound like a small improvement, but the asthetics
# are quite profound. 
# Note: I changed to packing the row_height, rather than col_width, but same principles apply
packed_tiled_layout = (opinions, width, height, r, targets, params) -> 
  MAX_DISTURBANCE = 1 * width # how far away from its target is an opinion allowed to start?
  laid_out = []
  return laid_out if opinions.length == 0 

  wiggle = params?.wiggle
  scale = params?.scale or 1

  find_split = (start, end, iterations) ->
    halfway = Math.round((end - start) / 2) + start
    if iterations > 4
      return halfway

    if opinions[start].stance < 0 && opinions[halfway].stance < 0
      return find_split(halfway, end, iterations + 1)
    else 
      return find_split(start, halfway, iterations + 1)

  split_idx = find_split(0, opinions.length - 1, 0)

  col_width = 2 * r
  row_height = r + (r * Math.sqrt(2)) / 2
  num_cols = Math.round(width / col_width)
  num_rows = Math.round(height / row_height)  # -.5 * r is to accommodate the avg offset for packing (0 vs r)
  grid = []
  current_row = []

  col = 0 
  while col < num_cols
    grid[col] = []
    current_row[col] = 0
    row = 0 
    while row < num_rows
      grid[col][row] = 0
      row +=1
    col += 1


  for negative_pole in [true, false]
    idx = if negative_pole then 0 else opinions.length - 1

    while (negative_pole && idx < split_idx) || (!negative_pole && idx >= split_idx)
      adjusted_stance = (opinions[idx].stance + 1) / 2
      x_target = adjusted_stance * width
      target_col = Math.round( adjusted_stance * num_cols  ) 

      if !negative_pole
        target_col -= 1

      if target_col >= num_cols
        target_col = num_cols - 1
      else if target_col < 0 
        target_col = 0

      col = target_col

      # find a good position for this node
      assigned = false 
      cnt_in_target = grid[target_col][0]

      if negative_pole
        while (col - target_col) * 2 * r < MAX_DISTURBANCE && col < num_cols
          if grid[col][current_row[col]] < cnt_in_target
            row = current_row[col]
            assigned = true 
            break
          col += 1
      else 
        while (target_col - col) * 2 * r < MAX_DISTURBANCE && col >= 0 
          if grid[col][current_row[col]] < cnt_in_target
            row = current_row[col]
            assigned = true 
            break
          col -= 1

      if !assigned
        col = target_col 
        row = 0 

      grid[col][row] += 1
      if row == num_rows - 1
        current_row[col] = 0
      else 
        current_row[col] += 1

      x = col * col_width + r
      y = height - (row * row_height) - r
      if row % 2 == 1
        # offset for packing
        if x_target < 0
          x -= r 
        else 
          x += r

      laid_out.push {
        index: idx
        radius: r * scale
        x: x
        y: y
        x_target: x_target
      }

      if negative_pole
        idx += 1
      else 
        idx -= 1


  

  if wiggle
    for n in laid_out
      n.x += (Math.random() - .5) * r
      # n.y += (Math.random() - .5) * r
      if n.x + r > width 
        n.x = width - r 
      else if n.x < r 
        n.x = r 
      if n.y + r > height
        n.y = height - r 
      else if n.y < r
        n.y = r 


  laid_out.sort (a,b) -> a.index - b.index
  laid_out


#####
# Physics engine for reasonable layout of avatars within area
#

positionAvatarsWithJustLayout = (opts) -> 
  {nodes, targets, opinions, width, height, r} = initialize_positions opts

  positions = {}
  for n in nodes
    r = n.radius
    i = n.index
    if opts.layout_params.round  
      positions[parseInt(opinions[i].user.substring(6))] = \
        [Math.round((n.x - r) * 10) / 10, Math.round((n.y - r) * 10) / 10]
    else 
      positions[parseInt(opinions[i].user.substring(6))] = [n.x - r, n.y - r]

  opts.done?(positions)
  histo_run_next_job(opts)



positionAvatarsWithMatterJS = (opts) -> 
  Events = Matter.Events
  Engine = Matter.Engine
  init = initialize_positions opts
  width = init.width 
  height = init.height 
  opinions = init.opinions

  layout_params = opts.layout_params

  # create engine
  engine = Engine.create()
  engine.enableSleeping = true
  
  #############
  # add walls
  wall = 1000
  wall_params = { isStatic: true, render: strokeStyle: 'transparent' }
  Matter.Composite.add engine.world, [ 
    # top
    Matter.Bodies.rectangle(  width / 2, -wall / 2, 2 * width, wall, wall_params)
    # bottom
    Matter.Bodies.rectangle(  width / 2, height + wall / 2, 2 * width + wall / 2, wall, wall_params)
    # right
    Matter.Bodies.rectangle(  width + wall / 2, height / 2, wall, 2 * height + wall, wall_params)
    # left
    Matter.Bodies.rectangle(  -wall / 2, height / 2, wall, 2 * height + wall, wall_params)
  ]
  #############

  ############
  # Initialize avatar positions
  bodies = []
  params = 
    density: layout_params.density or .1 # significantly heavier than default so they don't overlap as much
    sleepThreshold: layout_params.sleepThreshold or 60 # This is the default
    restitution: layout_params.restitution or 0 # Don't bounce off of each other
    friction: layout_params.friction or .001
    frictionStatic: layout_params.frictionStatic or .3
    frictionAir: layout_params.frictionAir or 0
    slop: layout_params.slop or .05

  for n in init.nodes 
    bd = Matter.Bodies.circle n.x, n.y, init.r, params
    #b = Matter.Bodies.polygon(n.x, n.y, 4, r, params)
    _.extend bd, n
    bodies.push bd 

    bd.before_sleep = 
      x: bd.position.x 
      y: bd.position.y

    bd.original_sleep_threshold = bd.sleepThreshold

  # sort so we can optimize by knowing that bodies are ordered by x_target
  bodies.sort (a,b) -> a.x_target - b.x_target

  Matter.Composite.add engine.world, bodies
  ################




  # Swap the positions and velocities of two avatars if a swap would be worth it
  attempt_swap = (a,b) -> 
    current_distance = Math.abs(a.position.x - a.x_target) + Math.abs(b.position.x - b.x_target)
    swapped_distance = Math.abs(b.position.x - a.x_target) +  Math.abs(a.position.x - b.x_target)

    if current_distance - swapped_distance < .01 && Math.abs(a.position.x - b.position.x) < 1
      return false 

    if a.isSleeping
      Matter.Sleeping.set(a, false)
    if b.isSleeping
      Matter.Sleeping.set(b, false)

    # swap positions
    tmpx = a.position.x
    tmpy = a.position.y

    Matter.Body.setPosition a, b.position
    Matter.Body.setPosition b, 
      x: tmpx
      y: tmpy

    # swap velocity y and zero velocity x
    tmpy = a.velocity.y

    Matter.Body.setVelocity a, 
      x: 0
      y: b.velocity.y
    Matter.Body.setVelocity b, 
      x: 0
      y: tmpy

    a.sleepCounter = 0 
    b.sleepCounter = 0

    a.moved_insignificantly_after_sleep = 0 
    b.moved_insignificantly_after_sleep = 0   

    true


  Events.on engine, "collisionStart", (ev) ->

    for pair in ev.pairs
      a = pair.bodyA
      b = pair.bodyB 

      continue if a.isStatic || b.isStatic

      if (a.position.x < b.position.x && a.x_target > b.x_target) || \
         (a.position.x > b.position.x && a.x_target < b.x_target) 

        attempt_swap(a, b)      



  motionSleepThreshold = layout_params.motionSleepThreshold or .01  
  Matter.Sleeping._motionSleepThreshold = motionSleepThreshold                                               
                                              # The ease at which bodies fall asleep based on their motion. 
                                              # Much lower than default (.08) b/c otherwise the avatars are 
                                              # too soporific and suspended in air
  motionSleepThresholdIncrement = layout_params.motionSleepThresholdIncrement or .00001 
                                              # Each tick, we make it slightly easier for bodies to fall asleep. This is like 
                                              # faux simulated annealing to bring the layout to an end faster.   
  
  wake_every_x_ticks = layout_params.wake_every_x_ticks
  global_swap_every_x_ticks = layout_params.global_swap_every_x_ticks
  total_ticks = 0
  total_sleeping = 0 

  runner = Matter.Runner.create()
  try_swap = 0
  did_swap = 0
  no_swap = 0 


  histo_layout_explorer_options = fetch('histo_layout_explorer_options')



  sweep_all_for_position_swaps = ->
    for body, i in bodies 
      for body2,j in bodies when i < j
        # bodies is ordered by x_target, so we know body.x_target <= body2.x_target
        if body.position.x > body2.position.x && body.x_target != body2.x_target
          attempt_swap(body, body2)

  write_positions = -> 
    positions = {}
    for body in bodies
      o = body.position
      r = body.radius
      i = body.index 

      if layout_params.round 
        positions[parseInt(opinions[i].user.substring(6))] = \
          [Math.round((o.x - r) * 10) / 10, Math.round((o.y - r) * 10) / 10, r, body.stability]
      else 
        positions[parseInt(opinions[i].user.substring(6))] = \
          [o.x - r, o.y - r, r, body.stability]


    opts.done?(positions)


  _requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame \
                                || window.mozRequestAnimationFrame || window.msRequestAnimationFrame \
                                || (callback) -> 
                                      setTimeout -> 
                                        callback Matter.Common.now()
                                      , 1000 / 60

  #####################
  # How stable is this body?
  # We'll consider the angles of any bodies or edges this body is touching, if any. 
  # The greatest stability is when the maximum angle between touch points in the lower 
  # half circle is just under PI / 2. The worst -- free fall -- is when there are no touch points
  # in the lower half circle, which is simply PI. If the body is resting on the surface,
  # the max angle is PI / 2. Thus stability = 1 - (max_arc - best ) / best, which
  # is 0 for free fall and 1 for resting comfortably. 
  calc_stability = (body, blacklist = {}) -> 
    x = Math.round body.position.x
    y = Math.round body.position.y
    r = body.radius

    # resting on the ground
    return 1 if y + r + 1 >= height 

    if neighbors_last_set != total_ticks
      find_neighbors()

    stabilizing_neighbors = (angle for [other_idx, angle] in body.neighbors when angle < Math.PI && angle > 0 && !blacklist[other_idx])

    # body in freefall
    return 0 if stabilizing_neighbors.length == 0 

    # find the neighbor most centrally below the body
    most_stable = 2 * Math.PI
    for angle in stabilizing_neighbors
      if Math.abs(Math.PI / 2 - angle) < most_stable
        most_stable = angle

    stabilizing_neighbors.sort()

    neighbors = body.neighbors
    if x <= r
      neighbors = neighbors.slice()
      neighbors.unshift ['left edge', Math.PI]
    else if x >= width - r
      neighbors = neighbors.slice()
      neighbors.unshift ['right edge', 0]

    # search for a counterbalancing body. A counterbalancing body will be within π radians on the lower half circle formed
    # from the most stable angle
    for n in neighbors when !blacklist[n[0]]
      n_angle = n[1]
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
    dist = Math.abs(body.position.x - body.x_target)
    dist /= width 

    truth = Math.pow 1 - dist, 2
    body.truth = truth

    ####################
    # How visible? Is it covered up at all?
    r = body.radius
    mask = get_mask(r)
    x = Math.round body.position.x
    y = Math.round body.position.y

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


  # Instead of laboriously computing the stability of all possible positions for unstable
  # bodies to be moved to, we exploit the shape of the lower most openings to heuristically 
  # eliminate unstable positions. Because the avatars are circles, unstable positions are 
  # those where the y position of an opening is rising or falling (putting something on top
  # at those places would be slippery). So we filter them out by identifying positive (going 
  # from decreasing to increasing) and negative (vice versa) inflection points. These roughly
  # correspond to a stable position resting on top of a body, and nestled in between two 
  # bodies. Flat areas are also stable. 
  Math.dist = (a,b) -> 
    Math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))

  filter_openings = (openings, target_radius, filter_to_inflections_and_flats) ->

    radius = target_radius or init.radius

    # Find the first opening from bottom up in each col. These are candidate
    # stable positions to move an unstable body.
    flattened_openings = [] 
    for col in [0..width]
      opening_this_col = 0
      
      for row in [height - 1..0 - 1] by -1
        if row <= height - radius && col >= radius && col <= width - radius && openings[ row * width + col ] == 0 
          opening_this_col = row 
          break 

      flattened_openings.push opening_this_col

    if !filter_to_inflections_and_flats
      return flattened_openings

    candidates = []
    r_long = Math.round(radius * layout_params.cleanup_overlap) - 1
    dist = Math.round(radius/2) - 1
    for i in [0..width]
      y = flattened_openings[i]
      y_prev = flattened_openings[i-dist]
      y_next = flattened_openings[i+dist]
      hypo_pos =
        y: y + r_long
        x: i
      if (!y_next? || ((hypo_pos.y < y) == ( hypo_pos.y < y_next) && Math.dist(hypo_pos, {x: i+dist, y: y_next}) >= r_long)) && \
         (!y_prev? || ((hypo_pos.y < y) == ( hypo_pos.y < y_prev) && Math.dist(hypo_pos, {x: i-dist, y: y_prev}) >= r_long)) 
         
        candidates.push y
      else 
        candidates.push 0 

    return candidates


  _cascade_instability = (body, instabilities, cleanup_stability) ->
    instabilities[body.index] = 1

    if layout_params.cascade_instability 
      for n in body.neighbors 
        nb = bodies[n[0]]
        continue if instabilities[nb.index]
        if calc_stability(nb, instabilities) < cleanup_stability
          _cascade_instability nb, instabilities, cleanup_stability


  get_unstable_bodies = (cleanup_stability) ->
    instabilities = {}
    for body in bodies 
      if calc_stability(body) < cleanup_stability
        _cascade_instability body, instabilities, cleanup_stability

    unstable = (bodies[k] for k,v of instabilities when v == 1)
    positive = (b for b in unstable when b.x_target <= width)
    negative = (b for b in unstable when b.x_target > width)

    positive.sort (a,b) -> b.x_target - a.x_target
    negative.sort (a,b) -> a.x_target - b.x_target
    negative.concat positive

  get_highest_bodies = ->
    highest = []
    for body in bodies 
      continue if body.position.y >= height - body.radius
      has_body_on_top = false
      for n in body.neighbors
        if n[1] > Math.PI * 1.1
          has_body_on_top = true 
          break
      if !has_body_on_top
        highest.push body 

    highest


  cleanup_overlap = layout_params.cleanup_overlap or 2
  cleanup_layout = (cleanup_stability) ->
    cleanup_stability = cleanup_stability or layout_params.cleanup_stability or .7

    self_available = no_self_available = self_should_be_available = below_self = above_self = 0 

    if layout_params.verbose
      running_state.cleanup ?= []
    current_cleanup = []

    iterations = 0 
    exhausted_prime = !layout_params.filter_to_inflections_and_flats 

    openings = build_openings()
    while true 
      # openings = build_openings()
      num_changed = 0

      unstable_bodies = get_unstable_bodies(cleanup_stability)

      if layout_params.restack_top && unstable_bodies.length > 0 && iterations < 1
        unstable_bodies = unstable_bodies.concat get_highest_bodies()

      # this is unneeded except in testing
      if layout_params.verbose && histo_layout_explorer_options.show_explorer
        occupancy = build_occupancy_map()

      # remove these unstable bodies from the map so that its position within the current 
      # body might be selected 
      for body, i in unstable_bodies
        imprint_body_on_map openings, body, -1, Math.round(body.radius * cleanup_overlap) - 1

        if layout_params.verbose && histo_layout_explorer_options.show_explorer
          imprint_body_on_map occupancy, body, -1, body.radius

      for body, i in unstable_bodies
        r = body.radius
        x = Math.round(body.position.x)
        y = Math.round(body.position.y)
        x_target = Math.round(body.x_target)

        move_within = Math.round width * .125
        bounds = [x_target - move_within, x_target + move_within]
        if bounds[0] > x
          bounds[0] = x         # allow it to stay in the same row, even though it 
        else if bounds[1] < x   # is targetting a ways away
          bounds[1] = x 

        options = filter_openings openings, body.radius, !exhausted_prime
        candidates = []
        for col in [bounds[0]..bounds[1]]
          continue if col < r || col >= width - r 
          if options[col] > 0
            score = Math.log(options[col] + 1) / Math.abs( (body.x_target - col) / width )
            candidates.push [col, options[col], score]
        #########

        candidates.sort (a,b) -> b[2] - a[2]

        top_candidate = candidates[0]
        if top_candidate && (top_candidate[0] != x || top_candidate[1] != y)
          # wake it up and set a new position
          if body.isSleeping
            Matter.Sleeping.set(body, false)
          body.sleepCounter = 0
          body.moved_insignificantly_after_sleep = 0 

          Matter.Body.setPosition body, {x: top_candidate[0], y: top_candidate[1]}

          if layout_params.verbose && histo_layout_explorer_options.show_explorer
            current_cleanup.push 
              body: JSON.parse JSON.stringify {position: body.position, radius: body.radius, x_target: body.x_target, index: body.index}
              from: {x, y}
              to: {x: body.position.x, y: body.position.y}
              candidates: candidates
              openings: JSON.parse JSON.stringify openings # build_openings()
              occupancy: JSON.parse JSON.stringify occupancy 
              prime_positions: JSON.parse JSON.stringify options
              unstable_bodies: JSON.parse JSON.stringify ({index: b.index, position: b.position, radius: b.radius} for b in unstable_bodies)
              bodies: ({neighbors: b.neighbors, position: b.position, radius: b.radius, index: b.index} for b in bodies)

          num_changed += 1

        imprint_body_on_map openings, body, 1, Math.round(body.radius * cleanup_overlap) - 1
        if layout_params.verbose && histo_layout_explorer_options.show_explorer
          imprint_body_on_map occupancy, body, 1, r


      # console.log "Changed #{num_changed} positions"
      if num_changed == 0 || iterations > 100
        if exhausted_prime   
          # console.log "Done!", {iterations, unstable_bodies, candidates}  
          break
        else 
          exhausted_prime = true
          iterations = 0 

      find_neighbors()
      iterations += 1
    if layout_params.verbose && current_cleanup.length > 0
      running_state.cleanup.push current_cleanup


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

  # Returns array representing a 2d width x height map of which pixels are occupied
  # by avatars. Each cell has the number of avatars occupying that space.
  build_occupancy_map = (r_mult = 1) -> 
    size = width * height 
    occupancy_map = new Int32Array width * height 
    
    for body in bodies
      if r_mult > 1
        r = Math.round(body.radius * r_mult) - 1
      else 
        r = body.radius

      mask = get_mask(r)
      imprint_body_on_map occupancy_map, body, 1, r 

    occupancy_map

  imprint_body_on_map = (occupancy_map, body, increment = 1, radius = null, v) ->
    # imprint the body's mask on the occupancy map
    # get the start offset of the occupancy map at which to start imprinting
    r = Math.round(radius or body.radius)
    x = Math.round body.position.x 
    y = Math.round body.position.y
    mask = get_mask(r)
    row = y - r 
    col = x - r
    mask_row = mask_col = 0 
    while mask_row < 2 * r
      offset_row = row + mask_row 
      
      if offset_row >= 0 && offset_row < height
        while mask_col < 2 * r
          offset_col = col + mask_col 

          if offset_col > 0 && offset_col < width && mask[ mask_row * 2 * r + mask_col ]
            # imprint
            occupancy_map[offset_row * width + offset_col] += increment
            # console.log "Set #{offset_row * width + offset_col} to #{occupancy_map[offset_row * width + offset_col]}"

          mask_col += 1


      mask_row += 1
      mask_col = 0

  # An opening is a place where a body could move. Computed using the occupancy map, just doubling 
  # the radius of all bodies. Any entry in the occupancy map that remains zero is free. 
  # Then scan through and set as a valid spot to move to. 
  build_openings = ->
    build_occupancy_map(cleanup_overlap)  



  # Determines which bodies are adjacent to a body. For each body, sets the angle {0, 360º} which represents 
  # the angle at which the body is touched by the other body. 
  # 0 is the right, 90º is the middle bottom, 180º is the left, 270º is the middle top.
  # 
  # epsilon is a little extra that will help bodies that are *almost* touching to be considered touching.

  a90  = Math.PI / 2
  a180 = Math.PI
  a270 = 3 * Math.PI / 2
  a360 = 2 * Math.PI
  neighbors_last_set = -1
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

        if b.position.y < a.position.y || (b.position.y == a.position.y && a.position.x > b.position.x) 
          aa = bodies[j]; bb = bodies[i] # make sure a is always at least as high as b; for ease in computing angles
        else 
          aa = bodies[i]; bb = bodies[j]

        a_x = aa.position.x; a_y = aa.position.y 
        b_x = bb.position.x; b_y = bb.position.y
        a_r = aa.radius; b_r = bb.radius

        dist = Math.sqrt (a_x - b_x) * (a_x - b_x) + (a_y - b_y) * (a_y - b_y)
        if dist <= a_r + b_r + epsilon

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

          aa.neighbors.push [bb.index, a_angle]
          bb.neighbors.push [aa.index, b_angle]

        j += 1
      i += 1

    neighbors_last_set = total_ticks


  ############################
  # Each time step, move each avatar toward its desired x-target. 
  # The default gravity in the layout_params engine is also enabled, so 
  # each avatar also has a downwards force applied. 

  engine.world.gravity.scale = layout_params.gravity_scale or .000012  
                                        # much less gravity than default (.001); if it is too high, 
                                        # avatars are compacted on top of each other.
  
  x_force_mult = layout_params.x_force_mult or .006
  beforeTick = ->
    
    for body in bodies 
      continue if body.isStatic || body.isSleeping

      # Move the avatar toward the target with force proportional 
      # to its distance away from it. 
      dist_to_target = body.x_target - body.position.x
      
      x_push = dist_to_target * x_force_mult

      ################
      # Attempted optimization: if the avatar strings together a series of unblocked 
      # movements, boost their speed, as it suggests they may be unimpeded. 
      # Helps especially with convergence on histograms with few avatars. 
      if layout_params.enable_boosting
        body.last_push ?= x_push
        boostable = Math.abs(dist_to_target + body.last_push - body.last_dist_target) < .0000000000001
        # console.log boostable, Math.abs(dist_to_target + body.last_push - body.last_dist_target)
        if boostable 
          if body.boost_streak > 0
            # console.log "boosted"
            x_push = x_push * body.boost_streak
          body.boost_streak += 1
        else 
          x_push = x_push
          body.boost_streak = 0 
        body.last_push = x_push
        body.last_dist_target = dist_to_target
      ################

      # Apply the push toward the desired x-target
      Matter.Body.translate body, {x: x_push, y: 0}




  ticks_since_last_cleanup = 100
  current_cleanup_stability = layout_params.cleanup_stability
  afterTick = (ev) ->

    Matter.Sleeping._motionSleepThreshold += motionSleepThresholdIncrement 

    total_sleeping = 0 
    for body,i in bodies 
      x = body.position.x 
      y = body.position.y
      x_target = body.x_target

      # Don't let bodies fall through the bottom
      if y > height 
        Matter.Body.setPosition body, {x: x, y: height}
        y = height

      ##############
      # wake bodies up periodically to see if space opened up for them while they were sleeping
      if wake_every_x_ticks && total_ticks % wake_every_x_ticks == wake_every_x_ticks - 1
        if body.isSleeping

          # Check how much this body moved since the last time it was woke. If it didn't move much,
          # then put it to sleep quicker this time.
          if layout_params.reduce_sleep_threshold_if_little_movement
            reduction_exponent = layout_params.sleep_reduction_exponent or .7 
            body.moved_insignificantly_after_sleep ?= 0
            if body.before_sleep
              xs = body.position.x 
              xy = body.position.y
              dist = Math.sqrt( (x-xs) * (x-xs) + (y-xy) * (y-xy)  )
              if dist < .00000001
                body.moved_insignificantly_after_sleep += 1
              else if body.moved_insignificantly_after_sleep > 0
                body.moved_insignificantly_after_sleep = 0

            body.sleepThreshold = body.original_sleep_threshold * Math.pow(reduction_exponent, (1 + body.moved_insignificantly_after_sleep))

            body.before_sleep = 
              x: x
              y: y

          Matter.Sleeping.set(body, false)

          # Give it a little nudge down after it awakens
          body.force.y += 2 * body.mass * engine.world.gravity.y * engine.world.gravity.scale
      ##########################


      if body.isSleeping 
        total_sleeping += 1


    #############################
    # Swap positions when advantageous. Don't do it every tick for performance reasons, as this is n^2.
    global_position_swap = global_swap_every_x_ticks && total_ticks % global_swap_every_x_ticks == global_swap_every_x_ticks - 1 
    if global_position_swap
      sweep_all_for_position_swaps()
    ##########

    if layout_params.cleanup_layout_every_x_ticks
      if total_sleeping > bodies.length * layout_params.cleanup_when_percent_sleeping && ticks_since_last_cleanup > layout_params.cleanup_layout_every_x_ticks        
        
        if current_cleanup_stability > 0
          cleanup_layout(current_cleanup_stability)
          if layout_params.change_cleanup_stability?
            current_cleanup_stability += layout_params.change_cleanup_stability
          if global_swap_every_x_ticks
            sweep_all_for_position_swaps()      
        ticks_since_last_cleanup = 0 
      else 
        ticks_since_last_cleanup += 1

    # stop when all the avatars are sleeping or we've given up 
    done = total_ticks > 2000 || total_sleeping / bodies.length >= layout_params.end_sleep_percent

    done ||= opts.abort?()

    if done

      if layout_params.cleanup_layout_every_x_ticks
        if layout_params.final_cleanup_stability 
          current_cleanup_stability = layout_params.final_cleanup_stability

        if current_cleanup_stability > 0
          cleanup_layout(current_cleanup_stability)

      if global_swap_every_x_ticks
        sweep_all_for_position_swaps()

      Matter.Runner.stop(runner)
      runner.enabled = false

    total_ticks += 1

  Matter.Runner.run = (runner, engine) ->

    update_verbose = (tick_time) ->
      running_state.layout_time ?= 0 
      running_state.layout_time += tick_time
      global_running_state[layout_params.param_hash].tick_time += tick_time

      find_neighbors()
      evaluate_layout()
      running_state.occupancy_map = build_occupancy_map()
      running_state.openings = build_openings()
      running_state.bodies = ( {index: b.index, position: b.position, radius: b.radius, neighbors: b.neighbors} for b in bodies )
      running_state.ticks = total_ticks
      _.extend running_state, 
        '%_sleeping': "#{(100 * total_sleeping / bodies.length).toFixed(1)}%"
        ticks: total_ticks

      save running_state
      save global_running_state


    after_run = ->
      write_positions()
      histo_run_next_job(opts)

    if layout_params.show_histogram_physics
      renderer = (time) -> 
        runner.frameRequestId = _requestAnimationFrame(renderer)

        if time && runner.enabled
          if layout_params.verbose
            t0 = performance.now()

          beforeTick()
          Engine.update(engine)
          afterTick()

          if layout_params.verbose
            update_verbose performance.now() - t0

          write_positions()

        if !runner.enabled
          after_run()

      renderer()

    else 
      setTimeout ->

        if layout_params.verbose
          t0 = performance.now()

        # console.profile(opts.running_state)
        while runner.enabled 
          beforeTick()
          Engine.update(engine)
          afterTick()
        # console.profileEnd(opts.running_state)

        if layout_params.verbose
          update_verbose performance.now() - t0

        after_run()
      , 0

    runner


  if layout_params.verbose
    # console.profile(running_state.key)

    running_state = fetch opts.running_state
    global_running_state = fetch 'histo-timing'

    global_running_state[layout_params.param_hash] ?=
      tick_time: 0 
      truth: 0
      visibility: 0
      stability: 0
      cnt: 0

  Matter.Runner.run runner, engine




#####
# Calculate node radius based on the largest density of avatars in an 
# area (based on a moving average of # of opinions, mapped across the
# width and height)
window.calculateAvatarRadius = (width, height, opinions, {fill_ratio, round}) -> 
  fill_ratio ?= .25
  round ?= true

  filter_out = fetch 'filtered'
  if filter_out.users && !filter_out.enable_comparison
    opinions = (o for o in opinions when !(filter_out.users?[o.user]))

  opinions.sort (a,b) -> a.stance - b.stance

  # find most dense region of opinions
  window_size = .05
  avg_inc = .025
  max_opinions = 0
  idx = 0
  stance = -1.0 

  while stance <= 1.0 + window_size

    o = idx
    cnt = 0
    while o < opinions.length

      if opinions[o].stance < stance - window_size
        idx = o
      else if opinions[o].stance > stance + window_size
        break
      else 
        cnt += 1

      o += 1

    if cnt > max_opinions
      max_opinions = cnt 

    stance += avg_inc


  # Calculate the avatar radius we'll use. It is based on 
  # trying to fill fill_ratio of the densest area of the histogram
  if max_opinions > 0 
    effective_width = width * 2 * window_size
    area_per_avatar = fill_ratio * effective_width * height / max_opinions
    r = Math.sqrt(area_per_avatar) / 2

  else 
    r = Math.sqrt(width * height / opinions.length * fill_ratio) / 2

  r = Math.min(r, width / 2, height / 2)

  if round 
    Math.round r
  else 
    r















######
# Uses a d3-based layout_params simulation to calculate a reasonable layout
# of avatars within a given area.
positionAvatarsWithD3 = (opts) -> 

  # Check if system energy would be reduced if two nodes' positions would 
  # be swapped. We square the difference in order to favor large differences 
  # for one vs small differences for the pair.
  energy_reduced_by_swap = (p1, p2) ->
    # how much does each point covet the other's location, over their own?
    p1_jealousy = (p1.x - p1.x_target) * (p1.x - p1.x_target) - \
                  (p2.x - p1.x_target) * (p2.x - p1.x_target)
    p2_jealousy = (p2.x - p2.x_target) * (p2.x - p2.x_target) - \
                  (p1.x - p2.x_target) * (p1.x - p2.x_target) 
    p1_jealousy + p2_jealousy

  # Swaps the positions of two avatars
  swap_position = (p1, p2) ->
    swap_x = p1.x; swap_y = p1.y
    p1.x = p2.x; p1.y = p2.y
    p2.x = swap_x; p2.y = swap_y 

  # One iteration of the simulation
  tick = (alpha) ->
    stable = true

    ####
    # Repel colliding nodes
    # A quadtree helps efficiently detect collisions
    q = d3.geom.quadtree(nodes)

    for n in nodes 
      q.visit collide(n, alpha)

    for o, i in nodes
      o.px = o.x
      o.py = o.y

      # Push node toward its desired x-position
      o.x += alpha * (x_force_mult * width  * .001) * (o.x_target - o.x)

      # Push node downwards
      o.y += alpha * y_force_mult

      # Ensure node is still within the bounding box
      if o.x < o.radius
        o.x = o.radius
      else if o.x > width - o.radius
        o.x = width - o.radius

      if o.y < o.radius
        o.y = o.radius
      else if o.y > height - o.radius
        o.y = height - o.radius

      dx = Math.abs(o.py - o.y)
      dy = Math.abs(o.px - o.x) > .1

      if stable && Math.sqrt(dx * dx + dy * dy) > 1
        stable = false

    # Complete the simulation if we've reached a steady state
    stable

  collide = (p1, alpha) ->

    return (quad, x1, y1, x2, y2) ->
      collisions += 1

      p2 = quad.point
      if quad.leaf && p2 && p2 != p1
        dx = Math.abs (p1.x - p2.x)
        dy = Math.abs (p1.y - p2.y)
        dist = Math.sqrt(dx * dx + dy * dy)
        combined_r = p1.radius + p2.radius

        # Transpose two points in the same neighborhood if it would reduce 
        # energy of system
        if energy_reduced_by_swap(p1, p2) > 0
          swap_position(p1, p2)          

        # repel both points equally in opposite directions if they overlap
        if dist < combined_r
          separate_by = if dist == 0 then 1 else ( combined_r - dist ) / combined_r
          offset_x = (combined_r - dx) * separate_by
          offset_y = (combined_r - dy) * separate_by

          if p1.x < p2.x 
            p1.x -= offset_x / 2
            p2.x += offset_x / 2
          else 
            p2.x -= offset_x / 2
            p1.x += offset_x / 2

          if p1.y < p2.y           
            p1.y -= offset_y / 2
            p2.y += offset_y / 2

          else 
            p2.y -= offset_y / 2
            p1.y += offset_y / 2


      # Visit subregions if we could possibly have a collision there
      neighborhood_radius = p1.radius
      nx1 = p1.x - neighborhood_radius
      nx2 = p1.x + neighborhood_radius
      ny1 = p1.y - neighborhood_radius
      ny2 = p1.y + neighborhood_radius

      return x1 > nx2 || 
              x2 < nx1 ||
              y1 > ny2 ||
              y2 < ny1

  write_positions = -> 
    setTimeout ->
      positions = {}
      for o, i in nodes
        positions[parseInt(opinions[i].user.substring(6))] = \
          [Math.round((o.x - o.radius) * 10) / 10, Math.round((o.y - o.radius) * 10) / 10, false, o.stability]

      opts.done?(positions)

  {nodes, targets, opinions, width, height, r} = initialize_positions opts
  bodies = nodes 
  layout_params = opts.layout_params

  ###########
  # run the simulation
  stable = false
  alpha = layout_params.alpha or .8
  decay = layout_params.decay or .8
  min_alpha = layout_params.min_alpha or 0.0000001
  x_force_mult = layout_params.x_force_mult or 2
  y_force_mult = layout_params.y_force_mult or 2

  total_ticks = 0
  collisions = 0 

  if layout_params.verbose
    # console.profile(running_state.key)

    running_state = fetch opts.running_state
    global_running_state = fetch 'histo-timing'

    global_running_state[layout_params.param_hash] ?=
      tick_time: 0 
      truth: 0
      visibility: 0
      stability: 0
      cnt: 0


  update_verbose = (tick_time) ->
    running_state.layout_time ?= 0 
    running_state.layout_time += tick_time
    global_running_state[layout_params.param_hash].tick_time += tick_time
    global_running_state[layout_params.param_hash].cnt += 1

    running_state.ticks = total_ticks
    _.extend running_state, 
      ticks: total_ticks

    save running_state
    save global_running_state

  after_run = ->
    write_positions()
    histo_run_next_job(opts)

  if opts.layout_params?.show_histogram_physics

    _requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame \
                                  || window.mozRequestAnimationFrame || window.msRequestAnimationFrame \
                                  || (callback) -> 
                                        setTimeout -> 
                                          callback()
                                        , 1000 / 60

    iterate = => 
      if layout_params.verbose
        t0 = performance.now()

      stable = tick alpha

      alpha *= decay
      total_ticks += 1

      # console.log "Tick: #{total_ticks} Collisions: #{collisions}"
      collisions = 0

      stable ||= alpha <= min_alpha


      if layout_params.verbose
        update_verbose performance.now() - t0

      aborted = opts.abort?()
      if stable || aborted
        # console.profileEnd(opts.running_state)
        after_run()

      else 
        write_positions()
        _requestAnimationFrame iterate


    iterate()

  else 

    if layout_params.verbose
      t0 = performance.now()

    while true
      stable = tick alpha
      alpha *= decay
      total_ticks += 1

      stable ||= alpha <= min_alpha

      aborted = opts.abort?()
      break if stable || aborted

    if layout_params.verbose
      update_verbose performance.now() - t0

    after_run()

