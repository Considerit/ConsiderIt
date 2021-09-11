
RATE_LIMIT = 100
update_scheduled = false 


is_el_visible = (el, scrollY, innerHeight, slop) ->
  slop ?= 1
  slop -= 1
  el_top = -scrollY
  h = innerHeight

  parent = el 
  while (true)
    el_top += parent.offsetTop
    if !parent.offsetParent
      break
    parent = parent.offsetParent

  el_bottom = el_top + h 

  topVisible =    -slop * h < el_top && el_top < h * 2 * slop
  bottomVisible = -slop * h < el_bottom && el_bottom < h * 2 * slop    
  visible = topVisible || bottomVisible

  visible


sense_viewport_visibility_changes = ->
  els = document.querySelectorAll '[data-receive-viewport-visibility-updates]'

  if els.length > 0
    scrollY = window.scrollY 
    innerHeight = window.innerHeight 

    # if performance tuning, this could be improved by doing a binary search in els 
    # (assuming sorted by offsetY) to find the visible elements more efficiently
    for el in els 
      slop = parseInt(el.getAttribute('data-receive-viewport-visibility-updates') or 1)
      visible = is_el_visible el, scrollY, innerHeight, slop

      state = fetch el.getAttribute 'data-component'
      if !state.in_viewport? || state.in_viewport != visible 
        state.in_viewport = visible 
        save state

  update_scheduled = false



window.schedule_viewport_position_check = ->
  if !update_scheduled
    update_scheduled = true 
    to_timer = setTimeout ->
      requestAnimationFrame sense_viewport_visibility_changes
      clearTimeout to_timer
    , RATE_LIMIT


document.addEventListener "visibilitychange", schedule_viewport_position_check
document.addEventListener "scroll", schedule_viewport_position_check
window.addEventListener "resize", schedule_viewport_position_check
