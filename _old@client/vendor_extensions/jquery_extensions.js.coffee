do ($) ->
  $.fn.toggleWrapper = (obj = {}, init = true) ->
    _.defaults obj,
      className: ""
      backgroundColor: if @css("backgroundColor") isnt "transparent" then @css("backgroundColor") else "white"
      zIndex: if @css("zIndex") is "auto" or 0 then 1000 else (Number) @css("zIndex")
    
    $offset = @offset()
    $width   = @outerWidth(false)
    $height = @outerHeight(false)
    
    if init
      $("<div>")
        .appendTo("body")
          .addClass(obj.className)
            .attr("data-wrapper", true)
              .css
                width: $width
                height: $height 
                top: $offset.top
                left: $offset.left
                position: "absolute"
                zIndex: obj.zIndex + 1
                backgroundColor: obj.backgroundColor
    else
      $("[data-wrapper]").remove()

  # http://danielarandaochoa.com/backboneexamples/blog/2012/08/02/backbone-view-listening-for-a-remove-event-the-missing-item/
  $.event.special.destroyed =
    remove: (o) -> o.handler() if o.handler

  #X-Editable option
  $.fn.editable.defaults.mode = 'inline'

  toastr.options.fadeOut = 2500


  $.fn.ensureInView = (options = {}) ->
    _.defaults options,
      fill_threshold: .5
      offset_buffer: 50
      scroll: true
      position: 'top' 
      speed: null

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

    # console.log "amount: #{fill_threshold}"
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
        $('body').animate {scrollTop: target}, distance_to_travel
      else 
        $(document).scrollTop target


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

  $.fn.showParentStates = ->
    console.log 'Parent states for ', $(this), ':'
    $this = $(this)
    console.log '\t', $this.attr('state') if $this.attr('state')
    $(this).parents('[state]').each ->
      console.log '\t', $(this).attr('state'), $(this)
