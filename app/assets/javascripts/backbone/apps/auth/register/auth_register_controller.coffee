@ConsiderIt.module "Auth.Register", (Register, App, Backbone, Marionette, $, _) ->

  class Register.Controller extends App.Controllers.Base

    initialize : (options = {}) ->
      @layout = @getRegisterLayout()
      @listenTo @layout, 'show', =>
        @setupLayout @layout

      @dialog_overlay = @getOverlay @layout

      @listenTo @dialog_overlay, 'dialog:canceled', =>
        App.request 'user:current:clear'
        @close()

      @listenTo App.vent, 'registration:complete_paperwork', =>
        @completePaperwork()

      @listenTo App.vent, 'user:signin', =>
        @close()

      if App.request 'user:fixed:exists'
        App.request 'registration:complete_paperwork', @        

    close : ->
      @dialog_overlay.close()
      @layout.close()
      super

    setupLayout : (layout) ->
      user = layout.model
      
      auth_options_view = new Register.AuthOptions
        model: user
        providers: [ {name: 'email', provider: 'email'}, {name: 'google', provider: "google_oauth2"}, {name: 'facebook', provider: 'facebook'}, {name: 'twitter', provider: 'twitter'} ]
        fixed : App.request 'user:fixed:exists'

      @listenTo auth_options_view, 'email_auth_request', ->
        App.request 'registration:complete_paperwork', @

      @listenTo auth_options_view, 'switch_method_requested', ->
        @close()
        App.vent.trigger 'signin:requested'

      layout.authOptionsRegion.show auth_options_view

      @listenTo auth_options_view, 'third_party_auth_request', @handleThirdPartyAuthRequest


    completePaperwork : () ->
      @layout.authOptionsRegion.close()
      paperwork_layout = @getPaperworkLayout @layout.model

      @listenTo paperwork_layout, 'show', =>

        @paperwork_view = new Register.PaperworkView
          model : @layout.model
          fixed : App.request 'user:fixed:exists'

        @listenTo @paperwork_view, 'show', =>
          @listenTo @paperwork_view, 'third_party_auth_request', @handleImportThirdPartyImage

        paperwork_layout.cardRegion.show @paperwork_view

        if App.request('tenant:get').get 'pledge_enabled'
          paperwork_pledge_view = new Register.PaperworkPledgeView
            model : @layout.model
          paperwork_layout.pledgeRegion.show paperwork_pledge_view

        paperwork_footer_view = new Register.PaperworkFooterView
          model : @layout.model

        @listenTo paperwork_footer_view, 'show', =>

        paperwork_layout.footerRegion.show paperwork_footer_view

        @listenTo paperwork_layout, 'registration:returned', @handleRegistrationResponse


      @layout.completePaperworkRegion.show paperwork_layout

    handleThirdPartyAuthRequest : (provider) ->

      App.request 'third_party_auth:new',
        provider : provider
        callback : (user_data) =>
          App.request "user:signin", user_data, @

    handleImportThirdPartyImage : (provider) ->
      App.request 'third_party_auth:new',
        provider : provider
        callback : (user_data) =>
          avatar = user_data.user.avatar_url || user_data.user.avatar_remote_url
          @paperwork_view.updateAvatarFile avatar


    handleRegistrationResponse : (data) =>
      if data.result == 'successful' 
        App.request 'user:signin', data.user
      else if data.result == 'rejected' && data.reason == 'user_exists'
        toastr.error 'An account with that same email address already exists. Please sign in instead.'
      else
        toastr.error 'Sorry, we could not create your account. Please email travis@consider.it if the problem persists.'

    getOverlay : (view) ->
      App.request 'dialog:new', view, 
        class: 'auth_overlay'

    getUser : ->
      if App.request 'user:fixed:exists'
        App.request 'user:fixed'
      else
        App.request 'user:current'

    getRegisterLayout : ->
      new Register.Layout
        model: @getUser()

    getPaperworkLayout : (user) ->
      new Register.PaperworkLayout
        model: user
