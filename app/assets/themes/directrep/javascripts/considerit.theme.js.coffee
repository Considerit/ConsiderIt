_.templateSettings =  
  interpolate : /\{\{(.+?)\}\}/g
  evaluate : /\(\((.+?)\)\)/g

#_.extend(ConsiderIt, {Models: {}, Collections: {}, Views: {}})


window.PaperClip =
  get_avatar_url : (user, size, fname) ->
    if fname?
      "/system/avatars/#{user.id}/#{size}/#{fname}"
    else if user.get('avatar_file_name')
      "/system/avatars/#{user.id}/#{size}/#{user.get('avatar_file_name')}"
    else
      "/system/default_avatar/#{size}_default-profile-pic.png"

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
      
    tileSize


window.ConsiderIt.update_current_user = (parameters) ->
  if parameters.id of ConsiderIt.users
    ConsiderIt.current_user = ConsiderIt.users[parameters.id]

  ConsiderIt.current_user.set(parameters)

window.getCenteredCoords = (width, height) ->
  if (window.ActiveXObject)
    xPos = window.event.screenX - (width/2) + 100
    yPos = window.event.screenY - (height/2) - 100
  else
    parentSize = [window.outerWidth, window.outerHeight]
    parentPos = [window.screenX, window.screenY]
    xPos = parentPos[0] +
        Math.max(0, Math.floor((parentSize[0] - width) / 2))
    yPos = parentPos[1] +
        Math.max(0, Math.floor((parentSize[1] - (height*1.25)) / 2))
  
  [xPos, yPos]

window.openPopupWindow = (url) ->
  window.openidpopup = window.open(url, 'openid_popup', 'width=450,height=500,location=1,status=1,resizable=yes')
  coords = getCenteredCoords(450,500)  
  openidpopup.moveTo(coords[0],coords[1])

window.handleOpenIdResponse = (parameters, redirect_to) ->
  ConsiderIt.app.usermanagerview.handle_third_party_callback(parameters)


$.event.special.destroyed =
  remove: (o) ->
    if o.handler
      o.handler()    


$(document).on "click", "a[href^='/']", (event) ->
  href = $(event.currentTarget).attr('href')

  # Allow shift+click for new tabs, etc.
  if !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
    event.preventDefault()
    # Instruct Backbone to trigger routing events
    ConsiderIt.router.navigate(href, { trigger : true })
    return false
  
        
