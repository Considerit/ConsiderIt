require './histogram_layout'
require './cluster'


addEventListener 'message', (ev) ->
  msg = ev.data

  if msg.task == 'layoutAvatars' 
    DedicatedWorkerGlobalScope.enqueue_histo_layout msg

  else if msg.task == 'cluster'
    userIdToClusterId = DedicatedWorkerGlobalScope.clusterAndMap( msg.userXProposalToOpinion )
    postMessage( {result:'clustered', userIdToClusterId:userIdToClusterId} )

