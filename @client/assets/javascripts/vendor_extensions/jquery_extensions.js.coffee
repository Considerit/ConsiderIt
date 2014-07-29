do ($) ->

  $.fn.stickyTopBottom = (options = {}) ->


    ## ##############
    #initialization
    _.defaults options, 
      container: $('body')
      top_offset: 0
      bottom_offset: 0

    $el = $(this)

    container_top = options.container.offset().top 
    element_top = $el.offset().top

    current_translate = 0

    viewport_height = $(window).height()
    $(window).on 'resize', -> 
      viewport_height = $(window).height()

    last_viewport_top = document.documentElement.scrollTop || document.body.scrollTop

    setTop = (translation) -> 
      #this will overwrite existing transform...
      $el.css 'transform', "translate(0, #{current_translate}px)" 

    ## #################
    # The meat: scroll handler
    #
    # When moving up or element is shorter than viewport:
    #    if scrolled above top of element, position top of element to top of viewport
    #      (stick to top)
    # When moving down: 
    #    if scrolled past bottom of element, position bottom of element at bottom of viewport
    #      (stick to bottom)

    $(window).scroll (event) ->
      viewport_top = document.documentElement.scrollTop || document.body.scrollTop
      viewport_bottom = viewport_top + viewport_height
      effective_viewport_top = viewport_top + options.top_offset
      effective_viewport_bottom = viewport_bottom - options.bottom_offset

      # warning: checking height causes bad performance
      element_height = $el.height()

      scrolling_up = viewport_top < last_viewport_top
      taller_than_viewport = element_height > viewport_height

      if scrolling_up
        if effective_viewport_top < container_top # if we're scrolled past container top
          current_translate = 0
          setTop current_translate
        else if effective_viewport_top < element_top + current_translate
          current_translate = effective_viewport_top - element_top
          setTop current_translate

      else if !taller_than_viewport
        console.log !taller_than_viewport, effective_viewport_top, element_top, current_translate, effective_viewport_top > element_top + current_translate
        if effective_viewport_top > element_top + current_translate
          current_translate = effective_viewport_top - element_top
          setTop current_translate
      else # scrolling down
        container_bottom = container_top + options.container.height() #warning: checking height causes bad performance
        if effective_viewport_bottom > container_bottom #scrolled past container bottom
          current_translate = container_bottom - (element_top + element_height)
          setTop current_translate
        else if effective_viewport_bottom > element_top + element_height + current_translate
          current_translate = effective_viewport_bottom - (element_top + element_height)
          setTop current_translate

      last_viewport_top = viewport_top

  $.fn.ensureInView = (options = {}) ->

    _.defaults options,
      fill_threshold: .5
      offset_buffer: 50
      scroll: true
      position: 'top' 
      speed: null
      callback: ->

    $el = $(this)

    el_height = $el.height()
    el_top = $el.offset().top
    el_bottom = el_top + el_height

    doc_height = $(window).height()
    doc_top = $(window).scrollTop()
    doc_bottom = doc_top + doc_height
    is_onscreen = el_top > doc_top && el_bottom < doc_bottom

    #if less than 50% of the viewport is taken up by the el...
    bottom_inside = el_bottom < doc_bottom && (el_bottom - doc_top) > options.fill_threshold * el_height
    top_inside = el_top > doc_top && (doc_bottom - el_top) > options.fill_threshold * el_height    
    in_viewport = is_onscreen || top_inside || bottom_inside  

    # console.log "amount: #{options.fill_threshold}"
    # console.log "el_top: #{el_top}, el_bottom: #{el_bottom}"
    # console.log "doc_top: #{doc_top}, doc_bottom: #{doc_bottom}"
    # console.log "onscreen: #{is_onscreen}, top_inside: #{top_inside}, bottom_inside: #{bottom_inside}"

    if !in_viewport
      switch options.position 
        when 'top'
          target = el_top - options.offset_buffer
        when 'bottom'
          target = el_bottom - doc_height + options.offset_buffer
        else
          throw 'bad position for ensureInView'

      if options.scroll
        distance_to_travel = options.speed || Math.abs( doc_top - target )
        $el.velocity 'scroll', 
          duration: Math.min(distance_to_travel, 1500)
          offset: -options.offset_buffer
          complete: options.callback
        , 'ease-in'

      else 
        $(document).scrollTop target
        options.callback()
    else
      options.callback()


  $.fn.moveToBottom = (offset_buffer = 50, scroll = false) ->
    $el = $(this)
    el_height = $el.height()
    el_top = $el.offset().top
    el_bottom = el_top + el_height

    doc_height = $(window).height()
    doc_top = $(window).scrollTop()
    doc_bottom = doc_top + doc_height


    target = el_bottom - doc_height + offset_buffer

    # console.log "el_top: #{el_top}, el_bottom: #{el_bottom}"
    # console.log "doc_top: #{doc_top}, doc_bottom: #{doc_bottom}"
    # console.log "target: #{target}"

    if scroll
      distance_to_travel = Math.abs( doc_top - target )
      $('body').animate {scrollTop: target}, distance_to_travel
    else
      $(document).scrollTop target

  $.fn.moveToTop = (offset_buffer = 50, scroll = false) ->
    $el = $(this)
    el_top = $el.offset().top
    el_bottom = 
    target = el_top - offset_buffer
    doc_top = $(window).scrollTop()

    if scroll
      distance_to_travel = Math.abs( doc_top - target )
      $('body').animate {scrollTop: target}, distance_to_travel
    else
      $(document).scrollTop target

  $.fn.putBehindLightbox = ->
    $('#lightbox').remove()
    $(this).after '<div id="lightbox">'

  $.fn.removeLightbox = ->
    $('#lightbox').remove()

