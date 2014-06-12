@ConsiderIt.module "Helpers.ThirdPartyAuth", (ThirdPartyAuth, App, Backbone, Marionette, $, _) ->
  class ThirdPartyAuth.ThirdPartyAuthController extends App.Controllers.Base
    
    initialize : (options = {}) ->
      provider = options.provider

      if provider == 'twitter'
        url = Routes.user_omniauth_authorize_path provider,
          x_auth_access_type : 'read'
      else
        url = Routes.user_omniauth_authorize_path provider

      @callback = options.callback
      @popup = @openPopupWindow(url)

    handleOpenIdResponse : (parameters) ->  
      parameters.user = parameters.user.user
      @callback parameters
      #ConsiderIt.app.vent 'auth:third_party_auth', parameters
      #ConsiderIt.app.usermanagerview.handle_third_party_callback(parameters)

    pollLoginPopup : ->
      if @popup? && @popup.location && window.location && window.location.origin == @popup.location.origin && @popup.open_id_params?
        @handleOpenIdResponse(@popup.open_id_params)
        @popup.close()
        @popup = null
        clearInterval(@polling_interval)

    openPopupWindow : (url) ->
      openidpopup = window.open(url, 'openid_popup', 'width=450,height=500,location=1,status=1,resizable=yes')
      openidpopup.open_id_params = null
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


  App.reqres.setHandler "third_party_auth:new", (options = {}) ->

    @controller = new ThirdPartyAuth.ThirdPartyAuthController options

    @controller