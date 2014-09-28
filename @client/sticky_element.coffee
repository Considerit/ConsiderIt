# jQuery plugin 
# Author: Travis Kriplean
#
# Implements scheme described at http://stackoverflow.com/questions/18358816/sticky-sidebar-stick-to-bottom-when-scrolling-down-top-when-scrolling-up 
# Only works in browsers that support CSS3 transforms (i.e. IE9+)
#
#TODO: 
#  - destroy event handler if element is destroyed
#  - track all the sticky elements and give them vertical preference
#    so that the calculation as to where they offset with each other
#    is automatically taken care of
#  - can we automatically insert a placeholder if needed?

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

      @options = $.extend {}, defaults, options

      @my_id = @constructor.current_id
      @constructor.current_id += 1

      @$el = $(el)
      @scroll_y = @scroll_x = -1

      @is_stuck = false
      @last_viewport_top = document.documentElement.scrollTop || document.body.scrollTop

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


      ######
      # DETERMINE OUR STICKY STATE
      # Are we transitioning between being stuck and not being stuck?
      should_be_stuck = effective_viewport_top >= container_top

      if should_be_stuck && !@is_stuck && (!@options.conditional || @options.conditional())
        @$el[0].style['position'] = 'fixed'
        @$el[0].style['top'] = "#{@options.top_offset}px"     
        @$el[0].style["-webkit-backface-visibility"] = "hidden"

        @options.sticks() if @options.sticks
        if @options.placeholder
          @options.placeholder.style['visibility'] = 'hidden'
          @options.placeholder.style['display'] = ''
        @is_stuck = true

      else if (!should_be_stuck && @is_stuck) || @options.conditional && !@options.conditional()
        @scroll_y = @scroll_x = -1
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
      # We need to adjust for any horizontal scroll, because position:fixed elements don't 
      # move with the rest of the content. So we'll use scrollLeft to offset the fixed
      # element. But this is difficult to do correctly because of weird interactions between
      # pinch zoom and scroll left. Under certain conditions, we have to do a complex 
      # calculation to figure out how much to offset the fixed element. 

      # If the full screen is visible, scroll_x will be 0; if the window is small, but no pinch zooming, 
      # it will be $(window).scrollLeft(). Otherwise...
      # If the user has pinch zoomed when the window is smaller than the document, 
      # we can't just use scrollLeft directly. Instead, we need to adjust scrollLeft
      # based on the difference between the actual window width, the width of the zoomed
      # area the user sees, and the % amount of horizontal scrolling they've done. 
      zoom_width_difference = $(window).width() - window.innerWidth
      max_scroll_left =       $(document).width() - window.innerWidth
      zoom_adjustment =       $(window).scrollLeft() / max_scroll_left

      scroll_x = $(window).scrollLeft() - zoom_adjustment * zoom_width_difference

      # (temporarily addressed) BUG: 
      # The scroll_x adjustment above does not immediately work on iOS devices.
      # I haven't been able to figure out exactly which values to use to make the
      # proper adjustments cross-platform. So I'm hardcoding some values that look
      # about right, though they are not *principled* calculations, and thus might
      # be horribly wrong in some conditions. 
      # TODO: test on android
      device_specific_adjuster = 1
      if navigator.platform.match /iPad/
        device_specific_adjuster = .82
      else if navigator.platform.match /iPhone/
        if screen.width >= 375 # iPhone 6
          device_specific_adjuster = 1.64
        else if screen.width >= 320 #iPhone 4, 5, & 5s
          device_specific_adjuster = 1.8

      scroll_x /= device_specific_adjuster

      ######
      # VERTICAL ADJUSTMENTS 

      element_height = @$el.height() # check element's height each scroll event because it may have changed
      element_fits_in_viewport = element_height < (@viewport_height - @options.top_offset)

      if element_fits_in_viewport #the common case, often for an empty decision board or the proposal header
        scroll_y = 0
        # BUG with vertical adjustments when pinch zoomed on iOS or desktop safari: 
        #    The fixed position element slowly drifts off the page when scrolling down. 
        #    See http://remysharp.com/2012/05/24/issues-with-position-fixed-scrolling-on-ios#position-drift. 
        #    I haven't been able to find the right measurements to adjust it. 
        #    One thing that is interesting is that scrollTop != offset().top. Don't know if that's a red herring.

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

      # console.log ""
      # console.log "General:"
      # console.log "          pinch zoom ratio: #{$(window).width() / window.innerWidth}"
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
      # console.log "               *adjustment: #{scroll_x}"

      # console.log ""
      # console.log "Vertical:"
      # console.log "        @$el.offset().top: #{@$el.offset().top}px"
      # console.log "    $(window).scrollTop(): #{$(window).scrollTop()}px"
      # console.log "       window.innerHeight: #{window.innerHeight}px"
      # console.log "       $(window).height(): #{$(window).height()}px"
      # console.log "     $(document).height(): #{$(document).height()}px"
      # console.log "            screen.height: #{screen.height}"
      # console.log "              *adjustment: #{scroll_y}"


      ####
      # APPLY THE ADJUSTMENTS to the fixed element
      if scroll_y != @scroll_y || scroll_x != @scroll_x
        @scroll_y = scroll_y
        @scroll_x = scroll_x

        @$el[0].style.transform = "translate(-#{@scroll_x}px, #{@scroll_y}px)"        
        @$el[0].style['-webkit-transform'] = "translate(-#{@scroll_x}px, #{@scroll_y}px)"
        @$el[0].style['-ms-transform'] = "translate(-#{@scroll_x}px, #{@scroll_y}px)"
        @$el[0].style['-moz-transform'] = "translate(-#{@scroll_x}px, #{@scroll_y}px)"

      # Make sure that elements that don't scroll down past their container bottom
      # BUG: This does not trigger in Chrome unless inspecter is open (gah!). 
      #      It works in Safari, Firefox, and IE9. 
      if effective_viewport_top + element_height > container_bottom
        @$el[0].style['top'] = "#{container_bottom - element_height - viewport_top}px" 
      else if @$el[0].style['top'] != "#{@options.top_offset}px"
        @$el[0].style['top'] = "#{@options.top_offset}px"          

      @last_viewport_top = viewport_top

    destroy : -> 
      $(window).off ".plugin_StickyElement-#{@my_id}"
      $.removeData @$el[0], "plugin_StickyElement" if @$el
      @$el = null


