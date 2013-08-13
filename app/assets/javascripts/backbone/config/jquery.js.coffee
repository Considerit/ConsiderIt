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
