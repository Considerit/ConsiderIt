require './shared'


styles += """

#tooltip .downward_arrow {
  width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;  
  border-top: 10px solid black;
}
#tooltip .upward_arrow {
  width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;  
  border-bottom: 10px solid black;
}

"""

window.clearTooltip = ->
  tooltip = fetch('tooltip')
  tooltip.coords = tooltip.tip = tooltip.render = tooltip.top = tooltip.positioned = null
  tooltip.offsetY = tooltip.offsetX = null 
  tooltip.rendered_size = false 
  save tooltip


window.Tooltip = ReactiveComponent
  displayName: 'Tooltip'

  render : -> 


    tooltip = fetch('tooltip')
    return SPAN(null) if !tooltip.coords

    coords = tooltip.coords
    tip = tooltip.tip

    style = _.defaults {}, (@props.style or {}), 
      fontSize: 14
      padding: '4px 8px'
      borderRadius: 8
      pointerEvents: 'none'
      zIndex: 9999
      color: 'white'
      backgroundColor: 'black'
      position: 'absolute'      
      boxShadow: '0 1px 1px rgba(0,0,0,.2)'
      maxWidth: 350



    if tooltip.top || !tooltip.top?
      # place the tooltip above the element
      _.extend style, 
        top: coords.top + (tooltip.offsetY or 0) - (tooltip.rendered_size?.height or 0) - 12
        left: if !tooltip.rendered_size then -99999 else coords.left + (tooltip.offsetX or 0) - tooltip.rendered_size?.width / 2
    else 
      # place the tooltip below the element
      _.extend style, 
        top: coords.top + (tooltip.offsetY or 0)
        left: if !tooltip.rendered_size then -99999 else coords.left + (tooltip.offsetX or 0) - (tooltip.rendered_size.width or 0)

    DIV
      id: 'tooltip'
      role: "tooltip"
      style: style


      if tooltip.render 
        tooltip.render()
      else 
        DIV 
          dangerouslySetInnerHTML: {__html: tip}

      if tooltip.top || !tooltip.top?
        SPAN 
          className: 'downward_arrow'
          style: 
            position: 'absolute'
            bottom: -7
            left: if tooltip.positioned != 'right' then "calc(50% - 10px)" 
            right: if tooltip.positioned == 'right' then 7

      else   
        SPAN 
          className: 'upward_arrow'
          style: 
            position: 'absolute'
            left: if tooltip.positioned != 'right' then "calc(50% - 10px)" 
            top: -7
            right: if tooltip.positioned == 'right' then 7

  componentDidUpdate: ->
    tooltip = fetch('tooltip')
    if !tooltip.rendered_size && tooltip.coords 

      tooltip.rendered_size = 
        width: @getDOMNode().offsetWidth
        height: @getDOMNode().offsetHeight
      save tooltip

