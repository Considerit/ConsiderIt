require './shared'
require './customizations'
require './drop_menu'




# get_all_tags = -> 
#   proposals = fetch '/proposals'
#   all_tags = {}
#   for proposal in proposals.proposals 
#     text = "#{proposal.name} #{proposal.description}"

#     if text.indexOf("#") > -1 && tags = text.match(/#(\w+)/g)
#       for tag in tags
#         tag = tag.toLowerCase()

#         all_tags[tag] ||= 0
#         all_tags[tag] += 1

#   # ordered_tags = ({tag: k, count: v} for k,v of all_tags when v > 1)
#   # ordered_tags.sort (a,b) -> b.count - a.count

#   all_tags 


regexes = {}
ApplyFilters = ReactiveComponent
  displayName: 'ApplyFilters'

  render: ->
    filters = fetch 'filters'
    filter_out = fetch 'filtered'
    filter_out.proposals ||= {}

    proposals = fetch '/proposals'

    new_filter_out = {}

    for filter in (filters.for_proposals or [])
      if !regexes[filter]
        regexes[filter] = new RegExp filter, 'i'

    for proposal in proposals.proposals
      editor = proposal_editor(proposal)
      if editor 
        editor = fetch(editor).name 
      else 
        editor = ""
      text = "#{editor} #{proposal.name} #{proposal.description} #{prettyDate(proposal.created_at)}"
      passes = true 
      for filter in (filters.for_proposals or [])
        passes &&= !!text.match regexes[filter]
      if !passes
        new_filter_out[proposal.key] = 1

    if JSON.stringify(new_filter_out) != JSON.stringify filter_out.proposals
      filter_out.proposals = new_filter_out
      save filter_out

    SPAN null


proposal_sort_keys = {}
window.stale_sort_order = (sort_key) ->
  fetch(sort_key).stale

window.invalidate_proposal_sorts = -> 
  for sort_key, __ of proposal_sort_keys 
    v = fetch sort_key
    v.force_resort = true
    save v

window.sorted_proposals = (proposals, sort_key, require_force) ->

  if sort_key not of proposal_sort_keys 
    proposal_sort_keys[sort_key] = true

  sort = fetch 'sort_and_filter_proposals'
  set_default_sort() if !sort.name? 

  proposals = proposals.slice()


  # filter out filtered proposals
  filter_out = fetch 'filtered'
  if filter_out.proposals
    filtered = []
    for proposal in proposals
      if filter_out.proposals[proposal.key]
        filtered.push proposal
    for proposal in filtered
      proposals.splice proposals.indexOf(proposal), 1

  if sort.filter? && sort.filter?.name != 'Show all'
    proposals = (p for p in proposals when sort.filter.passes(p))


  proposals = sort.order(proposals)

  if require_force
    # when dragging a slider on a list of proposals, we may want to 
    # return the old sort order even if it isn't technically correct.
    # This is because it is too annoying to have the proposals list
    # jumping around all the time.  

    keys = (p.key for p in (proposals or []))
    order = md5 keys

    sorted = fetch sort_key
    if !sorted.cache
      cached_order = null 
      _.extend sorted, 
        cache: []
        stale: true
        force_resort: true
      save sorted 
    else 
      cached_order = md5 sorted.cache

    # alright, same order
    if cached_order == order
      if sorted.stale || sorted.force_resort
        sorted.force_resort = false 
        sorted.stale = false 
        save sorted 

    # force an update to the sort order, either because its stale, bc we're initializing, or 
    # because a new proposal has been added or removed
    else if sorted.force_resort || proposals.length != sorted.cache.length
      sorted.force_resort = false
      sorted.stale = false
      sorted.cache = keys
      save sorted 

    # return the stale sort order
    else 
      if !sorted.stale
        sorted.stale = true 
        save sorted 

      dict_proposals = {}
      for p in proposals 
        dict_proposals[p.key] = p 
      proposals = (dict_proposals[k] for k in sorted.cache)

  proposals


rnd_order = {}

sort_options = [

  { 
    name: 'Total Score'
    description: "Each proposal is scored by the sum of all opinions, where each opinion expresses a score on a spectrum from -1 to 1. "    
    order: (proposals) -> 
      cache = {}
      opinion_views = fetch 'opinion_views'

      val = (proposal) ->
        if proposal.key not of cache 
          opinions = fetch(proposal).opinions or []   
          {weights, salience, groups} = compose_opinion_views opinions, proposal, opinion_views
          sum = 0
          for opinion in opinions
            continue if salience[opinion.user] < 1 # don't count users who aren't fully salient, they're considered backgrounded
            w = weights[opinion.user] # * salience[opinion.user]
            sum += opinion.stance * w
          cache[proposal.key] = sum
        cache[proposal.key]
      proposals.sort (a, b) -> val(b) - val(a)
  }, {
    name: 'Trending'
    description: "Same as 'Total Score', except newer proposals and opinions are weighed more heavily."

    order: (proposals) ->
      cache = {}

      n = Date.now()
      ov = (o) -> 
        ot = new Date(o.updated_at).getTime()
        o.stance / (1 + Math.pow((n - ot) / 100000, 2))

      opinion_views = fetch 'opinion_views'

      filters_for_proposals = {}

      # get last opinion to use as our "trending" stopper
      last_activity = "0"
      for prop in proposals
        opinions = prop.opinions or fetch(prop).opinions or [] 

        filters_for_proposals[prop.key] = 
          opinions: opinions
          views: compose_opinion_views opinions, prop, opinion_views
        {weights, salience, groups} = filters_for_proposals[prop.key].views
        for o in opinions
          continue if salience[o.user] < 1 || weights[o.user] == 0
          if o.updated_at > last_activity 
            last_activity = o.updated_at

        if prop.created_at > last_activity
          last_activity = prop.created_at

      latest_timestamp = new Date(last_activity).getTime()
      date_filter = fetch('opinion-date-filter')
      if date_filter.end
        latest_timestamp = Math.min(date_filter.end, latest_timestamp)

      RECENCY_SENSITIVITY = 100 # decrease this constant to favor newer proposals
      val = (proposal) -> 
        if proposal.key not of cache
          opinions = filters_for_proposals[proposal.key].opinions
          {weights, salience, groups} = filters_for_proposals[proposal.key].views
          sum = 0
          for opinion in opinions
            continue if salience[opinion.user] < 1 # don't count users who aren't fully salient, they're considered backgrounded
            w = weights[opinion.user] # * salience[opinion.user]
            sum += opinion.stance * w

          pt = new Date(proposal.created_at).getTime()

          if sum < 0
            cache[proposal.key] = sum * (1 + (latest_timestamp - pt) / RECENCY_SENSITIVITY)  
          else 
            cache[proposal.key] = sum / (1 + (latest_timestamp - pt) / RECENCY_SENSITIVITY) 

        cache[proposal.key]

      proposals.sort (a, b) ->
        val(b) - val(a)
  },
  {
    order: (proposals) -> 
      proposals.sort (a,b) -> new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    name: 'Date: Most recent first'
    description: "The proposals submitted most recently are shown first."
  }, {
    order: (proposals) -> 
      proposals.sort (a,b) -> new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    name: 'Date: Earliest first'
    description: "The proposals submitted first are shown first."
  }, { 
    name: 'Most unifying first'
    description: "The proposals on which participants are most united for or against are shown first."
    order: (proposals) -> 
      for sort in sort_options
        if sort.name == 'Most polarizing first'
          sorted = sort.order(proposals)
          sorted.reverse()
          return sorted
      return []

  }, { 
    name: 'Most polarizing first'
    description: "The proposals on which participants are most split are shown highest."
    order: (proposals) -> 
      cache = {}
      opinion_views = fetch 'opinion_views'

      val = (proposal) ->
        if proposal.key not of cache 
          opinions = fetch(proposal).opinions or []   
          {weights, salience, groups} = compose_opinion_views opinions, proposal, opinion_views
          sum = 0
          weight = 0 
          for opinion in opinions
            continue if salience[opinion.user] < 1 # don't count users who aren't fully salient, they're considered backgrounded
            w = weights[opinion.user] # * salience[opinion.user]
            sum += opinion.stance * w
            weight += w

          avg = sum / weight

          differences = 0
          weight = 0 
          for opinion in opinions
            continue if salience[opinion.user] < 1 # don't count users who aren't fully salient, they're considered backgrounded
            w = weights[opinion.user] # * salience[opinion.user]
            differences += w * (opinion.stance - avg) * (opinion.stance - avg)
            weight += w

          std_dev = Math.sqrt(differences / weight)
          if opinions.length > 1
            cache[proposal.key] = std_dev * Math.log(opinions.length + 1) 
          else 
            cache[proposal.key] = -1

        cache[proposal.key]
      proposals.sort (a, b) -> val(b) - val(a)


  }, 

  { 
    name: 'Average Score'
    description: "each proposal is scored by the average opinion, where each opinion expresses a score on a spectrum from -1 to 1. "
    order: (proposals) -> 
      cache = {}
      opinion_views = fetch 'opinion_views'
      val = (proposal) ->
        if proposal.key not of cache 
          opinions = fetch(proposal).opinions or []   
          {weights, salience, groups} = compose_opinion_views opinions, proposal, opinion_views
          sum = 0
          weight = 0 
          for opinion in opinions
            continue if salience[opinion.user] < 1 # don't count users who aren't fully salient, they're considered backgrounded
            w = weights[opinion.user] # * salience[opinion.user]
            sum += opinion.stance * w
            weight += w
          cache[proposal.key] = sum / weight 
        cache[proposal.key]
      proposals.sort (a, b) -> val(b) - val(a)


  },   
  # {
  #   name: 'Most Activity'
  #   description: "Ranked by number of opinions and discussion."

  #   order: (proposals) -> 
  #     cache = {}
  #     opinion_views = fetch 'opinion_views'

  #     val = (proposal) ->
  #       if proposal.key not of cache 
  #         opinions = fetch(proposal).opinions or []   
  #         {weights, salience, groups} = compose_opinion_views opinions, proposal, opinion_views
  #         sum = 0
  #         weight = 0 
  #         for opinion in opinions
  #           continue if salience[opinion.user] < 1 # don't count users who aren't fully salient, they're considered backgrounded
  #           w = weights[opinion.user] # * salience[opinion.user]
  #           sum += (1 + (opinion.point_inclusions or []).length) * w
  #           weight += w
  #         cache[proposal.key] = sum
  #       cache[proposal.key]
  #     proposals.sort (a, b) -> val(b) - val(a)
  # 
  # }, 
  { 
    name: 'Alphabetical order'
    order: (proposals) -> 
      proposals.sort (a, b) -> a.name.localeCompare b.name
    description: "Sort alphabetically by the item's title"
  }, 
  {
    name: 'Randomized'
    description: "Item order is randomized on each page load."

    order: (proposals) -> 
      proposals.sort (a,b) ->
        rnd_order[a.key] ||= Math.round(Math.random() * 99999) + 1
        rnd_order[b.key] ||= Math.round(Math.random() * 99999) + 1
        rnd_order[a.key] - rnd_order[b.key]
  }


]

window.set_sort_order = (name) ->
  sort = fetch 'sort_and_filter_proposals'
  for s in sort_options
    if s.name == name
      _.extend sort, s or sort_options[1]
      save sort
      return 

set_default_sort = -> 
  sort = fetch 'sort_and_filter_proposals'
  if !sort.name?
    found = false 
    loc = fetch('location')
    if loc.query_params?.sort_by
      for s in sort_options
        if s.name == loc.query_params.sort_by.replace('_', ' ')
          _.extend sort, s or sort_options[1]
          found = true 
          break

    if !found
      if def_sort = customization('homepage_default_sort_order')
        def = null 
        for s in sort_options
          if s.name == def_sort
            def = s
            break 
        _.extend sort, def or sort_options[1]

      else 
        _.extend sort, sort_options[1]

    save sort 





# currently unused
ProposalSort = ReactiveComponent
  displayName: 'ProposalSort'

  render : -> 

    proposals = fetch '/proposals' # registering dependency so that we get re-rendered...ApplyFilters is actually dependent
    subdomain = fetch '/subdomain'

    return SPAN null if !subdomain.name


    SPAN 
      style: _.defaults (@props.style or {})

      # ApplyFilters()


      DIV
        style: 
          display: 'inline-block'
          #verticalAlign: 'top'
          #paddingTop: 4 #16
          paddingRight: 12

        SortProposalsMenu() 

      # DIV
      #   style: 
      #     display: 'inline-block'
      #     verticalAlign: 'top'
      #     paddingTop: 8

      #   FORM 
      #     style: 
      #       position: 'relative'

      #     onSubmit: (e) => 
      #       n = @refs.new_filter
      #       filters.for_proposals ||= []
      #       filters.for_proposals.push n.value
      #       save filters
      #       n.value = null

      #       e.stopPropagation(); e.preventDefault()

      #     SVG
      #       width: 20
      #       height: 20
      #       style: 
      #         pointerEvents: 'none'
      #         position: 'absolute'
      #         right: 5
      #         top: 9
      #         zIndex: 1
      #       fill: '#888'

      #       viewBox: "0 0 100 125"
      #       G null,
      #         PATH
      #           d: "M69.054,59.058l27.471,23.811c2.494,2.162,2.766,5.971,0.604,8.465l-0.981,1.132c-2.162,2.494-5.971,2.766-8.465,0.604   L60.418,69.438"
      #         PATH 
      #           d: "M2.358,41.458c0-19.744,16.005-35.749,35.751-35.749c19.744,0,35.749,16.005,35.749,35.749  c0,19.746-16.005,35.751-35.749,35.751C18.363,77.208,2.358,61.203,2.358,41.458z M38.563,67.583  c14.428,0,26.124-11.696,26.124-26.126c0-14.428-11.696-26.124-26.124-26.124c-14.43,0-26.126,11.696-26.126,26.124  C12.438,55.887,24.134,67.583,38.563,67.583z"

      #     INPUT
      #       ref: 'new_filter' 
      #       type: 'text'
      #       'aria-label': 'search proposals'

      #       style:
      #         fontSize: 14
      #         padding: '2px 8px'
      #         width: 150
      #         border: '1px solid #aaa'

      #   DIV 
      #     style:
      #       paddingTop: 5

      #     for filter in (filters.for_proposals or [])
      #       do (filter) => 
      #         BUTTON 
      #           style: 
      #             backgroundColor: '#eee'
      #             color: '#666'
      #             padding: '4px 8px'
      #             borderRadius: 16
      #             fontSize: 16
      #             cursor: 'pointer'
      #             boxShadow: '0 1px 1px rgba(0,0,0,.2)'
      #             marginRight: 10
      #             border: 'none'

      #           onClick: -> 
      #             idx = filters.for_proposals.indexOf(filter)
      #             filters.for_proposals.splice idx, 1
      #             save filters

      #           filter
      #           SPAN 
      #             style: 
      #               color: '#aaa'
      #               fontSize: 10
      #               paddingLeft: 10
      #             'x'



opined_on = (proposal) -> 
  proposal.your_opinion?.published != false 

filter_options = [
  { 
    name: "All"
    description: "All proposals shown."    
    passes: (proposal) -> true
  }

  { 
    name: "Completed"
    description: "Only show proposals on which you've expressed an opinion."    
    passes: (proposal) -> opined_on(proposal)
  }
  { 
    name: "Incomplete"
    description: "Show proposals that you have not yet expressed an opinion about."    
    passes: (proposal) -> !opined_on(proposal)
  }  
]


FilterProposalsMenu = ReactiveComponent
  displayName: 'FilterProposalsMenu'
  render: -> 

    sort_and_filter_state = fetch 'sort_and_filter_proposals'
    sort_and_filter_state.filter ?= _.extend {}, filter_options[0]

    DIV 
      style: 
        position: 'relative'
        paddingLeft: 12
    

      DropMenu 
        className: 'default_drop bluedrop'    
        options: filter_options
        anchor_class_name: 'sort_proposals'

        open_menu_on: 'activation'

        selection_made_callback: (option) -> 
          invalidate_proposal_sorts()

          _.extend sort_and_filter_state.filter, option   
          save sort_and_filter_state 

        render_anchor: ->
          current_filter = translator "engage.filter.#{sort_and_filter_state.filter.name}", sort_and_filter_state.filter.name
          if current_filter.indexOf(':') > -1 
            current_filter = current_filter.split(':')[1]
          [
            TRANSLATE "engage.filter_by", "show"
            ": "

            SPAN 
              key: 'filter_name'
              style: 
                fontWeight: 700
                paddingLeft: 8

              current_filter

              SPAN style: _.extend cssTriangle 'bottom', 'white', 8, 5,
                display: 'inline-block'
                marginLeft: 4   
                marginBottom: 2
          ]

        render_option: (option, is_active) -> 
          [
            SPAN 
              key: 'option-name'
              "data-filter": option.name
              style: 
                # fontWeight: 600
                fontSize: 16
                marginBottom: 2

              translator "engage.filter.#{option.name}", option.name 

            if !browser.is_mobile
              SPAN 
                key: 'help icon'
                style: 
                  float: 'right'
                HelpIcon translator("engage.filter.#{option.name}.description", option.description),
                  color: 'black' #if is_active then 'white'
                
          ]





SortProposalsMenu = ReactiveComponent
  displayName: 'SortProposalsMenu'
  render: -> 

    sort = fetch 'sort_and_filter_proposals'
    set_default_sort() if !sort.name?       

    DIV 
      style: 
        position: 'relative'
      DropMenu 
        className: 'default_drop bluedrop'    
        options: sort_options

        open_menu_on: 'activation'

        selection_made_callback: (option) -> 
          invalidate_proposal_sorts()
          _.extend sort, option   
          save sort 

        render_anchor: ->
          current_sort = translator "engage.sort_order.#{sort.name}", sort.name
          if current_sort.indexOf(':') > -1 
            current_sort = current_sort.split(':')[1]
          [
            TRANSLATE "engage.sort_by", "sort"
            ": "

            SPAN 
              key: 'sort name'
              style: 
                fontWeight: 700
                paddingLeft: 8

              current_sort

              SPAN style: _.extend cssTriangle 'bottom', 'white', 8, 5,
                display: 'inline-block'
                marginLeft: 4   
                marginBottom: 2
          ]

        render_option: (option, is_active) -> 
          [
            SPAN 
              key: 'sort name'
              "data-sort": option.name
              style: 
                # fontWeight: 600
                fontSize: 16
                marginBottom: 2

              translator "engage.sort_order.#{option.name}", option.name 

            if !browser.is_mobile
              SPAN 
                key: 'help-icon'
                style: 
                  float: 'right'
                HelpIcon translator "engage.sort_order.#{option.name}.description", option.description
                

            # DIV 
            #   style: 
            #     fontSize: 12
            #     color: if is_active then 'white' else '#444'

            #   translator "engage.sort_order.#{option.name}.description", option.description 
          ]



ManualProposalResort = ReactiveComponent
  displayName: 'ManualProposalResort'

  render: -> 
    sort = fetch 'sort_and_filter_proposals'

    if !stale_sort_order(@props.sort_key) || ONE_COL()
      return SPAN null 

    if running_timelapse_simulation?
      invalidate_proposal_sorts()
      return SPAN null

    DIV
      style: 
        position: 'relative'

      SPAN 
        style: 
          color: '#888'
          fontSize: 10
          position: 'absolute'
          top: -16
          left: 9
          width: 175
        translator "engage.sort_order.out-of-order", "List is out of order"



      BUTTON 
        style: 
          color: 'white'
          fontWeight: 800
          backgroundColor: selected_color
          textAlign: 'center'
          fontSize: 12
          padding: '3px 16px'
          border: 'none'
          borderRadius: 8
          display: 'flex'
          alignItems: 'center'

        # 'data-tooltip': if !browser.is_mobile then translator "engage.sort_order.out-of-order-tooltip", "A re-sort may be needed because someone else added or updated their opinion, or you selected an opinion view that filtered or weighed opinions differently."

        onClick: invalidate_proposal_sorts

        SVG 
          width: 17
          height: 20
          viewBox: "0 0 17 20" 
          dangerouslySetInnerHTML: __html: """
                <g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
                    <g transform="translate(-318.000000, -564.000000)" fill="#FFFFFF" fill-rule="nonzero">
                        <g transform="translate(318.000000, 564.000000)">
                            <g transform="translate(0.000000, 0.000000)">
                                <path d="M8.25687555,19.6225181 C8.33853565,19.7047747 8.47091122,19.7047747 8.55257132,19.6225181 L11.3646601,16.7891261 C11.4244669,16.7288791 11.4423691,16.6382674 11.4100203,16.5595369 C11.3776715,16.4808064 11.301441,16.4294337 11.2168695,16.4294337 L5.59257699,16.4294337 C5.5079845,16.4294337 5.4317111,16.4807419 5.39933258,16.559483 C5.36695405,16.6382241 5.38484894,16.7288641 5.44467062,16.7891261 L8.25687555,19.6225181 Z" id="Path"></path>
                                <path d="M16.7908878,13.4735403 L0.209108553,13.4735403 C0.0936262631,13.4735437 3.72626523e-16,13.5678642 3.72626523e-16,13.6842191 L3.72626523e-16,14.7154119 C3.72626523e-16,14.8317733 0.0936197098,14.9261042 0.209108553,14.9261075 L16.7908878,14.9261075 C16.906378,14.9261062 17,14.8317748 17,14.7154119 L17,13.6842191 C17,13.5678628 16.9063715,13.4735416 16.7908878,13.4735403 L16.7908878,13.4735403 Z" id="Path"></path>
                                <path d="M16.7908878,10.5683891 L0.209108553,10.5683891 C0.0936197098,10.5683925 3.72626523e-16,10.6627233 3.72626523e-16,10.7790848 L3.72626523e-16,11.8102776 C3.72626523e-16,11.926639 0.0936197098,12.0209699 0.209108553,12.0209732 L16.7908878,12.0209732 C16.906378,12.0209719 17,11.9266405 17,11.8102776 L17,10.7790848 C17,10.6627219 16.906378,10.5683904 16.7908878,10.5683891 Z" id="Path"></path>
                                <path d="M16.7908878,9.11580508 C16.9063715,9.11580379 17,9.02148266 17,8.90512636 L17,7.87393354 C17,7.75757065 16.906378,7.66323921 16.7908878,7.66323792 L0.209108553,7.66323792 C0.0936197098,7.66324127 3.72626523e-16,7.7575721 3.72626523e-16,7.87393354 L3.72626523e-16,8.90512636 C3.72626523e-16,9.02148121 0.0936262631,9.11580173 0.209108553,9.11580508 L16.7908878,9.11580508 Z" id="Path"></path>
                                <path d="M16.7908878,4.75810362 L0.209108553,4.75810362 C0.0936197098,4.75810697 3.72626523e-16,4.8524378 3.72626523e-16,4.96879924 L3.72626523e-16,5.99997515 C3.72626523e-16,6.1163366 0.0936197098,6.21066743 0.209108553,6.21067077 L16.7908878,6.21067077 C16.906378,6.21066949 17,6.11633805 17,5.99997515 L17,4.96879924 C17,4.85243635 16.906378,4.75810491 16.7908878,4.75810362 L16.7908878,4.75810362 Z" id="Path"></path>
                                <path d="M8.25687555,0.0616930268 L5.44467146,2.89508497 C5.38486178,2.95534863 5.36697453,3.04598071 5.39935153,3.12471442 C5.43172853,3.20344812 5.50799272,3.25476054 5.59257783,3.25476054 L11.2168707,3.25476054 C11.3014348,3.25476054 11.3776561,3.20338365 11.4100034,3.12466053 C11.4423507,3.04593741 11.4244561,2.95533361 11.3646613,2.89508497 L8.55257249,0.0616930268 C8.47091226,-0.0205643423 8.33853578,-0.0205643423 8.25687555,0.0616930268 L8.25687555,0.0616930268 Z" id="Path"></path>
                            </g>
                        </g>
                    </g>
                </g>"""

        SPAN 
          style: 
            padding: "2px 0 2px 8px"
            whiteSpace: 'nowrap'

          translator "engage.sort_order.resort", 'Re-sort'



window.ProposalSort = ProposalSort
window.SortProposalsMenu = SortProposalsMenu
window.FilterProposalsMenu = FilterProposalsMenu
window.ManualProposalResort = ManualProposalResort
