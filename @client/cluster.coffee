
class CosineSimilarityAccumulator
  constructor: ->
    @sumSq1 = 0
    @sumSq2 = 0
    @sumProducts = 0

  increment: ( value1, value2 ) ->
    value1 ?= 0
    value2 ?= 0
    @sumSq1 += (value1 * value1)
    @sumSq2 += (value2 * value2)
    @sumProducts += (value1 * value2)

  current: ->
    if ((0 < @sumSq1) and (0 < @sumSq2))  then @sumProducts / Math.sqrt( @sumSq1 * @sumSq2 )  else 0


# Use cosine-similarity because it is scale-invariant, but still anchored around zero.
# Covariance is translation-invariant, not anchored.  Euclidean-distance is scale sensitive.
cosineSimilarity = ( nameToNumber1, nameToNumber2 ) ->
  similarity = new CosineSimilarityAccumulator()
  # For each feature that exists in nameToNumber1... increment similarity
  for name,value1 of nameToNumber1
    value2 = nameToNumber2[ name ] ?  0
    similarity.increment( value1, value2 )
  # For each feature that exists only in nameToNumber2... increment similarity
  for name,value2 of nameToNumber2
    if name not of nameToNumber1
      similarity.increment( 0, value2 )
  similarity.current()


weightedAverage = ( nameToNumber1, weight1, nameToNumber2, weight2 ) ->
  nameToAverage = { }  # map[ name -> weighted average of feature ]
  sumWeights = weight1 + weight2
  if sumWeights == 0
    return nameToAverage
  # For each feature that exists in nameToNumber1... set average
  for name,value1 of nameToNumber1
    value2 = nameToNumber2[ name ] ?  0
    nameToAverage[ name ] = if (sumWeights == 0)  then 0  else ( (value1 * weight1) + (value2 * weight2) ) / sumWeights
  # For each feature that exists only in nameToNumber2... set average
  for name,value2 of nameToNumber2
    if name not of nameToNumber1
      nameToAverage[ name ] = if (sumWeights == 0)  then 0  else (value2 * weight2) / sumWeights
  nameToAverage


# Automatically cluster users based on similarity of their opinions across all opinions
cluster = ( clusters ) ->
  # Halt based on minimum-cluster-coverage and minimum-similarity.  Enforce maximum-number-of-groups.
  MIN_CLUSTERED_USERS_FRAC = 0.50
  MAX_GROUP_USERS_FRAC = 0.30
  MIN_SIMILARITY = 0.50
  MAX_CLUSTERS = 5
  MAX_LOOPS = Math.floor( clusters.length * MIN_CLUSTERED_USERS_FRAC )
  # Cluster bottom-up, merging the most similar pair of users/clusters
  numUsers = clusters.length
  loopNum = 0
  # Loop until users condense to a few dense clusters, and some leftover unclustered users...
  while true
    ++loopNum
    if MAX_LOOPS < loopNum
      break

    # Enforce halting before finding candidate merge
    numUsersUnclustered = clusters.filter( (c) -> (c.userIds.length == 1) ).length
    numClusters = clusters.length - numUsersUnclustered
    clusteredUsersFrac = ( numUsers - numUsersUnclustered ) / numUsers
    suffientClusteringDone = (numClusters <= MAX_CLUSTERS) and (MIN_CLUSTERED_USERS_FRAC <= clusteredUsersFrac)

    # Find most similar cluster pair
    maxSimilarity = Number.NEGATIVE_INFINITY
    maxSimilarityPair = null
    # For each unique pair of cluster1 x cluster2...
    for cluster1, index1 in clusters
      for index2 in [ index1+1 ... clusters.length ]
        cluster2 = clusters[ index2 ]
        similarity = cosineSimilarity( cluster1.center, cluster2.center )
        groupFrac = ( cluster1.userIds.length + cluster2.userIds.length ) / numUsers
        if ( maxSimilarity < similarity ) and ( groupFrac < MAX_GROUP_USERS_FRAC )
          maxSimilarity = similarity
          maxSimilarityPair = [ cluster1, cluster2 ]

    # Merge most similar cluster pair
    if not maxSimilarityPair  then break
    newCluster = { 
      userIds: maxSimilarityPair[0].userIds.concat( maxSimilarityPair[1].userIds ) 
      center: weightedAverage( maxSimilarityPair[0].center, maxSimilarityPair[0].userIds.length, maxSimilarityPair[1].center, maxSimilarityPair[1].userIds.length )
    }

    # Replace most similar pair with new cluster
    newClusters = clusters.filter( (i) -> (i != maxSimilarityPair[0]) and (i != maxSimilarityPair[1]) )
    newClusters.push( newCluster )

    # Enforce halting conditions on new candidate clusters
    if suffientClusteringDone and (maxSimilarity < MIN_SIMILARITY)
      break

    # Update clusters
    clusters = newClusters

  clusters



DedicatedWorkerGlobalScope.clusterAndMap = ( userXProposalToOpinion ) ->
  # Put all users into separate clusters
  initialClusters = [ ]
  for user, userProposalToOpinion of userXProposalToOpinion
    initialClusters.push(  { userIds:[user], center:userProposalToOpinion }  )

  # Group users
  clusters = cluster( initialClusters )

  # Collect map[ userId -> clusterId ]
  userIdToClusterId = { }
  for cluster, clusterIndex in clusters
    for userId, userIndex in cluster.userIds
      clusterId = if ( cluster.userIds.length == 1 )  then 'None'  else String( clusterIndex )
      userIdToClusterId[ userId ] = clusterId

  userIdToClusterId


