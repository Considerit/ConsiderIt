# jQuery plugin 
# Author: Travis Kriplean
#
# Implements scheme described at http://stackoverflow.com/questions/18358816/sticky-sidebar-stick-to-bottom-when-scrolling-down-top-when-scrolling-up 
# Only works in browsers that support CSS3 transforms (i.e. IE9+)
#
# Useful reference: http://www.quirksmode.org/mobile/viewports.html
#
#TODO: 
#  - destroy event handler if element is destroyed
#  - track all the sticky elements and give them vertical preference
#    so that the calculation as to where they offset with each other
#    is automatically taken care of
#  - can we automatically insert a placeholder if needed?
#  - document options

do ($, window, document) ->
  $.fn.StickyElement = (options = {}) ->
    @each ->
      if typeof options == 'object'
        #init
        unless $.data @, "plugin_StickyElement"  
          $.data @, "plugin_StickyElement", new StickyElement @, options
      else 
        switch options
          when 'update'
            $.data(@, "plugin_StickyElement").update()
          when 'destroy'
            plugin_obj = $.data @, "plugin_StickyElement"
            $(@).unbind "destroyed", plugin_obj.destroy
            plugin_obj.destroy()
          when 'fix_initial_position'
            # hack to get around a problem where the browser's remembered scroll position messes
            # up the sticky location after initialization
            $(document).scrollTop (document.documentElement.scrollTop || document.body.scrollTop) - 1

  class StickyElement

    @current_id: 0 #track a unique id for each element with StickyElement

    constructor : (el, options) -> 
      defaults = 
        container: $('body') #reference element for starting and stopping the sticking (doesn't actually have to contain the element)
        top_offset: 0 #distance from top of viewport to stick top of element
        bottom_offset: 0 #distance from bottom of viewport to stick bottom of element
        sticks : null #callback when this element comes back to its base position
        unsticks : null #callback when this element leaves its base position
        conditional : null #callback to check whether to continue sticking
        stick_on_zoomed_screens : true

      @options = $.extend {}, defaults, options

      @my_id = @constructor.current_id
      @constructor.current_id += 1

      @$el = $(el)
      @translate_y = @translate_x = -1

      @is_stuck = false
      @last_viewport_top = document.documentElement.scrollTop || document.body.scrollTop


      # Fixed positioned elements are terribly supported on mobile devices.
      # On mobile browsers, we'll use absolute positioning, adjusted with transforms, to simulate sticking
      # On desktop browsers, we'll use fixed positioning (still with transforms), because it doesn't jitter
      # We detect mobile browsers by inspecting the user agent. This check isn't perfect.
      #    See these resources for information about fixed positioning on mobile devices
      #        - http://remysharp.com/2012/05/24/issues-with-position-fixed-scrolling-on-ios#position-drift. 
      #        - https://developer.apple.com/library/safari/technotes/tn2010/tn2262/_index.html ("4. Modify code that relies on CSS fixed positioning")
      #        - http://www.quirksmode.org/blog/archives/2010/12/the_fifth_posit.html

      @use_fixed_positioning =  !(navigator.userAgent.match(/Android/i) || 
                                      navigator.userAgent.match(/webOS/i) ||
                                      navigator.userAgent.match(/iPhone/i) ||
                                      navigator.userAgent.match(/iPad/i) ||
                                      navigator.userAgent.match(/iPod/i) ||
                                      navigator.userAgent.match(/BlackBerry/i) ||
                                      navigator.userAgent.match(/Windows Phone/i))

      $(window).on "resize.plugin_StickyElement-#{@my_id}", => @resize()
      $(window).on "scroll.plugin_StickyElement-#{@my_id}", => @update()

      $(document).on "touchend", => @update()

      @$el.on 'destroyed', $.proxy(@destroy, @) 

      if @options.placeholder
        @options.placeholder.style['visibility'] = 'hidden'
        @options.placeholder.style['display'] = 'none'

      @resize()
      @update()


    resize : -> @viewport_height = window.innerHeight

    # Update 
    # Updates the position of the element with respect to the viewport. 
    # When moving up or element is shorter than viewport:
    #    if scrolled above top of element, position top of element to top of viewport
    #      (stick to top)
    # When moving down: 
    #    if scrolled past bottom of element, position bottom of element at bottom of viewport
    #      (stick to bottom)
    update : -> 

      if !@$el
        console.error('sticky element has disappeared!!')
        @destroy()
        return

      container_top = @options.container.offset().top 
      viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)
      effective_viewport_top = viewport_top + @options.top_offset

      is_zoomed = window.innerWidth < $(window).width()

      ######
      # DETERMINE OUR STICKY STATE
      # Are we transitioning between being stuck and not being stuck?
      should_be_stuck = effective_viewport_top >= container_top && (@options.stick_on_zoomed_screens || (!is_zoomed && screen.width > 700) ) && (!@options.conditional || @options.conditional())

      if should_be_stuck && !@is_stuck
        @$el[0].style['position'] = if @use_fixed_positioning then 'fixed' else 'absolute'
        @$el[0].style['top'] = "#{@options.top_offset}px" 
        @$el[0].style["-webkit-backface-visibility"] = "hidden"

        @options.sticks() if @options.sticks
        if @options.placeholder
          @options.placeholder.style['visibility'] = 'hidden'
          @options.placeholder.style['display'] = ''
        @is_stuck = true

      else if !should_be_stuck && @is_stuck
        @translate_y = @translate_x = -1
        @$el[0].style['position'] = ''
        @$el[0].style['top'] = ''

        @$el[0].style.transform = ""        
        @$el[0].style['-webkit-transform'] = ""
        @$el[0].style['-ms-transform'] = ""
        @$el[0].style['-moz-transform'] = ""        
  
        if @is_stuck      
          @options.unsticks() if @options.unsticks

        @is_stuck = false

        if @options.placeholder
          @options.placeholder.style['display'] = 'none'

      # Don't need to do anything if we're not actually stuck
      return if !@is_stuck

      ######
      # HORIZONTAL ADJUSTMENTS
      # We need to adjust for any horizontal scroll for fixed position elements because they don't 
      # move with the rest of the content (they're fixed to the viewport). 
      # So we'll use scrollLeft to offset the fixed element so it actually is stuck to the window. 
      translate_x = if @use_fixed_positioning then $(window).scrollLeft() else 0

      ######
      # VERTICAL ADJUSTMENTS 

      element_height = @$el.height() # check element's height each scroll event because it may have changed
      element_fits_in_viewport = element_height < (@viewport_height - @options.top_offset)
      element_bottom = @$el.offset().top + element_height #container_top + element_height
      container_bottom = container_top + @options.container.height()

      if element_fits_in_viewport #the common case, often for an empty decision board or the proposal header
        translate_y = if @use_fixed_positioning then 0 else $(window).scrollTop() - @$el.offsetParent().offset().top

      else # if element doesn't fit in viewport, such as if you have a really full decision board
        element_top = @$el.offset().top

        viewport_bottom = viewport_top + @viewport_height
        effective_viewport_bottom = viewport_bottom - @options.bottom_offset

        is_scrolling_up = viewport_top < @last_viewport_top

        # When scrolling up, simulate sticking to the top of the screen. 
        if is_scrolling_up
          if effective_viewport_top <= element_top
            translate_y = @translate_y + (effective_viewport_top - element_top) #adjustment is for scroll flicks
          else
            translate_y = @translate_y + (@last_viewport_top - viewport_top)

        # When scrolling down, simulate sticking to the bottom of the screen. 
        else           
          # if scrolled past the element bottom, we want to stick here
          if effective_viewport_bottom >= element_bottom            
            translate_y = @translate_y + (effective_viewport_bottom - element_bottom) #adjustment is for scroll flicks

          # otherwise, we'll simulate scrolling down through this element with negative Y translation
          else 
            translate_y = @translate_y + (@last_viewport_top - viewport_top) #- (effective_viewport_top - container_top)

      # make sure that inertial scroll didn't force us to scroll past the bottom of the container
      if element_bottom + (translate_y - @translate_y) + @options.bottom_offset > container_bottom
        translate_y = container_bottom - element_bottom + @translate_y - @options.bottom_offset


      # console.log ""
      # console.log "General:"
      # console.log "           Layout viewport: #{$(window).width()} x #{$(window).height()}"
      # console.log "           Visual viewport: #{window.innerWidth} x #{window.innerHeight}"
      # console.log "         mobile zoom ratio: #{$(window).width() / window.innerWidth}"
      # console.log "   window.devicePixelRatio: #{window.devicePixelRatio}"
      # console.log "        navigator.platform: #{navigator.platform}"
      # console.log "         navigator.appName: #{navigator.appName}"
      # console.log "       navigator.userAgent: #{navigator.userAgent}"
      
      # console.log ""
      # console.log "Horizontal:"
      # console.log "        @$el.offset().left: #{@$el.offset().left}px"
      # console.log "    $(window).scrollLeft(): #{$(window).scrollLeft()}px"
      # console.log "         window.innerWidth: #{window.innerWidth}px"
      # console.log "       $(document).width(): #{$(document).width()}px"
      # console.log "              screen.width: #{screen.width}"
      # console.log "               *adjustment: #{translate_x}"

      # console.log ""
      # console.log "Vertical:"
      # console.log "        @$el.offset().top: #{@$el.offset().top}px"
      # console.log "    $(window).scrollTop(): #{$(window).scrollTop()}px"
      # console.log " scroll/offset difference: #{$(window).scrollTop() - @$el.offset().top}px"
      # console.log "       window.innerHeight: #{window.innerHeight}px"
      # console.log "       $(window).height(): #{$(window).height()}px"
      # console.log "     $(document).height(): #{$(document).height()}px"
      # console.log "            screen.height: #{screen.height}"
      # console.log "              *adjustment: #{translate_y}"


      ####
      # APPLY THE ADJUSTMENTS to the fixed element
      if translate_y != @translate_y || translate_x != @translate_x
        @translate_y = translate_y
        @translate_x = translate_x

        @$el[0].style.transform = "translate(-#{@translate_x}px, #{@translate_y}px)"        
        @$el[0].style['-webkit-transform'] = "translate(-#{@translate_x}px, #{@translate_y}px)"
        @$el[0].style['-ms-transform'] = "translate(-#{@translate_x}px, #{@translate_y}px)"
        @$el[0].style['-moz-transform'] = "translate(-#{@translate_x}px, #{@translate_y}px)"


      # Make sure that elements don't scroll down past their container bottom
      # if effective_viewport_top + element_height > container_bottom
      #   @$el[0].style['top'] = "#{container_bottom - element_height - viewport_top}px" 
      # else if @$el[0].style['top'] != "#{@options.top_offset}px"
      #   @$el[0].style['top'] = "#{@options.top_offset}px"          

      @last_viewport_top = viewport_top

    destroy : -> 
      $(window).off ".plugin_StickyElement-#{@my_id}"
      $.removeData @$el[0], "plugin_StickyElement" if @$el
      @$el = null


