class ThirdPartyAuthHandler 
  constructor : (options = {}) ->
    provider = options.provider
    callback = options.callback

    if provider == 'google'
      provider = 'google_oauth2'

    # vanity_url = location.host.split('.').length == 1 || location.host.split(':')[0] == '127.0.0.1'
    # if !vanity_url
    #   document.domain = location.host.replace(/^.*?([^.]+\.[^.]+)$/g,'$1') 
    # else 
    #   document.domain = document.domain # make sure it is explitly set

    @callback = callback
    @popup = @openPopupWindow "/auth/#{provider}"

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
      try 
        @pollLoginPopup()
      catch e
        console.log "Could not access popup", e

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



OAuth_providers = ['facebook', 'google']


# Mixin for authenticating via OAuth
window.OAuthLogin =

  startThirdPartyAuth : (provider) ->
    root = @root
    new ThirdPartyAuthHandler
      provider : provider
      callback : (new_data) => 
        # Yay we got a new current_user object!  But this hasn't gone
        # through the normal arest channel, so we gotta save it in
        # sneakily with updateCache()
        arest.updateCache(new_data)

        # We know that the user has authenticated, but we don't know
        # whether they've completed OUR registration process including
        # the pledge.  The server tells us this via the existence of a
        # `user' object in current_user.

        # current_user = fetch '/current_user'
        # if current_user.logged_in
        #   # We are logged in!  The user has completed registration.
        #   @authCompleted()

        # else 
        #   # We still need to show the pledge!
        #   root.auth_mode = 'register'
        #   save(root)

  RenderOAuthProviders: -> 
    current_user = fetch '/current_user'
    root = fetch 'root'


    third_party_authenticated = current_user.facebook_uid || current_user.twitter_uid || current_user.google_uid

    return SPAN(null) if current_user.provider || third_party_authenticated


    DIV className: 'third_party_auth',
      LABEL 
        style: {marginRight: 18}
        'Instantly:'
      for provider in OAuth_providers
        do (provider) =>
          BUTTON 
            key: provider
            className: "third_party_option #{provider}"
            onClick: => 
              @startThirdPartyAuth(provider)

            I className: "fa fa-#{provider}"
            SPAN null, provider



styles += """
.third_party_option {
  border: 1px solid #777777;
  border-color: rgba(0, 0, 0, 0.2);
  border-bottom-color: rgba(0, 0, 0, 0.4);
  color: white;
  box-shadow: inset 0 0.1em 0 rgba(255, 255, 255, 0.4), inset 0 0 0.1em rgba(255, 255, 255, 0.9);
  display: inline-block;
  padding: 3px 9px 3px 34px;
  margin: 0 4px;
  text-align: center;
  text-shadow: 0 1px 0 rgba(0, 0, 0, 0.5);
  border-radius: 0.3em;
  position: relative;
  background-color: #{focus_blue}; }
.third_party_option:hover {
  background-color: #19528b; }
.third_party_option:before {
  border-right: 0.075em solid rgba(0, 0, 0, 0.1);
  box-shadow: 0.075em 0 0 rgba(255, 255, 255, 0.25);
  content: "";
  position: absolute;
  top: 0;
  left: 25px;
  height: 100%;
  width: 1px; }
.third_party_option i {
  margin-right: 18px;
  display: inline-block;
  font-size: 16px;
  position: absolute;
  left: 9px; }
.third_party_option span {
  font-weight: 600;
  font-size: 12px; }

"""


