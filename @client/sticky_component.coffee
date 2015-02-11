####
# Implements scheme described at http://stackoverflow.com/questions/18358816/sticky-sidebar-stick-to-bottom-when-scrolling-down-top-when-scrolling-up 
# Only works in browsers that support CSS3 transforms (i.e. IE9+)
#
# Useful reference: http://www.quirksmode.org/mobile/viewports.html
#
#
# set props.parent_key if you want the parent to know when 
# we're in sticky mode

__sticky_components = 0

window.StickyComponent = ReactiveComponent
  displayName: 'StickyComponent'

  render : -> 

    if !@local.initialized
      _.defaults @local,
        initialized: true
        use_fixed_positioning: !browser.is_mobile
        is_stuck: false
        top_offset: @props.top_offset? or 0 #distance from top of viewport to stick top of element
        bottom_offset: @props.bottom_offset? or 0 #distance from bottom of viewport to stick bottom of element
        stick_on_zoomed_screens : (@props.stick_on_zoomed_screens? && @props.stick_on_zoomed_screens) or true
        last_viewport_top : document.documentElement.scrollTop || document.body.scrollTop

      save @local

    if @local.is_stuck
      style = 
        position: if @local.use_fixed_positioning then 'fixed' else 'absolute'
        top: @local.top_offset
        WebkitBackfaceVisibility: "hidden"
        transform: "translate(-#{@local.translate_x}px, #{@local.translate_y}px)"
        zIndex: 9999
        width: '100%'
    else 
      style = {}

    @transferPropsTo DIV null,
      DIV style: {height: if @local.is_stuck && @local.placeholder_height? then @local.placeholder_height else 0}
       
      DIV ref: 'stuck', style: css.crossbrowserify(style),
        @props.children

  componentDidMount : -> 
    @my_id = __sticky_components
    __sticky_components += 1

    # attach event listeners
    $(window).on "resize.StickyComponent-#{@my_id}", => @windowResized()
    $(window).on "scroll.StickyComponent-#{@my_id}", => @updatePosition()

    @windowResized()

  componentWillUnmount : -> 
    $(window).off ".StickyComponent-#{@my_id}"

  windowResized : -> 
    @local.viewport_height = window.innerHeight
    save @local

  toggleSticky : -> 
    @local.is_stuck = !@local.is_stuck
    if @props.parent_key
      data = fetch(@props.parent_key)
      data.sticky = @local.is_stuck
      save data
    save @local

  updatePosition : -> 
    $container = $(@props.container_selector)
    container_top = $container.offset().top 
    viewport_top = (document.documentElement.scrollTop || document.body.scrollTop)
    effective_viewport_top = viewport_top + @local.top_offset

    is_zoomed = window.innerWidth < $(window).width()

    ######
    # DETERMINE OUR STICKY STATE
    # Are we transitioning between being stuck and not being stuck?
    should_be_stuck = effective_viewport_top >= container_top && 
                       (@local.stick_on_zoomed_screens || (!is_zoomed && screen.width > 700) ) && 
                       (!@props.conditional || @props.conditional())

    if should_be_stuck && !@local.is_stuck
      @toggleSticky()

    else if !should_be_stuck && @local.is_stuck
      @toggleSticky()

    # Don't need to do anything if we're not actually stuck
    if !@local.is_stuck
      @local.last_viewport_top = viewport_top
      save @local
      return

    ######
    # HORIZONTAL ADJUSTMENTS
    # We need to adjust for any horizontal scroll for fixed position elements because they don't 
    # move with the rest of the content (they're fixed to the viewport). 
    # So we'll use scrollLeft to offset the fixed element so it actually is stuck to the window. 
    translate_x = if @local.use_fixed_positioning then $(window).scrollLeft() else 0

    ######
    # VERTICAL ADJUSTMENTS 

    $el = $(@refs.stuck.getDOMNode()).children()
    element_height = $el.height() # check element's height each scroll event because it may have changed
    element_fits_in_viewport = element_height < (@local.viewport_height - @local.top_offset)
    element_top = $el.offset().top
    element_bottom = element_top + element_height #container_top + element_height

    if element_fits_in_viewport #the common case, often for an empty decision board or the proposal header
      translate_y = if @local.use_fixed_positioning then 0 else $(window).scrollTop() - $(@getDOMNode()).offsetParent().offset().top

    else # if element doesn't fit in viewport, such as if you have a really full decision board

      # The sticky positioning will be off if the sticky element is bigger than its container
      # So we'll make the container bigger in that case. Note that this solution might not generalize.
      
      # if element_height > $container.height()
      #   $container.css('height', element_height)

      viewport_bottom = viewport_top + @local.viewport_height
      effective_viewport_bottom = viewport_bottom - @local.bottom_offset

      is_scrolling_up = viewport_top < @local.last_viewport_top

      # When scrolling up, simulate sticking to the top of the screen. 
      if is_scrolling_up
        if effective_viewport_top <= element_top
          translate_y = @local.translate_y + (effective_viewport_top - element_top) #adjustment is for scroll flicks
        else
          translate_y = @local.translate_y + (@local.last_viewport_top - viewport_top)

      # When scrolling down, simulate sticking to the bottom of the screen. 
      else           
        # if scrolled past the element bottom, we want to stick here
        if effective_viewport_bottom >= element_bottom  
          translate_y = @local.translate_y + (effective_viewport_bottom - element_bottom) #adjustment is for scroll flicks

        # otherwise, we'll simulate scrolling down through this element with negative Y translation
        else 
          translate_y = @local.translate_y + (@local.last_viewport_top - viewport_top) #- (effective_viewport_top - container_top)

    container_bottom = container_top + $container.height()
    # make sure that inertial scroll didn't force us to scroll past the bottom of the container
    if element_bottom + (translate_y - @local.translate_y) > container_bottom
      translate_y = container_bottom - element_bottom + @local.translate_y

    ####
    # APPLY THE ADJUSTMENTS to the fixed element
    if translate_y != @local.translate_y || translate_x != @local.translate_x
      @local.translate_y = translate_y
      @local.translate_x = translate_x

    # Make sure that elements don't scroll down past their container bottom
    # if effective_viewport_top + element_height > container_bottom
    #   @$el[0].style['top'] = "#{container_bottom - element_height - viewport_top}px" 
    # else if @$el[0].style['top'] != "#{@local.top_offset}px"
    #   @$el[0].style['top'] = "#{@local.top_offset}px"          

    @local.last_viewport_top = viewport_top
    @local.placeholder_height = if $el[0].style.position in ['absolute', 'fixed'] then 0 else element_height 
    save @local


    ##### 
    # Some debug output...
    #
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
