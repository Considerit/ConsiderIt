do ($) ->

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

