# TODO: document and generalize

require './shared'

window.Tooltip = ReactiveComponent
  displayName: 'Tooltip'

  render : -> 


    tooltip = fetch('tooltip')
    return SPAN(null) if !tooltip.coords

    coords = tooltip.coords
    tip = tooltip.tip

    style = _.defaults {}, (@props.style or {}), 
      fontSize: 16
      padding: '4px 8px'
      borderRadius: 8
      pointerEvents: 'none'
      zIndex: 9999
      color: '#777'
      backgroundColor: '#f6f6f6'
      position: 'absolute'      
      boxShadow: '0 1px 1px rgba(0,0,0,.2)'
      borderBottom: '1px solid #eee'
      #maxWidth: 200

    size = sizeWhenRendered(tip, style)

    # place the tooltip above the element
    _.extend style, 
      top: coords.top - size.height - 9
      left: coords.left - size.width / 2

    DIV
      id: 'tooltip'
      role: "tooltip"
      style: style
      dangerouslySetInnerHTML: {__html: tip}

