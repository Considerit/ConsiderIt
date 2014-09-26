do ($, window, document) ->


  class StickyTopBottom
    # only works in browsers that support CSS3 transforms (i.e. IE9+)
    #TODO: 
    #  - destroy event handler if element is destroyed
    #  - track all the sticky elements and give them vertical preference
    #    so that the calculation as to where they offset with each other
    #    is automatically taken care of
    #  - can we automatically insert a placeholder if needed?

    @current_id: 0 #track a unique id for each element with stickytopbottom

    constructor : (el, options) -> 
      defaults = 
        container: $('body') #reference element for starting and stopping the sticking (doesn't actually have to contain the element)
        top_offset: 0 #distance from top of viewport to stick top of element
        bottom_offset: 0 #distance from bottom of viewport to stick bottom of element
        sticks : null #callback when this element comes back to its base position
        unsticks : null #callback when this element leaves its base position
        conditional : null #callback to check whether to continue sticking

      @options = $.extend {}, defaults, options

      @my_id = @constructor.current_id
      @constructor.current_id += 1

      @$el = $(el)
      @scroll_y = @scroll_x = 0

      @is_stuck = false
      @last_viewport_top = document.documentElement.scrollTop || document.body.scrollTop

      $(window).on "resize.plugin_stickytopbottom-#{@my_id}", => @resize()
      $(window).on "scroll.plugin_stickytopbottom-#{@my_id}", => @update()

      @$el.on 'destroyed', $.proxy(@destroy, @) 

      if @options.placeholder
        @options.placeholder.style['visibility'] = 'hidden'
        @options.placeholder.style['display'] = 'none'

      @resize()
      @update()



    resize : -> @viewport_height = $(window).height()

    # Update 
    # Updates the position of the element with respect to the viewport. 
    # When moving up or element is shorter than viewport:
    #    if scrolled above top of element, position top of element to top of viewport
    #      (stick to top)
    # When moving down: 
    #    if scrolled past bottom of element, position bottom of element at bottom of viewport
    #      (stick to bottom)
    update : -> 

      container_top = @options.container.offset().top 
      viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)
      effective_viewport_top = viewport_top + @options.top_offset


      ######
      # DETERMINE OUR STICKY STATE
      # Are we transitioning between being stuck and not being stuck?
      should_be_stuck = effective_viewport_top >= container_top

      if should_be_stuck && !@is_stuck
        @$el[0].style['position'] = 'fixed'
        @$el[0].style['top'] = "#{@options.top_offset}px"     
        @$el[0].style["-webkit-backface-visibility"] = "hidden"

        @options.sticks() if @options.sticks
        if @options.placeholder
          @options.placeholder.style['visibility'] = 'hidden'
          @options.placeholder.style['display'] = ''
        @is_stuck = true

      if !should_be_stuck && @is_stuck
        @scroll_y = 0
        @$el[0].style['position'] = ''
        @$el[0].style['top'] = ''
        @$el[0].style.transform = ""        
        @$el[0].style['-webkit-transform'] = ""
        @$el[0].style['-ms-transform'] = ""
        @$el[0].style['-moz-transform'] = ""        
        @is_stuck = false

        @options.unsticks() if @options.unsticks
        if @options.placeholder
          @options.placeholder.style['display'] = 'none'

      # Don't need to do anything if we're not actually stuck
      return if !@is_stuck


      ######
      # HORIZONTAL ADJUSTMENTS
      # We need to adjust for any horizontal scroll, because position:fixed elements don't 
      # move with the rest of the content. So we'll use scrollLeft to offset the fixed
      # element. But this is difficult to do correctly because of weird interactions between
      # pinch zoom and scroll left. Under certain conditions, we have to do a complex 
      # calculation to figure out how much to offset the fixed element. 

      zoom = $(window).width() / window.innerWidth

      #console.log "zoom: #{zoom.toPrecision(3)}", "doc width: #{$(document).width()}", "window width: #{$(window).width()}", "window inner width: #{window.innerWidth}", "client width: #{document.documentElement.clientWidth}"

      # window innerwidth is the number of pixels from the perspective of the site markup, 
      # whereas window.width is the actual size of the window on the user's screen

      # We don't have to adjust horizontally if the window is bigger than the document (even if we're pinch zoomed)
      if $(document).width() <= window.innerWidth
        scroll_x = 0

      # If the window is smaller than the document, but we're not zoomed, we just
      # need to adjust the element by the distance we're horizontally scrolled.
      # Note that we could eliminate this condition entirely because 
      # the else below will work out to the same value for no zoom. However
      # this is a common case and the else statement incurs some performance
      # costs in the calculations it has to do. 
      else if zoom == 1
        scroll_x = $(window).scrollLeft()

      # If the user has pinch zoomed when the window is smaller than the document, 
      # we can't just use scrollLeft directly. Instead, we need to adjust scrollLeft
      # based on the difference between the actual window width, the width of the zoomed
      # area the user sees, and the % amount of horizontal scrolling they've done. 
      else
        zoom_width_difference = $(window).width() - window.innerWidth
        max_scroll_left =       $(document).width() - window.innerWidth
        zoom_adjustment =       $(window).scrollLeft() / max_scroll_left

        # BUG: this adjustment does not work on iOS devices, though it does work on Desktop safari

        scroll_x = $(window).scrollLeft() - zoom_adjustment * zoom_width_difference

        #console.log zoom, scroll_x, zoom_width_difference, max_scroll_left, zoom_adjustment,  $(window).scrollLeft()

      ######
      # VERTICAL ADJUSTMENTS 

      # BUG with vertical adjustments: 
      #    iOS & desktop safari has position:fixed drift when pinch zoomed. 
      #    See http://remysharp.com/2012/05/24/issues-with-position-fixed-scrolling-on-ios#position-drift. 
      #    I haven't been able to find the right measurements to adjust it. 
      #    One thing that is interesting is that scrollTop != offset().top. Don't know if that's a red herring. 

      element_height = @$el.height() # check element's height each scroll event because it may have changed
      element_fits_in_viewport = element_height < (@viewport_height - @options.top_offset)

      if element_fits_in_viewport #the common case, often for an empty decision board or the proposal header
        scroll_y = 0
        # console.log "OffsetY: #{@$el.offset().top}, ScrollY: #{$(window).scrollTop()}px, adjusted: #{scroll_y}"

      else # if element doesn't fit in viewport, such as if you have a really full decision board
        element_top = @$el.offset().top
        element_bottom = @$el.offset().top + element_height #container_top + element_height

        viewport_bottom = viewport_top + @viewport_height
        effective_viewport_bottom = viewport_bottom - @options.bottom_offset

        is_scrolling_up = viewport_top < @last_viewport_top
        container_bottom = container_top + @options.container.height()

        if is_scrolling_up
          if effective_viewport_top <= element_top
            scroll_y = @scroll_y + (effective_viewport_top - element_top) #adjustment is for scroll flicks
          else
            scroll_y = @scroll_y + (@last_viewport_top - viewport_top)

        # When scrolling down, we want to simulate sticking to the bottom of the screen. 
        else           
          # if scrolled past the element bottom, we want to stick here
          if effective_viewport_bottom >= element_bottom            
            scroll_y = @scroll_y + (effective_viewport_bottom - element_bottom) #adjustment is for scroll flicks

          # otherwise, we'll simulate scrolling down through this element with negative Y translation
          else 
            scroll_y = @scroll_y + (@last_viewport_top - viewport_top) #- (effective_viewport_top - container_top)

        # make sure that inertial scroll didn't force us to scroll past the bottom of the container
        if element_bottom + (scroll_y - @scroll_y) + @options.bottom_offset > container_bottom
          scroll_y = container_bottom - element_bottom + @scroll_y - @options.bottom_offset

      ####
      # APPLY THE ADJUSTMENTS to the fixed element
      if scroll_y != @scroll_y || scroll_x != @scroll_x
        @scroll_y = scroll_y
        @scroll_x = scroll_x

        @$el[0].style.transform = "translate(-#{@scroll_x}px, #{@scroll_y}px)"        
        @$el[0].style['-webkit-transform'] = "translate(-#{@scroll_x}px, #{@scroll_y}px)"
        @$el[0].style['-ms-transform'] = "translate(-#{@scroll_x}px, #{@scroll_y}px)"
        @$el[0].style['-moz-transform'] = "translate(-#{@scroll_x}px, #{@scroll_y}px)"

      # make sure that elements that don't scroll down past their container bottom
      if effective_viewport_top + element_height > container_bottom
        @$el[0].style['top'] = "#{container_bottom - element_height - viewport_top}px" 
      else if @$el[0].style['top'] != "#{@options.top_offset}px"
        @$el[0].style['top'] = "#{@options.top_offset}px"          


      @last_viewport_top = viewport_top

    destroy : -> 
      $(window).off ".plugin_stickytopbottom-#{@my_id}"
      $.removeData @$el[0], "plugin_stickytopbottom"
      @$el = null


  $.fn.stickyTopBottom = (options = {}) ->
    @each ->
      if typeof options == 'object'
        #init
        unless $.data @, "plugin_stickytopbottom"  
          $.data @, "plugin_stickytopbottom", new StickyTopBottom @, options
      else 
        switch options
          when 'update'
            $.data(@, "plugin_stickytopbottom").update()
          when 'destroy'
            plugin_obj = $.data @, "plugin_stickytopbottom"
            $(@).unbind "destroyed", plugin_obj.destroy
            plugin_obj.destroy()
          when 'fix_initial_position'
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

