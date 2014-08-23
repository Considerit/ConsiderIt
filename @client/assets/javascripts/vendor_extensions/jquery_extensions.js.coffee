do ($, window, document) ->


  class StickyTopBottom
    # only works in browsers that support CSS3 transforms (i.e. IE9+)
    #TODO: 
    #  - destroy event handler if element is destroyed
    #  - track all the sticky elements and give them vertical preference
    #    so that the calculation as to where they offset with each other
    #    is automatically taken care of

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
      @current_translate = 0
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
      element_top = @$el.offset().top # - @current_translate


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

      now_stuck = effective_viewport_top >= container_top
      start_sticking = now_stuck && !@is_stuck
      start_unsticking = !now_stuck && @is_stuck
      @is_stuck = now_stuck

      element_bottom = @$el.offset().top + element_height #container_top + element_height
      
      if @is_stuck && !element_fits_in_viewport
        if is_scrolling_up
          if effective_viewport_top <= element_top
            new_translate = @current_translate + (effective_viewport_top - element_top) #adjustment is for scroll flicks
          else
            new_translate = @current_translate + (@last_viewport_top - viewport_top)

        # When scrolling down, we want to simulate sticking to the bottom of the screen. 
        else           
          # if scrolled past the element bottom, we want to stick here
          if effective_viewport_bottom >= element_bottom            
            new_translate = @current_translate + (effective_viewport_bottom - element_bottom) #adjustment is for scroll flicks

          # otherwise, we'll simulate scrolling down through this element with negative Y translation
          else 
            new_translate = @current_translate + (@last_viewport_top - viewport_top) #- (effective_viewport_top - container_top)

        # make sure that inertial scroll didn't force us to scroll past the bottom of the container
        container_bottom = container_top + @options.container.height()
        if element_bottom + (new_translate - @current_translate) + @options.bottom_offset > container_bottom
          new_translate = container_bottom - element_bottom + @current_translate - @options.bottom_offset

        if new_translate != @current_translate
          @current_translate = new_translate
          @$el[0].style["-webkit-backface-visibility"] = "hidden"
          @$el[0].style.transform = "translate(0, #{@current_translate}px)"        
          @$el[0].style['-webkit-transform'] = "translate(0, #{@current_translate}px)"
          @$el[0].style['-ms-transform'] = "translate(0, #{@current_translate}px)"
          @$el[0].style['-moz-transform'] = "translate(0, #{@current_translate}px)"

      if start_sticking
        @$el[0].style['position'] = 'fixed'
        @$el[0].style['top'] = "#{@options.top_offset}px"          
        @options.sticks() if @options.sticks
        if @options.placeholder
          @options.placeholder.style['visibility'] = 'hidden'
          @options.placeholder.style['display'] = ''

      if start_unsticking
        @$el[0].style['position'] = ''
        @$el[0].style['top'] = ''
        @$el[0].style.transform = ""        
        @$el[0].style['-webkit-transform'] = ""
        @$el[0].style['-ms-transform'] = ""
        @$el[0].style['-moz-transform'] = ""        

        @options.unsticks() if @options.unsticks
        if @options.placeholder
          @options.placeholder.style['display'] = 'none'

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

