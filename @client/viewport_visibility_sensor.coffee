
RATE_LIMIT = 100
update_scheduled = false 


window.is_el_visible = (el, scrollY, viewport_height, slop) ->
  slop ?= 1
  slop -= 1
  el_top = -scrollY
  vh = viewport_height

  parent = el 
  while (true)
    el_top += parent.offsetTop
    if !parent.offsetParent
      break
    parent = parent.offsetParent

  el_bottom = el_top + vh 

  topVisible =    el_top    > -slop * vh  &&  el_top    < vh + slop * vh
  bottomVisible = el_bottom > -slop * vh  &&  el_bottom < vh + slop * vh

  visible = topVisible || bottomVisible

  visible



sense_viewport_visibility_changes = ->
  els = document.querySelectorAll '[data-receive-viewport-visibility-updates]'

  if els.length > 0
    scrollY = window.scrollY 
    innerHeight = window.innerHeight 

    el_sets = {}
    for el in els
      slop = parseFloat(el.getAttribute('data-receive-viewport-visibility-updates') or 1)
      name = el.getAttribute 'data-visibility-name'
      key = "#{name}-#{slop}"

      el_sets[key] ?= []
      el_sets[key].push el


    # Use previous visibility values to find one visible element, then figure out which elements 
    # around it are also visible. We assume that the elements are sorted by global 
    # offset Y here. This is usually true, but we can get in trouble. Set 
    # data-visibility-name if there's a problem with the assumption. 
    for __, els of el_sets
      visibility = {}
      # slop will be same for all elements in this set
      slop = parseFloat(els[0].getAttribute('data-receive-viewport-visibility-updates') or 1)
      len = els.length
      start_here = Math.floor(len / 2)
      found_visible = false
      for el, idx in els 
        state = fetch el.getAttribute 'data-component'
        if state.in_viewport
          visibility[idx] = is_el_visible els[idx], scrollY, innerHeight, slop
          if visibility[idx]
            start_here = idx
            found_visible = true
           

      # look for visible elements around this element
      for step in [1,-1]
        inc = start_here

        while inc >= 0 && inc < len
          visibility[inc] ?= is_el_visible els[inc], scrollY, innerHeight, slop
          if !visibility[inc] && found_visible
            break
          inc += step

      # set visibility of elements
      for el, idx in els 
        visible = !!visibility[idx]
        state = fetch el.getAttribute 'data-component'
        el.setAttribute 'data-in-viewport', visible
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
