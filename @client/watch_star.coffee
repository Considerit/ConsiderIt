require './tooltip'


window.WatchStar = ReactiveComponent
  displayName: 'WatchStar'

  render : -> 
    current_user = fetch('/current_user')
    proposal = @props.proposal 
    size = @props.size || 30
    icon = @props.icon || 'fa-star'
    watch_color = @props.watch_color || logo_red

    label = @props.label || (watching) -> 
      if watching     
        "Stop getting notifications" 
      else 
        "Get notifications about this topic"

    watching = current_user.subscriptions[proposal.key] == 'watched'

    style = 
      opacity: if @local.hover_watch != proposal.key && !watching then .35
      color: if watching then watch_color else "#888"
      width: size 
      height: size
      cursor: 'pointer'

    I 
      className: "fa #{if watching then icon else "#{icon}-o"}"
      style: _.extend {}, style, (@props.style || {})

      onMouseEnter: => 
        @local.hover_watch = proposal.key; save @local

        tooltip = fetch 'tooltip'
        tooltip.coords = $(@getDOMNode()).offset()
        tooltip.tip = label(watching)
        save tooltip

      onMouseLeave: => 
        @local.hover_watch = null; save @local
        tooltip = fetch 'tooltip'
        tooltip.coords = null
        save tooltip

      onClick: => 
        if !current_user.subscriptions[proposal.key]
          current_user.subscriptions[proposal.key] = 'watched'
        else 
          delete current_user.subscriptions[proposal.key]

        save current_user
