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


  $.fn.ensureInView = (amount_of_viewport_taken_by_el=.5, offset_buffer=50, scroll = true) ->
    $el = $(this)

    el_top = $el.offset().top
    doc_top = $(window).scrollTop()
    doc_bottom = doc_top + $(window).height()
    is_onscreen = el_top > doc_top && el_top < doc_bottom

    #if less than 50% of the viewport is taken up by the el...
    in_viewport = is_onscreen || (doc_bottom - el_top) > amount_of_viewport_taken_by_el * (doc_bottom - doc_top)  

    target = el_top - offset_buffer
    if !in_viewport
      if scroll
        distance_to_travel = Math.abs( doc_top - target )
        $('body').animate {scrollTop: target}, distance_to_travel
      else 
        $('body').scrollTop target

  $.fn.moveToTop = (offset_buffer = 50, scroll = false) ->
    $el = $(this)
    el_top = $el.offset().top
    target = el_top - offset_buffer
    doc_top = $(window).scrollTop()

    if scroll
      distance_to_travel = Math.abs( doc_top - target )
      $('body').animate {scrollTop: target}, distance_to_travel
    else
      $('body').scrollTop target