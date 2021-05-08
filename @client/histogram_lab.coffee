window.HistogramTester = ReactiveComponent
  displayName: 'HistogramTester'

  render: -> 

    common_layout_params = 
      engine: 'matterjs'
      initial_layout: 'tiled'      
      show_histogram_physics: false  
      verbose: true
      
      fill_ratio: 1
      motionSleepThreshold: .005
      motionSleepThresholdIncrement: .000025
      enable_boosting: false
      wake_every_x_ticks: 9999
      global_swap_every_x_ticks: 150
      reduce_sleep_threshold_if_little_movement: true 
      sleep_reduction_exponent: .5
      cleanup_layout_every_x_ticks: 50
      x_force_mult: .008
      gravity_scale: .000012
      restack_top: false 
      final_cleanup_stability: .5
      change_cleanup_stability: -0.2
      cleanup_stability: .9
      cleanup_when_percent_sleeping: .4
      end_sleep_percent: .75
      filter_to_inflections_and_flats: true
      cleanup_overlap: 1.8
      cascade_instability: true

    layout_params = []

    # layout_params.push {engine: 'd3'}

    # layout_params.push {engine: 'tiled'}

    for engine in ['matterjs'] #, 'packed-tile', 'tiled-with-wiggle', 'tiled-with-wiggle-2']

      # don't believe in the aesthetics > .01
      for motionSleepThreshold in [.005] #[0, .01]
        # don't believe in the aesthetics > .00005, might be able to get away with .00005, but it doesn't help much
        for motionSleepThresholdIncrement in [.000025] #, .00005] #[0, .00001, .0001]
          # This matters timing wise, but I'm not sure if .5 is good enough aesthetically
          for sleep_reduction_exponent in [.5] #[.5, .7] #[.5, .7, .9]
            # Significant timing impact, is there any benefit to < 125? 250 even looks pretty good
            for wake_every_x_ticks in [9999]
              for x_force_mult in [.008]
                # this matters a lot for time. big improvement in aestetics if disabled, with big performance hit
                for reduce_sleep_threshold_if_little_movement in [true]
                  # This matters a lot, but not sure if > 10 is ok aesthetically. Actually, with cleanup layout, not sure it is even necessary.
                  for global_swap_every_x_ticks in [150] # [10, 100, 250] #[2, 10, 100]
                    for end_sleep_percent in [.75]

                      # layout_params.push {end_sleep_percent, engine, show_histogram_physics: false, x_force_mult, filter_to_inflections_and_flats: null, cascade_instability: null, cleanup_stability: null, cleanup_overlap: null, cleanup_layout_every_x_ticks: null,motionSleepThreshold,motionSleepThresholdIncrement,sleep_reduction_exponent,wake_every_x_ticks,reduce_sleep_threshold_if_little_movement,global_swap_every_x_ticks}
                      for filter_to_inflections_and_flats in [true]
                        for cleanup_layout_every_x_ticks in [50]
                          for cleanup_when_percent_sleeping in [.4]
                            for cleanup_overlap in [1.8]
                              for cleanup_stability in [.7, .9]
                                for final_cleanup_stability in [.5]
                                  for change_cleanup_stability in [-0.2]
                                    for cascade_instability in [true]
                                      layout_params.push {end_sleep_percent, engine, cleanup_when_percent_sleeping, change_cleanup_stability, final_cleanup_stability, x_force_mult, filter_to_inflections_and_flats, cascade_instability, cleanup_stability, cleanup_overlap, cleanup_layout_every_x_ticks,motionSleepThreshold,motionSleepThresholdIncrement,sleep_reduction_exponent,wake_every_x_ticks,reduce_sleep_threshold_if_little_movement,global_swap_every_x_ticks}


    param_sets = {}
    for param in layout_params 
      _.defaults param, common_layout_params
      param_hash = JSON.stringify(param)
      param_sets[param_hash] = _.clone(param)
      param.param_hash = param_hash

    sizes = [
      {
        width: PROPOSAL_HISTO_WIDTH()
        height: 170   
      } 
      # {
      #   width: PROPOSAL_HISTO_WIDTH() / 2
      #   height: 170 / 2
      # } 

    ]

    histos = []

    for layout in layout_params 
      for size in sizes 
        histos.push _.extend {}, size, {layout_params: layout}

    proposals = fetch('/proposals').proposals
    proposals.sort (a,b) -> opinionsForProposal(b).length - opinionsForProposal(a).length

    # proposals.sort (b,a) -> opinionsForProposal(b).length - opinionsForProposal(a).length

    num_histos = 40
    start_idx = 0
    proposals_to_show = proposals.slice(start_idx,start_idx + num_histos)


    DIV 
      style:
        width: PROPOSAL_HISTO_WIDTH() 
        margin: 'auto'

      GlobalHistTiming
        param_sets: param_sets

      for proposal in proposals_to_show
        histo = 
          proposal: proposal
          opinions: opinionsForProposal(proposal)
          enable_individual_selection: false
          enable_range_selection: false
          draw_base: true
          backgrounded: false
          draw_base_labels: true
          base_style: "2px solid #414141"
          label_style: 
            display: 'none'

        DIV 
          style: 
            marginTop: 40

          DIV 
            style:
              fontFamily: 'Fira Sans Condensed' 
              fontWeight: 700
              fontSize: 28
            proposal.name

            DIV null, 
              for hist, i in histos 
                params = _.defaults {key: "#{namespaced_key('histogram', proposal)}-#{i}"}, histo, hist
                RenderedHist = Histogram params 

                DIV 
                  style: 
                    marginBottom: 20 
                    position: 'relative'
                  RenderedHist 

                  HistoDetails
                    running_state: RenderedHist.props.key
                    hist: hist
                    param_sets: param_sets

                  LayoutExplorer 
                    running_state: RenderedHist.props.key
                    hist: params 


histo_layout_explorer_options = fetch('histo_layout_explorer_options')
_.defaults histo_layout_explorer_options, 
  show_explorer: false
  ms_between_plays: 99999
  show_move_log: false 
  show_occupancy: true
  show_openings: true
  show_prime_openings: true      
  circle_around_openings: false 
  highlight_instability: true 
  show_neighbor_touchpoints: false
  connect_to_xtarget: false 
  line_from_to: false
save histo_layout_explorer_options

LayoutExplorerOptions = ReactiveComponent
  displayName: 'LayoutExplorerOptions'

  render: ->  
    opts = fetch('histo_layout_explorer_options')

    DIV 
      style: 
        position: 'absolute'
        left: -260

      for k,v of opts when k != 'key' && (opts.show_explorer || k == 'show_explorer')
        DIV 
          style: 
            fontSize: 12        
          do(k,v) =>
            LABEL 
              style: 
                fontSize: 12

              if k == 'ms_between_plays'
                INPUT 
                  type: 'text'
                  value: v 
                  style:
                    width: 50
                  onChange: (ev) => 
                    my_time = opts.ms_between_plays = parseInt(ev.target.value)
                    do (my_time) ->
                      setTimeout ->
                        if opts.ms_between_plays == my_time
                          save opts 
                      , 1000
              else 
                INPUT 
                  type: 'checkbox'
                  checked: v 
                  title: k
                  onChange: (ev) =>
                    opts[k] = ev.target.checked
                    save opts

              k.replaceAll('_', ' ')


LayoutExplorer = ReactiveComponent
  displayName: 'LayoutExplorer'

  render: ->  


    fetch @props.running_state
    running_state = fetch @props.running_state
    cleanup = running_state.cleanup
    has_cleanup = cleanup?.length > 0

    if has_cleanup
      @local.ticks ?= 0
      @local.move ?= 0 

      tick_data = cleanup[@local.ticks][@local.move]

      x = tick_data.from.x; y = tick_data.from.y
      x2 = tick_data.to.x; y2 = tick_data.to.y

    opts = fetch('histo_layout_explorer_options')

    DIV 
      style: 
        margin: 'auto'

      LayoutExplorerOptions()

      if opts.show_explorer
        DIV null, 
          CANVAS 
            ref: 'my_canvas'


          if has_cleanup 
            DIV null,
              DIV null,
                "Move: #{@local.move + 1} / #{cleanup[@local.ticks].length}"

                for move in [0..cleanup[@local.ticks].length - 1]
                  do (move) =>
                    BUTTON
                      style: 
                        marginLeft: 8
                        fontSize: 10
                      className: 'like_link'
                      onClick: (ev) =>
                        @local.move = move 
                        save @local 
                      move 

              DIV null,
                "Tick: #{@local.ticks + 1} / #{cleanup.length}"

                for tick in [0..cleanup.length - 1]
                  do (tick) =>
                    BUTTON
                      className: 'like_link'
                      style: 
                        marginLeft: 8
                        fontSize: 10                
                      onClick: (ev) =>
                        @local.ticks = tick 
                        @local.move = 0
                        save @local 
                      tick 

              if opts.show_move_log 
                DIV null, 
                  "#{tick_data.body.index} [#{tick_data.body.x_target}]: (#{x}, #{y}) => (#{x2}, #{y2})"

                  DIV 
                    style: 
                      fontSize: 13

                    for tick in [0..cleanup.length - 1]

                      DIV null,
                        "Tick #{tick}"

                        for move in [0..cleanup[tick].length - 1]
                          tdat = cleanup[tick][move]
                          x = tdat.from.x; y = tdat.from.y
                          x2 = tdat.to.x; y2 = tdat.to.y

                          DIV null,
                            "#{tdat.body.index} [#{tdat.body.x_target}]: (#{x}, #{y}) => (#{x2}, #{y2})"




  update: -> 
    running_state = fetch @props.running_state
    cleanup = running_state.cleanup
    opts = fetch('histo_layout_explorer_options')

    return if !opts.show_explorer || !running_state.occupancy_map

    @local.ticks ?= 0
    @local.move ?= 0 


    width = @props.hist.width 
    height = @props.hist.height

    canvas = @refs.my_canvas.getDOMNode()
    canvas.width = width 
    canvas.height = height
    ctx = canvas.getContext('2d')

    ctx.clearRect(0, 0, canvas.width, canvas.height)

    img = ctx.createImageData(width, height)
    d  = img.data

    has_cleanup = cleanup?.length > 0 

    if has_cleanup
      tick_data = cleanup[@local.ticks][@local.move]
      map = tick_data.occupancy
      openings = tick_data.openings 

      if !@local.last_advance? || Date.now() - @local.last_advance >= opts.ms_between_plays
        @local.last_advance = Date.now()
        setTimeout => 
          @local.move += 1

          if @local.move >= cleanup[@local.ticks].length
            @local.ticks += 1
            @local.move = 0 
            if @local.ticks >= cleanup.length
              @local.ticks = 0 
          save @local 
        , opts.ms_between_plays

      radius = tick_data.body.radius
    else 
      map = running_state.occupancy_map
      openings = running_state.openings 


    for col in [0..width]
      opening_this_col = false
      
      for row in [height - 1..0 - 1] by -1
        occupancy = map[ row * width + col ]
        if opts.show_occupancy && occupancy > 0 
          base = 4 * (row * width + col)

          a = 255
          r = g = b =150

          d[base + 0]   = r
          d[base + 1]   = g
          d[base + 2]   = b
          d[base + 3]   = a
        else if opts.show_openings && !opening_this_col && row <= height - radius && col >= radius && col <= width - radius && openings[ row * width + col ] == 0 
          for i in [0..1]
            base = 4 * ((row - i) * width + col)
            d[base + 0]   = 128
            d[base + 1]   = 180
            d[base + 2]   = 128
            d[base + 3]   = 255

          opening_this_col = row 

    if has_cleanup && opts.show_prime_openings
      prime_positions = tick_data.prime_positions
      for col in [0..width]
        if prime_positions[col]
          for w in [0] #[-1..2]
            for h in [0..4]
              base = 4 * ((prime_positions[col] - h) * width + col + w)
              d[base + 0]   = 128
              d[base + 1]   = 128
              d[base + 2]   = 255
              d[base + 3]   = 255

    ctx.putImageData( img, 0, 0)

    # lines from center of each body toward each neighbor's center
    if opts.show_neighbor_touchpoints
      for a in running_state.bodies 
        if a.neighbors?.length > 0 
          for [b, angle] in a.neighbors
            x = Math.round a.position.x; y = Math.round a.position.y
            r = a.radius
            x2 = x + r * Math.cos(angle)
            y2 = y + r * Math.sin(angle)

            ctx.beginPath()
            ctx.moveTo(x, y)
            ctx.lineTo(x2, y2)
            ctx.strokeStyle = '#444444'
            ctx.closePath()
            ctx.stroke()



    return if !has_cleanup

    # circle around unstable bodies
    if opts.highlight_instability
      unstable_bodies = tick_data.unstable_bodies
      for unstable_body in unstable_bodies or []
        ctx.beginPath()
        ctx.strokeStyle = 'red'   
        ctx.lineWidth = 1
        ctx.arc(unstable_body.position.x, unstable_body.position.y, unstable_body.radius, 0, 2 * Math.PI)
        ctx.closePath()
        ctx.stroke()

    x = tick_data.from.x; y = tick_data.from.y
    x2 = tick_data.to.x; y2 = tick_data.to.y

    # From / to circles around the moved body
    ctx.beginPath()
    ctx.fillRect(x,y,1,1)
    ctx.fillStyle = 'black'
    ctx.arc(x, y, tick_data.body.radius, 0, 2 * Math.PI)
    ctx.closePath()
    ctx.stroke()

    ctx.beginPath()
    ctx.fillRect(x2,y2,1,1)
    ctx.fillStyle = 'black'    
    ctx.arc(x2, y2, tick_data.body.radius, 0, 2 * Math.PI)
    ctx.closePath()
    ctx.stroke()

    # Line connecting the from/to circles
    if opts.line_from_to
      ctx.beginPath()
      ctx.moveTo(x, y)
      ctx.lineWidth = 3
      ctx.lineTo(x2, y2)
      ctx.strokeStyle = '#FF6666'
      ctx.closePath()
      ctx.stroke()

    # Line connecting the new location of the body to its x-target
    if opts.connect_to_xtarget
      ctx.beginPath()
      ctx.moveTo(x2, y2)
      ctx.lineWidth = 3
      ctx.lineTo(tick_data.body.x_target, height)
      ctx.strokeStyle = '#FF6666'
      ctx.closePath()
      ctx.stroke()

    # visualize circle around some of the prime positions
    if opts.circle_around_openings
      last_row = -1
      prime_positions = tick_data.prime_positions
      for col in [0..width]
        row = prime_positions[col]
        if row && last_row != row 
          ctx.beginPath()
          ctx.strokeStyle = '#444444'   
          ctx.lineWidth = 1
          ctx.arc(col, row, tick_data.body.radius, 0, 2 * Math.PI)
          ctx.closePath()
          ctx.stroke()
          last_row = row






  componentDidUpdate: -> @update()
  componentDidRender: -> @update()




HistoDetails = ReactiveComponent 
  displayName: 'HistoDetails'
  render: -> 
    running_state = fetch(@props.running_state)
    hist = @props.hist

    param_sets = @props.param_sets

    params_with_multiple_vals = {}
    _checker = {}

    for param_hash, param_set of param_sets
      for k,v of param_set
        if k of _checker && _checker[k] != v 
          params_with_multiple_vals[k] = true
        else
          _checker[k] = v

    colors = getNiceRandomHues Object.keys(params_with_multiple_vals).length
    i = -1
    DIV 
      key: "histo-state-#{running_state.total_ticks}"
      style:
        fontSize: 10
        position: 'absolute'
        right: -260
        bottom: 0

      DIV 
        style: 
          marginBottom: 10

        for k,v of hist.layout_params when k not in ['verbose', 'show_histogram_physics', 'param_hash'] && params_with_multiple_vals[k]
          i += 1
          DIV null,
            "#{k} = "
            SPAN
              style:
                color: hsv2rgb(colors[i], .7, .5)
                fontSize: 18
                fontWeight: 'bold'
              "#{v}"

      for k,v of running_state when v && k not in ['initialized', 'key', 'occupancy_map', 'bodies', 'openings', 'cleanup']
        DIV null,
          "#{k} = #{v}"

      if running_state.layout_time 
        DIV null, 
          DIV 
            style: 
              width: Math.min 200, running_state.layout_time / (if hist.layout_params.show_histogram_physics then 250 else 100)
              height: 15
              backgroundColor: 'red'

GlobalHistTiming = ReactiveComponent
  displayName: 'GlobalHistTiming'

  render: -> 
    global_running_state = fetch 'histo-timing'
    param_sets = @props.param_sets

    params_with_multiple_vals = {}
    _checker = {}
    totals = {}

    for param_hash, param_set of param_sets
      for k,v of param_set
        if k of _checker && _checker[k] != v
          params_with_multiple_vals[k] = true
        else
          _checker[k] = v


    for param_hash, param_set of param_sets
      for k,v of param_set
        continue if !params_with_multiple_vals[k] || !global_running_state[param_hash]?
        total_key = "#{k}=#{v}"
        if total_key of totals 
          totals[total_key] = [totals[total_key][0] + 1, totals[total_key][1] + global_running_state[param_hash].tick_time, totals[total_key][2] + global_running_state[param_hash].truth, totals[total_key][3] + global_running_state[param_hash].visibility, totals[total_key][4] + global_running_state[param_hash].stability, totals[total_key][5] + global_running_state[param_hash].cnt]
        else 
          totals[total_key] = [1, global_running_state[param_hash].tick_time, global_running_state[param_hash].truth, global_running_state[param_hash].visibility, global_running_state[param_hash].stability, global_running_state[param_hash].cnt]

    colors = getNiceRandomHues Object.keys(params_with_multiple_vals).length

    td_style = 
      padding: "4px 14px" 
      textAlign: 'right'
    th_style = _.extend {}, td_style, 
      fontWeight: 'bold'


    DIV 
      style: 
        width: 1400
      
      TABLE null, 

        TR null, 
          TH {style: th_style}, 'Param set'
          TH {style: th_style}, 'Truth'
          TH {style: th_style}, 'Visibility'
          TH {style: th_style}, 'Stability'
          TH {style: th_style}, 'Time (ms)'


          
        for param_hash, param_set of param_sets
          vals = global_running_state[param_hash]

          continue if !vals
          i = -1

          TR null,


                
            TD 
              style: td_style 
                           
              for k,v of param_set when params_with_multiple_vals[k]
                i += 1
                DIV 
                  style:
                    color: hsv2rgb(colors[i], .7, .5)
                    fontSize: 14
                    fontWeight: 'bold'
                  "#{k} = #{v}"



            TD 
              style: td_style 
              (100 * vals.truth / vals.cnt).toFixed(1)

            TD 
              style: td_style 
              (100 * vals.visibility / vals.cnt ).toFixed(1)

            TD 
              style: td_style 
              (100 * vals.stability / vals.cnt ).toFixed(1)

            TD 
              style: td_style 
              Math.round(vals.tick_time / vals.cnt)


      do =>
        keys = Object.keys(totals)
        keys.sort()
        i = -1
        colors = getNiceRandomHues keys.length

        TABLE 
          style: 
            marginTop: 36 

          TR null, 
            TH {style: th_style}, 'Param'
            TH {style: th_style}, 'Sets'
            TH {style: th_style}, 'Truth'
            TH {style: th_style}, 'Visibility'
            TH {style: th_style}, 'Stability'
            TH {style: th_style}, 'Time (ms)'


          for param in keys 
            [cnt, total_run_time, truth, visibility, stability, total_histos] = totals[param]
            i += 1


            TR 
              style: 
                backgroundColor: if i % 2 == 1 then '#f8f8f8'


                  
              TD 
                style: _.extend {}, td_style, color: hsv2rgb(colors[i], .7, .5)
                param


              TD 
                style: td_style 
                total_histos

              TD 
                style: td_style 
                Math.round(100 * truth / total_histos).toFixed(1)

              TD 
                style: td_style 
                Math.round(100 * visibility / total_histos).toFixed(1)

              TD 
                style: td_style 
                Math.round(100 * stability / total_histos).toFixed(1)

              TD 
                style: td_style 
                Math.round(total_run_time / total_histos)


