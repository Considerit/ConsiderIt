$(document).ready () ->

  # google analytics
  ( () ->
    ga = document.createElement('script')
    ga.type = 'text/javascript'
    ga.async = true
    ga.src = (if 'https:' == document.location.protocol then 'https://ssl' else 'http://www') + '.google-analytics.com/ga.js'
    s = document.getElementsByTagName('script')[0] 
    s.parentNode.insertBefore(ga, s)

  )()

window.ConsiderIt.utils = 
  add_CSRF : (params) ->
    csrfName = $("meta[name='csrf-param']").attr('content')
    csrfValue = $("meta[name='csrf-token']").attr('content')
    params[csrfName] = csrfValue
  update_CSRF : (new_csrf) ->
    $("meta[name='csrf-token']").attr('content', new_csrf)

  get_tile_size : (width, height, tileCount) ->
    # come up with an initial guess
    aspect = height/width
    xf = Math.sqrt(tileCount/aspect)
    yf = xf*aspect
    x = Math.max(1.0, Math.floor(xf))
    y = Math.max(1.0, Math.floor(yf))
    x_size = Math.floor(width/x)
    y_size = Math.floor(height/y)
    tileSize = Math.min(x_size, y_size)

    # test our guess:
    x = Math.floor(width/tileSize)
    y = Math.floor(height/tileSize)
    if x*y < tileCount # we guessed too high
    
      if ((x+1)*y < tileCount) && (x*(y+1) < tileCount) 
        # case 2: the upper bound is correct
        #         compute the tileSize that will
        #         result in (x+1)*(y+1) tiles
        x_size = Math.floor(width/(x+1))
        y_size = Math.floor(height/(y+1))
        tileSize = Math.min(x_size, y_size)
      else
        # case 3: solve an equation to determine
        #         the final x and y dimensions
        #         and then compute the tileSize
        #         that results in those dimensions
        test_x = Math.ceil(tileCount/y)
        test_y = Math.ceil(tileCount/x)
        x_size = Math.min(Math.floor(width/test_x), Math.floor(height/y))
        y_size = Math.min(Math.floor(width/x), Math.floor(height/test_y))
        tileSize = Math.max(x_size, y_size)
      
    tileSize - 1


$(document).on "click", "a[href^='/']", (event) ->
  href = $(event.currentTarget).attr('href')
  target = $(event.currentTarget).attr('target')

  if target == '_blank' || href == '/newrelic'  || $(event.currentTarget).data('remote') # || href[1..9] == 'dashboard'
    return true

  # Allow shift+click for new tabs, etc.
  if !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
    event.preventDefault()
    # Instruct Backbone to trigger routing events
    ConsiderIt.navigate(href, { trigger : true })
    return false


#http://blog.colin-gourlay.com/blog/2012/02/safely-using-ready-before-including-jquery/
(($, d) ->
  $(f) for f, i in readyQ
  $(d).bind("ready",f) for f,i in bindReadyQ
)(jQuery, document)


window.ensure_el_in_view = ($el, amount_of_viewport_taken_by_el=.5, offset_buffer=50, scroll = true) ->
  el_top = $el.offset().top
  doc_top = $(window).scrollTop()
  doc_bottom = doc_top + $(window).height()
  #if less than 50% of the viewport is taken up by the el...
  in_viewport = el_top > doc_top && el_top < doc_bottom && (doc_bottom - el_top) > amount_of_viewport_taken_by_el * (doc_bottom - doc_top)  
  target = el_top - offset_buffer
  if !in_viewport
    if scroll
      distance_to_travel = Math.abs( doc_top - target )
      $('body').animate {scrollTop: target}, distance_to_travel
    else 
      $('body').scrollTop target

window.moveToTop = ($el, offset_buffer = 50, scroll = false) ->
  el_top = $el.offset().top
  target = el_top - offset_buffer
  doc_top = $(window).scrollTop()

  console.log el_top, $el
  if scroll
    distance_to_travel = Math.abs( doc_top - target )
    $('body').animate {scrollTop: target}, distance_to_travel
  else
    $('body').scrollTop target

