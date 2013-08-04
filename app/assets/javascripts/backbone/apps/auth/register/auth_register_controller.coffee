@ConsiderIt.module "Auth.Register", (Register, App, Backbone, Marionette, $, _) ->

  class Register.Controller extends App.Controllers.Base

    initialize : (options = {}) ->
      @layout = @getRegisterLayout()
      @listenTo @layout, 'show', =>
        @setupLayout @layout

      @dialog_overlay = @getOverlay @layout

      @listenTo @dialog_overlay, 'dialog:canceled', =>
        ConsiderIt.current_user.clear()
        @close()

      @listenTo App.vent, 'registration:complete_paperwork', =>
        @completePaperwork()

      @listenTo App.vent, 'user:signin', =>
        @close()

    close : ->
      @dialog_overlay.close()
      @layout.close()
      super

    setupLayout : (layout) ->
      user = layout.model

      if App.request 'user:fixed:exists'
        if user.auth_method() == 'email'
          email_view = @setupEmailView
            model: user
            fixed: third_party_auth_request
          layout.emailAuthRegion.show email_view

        else
          auth_options_view = new Register.AuthOptions
            model: user
            providers: [ {name: user.auth_method()} ]
          layout.authOptionsRegion.show auth_options_view

      else
        
        auth_options_view = new Register.AuthOptions
          model: user
          providers: [ {name: 'email'}, {name: 'google'}, {name: 'facebook'}, {name: 'twitter'} ]

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

        @listenTo @paperwork_view, 'third_party_auth_request', @handleImportThirdPartyImage

        paperwork_layout.cardRegion.show @paperwork_view

        if App.request('tenant:get').get 'pledge_enabled'
          paperwork_pledge_view = new Register.PaperworkPledgeView
            model : @layout.model
          paperwork_layout.pledgeRegion.show paperwork_pledge_view

        paperwork_footer_view = new Register.PaperworkFooterView
          model : @layout.model

        @listenTo paperwork_footer_view, 'registration:returned', @handleRegistrationResponse
        paperwork_layout.footerRegion.show paperwork_footer_view

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
        ConsiderIt.utils.update_CSRF data.new_csrf
      else
        # TODO: handle gracefully
        throw 'Registration rejected from server'        

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

      # signinview.render()
      # signinview.$el.bind 'destroyed', () => 
      #   App.request 'dialog:close'
      #   #@post_signin()

      #signinview

    getPaperworkLayout : (user) ->
      new Register.PaperworkLayout
        model: user
