#window.ConsiderIt = {} #global namespace for ConsiderIt js methods

_.templateSettings =  
  interpolate : /\{\{(.+?)\}\}/g
  evaluate : /\(\((.+?)\)\)/g

#X-Editable option
$.fn.editable.defaults.mode = 'inline'

window.delay = (ms, func) -> setTimeout func, ms


window.PaperClip =
  get_avatar_url : (user, size, fname) ->
    if fname?
      "#{ConsiderIt.public_root}/system/avatars/#{user.id}/#{size}/#{fname}"
    else if user? && user.get('avatar_file_name')
      "#{ConsiderIt.public_root}/system/avatars/#{user.id}/#{size}/#{user.get('avatar_file_name')}"
    else
      "#{ConsiderIt.public_root}/system/default_avatar/#{size}_default-profile-pic.png"

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





# http://danielarandaochoa.com/backboneexamples/blog/2012/08/02/backbone-view-listening-for-a-remove-event-the-missing-item/
$.event.special.destroyed =
  remove: (o) -> o.handler() if o.handler
          
$(document).on "click", "a[href^='/']", (event) ->
  href = $(event.currentTarget).attr('href')
  target = $(event.currentTarget).attr('target')

  if target == '_blank' || href == '/newrelic'  || $(event.currentTarget).data('remote') # || href[1..9] == 'dashboard'
    return true

  # Allow shift+click for new tabs, etc.
  if !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
    event.preventDefault()
    # Instruct Backbone to trigger routing events
    ConsiderIt.router.navigate(href, { trigger : true })
    return false


#http://blog.colin-gourlay.com/blog/2012/02/safely-using-ready-before-including-jquery/
(($, d) ->
  $(f) for f, i in readyQ
  $(d).bind("ready",f) for f,i in bindReadyQ
)(jQuery, document)


String.prototype.toCamel = -> @replace(/(\-[a-z])/g, ($1) -> $1.toUpperCase().replace('-','')  )

String.prototype.toUnderscore = -> @replace(/([A-Z])/g, ($1) -> "_" + $1.toLowerCase() )


window.ensure_el_in_view = ($el, amount_of_viewport_taken_by_el=.5, offset_top=100) ->
  el_top = $el.offset().top
  doc_top = $(window).scrollTop()
  doc_bottom = doc_top + $(window).height()
  #if less than 50% of the viewport is taken up by the el...
  in_viewport = el_top > doc_top && el_top < doc_bottom && (doc_bottom - el_top) > amount_of_viewport_taken_by_el * (doc_bottom - doc_top)  
  target = el_top - offset_top
  distance_to_travel = Math.abs( doc_top - target )
  if !in_viewport
    $('body').animate {scrollTop: target}, distance_to_travel
