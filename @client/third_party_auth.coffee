class ThirdPartyAuthHandler 
  constructor : (options = {}) ->
    provider = options.provider
    callback = options.callback

    if provider == 'google'
      provider = 'google_oauth2'

    if provider == 'twitter'
      url = Routes.user_omniauth_authorize_path provider,
        x_auth_access_type : 'read'
    else
      url = Routes.user_omniauth_authorize_path provider

    @callback = callback
    @popup = @openPopupWindow(url)

  pollLoginPopup : ->
    if @popup? && @popup.location && window.location && window.location.origin == @popup.location.origin && @popup.current_user_hash?
      @callback @popup.current_user_hash
      @popup.close()
      @popup = null
      clearInterval(@polling_interval)

  openPopupWindow : (url) ->
    openidpopup = window.open(url, 'openid_popup', 'width=450,height=500,location=1,status=1,resizable=yes')
    openidpopup.current_user_hash = null
    coords = @getCenteredCoords(450,500)  
    openidpopup.moveTo(coords[0],coords[1])
    @polling_interval = setInterval => 
      @pollLoginPopup()
    , 200

    openidpopup

  getCenteredCoords : (width, height) ->
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
    yPos = 100
    [xPos, yPos]

window.ThirdPartyAuthHandler = ThirdPartyAuthHandler
