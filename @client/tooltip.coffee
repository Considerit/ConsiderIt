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
        padding: '0 4px'
        borderRadius: 8
        whiteSpace: 'nowrap'

    real_height = heightWhenRendered tip, style

    _.extend style, 
        top: coords.top - real_height - 5
        pointerEvents: 'none'
        zIndex: 9999
        color: 'black'
        backgroundColor: 'white'
        position: 'absolute'
        left: coords.left

    # place the tooltip above the element
    DIV
      style: style
      tip