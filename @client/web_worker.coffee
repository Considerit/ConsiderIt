require './histogram_layout'

addEventListener 'message', (ev) ->
  msg = ev.data

  if msg.task == 'layoutAvatars' 
    DedicatedWorkerGlobalScope.enqueue_histo_layout msg

