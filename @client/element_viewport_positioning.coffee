# jQuery replacement functions
#
# some functions derive from https://youmightnotneedjquery.com/ and 
# https://github.com/camsong/You-Dont-Need-jQuery

window.$$ = 

  add_delegated_listener: (el, eventName, selector, callback) ->

    el.addEventListener eventName, (e) ->
      target = e.target
      while target && target != el
        if target.matches selector
          callback.call target, e
          break
        target = target.parentNode
    , false

  closest: (el, selector) -> 
    if el.closest?
      el.closest(selector)
    else 
      matchesSelector = el.matches || el.webkitMatchesSelector || el.mozMatchesSelector || el.msMatchesSelector;
      current_el = el
      while (current_el)
        if matchesSelector.call(current_el, selector)
          return current_el
        else
          current_el = current_el.parentElement

      null

  height: (el) -> 
    # console.log "HEIGHT", Math.round(el.getBoundingClientRect().height), el.clientHeight, el.offsetHeight
    # Math.round el.getBoundingClientRect().height
    Math.round el.clientHeight

  width: (el) -> 
    Math.round el.getBoundingClientRect().width


  offset: (el) ->
    rect = el.getBoundingClientRect()

    top  = rect.top  + window.pageYOffset - document.documentElement.clientTop
    left = rect.left + window.pageXOffset - document.documentElement.clientLeft

    {top, left}


  offsetParent: (el) ->
    el.offsetParent or el

  scrollTop: (el) -> 
    el ?= document
    (el.documentElement && el.documentElement.scrollTop) || el.body.scrollTop

  # TODO: figure out how to handle parameters
  animate: (el, params, speed) -> 
    el.style.transition = 'all ' + speed
    
    for k,v of params
      el.style[k] = v


  ensureInView: (el, options = {}) ->
    if !el
      options.callback()
      return

    _.defaults options,
      fill_threshold: 0
      offset_buffer: 36
      scroll: true
      position: 'top' 
      speed: null
      callback: ->

    el_height = $$.height(el) + (options.extra_height or 0)

    el_top = $$.offset(el).top
    el_bottom = el_top + el_height

    doc_height = $$.height(document.body)
    doc_top = $$.scrollTop()

    doc_bottom = doc_top + doc_height
    is_onscreen = el_top > doc_top && el_bottom < doc_bottom

    #if less than 50% of the viewport is taken up by the el...
    bottom_inside = el_bottom < doc_bottom && (el_bottom - doc_top) > options.fill_threshold * el_height
    top_inside = el_top > doc_top && (doc_bottom - el_top) > options.fill_threshold * el_height    
    no_adjustment_needed = !options.force && is_onscreen && top_inside && bottom_inside  

    if !no_adjustment_needed
      if options.position != 'top'
        console.error "ensureInView doesn't support position targets except 'top'"

      if options.scroll

        distance_to_travel = options.speed || Math.abs( doc_top - (el_top - options.offset_buffer) )

        $$.smoothScrollToTarget 
          el: el
          offset_buffer: options.offset_buffer
          duration: Math.min(distance_to_travel, 1500)
          callback: options.callback

      else 
        window.scrollTo 0, target
        options.callback()
    else
      options.callback()

  ensure_in_viewport_when_appears: (selector) -> 
    viewport_ensurer = setInterval ->
      el = document.querySelector selector
      if el 
        $$.ensureInView el, {scroll: true}
        clearInterval viewport_ensurer
    , 10


  smoothScrollToTarget: ({duration, callback, el, offset_buffer}) ->
    target = $$.offset(el).top - offset_buffer

    diff = target - window.pageYOffset
    frames = 60 * duration / 1000
    dist_per_frame = diff / frames

    iter = (current_time) ->

      top = el.getBoundingClientRect().top
      if diff < 0 
        done = top + dist_per_frame > offset_buffer
      else 
        done = top - dist_per_frame < offset_buffer

      if done 
        dist_per_frame = top - offset_buffer

      scroll_to = window.pageYOffset + dist_per_frame

      window.scrollTo 0, scroll_to

      if !done
        requestAnimationFrame(iter)
      else 
        callback?()

    requestAnimationFrame(iter)


  moveToTop: (el, options = {}) ->
    _.defaults options, 
      offset_buffer: 50

    el_top = $$.offset(el).top
    el_bottom = 
    target = el_top - options.offset_buffer

    window.scrollTo 0, target


  setStyles: (selector, styles) ->
    els = document.querySelectorAll selector

    for el in els 
      for k,v of styles
        if k.indexOf('-') > -1
          el.style.setProperty k, v
        else 
          el.style[k] = v



