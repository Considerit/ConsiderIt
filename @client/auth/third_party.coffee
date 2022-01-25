class OAuthHandler 
  constructor : (options = {}) ->
    provider = options.provider
    callback = options.callback

    if provider == 'google'
      provider = 'google_oauth2'

    @callback = callback
    @popup = @openPopupWindow "/auth/#{provider}"

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



OAuth_providers = ['google'] #['facebook', 'google']


# Mixin for authenticating via OAuth
window.OAuthLogin =

  startThirdPartyAuth : (provider) ->
    root = @root
    new OAuthHandler
      provider : provider
      callback : (new_data) => 
        # Yay we got a new current_user object!  But this hasn't gone
        # through the normal arest channel, so we gotta save it in
        # sneakily with updateCache()
        arest.updateCache(new_data)


        # poll the server until we have an avatar
        poll_until_avatar_arrives()





  WrapOAuth: (form, children) -> 
    DIV 
      style: 
        display: 'flex' 

      DIV 
        style: 
          flexGrow: 4
        children

      DIV 
        style: 
          flexGrow: 0
          marginLeft: 40
          borderLeft: "1px dashed #ccc"
          padding: "15px 0 0 40px"

        @RenderOAuthProviders(form)



  RenderOAuthProviders: (form) -> 
    current_user = fetch '/current_user'
    root = fetch 'root'


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


google_icon = (size) ->
  SVG 
    width: "#{size}px" 
    height: "#{size}px" 
    viewBox: "0 0 39 39" 

    dangerouslySetInnerHTML: __html: """
      <g id="auth" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
          <g id="btn_google_light_normal_ios" transform="translate(-24.000000, -23.000000)">
              <g id="logo_googleg_48dp" transform="translate(24.000000, 23.000000)">
                  <path d="M38.22,19.9431818 C38.22,18.5604546 38.0959091,17.2309091 37.8654545,15.9545454 L19.5,15.9545454 L19.5,23.4975 L29.9945455,23.4975 C29.5425,25.935 28.1686364,28.0002272 26.1034091,29.3829545 L26.1034091,34.2756819 L32.4054545,34.2756819 C36.0927272,30.8809092 38.22,25.8818181 38.22,19.9431818 L38.22,19.9431818 Z" id="Shape" fill="#4285F4" fill-rule="nonzero"></path>
                  <path d="M19.5,39 C24.765,39 29.1790908,37.2538636 32.4054545,34.2756819 L26.1034091,29.3829545 C24.3572728,30.5529545 22.1236364,31.2443181 19.5,31.2443181 C14.4211364,31.2443181 10.1222727,27.8140908 8.58886364,23.205 L2.07409091,23.205 L2.07409091,28.2572728 C5.28272728,34.6302272 11.8772727,39 19.5,39 L19.5,39 Z" id="Shape" fill="#34A853" fill-rule="nonzero"></path>
                  <path d="M8.58886364,23.205 C8.19886364,22.035 7.97727272,20.7852273 7.97727272,19.5 C7.97727272,18.2147727 8.19886364,16.965 8.58886364,15.795 L8.58886364,10.7427273 L2.07409091,10.7427273 C0.753409091,13.3752273 0,16.3534091 0,19.5 C0,22.6465908 0.753409091,25.6247728 2.07409091,28.2572728 L8.58886364,23.205 L8.58886364,23.205 Z" id="Shape" fill="#FBBC05" fill-rule="nonzero"></path>
                  <path d="M19.5,7.75568181 C22.3629545,7.75568181 24.9334092,8.73954545 26.9543181,10.6718182 L32.5472728,5.07886364 C29.1702272,1.93227273 24.7561364,0 19.5,0 C11.8772727,0 5.28272728,4.36977272 2.07409091,10.7427273 L8.58886364,15.795 C10.1222727,11.1859091 14.4211364,7.75568181 19.5,7.75568181 L19.5,7.75568181 Z" id="Shape" fill="#EA4335" fill-rule="nonzero"></path>
                  <polygon id="Shape" points="0 0 39 0 39 39 0 39"></polygon>
              </g>
          </g>
      </g>
    """



