require './shared'


styles += """

#tooltip .downward_arrow {
  width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;  
  border-top: 10px solid #{brd_dark};
}
#tooltip .upward_arrow {
  width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;  
  border-bottom: 10px solid #{brd_dark};
}

"""

TOOLTIP_DELAY = 500
window.clear_tooltip = ->
  tooltip = bus_fetch('tooltip')
  tooltip.coords = tooltip.tip = tooltip.top = tooltip.positioned = null
  tooltip.offsetY = tooltip.offsetX = null 
  tooltip.rendered_size = false 
  save tooltip

toggle_tooltip = (e) ->
  tooltip_el = $$.closest(e.target, '[data-tooltip]')
  if tooltip_el?
    tooltip = bus_fetch('tooltip')
    if tooltip.coords
      clear_tooltip()
    else 
      show_tooltip(e)

show_tooltip = (e) ->

  tooltip_el = $$.closest(e.target, '[data-tooltip]')
  return if !tooltip_el? || tooltip_el.style.opacity == 0

  tooltip = bus_fetch 'tooltip'
  name = tooltip_el.getAttribute('data-tooltip')
  if tooltip.tip != name 
    tooltip.tip = name

    setTimeout ->
      if tooltip.tip == name 
        tooltip.coords = calc_coords_for_tooltip_or_popover(tooltip_el)
        save tooltip
    , TOOLTIP_DELAY

    e.preventDefault()
    e.stopPropagation()

tooltip = bus_fetch 'tooltip'
hide_tooltip = (e) ->
  if e.target.getAttribute('data-tooltip')
    clear_tooltip()
    e.preventDefault()
    e.stopPropagation()

document.addEventListener "click", toggle_tooltip

document.body.addEventListener "mouseover", show_tooltip, true
document.body.addEventListener "mouseleave", hide_tooltip, true

$$.add_delegated_listener document.body, 'focusin', '[data-tooltip]', show_tooltip
$$.add_delegated_listener document.body, 'focusout', '[data-tooltip]', hide_tooltip


window.Tooltip = ReactiveComponent
  displayName: 'Tooltip'

  render : -> 


    tooltip = bus_fetch('tooltip')
    return SPAN(null) if !tooltip.coords

    coords = tooltip.coords
    tip = tooltip.tip

    arrow_size = 
      height: 7
      width: 14

    {top, left, arrow_up, arrow_adjustment} = get_tooltip_or_popover_position({tooltip, arrow_size})

    style = _.defaults {top, left}, (@props.style or {}), 
      fontSize: 14
      padding: '4px 8px'
      borderRadius: 8
      pointerEvents: 'none'
      zIndex: 999999999999
      color: text_light
      backgroundColor: bg_dark
      position: 'absolute'      
      boxShadow: '0 1px 1px #{shadow_dark_20}'
      maxWidth: 350

    DIV
      id: 'tooltip'
      role: "tooltip"
      style: style


      DIV 
        dangerouslySetInnerHTML: {__html: tip}


      SVG 
        width: arrow_size.width
        height: arrow_size.height 
        viewBox: "0 0 531.74 460.5"
        preserveAspectRatio: "none"
        style: 
          position: 'absolute'
          bottom: if arrow_up then -arrow_size.height
          top: if !arrow_up then -arrow_size.height
          left: if tooltip.positioned != 'right' then "calc(50% - #{arrow_size.width / 2 + arrow_adjustment}px)" 
          right: if tooltip.positioned == 'right' then 7       
          transform: if !arrow_up then 'scale(1,-1)' 
          display: if tooltip.hide_triangle then 'none' 

        POLYGON
          stroke: brd_dark
          fill: bg_dark
          points: "530.874,0.5 265.87,459.5 0.866,0.5"


  componentDidUpdate: ->
    tooltip = bus_fetch('tooltip')
    if !tooltip.rendered_size && tooltip.coords 

      tooltip.rendered_size = 
        width: ReactDOM.findDOMNode(@).offsetWidth
        height: ReactDOM.findDOMNode(@).offsetHeight
      save tooltip

