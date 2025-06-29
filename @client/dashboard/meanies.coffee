
styles += """
.meanie-grid-table {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 1px;
  border: 1px solid #ccc;
  max-width: 800px;
  margin: 40px auto;
}

.meanie-header,
.meanie-cell {
  padding: 10px;
}

.meanie-header {
  font-weight: bold;
  background-color: #EEEEEE;
  border: 1px solid #ccc;
}

.meanie-cell {
  border: 1px solid #ccc;
  background-color: #fff;
}


"""

window.Meanies = ReactiveComponent
  displayName: 'Meanies'  

  mixins: [LoadScripts]
  js_dependencies: ['d3.v7.min.js', 'd3-force.js']
  
  
  componentDidMount: -> @loadScripts()
  componentDidUpdate: -> @loadScripts()

  render : -> 
    users = bus_fetch('/users').users
    visits = bus_fetch('/visits').visits
    opinions = bus_fetch('/opinions').opinions

    return ProposalsLoading() if !users || !visits  || !opinions


    @local.by_ip ?= true
    @local.close_in_time ?= false
    @local.single_opinion_only ?= false

    by_user = {}
    by_ip = {}
    for visit in visits
      if visit.user of arest.cache
        ip = if @local.by_ip then visit.ip else 'All IPs'
        by_ip[ip] ?= {}
        by_ip[ip][visit.user] = true
        by_user[visit.user] ?= {}
        by_user[visit.user][visit.ip] = 1

    opinions_by_user = {}
    for o in opinions 
      if by_user[o.user] && !arest.cache[o.user].verified && (!@local.by_ip || true || Object.keys(by_user[o.user]).length == 1)
        opinions_by_user[o.user] ?= {}
        opinions_by_user[o.user][o.proposal] = o.stance

    ip_clusters = {}
    for k,v of by_ip
      if Object.keys(v).length > 1

        ip_clusters[k] = {}
        for user, __ of v
          if opinions_by_user[user] && (!@local.single_opinion_only || Object.keys(opinions_by_user[user]).length == 1)
            ip_clusters[k][user] = opinions_by_user[user]
        if Object.keys(ip_clusters[k]).length < 2
          delete ip_clusters[k]





    high_matches = []

    SIMILARITY_THRESHOLD = 1 

    similarity_clusters = {}
    for ip, cluster of ip_clusters
      # cluster is an object mapping users to their opinions
      # we'll try to assess how "suspicious" a cluster is by 
      # how much their votes correlate. Two factors: 
      #   (1) the overlap in the proposals on which they opine
      #   (2) the degree to which their opinions are similar on 
      #       the proposals that they opine on
      similarity = jaccardSimilarity cluster, (a,b) -> Math.abs(a - b) < 0.025

      for user, similarities of similarity
        stripped = {}
        for other, sim of similarities
          if sim >= SIMILARITY_THRESHOLD && (!@local.close_in_time || Math.abs(new Date(arest.cache[other].created_at).getTime() - new Date(arest.cache[user].created_at).getTime()) < 1000 * 60 * 60 * 24)
            stripped[other] = sim
        if Object.keys(stripped).length > 0 
          similarity[user] = stripped
        else 
          delete similarity[user]

      if Object.keys(similarity).length > 0 
        similarity_clusters[ip] = similarity


    # for any particular similarity cluster, at this point there might be disconnected clusters. 
    # So lets make them into true clusters 
    true_clusters = []

    for ip, cluster of similarity_clusters
      visited = {}
      visit_node = (node, group) -> 
        return if node of visited
        group.push node
        visited[node] = true
        for similar_user, val of cluster[user]
          visit_node similar_user, group
        group

      for user, similar_users of cluster
        if !visited[user]
          true_clusters.push ["#{ip} ##{true_clusters.length}", visit_node(user, []), cluster]




    user_cells = [
      DIV 
        className: "meanie-header"
        "Name"
      DIV 
        className: "meanie-header"
        "Email"
      DIV 
        className: "meanie-header"
        "Registration Date"
      DIV 
        className: "meanie-header"
        "# Similar Accounts"
      DIV 
        className: "meanie-header"
        "Max Similarity"        
    ]


    DIV null, 
      LABEL null, 
        INPUT 
          type: 'checkbox'
          defaultChecked: @local.by_ip
          onChange: => @local.by_ip = !@local.by_ip; save @local

        "Group by IP Address prefix"

      LABEL null, 
        INPUT 
          type: 'checkbox'
          defaultChecked: @local.close_in_time
          onChange: => @local.close_in_time = !@local.close_in_time; save @local

        "Filter to accounts created within a day of each other"

      LABEL null, 
        INPUT 
          type: 'checkbox'
          defaultChecked: @local.single_opinion_only
          onChange: => @local.single_opinion_only = !@local.single_opinion_only; save @local

        "Filter to accounts that only added one opinion"



      for flagged_group in true_clusters
        [cluster_name, users, cluster] = flagged_group

        cells = user_cells
        for user in users            
          similarities = cluster[user] 

          user = bus_fetch(user)
          cells = cells.concat [
            DIV 
              className: "meanie-cell"
              user.name
            DIV 
              className: "meanie-cell"
              user.email
            DIV 
              className: "meanie-cell"
              user.created_at
            DIV 
              className: "meanie-cell"
              Object.keys(similarities).length
            DIV 
              className: "meanie-cell"
              Math.max.apply(null, (s for u,s of similarities))  
          ]

        console.log {cells, users}

        DIV 
          key: cluster_name
          H2 
            style: 
              marginTop: 32
              fontSize: 24
              textAlign: 'center'
            cluster_name

          DIV
            className: "meanie-grid-table" 
            key: ip


            cells








jaccardSimilarity = (votingData, voteComparisonCallback) ->
  calculateIntersection = (votes1, votes2) ->
    intersection = 0
    for proposal, vote1 of votes1
      if proposal of votes2
        intersection += 1 if voteComparisonCallback(vote1, votes2[proposal])
    intersection

  calculateUnion = (votes1, votes2) ->
    union = {}
    for proposal, _ of votes1
      union[proposal] = true
    for proposal, _ of votes2
      union[proposal] = true
    Object.keys(union).length

  similarities = {}
  for user1, votes1 of votingData
    similarities[user1] = {}
    for user2, votes2 of votingData
      if user1 != user2
        intersection = calculateIntersection(votes1, votes2)
        union = calculateUnion(votes1, votes2)
        similarities[user1][user2] = intersection / union
  similarities
