@ConsiderIt.module "Auth.Register", (Register, App, Backbone, Marionette, $, _) ->

  class Register.RegisterController extends App.Controllers.Base

    initialize : (options = {}) ->

      @layout = @getLayout()

      @listenTo @layout, 'show', =>
        @setupLayout @layout

      @dialog_overlay = @getOverlay @layout

      @listenTo @dialog_overlay, 'dialog:canceled', =>
        App.request 'user:current:clear'
        App.vent.trigger 'user:signin:canceled'
        @close()

      @listenTo App.vent, 'user:signin', =>
        @close()

    close : ->
      @dialog_overlay.close()
      @layout.close()
      super

    setupLayout : (layout) ->
      @paperwork_view = new Register.PaperworkView
        model : @layout.model
        fixed : App.request 'user:fixed:exists'
        params : @options.params


      @listenTo @paperwork_view, 'show', =>
        @listenTo @paperwork_view, 'third_party_auth_request', @handleImportThirdPartyImage

      layout.cardRegion.show @paperwork_view

      if App.request('tenant').get 'requires_civility_pledge_on_registration'
        paperwork_pledge_view = new Register.PaperworkPledgeView
          model : @layout.model
        layout.pledgeRegion.show paperwork_pledge_view

      paperwork_footer_view = new Register.PaperworkFooterView
        model : @layout.model

      @listenTo paperwork_footer_view, 'show', =>

      layout.footerRegion.show paperwork_footer_view

      @listenTo layout, 'registration:returned', @handleRegistrationResponse


    handleImportThirdPartyImage : (provider) ->
      App.request 'third_party_auth:new',
        provider : provider
        callback : (user_data) =>
          avatar = user_data.user.avatar_url || user_data.user.avatar_remote_url
          @paperwork_view.updateAvatarFile avatar


    handleRegistrationResponse : (data) ->
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
        [App.request('user:fixed'), true]
      else
        [App.request('user:current'), false]

    getLayout : ->
      [user, is_fixed] = @getUser()
      if is_fixed
        new Register.FixedLayout
          model: user
      else
        new Register.PaperworkLayout
          model: user
