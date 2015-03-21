# TODO: document and generalize

window.Tooltip = ReactiveComponent
  displayName: 'Tooltip'

  render : -> 
    tooltip = fetch('tooltip')
    return SPAN(null) if !tooltip.coords

    coords = tooltip.coords
    tip = tooltip.tip

    # place the tooltip above the element
    DIV
      style: 
        position: 'absolute'
        top: coords.top - 20
        left: coords.left
        fontSize: 16
        color: 'black'
        backgroundColor: 'white'
        padding: '0 4px'
        borderRadius: 8
        zIndex: 9999
        whiteSpace: 'nowrap'
        pointerEvents: 'none'
      tip