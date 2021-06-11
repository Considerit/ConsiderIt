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



window.invalidate_proposal_sorts = -> 
  sort = fetch 'sort_proposals'
  for k,v of sort.sorts 
    v.force_resort = true 
  save sort 

window.sorted_proposals = (proposals, sort_key, require_force) ->

  sort = fetch 'sort_proposals'
  set_sort() if !sort.name? 

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

  comp = sort.comp
  proposals = proposals.sort comp

  if require_force
    # when dragging a slider on a list of proposals, we may want to 
    # return the old sort order even if it isn't technically correct.
    # This is because it is too annoying to have the proposals list
    # jumping around all the time.  

    sort.sorts ||= {}

    keys = (p.key for p in (proposals or []))
    order = md5 keys

    cached_order = null
    if sort_key of sort.sorts
      cached_order = md5 sort.sorts[sort_key].cache
    else 
      cached_order = null 
      sort.sorts[sort_key] = {cache: [], stale: true, force_resort: true}

    # alright, same order
    if cached_order == order 
      if sort.sorts[sort_key].force_resort
        sort.sorts[sort_key].force_resort = false 
        sort.sorts[sort_key].stale = false 
        save sort

    # force an update to the sort order, either because its stale, bc we're initializing, or 
    # because a new proposal has been added or removed
    else if sort.sorts[sort_key].force_resort || proposals.length != sort.sorts[sort_key].cache.length
      sort.sorts[sort_key].force_resort = false
      sort.sorts[sort_key].stale = false
      sort.sorts[sort_key].cache = (p.key for p in proposals)
      save sort

    # return the stale sort order
    else 
      if !sort.sorts[sort_key].stale
        sort.sorts[sort_key].stale = true 
        save sort 
      dict_proposals = {}
      for p in proposals 
        dict_proposals[p.key] = p 
      proposals = (dict_proposals[k] for k in sort.sorts[sort_key].cache)

  proposals



basic_proposal_scoring = (proposal, opinion_value) -> 
  if !opinion_value
    opinion_value = (o) -> o.stance

  opinions = fetch(proposal).opinions    
  if !opinions || opinions.length == 0
    return {sum: 0, avg: 0, std_dev: 0, opinions: []}

  filtered_out = fetch 'filtered'
  if filtered_out.users
    opinions = (o for o in opinions when !(filtered_out.users?[o.user]))

  sum = 0
  for opinion in opinions
    sum += opinion_value(opinion)

  avg = sum / opinions.length

  differences = 0
  for o in opinions 
    differences += (o.stance - avg) * (o.stance - avg)

  std_dev = Math.sqrt(differences / opinions.length)
  {sum, avg, std_dev, opinions}



rnd_order = {}

sort_options = [

  { 
    comp: (a, b) -> basic_proposal_scoring(b, ((o) -> o.stance)).avg - basic_proposal_scoring(a, ((o) -> o.stance)).avg
    name: 'Average Score'
    description: "Each response is scored by the average opinion score, where opinions are on [-1, 1]."
  }, { 
    comp: (a, b) -> basic_proposal_scoring(b, ((o) -> o.stance)).sum - basic_proposal_scoring(a, ((o) -> o.stance)).sum
    name: 'Total Score'
    description: "Each response is scored by the sum of opinions, where opinions are on [-1, 1]."
  }, {
    name: 'Trending'
    description: "'Total Score', except that newer opinions and responses are weighed more heavily."

    comp: (a, b) ->
      ov = (o) -> 
        ot = new Date(o.updated_at).getTime()
        n = Date.now()
        o.stance / (1 + Math.pow((n - ot) / 100000, 2))

      val = (proposal) -> 
        sum = basic_proposal_scoring(proposal, ov).sum
        n = Date.now()
        pt = new Date(proposal.created_at).getTime()
        sum / (1 + (n - pt) / 10000000000)  # decrease this constant to favor newer proposals

      val(b) - val(a)
  },
  { 
    name: 'Alphabetically'
    comp: (a, b) -> a.name.localeCompare b.name
    description: "Sort alphabetically by the response's title"
  }, {
    comp: (a,b) -> new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    name: 'Newest'
    description: "The responses submitted most recently are shown first."
  }, {
    comp: (a,b) -> new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    name: 'Earliest'
    description: "The responses submitted first are shown first."
  }, { 
    name: 'Unity'
    description: "Responses where the community is most united for or against are shown highest."
    comp: (a,b) -> 
      ov = (o) -> o.stance
      val = (proposal) ->
        stats = basic_proposal_scoring(proposal, ov)
        if stats.opinions.length > 1
          Math.log(stats.opinions.length + 1) / stats.std_dev / (1 - Math.abs(stats.avg) + 1)
        else 
          -1
      val(b) - val(a)

  }, { 
    name: 'Difference'
    description: "Responses where the community is most split are shown highest."
    comp: (a,b) -> 

      ov = (o) -> o.stance
      val = (proposal) ->
        stats = basic_proposal_scoring(proposal, ov)
        if stats.opinions.length > 1
          stats.std_dev * Math.log(stats.opinions.length + 1) 
        else
          -1
      val(b) - val(a)

  }, {
    name: 'Most Activity'
    description: "Ranked by number of opinions and discussion."

    comp: (a,b) ->
      ov = (o) -> 1 + (o.point_inclusions or []).length
      basic_proposal_scoring(b, ov).sum - basic_proposal_scoring(a, ov).sum

  }, {
    name: 'Random'
    description: "Order will be randomized on every page load."

    comp: (a,b) ->
      rnd_order[a.key] ||= Math.round(Math.random() * 99999) + 1
      rnd_order[b.key] ||= Math.round(Math.random() * 99999) + 1
      rnd_order[a.key] - rnd_order[b.key]
  }


]

set_sort = -> 
  sort = fetch 'sort_proposals'
  if !sort.name?
    found = false 
    loc = fetch('location')
    if loc.query_params?.sort_by
      for s in sort_options
        if s.name == loc.query_params.sort_by.replace('_', ' ')
          _.extend sort, s or sort_options[2]
          found = true 
          break

    if !found
      if def_sort = customization('homepage_default_sort_order')
        def = null 
        for s in sort_options
          if s.name == def_sort
            def = s
            break 
        _.extend sort, def or sort_options[2]

      else 
        _.extend sort, sort_options[2]

    save sort 





ProposalSort = ReactiveComponent
  displayName: 'ProposalSort'

  render : -> 

    proposals = fetch '/proposals' # registering dependency so that we get re-rendered...ApplyFilters is actually dependent
    # filter_out = fetch 'filtered'
    # filters = fetch 'filters'

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
      #       n = @refs.new_filter.getDOMNode()
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



SortProposalsMenu = ReactiveComponent
  displayName: 'SortProposalsMenu'
  render: -> 

    sort = fetch 'sort_proposals'
    set_sort() if !sort.name? 

    SPAN
      style: 
        color: 'black'
        # fontSize: 20

      TRANSLATE "engage.sort_by", "sort by"

      " "

      DropMenu
        options: sort_options

        open_menu_on: 'activation'

        selection_made_callback: (option) -> 
          invalidate_proposal_sorts()
          _.extend sort, option   
          save sort 

        render_anchor: ->
          SPAN 
            style: 
              fontWeight: 700

            translator "engage.sort_order.#{sort.name}", sort.name

            SPAN style: _.extend cssTriangle 'bottom', focus_color(), 8, 5,
              display: 'inline-block'
              marginLeft: 4   
              marginBottom: 2

        render_option: (option, is_active) -> 
          [        
            DIV 
              style: 
                fontWeight: 600
                fontSize: 18

              translator "engage.sort_order.#{option.name}", option.name 

            DIV 
              style: 
                fontSize: 12
                color: if is_active then 'white' else 'black'

              translator "engage.sort_order.#{option.name}.description", option.description 
          ]

        wrapper_style: 
          display: 'inline-block'

        anchor_style: 
          fontWeight: 600
          padding: 0
          display: 'inline-block'
          color: focus_color() #'inherit'
          textTransform: 'lowercase'
          borderRadius: 16

        menu_style: 
          minWidth: 500
          backgroundColor: '#eee'
          border: "1px solid #{focus_color()}"
          left: -9999
          top: 18
          borderRadius: 8
          fontWeight: 400
          overflow: 'hidden'
          boxShadow: '0 1px 2px rgba(0,0,0,.3)'

        menu_when_open_style: 
          left: 0

        option_style: 
          padding: '6px 12px'
          borderBottom: "1px solid #ddd"
          display: 'block'

        active_option_style: 
          color: 'white'
          backgroundColor: focus_color()






window.ProposalSort = ProposalSort
window.SortProposalsMenu = SortProposalsMenu
