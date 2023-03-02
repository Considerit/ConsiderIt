

window.IframeEmbedding = ReactiveComponent
  displayName: 'IframeEmbedding'

  render: -> 
    loc = fetch 'location'
    SPAN null


  componentDidMount: -> @embed()
  componentDidUpdate: -> @embed()

  embed: -> 
    @listen()
    @post()

  post: -> 
    loc = fetch 'location'
    if loc.url != @local.url    
      parent.postMessage("iframe location changed to #{loc.url}", '*')
      @local.url = loc.url

  listen: -> 
    cb = (event) =>
      # return if event.source != openidpopup
      console.log "Got message from parent", event.data
      # parent?.postMessage("right back at ya from considerit", '*')

    window.addEventListener "message", cb, false
