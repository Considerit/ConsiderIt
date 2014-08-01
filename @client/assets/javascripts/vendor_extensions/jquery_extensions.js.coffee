do ($, window, document) ->


  class StickyTopBottom
    # only works in browsers that support CSS3 transforms (i.e. IE9+)
    #TODO: 
    #  - destroy event handler if element is destroyed
    #  - track all the sticky elements and give them vertical preference
    #    so that the calculation as to where they offset with each other
    #    is automatically taken care of


    constructor : (el, options) -> 
      defaults = 
        container: $('body') #reference element for starting and stopping the sticking (doesn't actually have to contain the element)
        top_offset: 0 #distance from top of viewport to stick top of element
        bottom_offset: 0 #distance from bottom of viewport to stick bottom of element
        docks : null #callback when this element comes back to its base position
        undocks : null #callback when this element leaves its base position
        conditional : null #callback to check whether to continue sticking

      @options = $.extend {}, defaults, options

      @$el = $(el)
      @viewport_height = $(window).height()
      $(window).on 'resize', -> 
        @viewport_height = $(window).height()

      @current_translate = 0
      @last_viewport_top = document.documentElement.scrollTop || document.body.scrollTop

      $(window).scroll (ev) => @update()
      @update()


    # Update 
    # Updates the position of the element with respect to the viewport. 
    # When moving up or element is shorter than viewport:
    #    if scrolled above top of element, position top of element to top of viewport
    #      (stick to top)
    # When moving down: 
    #    if scrolled past bottom of element, position bottom of element at bottom of viewport
    #      (stick to bottom)
    update : -> 
      if @options.conditional && !@options.conditional()
        @current_translate = 0
        @$el[0].style.transform = ""        
        @$el[0].style['-webkit-transform'] = ""
        @$el[0].style['-ms-transform'] = ""
        @$el[0].style['-moz-transform'] = ""        
        return

      #Get the top of the reference element.
      #If the container is translated Y, then this method will fail I believe.
      container_top = @options.container.offset().top 
      element_top = @$el.offset().top - @current_translate


      # Need to reset element's height each scroll event because it may have change height 
      # since initialization.
      # Warning: checking height is performance no-no
      element_height = @$el.height()

      viewport_top = document.documentElement.scrollTop || document.body.scrollTop
      viewport_bottom = viewport_top + @viewport_height
      effective_viewport_top = viewport_top + @options.top_offset
      effective_viewport_bottom = viewport_bottom - @options.bottom_offset

      is_scrolling_up = viewport_top < @last_viewport_top
      element_fits_in_viewport = element_height < (@viewport_height - @options.top_offset)

      new_translate = null
      if is_scrolling_up
        if effective_viewport_top < container_top # if we're scrolled past container top
          new_translate = 0
        else if effective_viewport_top < element_top + @current_translate
          new_translate = effective_viewport_top - element_top
      else if element_fits_in_viewport
        if effective_viewport_top > element_top + @current_translate
          new_translate = effective_viewport_top - element_top
      else # scrolling down
        container_height = @options.container.height()
        container_bottom = container_top + container_height #warning: checking height is performance no-no
        if effective_viewport_bottom > container_bottom #scrolled past container bottom
          new_translate = container_bottom - (element_top + element_height)
        else if effective_viewport_bottom > element_top + element_height + @current_translate
          new_translate = effective_viewport_bottom - (element_top + element_height)

      if new_translate != null
        is_undocking = @current_translate == 0 && new_translate != 0
        is_docking = @current_translate != 0 && new_translate == 0

        @current_translate = new_translate

        @$el[0].style["-webkit-backface-visibility"] = "hidden"
        @$el[0].style.transform = "translate(0, #{@current_translate}px)"        
        @$el[0].style['-webkit-transform'] = "translate(0, #{@current_translate}px)"
        @$el[0].style['-ms-transform'] = "translate(0, #{@current_translate}px)"
        @$el[0].style['-moz-transform'] = "translate(0, #{@current_translate}px)"

        @options.docks() if @options.docks && is_docking
        @options.undocks() if @options.undocks && is_undocking


      @last_viewport_top = viewport_top

  $.fn.stickyTopBottom = (options = {}) ->
    @each ->
      if typeof options == 'object'
        #init
        unless $.data @, "plugin_stickytopbottom"  
          $.data @, "plugin_stickytopbottom", new StickyTopBottom @, options
      else if options == 'update'
        $.data(@, "plugin_stickytopbottom").update()
      else if options == 'fix_initial_position'
        # hack to get around a problem where the browser's remembered scroll position messes
        # up the sticky location after initialization
        $(document).scrollTop (document.documentElement.scrollTop || document.body.scrollTop) - 1


do ($, window, document) ->

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

do ($, window, document) ->

  $.fn.putBehindLightbox = ->
    $('#lightbox').remove()
    $(this).after '<div id="lightbox">'

  $.fn.removeLightbox = ->
    $('#lightbox').remove()

