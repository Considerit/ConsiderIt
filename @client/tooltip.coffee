# TODO: document and generalize

require './shared'

window.Tooltip = ReactiveComponent
  displayName: 'Tooltip'

  render : -> 
    tooltip = fetch('tooltip')
    return SPAN(null) if !tooltip.coords

    coords = tooltip.coords
    tip = tooltip.tip

    style = 
        fontSize: 16
        padding: '2px 4px'
        borderRadius: 8
        #whiteSpace: 'nowrap'
        maxWidth: 200

    real_height = heightWhenRendered tip, style

    # place the tooltip above the element
    _.extend style, 
        top: coords.top - real_height - 9
        left: coords.left
        pointerEvents: 'none'
        zIndex: 9999
        color: 'white'
        backgroundColor: focus_blue
        position: 'absolute'

    DIV
      style: style
      tip