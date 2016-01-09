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
      #maxWidth: 200

    size = sizeWhenRendered(tip, style)

    # place the tooltip above the element
    _.extend style, 
      top: coords.top - size.height - 9
      left: coords.left - size.width / 2
      pointerEvents: 'none'
      zIndex: 9999
      color: '#999'
      backgroundColor: '#f6f6f6'
      position: 'absolute'

    DIV
      style: style
      dangerouslySetInnerHTML: {__html: tip}

