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
        "Get notifications"

    watching = current_user.subscriptions[proposal.key] == 'watched'

    style = 
      opacity: if @local.hover_watch != proposal.key && !watching then .35
      color: if watching then watch_color else "#888"
      width: size 
      height: size
      cursor: 'pointer'
      backgroundColor: 'transparent'
      border: 'none'
      margin: 0
      padding: 0

    show_tooltip =  => 
      @local.hover_watch = proposal.key; save @local
      tooltip = fetch 'tooltip'
      tooltip.coords = $(@getDOMNode()).offset()
      tooltip.tip = label(watching)
      save tooltip

    hide_tooltip = => 
      @local.hover_watch = null; save @local
      tooltip = fetch 'tooltip'
      tooltip.coords = null
      save tooltip


    BUTTON 
      'aria-label': label(watching)
      'aria-describedby': 'tooltip'
      'aria-pressed': watching

      className: "fa #{if watching then icon else "#{icon}-o"}"
      style: _.extend {}, style, (@props.style || {})

      onMouseEnter: show_tooltip
      onFocus: show_tooltip
      onMouseLeave: hide_tooltip
      onBlur: hide_tooltip

      onClick: => 
        if !current_user.subscriptions[proposal.key]
          current_user.subscriptions[proposal.key] = 'watched'
        else 
          delete current_user.subscriptions[proposal.key]

        save current_user
