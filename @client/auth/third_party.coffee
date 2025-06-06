class OAuthHandler 
  constructor : (options = {}) ->
    provider = options.provider
    callback = options.callback

    if provider == 'google'
      provider = 'google_oauth2'

    @callback = callback

    @popup = @openPopupWindow "#{location.protocol}//#{bus_fetch('/subdomain').host}/auth/#{provider}"  

  openPopupWindow : (url) ->
    openidpopup = window.open(url, 'openid_popup', 'width=450,height=500,location=1,status=1,resizable=yes')
    openidpopup.current_user_hash = null
    coords = @getCenteredCoords(450,500)  
    openidpopup.moveTo(coords[0],coords[1])

    cb = (event) =>
      return if event.source != openidpopup
      @callback event.data
      window.removeEventListener "message", cb

    window.addEventListener "message", cb, false
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



OAuth_providers = ['google'] # ['facebook', 'google']

styles += """
  .oauth_wrapper {
    display: flex;
  }

  .oauth_child_wrapper {
    flex-grow: 4;
  }

  .oauth_providers_wrapper {
    flex-grow: 0;
  }


  @media (min-width: 637px) {
    .oauth_wrapper {

    }

    .oauth_child_wrapper {

    }

    .oauth_providers_wrapper {
      border-left: 1px dashed #ccc;
      margin-left: 40px;
      padding: 15px 0 0 40px;
    }
  }

  @media (max-width: 637px) {
    .oauth_wrapper {
      flex-direction: column;
    }

    .oauth_child_wrapper {

    }

    .oauth_providers_wrapper {
      margin-top: 24px;
    }
  }

"""

# Mixin for authenticating via OAuth
window.OAuthLogin =

  startThirdPartyAuth : (provider) ->
    root = bus_fetch('root')
    new OAuthHandler
      provider : provider
      callback : (new_data) =>

        # Yay we got a new current_user object!  But this hasn't gone
        # through the normal arest channel, so we gotta save it in
        # sneakily with updateCache()
        arest.updateCache(new_data)

        #######################
        # If the subdomain has a vanity url, after logging in via oauth, 
        # we need to replay the login in third party auth. This is because 
        # the third party login was successful at the session of the consider.it 
        # domain, but not on the custom domain. To get around this, when a 
        # vanity url is used, the user will be given a single use secure code 
        # (via user.add_token), which is then passed here in new_data
        # from current_user_controller#update_via_third_party. We'll then 
        # replay the login from the vanity url to login in the current session, 
        # using the single use code to authenticate. See also references to 
        # oauth_single_use_code in current_user_controller#update. 

        subdomain = bus_fetch('/subdomain')
        if subdomain.custom_url
          current_user = bus_fetch '/current_user'
          current_user.trying_to = 'login'
          save current_user

        #####################


        # poll the server until we have an avatar
        poll_until_avatar_arrives()

        if forum_has_host_questions() && bus_fetch('/current_user').first_visit_to_forum
          auth = bus_fetch 'auth'
          auth.show_user_questions_after_account_creation = true 
          save auth



  WrapOAuth: (form, children) -> 
    DIV 
      className: 'oauth_wrapper'

      DIV 
        className: 'oauth_child_wrapper'
        children

      DIV 
        className: 'oauth_providers_wrapper'

        @RenderOAuthProviders(form)



  RenderOAuthProviders: (form) -> 
    current_user = bus_fetch '/current_user'
    root = bus_fetch 'root'


    third_party_authenticated = current_user.facebook_uid || current_user.twitter_uid || current_user.google_uid

    return SPAN(null) if current_user.provider || third_party_authenticated


    DIV 
      className: 'third_party_auth',
      LABEL null, 
        if form == 'create_account'
          translator 'auth.oauth.options_create-account', 'Or sign up using:'
        else 
          translator 'auth.oauth.options_login', 'Or log in using:'

      
      for provider in OAuth_providers
        do (provider) =>
          BUTTON 
            key: provider
            className: "third_party_option #{provider}"
            onClick: => 
              @startThirdPartyAuth(provider)

            if provider == 'google'
              google_icon(22)
            else 
              I className: "fa fa-#{provider}"
            SPAN null, provider



styles += """
.third_party_auth {
  max-width: 75px;
}
.third_party_auth label {
  font-size: 12px;
  margin-bottom: 12px;
  display: block;
  white-space: nowrap;
}
.third_party_option.facebook span {
  position: relative; 
  left: 12px;
}
.third_party_option {
  border: 1px solid #bbb;
  color: black;
  width: 120px;
  padding: 8px 0px;
  margin-bottom: 12px;
  text-align: center;
  border-radius: 4px;
  position: relative;
  font-size: 11px;
  text-transform: capitalize;
  background-color: transparent;
}

.third_party_option svg {
  vertical-align: middle;
  position: relative; 
  left: -14px;
}

.third_party_option i {
  display: inline-block;
}

.third_party_option i.fa-facebook {
  color: #3C5997;
  font-size: 24px;
  position: relative;
  left: -8px;
  vertical-align: middle;
}

"""





