@ConsiderIt.module "Auth.Register", (Register, App, Backbone, Marionette, $, _) ->

  class Register.Layout extends App.Views.Layout
    template: "#tpl_new_user"
    regions:
      authOptionsRegion : '.m-user-accounts-auth-options-region'
      completePaperworkRegion : '.m-user-accounts-complete-paperwork-form'

    dialog:
      title : 'Hi! How do you want to register?'

  class Register.FixedLayout extends Register.Layout

    dialog: -> 
      title : "Welcome, #{model.get('email')}! Please create an account."

  class Register.AuthOptions extends App.Views.ItemView
    template: "#tpl_auth_options"

    serializeData : -> 
      providers : @options.providers
      switch_label : 'Returning?'
      switch_prompt : 'Sign In'

    events:
      'click [data-target="third_party_auth"]' : 'thirdPartyAuthRequest'
      'click [data-provider="email"]' : 'emailAuthRequest'
      'click .m-user-accounts-switch-method' : 'switchMethod'

    switchMethod : ->
      @trigger 'switch_method_requested'

    thirdPartyAuthRequest : (ev) ->
      provider = $(ev.target).data('provider')
      @trigger 'third_party_auth_request', provider

    emailAuthRequest : (ev) ->
      @trigger 'email_auth_request'

  class Register.PaperworkLayout extends App.Views.Layout
    template: "#tpl_user_complete_paperwork"
    regions:
      cardRegion : '.m-user-accounts-complete-paperwork-card'
      pledgeRegion : '.m-user-accounts-complete-paperwork-pledge'
      footerRegion : '.m-user-accounts-complete-paperwork-footer'

  class Register.PaperworkView extends App.Views.ItemView
    template: "#tpl_user_paperwork_card"

    serializeData : -> 
      _.extend {}, @model.attributes, 
        auth_method : @model.auth_method()
        fixed : @options.fixed

    onShow : ->
      @$el.find('input[type="file"]').customFileInput()
      @$el.find('form').h5Validate({errorClass : 'error'})
      @$el.find('[placeholder]').simplePlaceholder() if !Modernizr.input.placeholder

      auth_method = @model.auth_method()
      if auth_method == 'email'
        @$el.find('.password_field').show() 
        if Modernizr.input.placeholder
          @$el.find('#user_name').focus() 
        else
          @$el.find('.password_field').prepend('<label for="user_password">Password</label>')


      else
        @$el.find('.password_field').hide()

      @$el.find('.import_from_third_party').hide() if auth_method in ['facebook', 'twitter']

      @stickit()      

      @updateAvatarFile @model.attributes.avatar_url


    bindings : 
      '.name_field input' : 'name'
      '.email_field input' : 'email'
      '.avatar_field .hide' : 
        observe : 'avatar_file_name'
        onGet : (values) ->
          return if !values? || $.trim(values)==''
          @$el('.avatar_field img.customfile-preview').attr('src', PaperClip.get_avatar_url(ConsiderIt.current_user, 'original', values))

    events : 
      'click [data-target="third_party_auth"]' : 'thirdPartyAuthRequest'

    thirdPartyAuthRequest : (ev) ->
      provider = $(ev.target).data('provider')
      @trigger 'third_party_auth_request', provider

    updateAvatarFile : (avatar_url) ->
      @$el.find('.customfile-preview').attr('src', avatar_url)
      @$el.find('.avatar_field input.avatar_url').val(avatar_url)

  class Register.PaperworkPledgeView extends App.Views.ItemView
    template: "#tpl_user_paperwork_pledge"

    events: 
      'change input[type="checkbox"]' : 'pledge_clicked'

    pledge_clicked : ->
      if @$el.find('input[type="checkbox"]').length == @$el.find('input[type="checkbox"]:checked').length
        $('.m-user-accounts-pledge-taken').fadeIn()
      else
        $('.m-user-accounts-pledge-taken').fadeOut()


  class Register.PaperworkFooterView extends App.Views.ItemView
    template: "#tpl_user_paperwork_footer"

    events:
      'ajax:complete form' : 'registrationReturned'
      'click .m-user-terms-show' : 'show_terms_of_use'

    registrationReturned : (ev, response, options) ->
      @trigger 'registration:returned', $.parseJSON(response.responseText)

    show_terms_of_use : ->
      @$el.find('.m-user-the-terms-of-use').slideToggle()

