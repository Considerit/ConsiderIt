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
    Math.round el.getBoundingClientRect().height

  width: (el) -> 
    Math.round el.getBoundingClientRect().width


  offset: (el) ->
    rect = el.getBoundingClientRect()

    top = rect.top + window.pageYOffset - document.documentElement.clientTop
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

    _.defaults options,
      fill_threshold: 0
      offset_buffer: 50
      scroll: true
      position: 'top' 
      speed: null
      callback: ->

    el_height = $$.height(el)

    el_top = $$.offset(el).top
    el_bottom = el_top + el_height

    doc_height = $$.height(document.body)
    doc_top = $$.scrollTop()

    doc_bottom = doc_top + doc_height
    is_onscreen = el_top > doc_top && el_bottom < doc_bottom

    #if less than 50% of the viewport is taken up by the el...
    bottom_inside = el_bottom < doc_bottom && (el_bottom - doc_top) > options.fill_threshold * el_height
    top_inside = el_top > doc_top && (doc_bottom - el_top) > options.fill_threshold * el_height    
    no_adjustment_needed = is_onscreen && top_inside && bottom_inside  

    if !no_adjustment_needed
      switch options.position 
        when 'top'
          target = el_top - options.offset_buffer
        when 'bottom'
          target = el_bottom - doc_height + options.offset_buffer
        else
          throw 'bad position for ensureInView'

      if options.scroll

        distance_to_travel = options.speed || Math.abs( doc_top - target )

        $$.smoothScrollToTarget 
          target: el_top - options.offset_buffer
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


  smoothScrollToTarget: ({target, duration, callback}) ->
    start_pos = window.pageYOffset
    diff = target - start_pos

    start_time = null

    iter = (current_time) ->
      if !start_time
        start_time = current_time

      time = current_time - start_time

      percent = Math.min time / duration, 1
      window.scrollTo 0, start_pos + diff * percent

      if time < duration
        requestId = window.requestAnimationFrame(iter)
      else
        window.cancelAnimationFrame requestId
        callback?()

    requestId = window.requestAnimationFrame(iter)


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




