class ThirdPartyAuthHandler 
  constructor : (options = {}) ->
    provider = options.provider
    callback = options.callback

    if provider == 'google'
      provider = 'google_oauth2'
      
    vanity_url = location.host.split('.').length == 1
    if !vanity_url
      document.domain = location.host.replace(/^.*?([^.]+\.[^.]+)$/g,'$1') 
    else 
      document.domain = document.domain # make sure it is explitly set


    if provider == 'twitter'
      url = Routes.user_omniauth_authorize_path provider,
        x_auth_access_type : 'read'
    else
      url = Routes.user_omniauth_authorize_path provider

    @callback = callback
    @popup = @openPopupWindow(url)

  pollLoginPopup : ->
    # try
    if @popup? && @popup.document && window.document && window.document.domain == @popup.document.domain && @popup.current_user_hash?
      @callback @popup.current_user_hash
      @popup.close()
      @popup = null
      clearInterval(@polling_interval)
    # catch e
    #   console.error e

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
