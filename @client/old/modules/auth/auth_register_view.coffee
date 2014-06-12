@ConsiderIt.module "Auth.Register", (Register, App, Backbone, Marionette, $, _) ->

  class Register.PaperworkLayout extends App.Views.Layout
    dialog:
      title : 'Please finish your registration'

    className : 'user-accounts-complete-paperwork-form'
    template: "#tpl_user_complete_paperwork"
    regions:
      cardRegion : '.user-accounts-complete-paperwork-card'
      pledgeRegion : '.user-accounts-complete-paperwork-pledge'
      footerRegion : '.user-accounts-complete-paperwork-footer'

    events:
      'ajax:complete form' : 'registrationReturned'
      'validated #user_email,#user_password,#user_name,input[type="checkbox"]' : 'checkIfSubmitEnabled'

    onShow : ->
      @$el.find('form').h5Validate({errorClass : 'error', keyup : true})
      @triggerValidationCheck()
      @checkIfSubmitEnabled true

    triggerValidationCheck : ->
      $email_field = @$el.find('#user_email')
      $name_field = @$el.find('#user_name')
      $password_field = @$el.find('#user_password')

      $email_field.focusout()
      $password_field.focusout()
      $name_field.focusout()

    checkIfSubmitEnabled : (manual_overdrive = false) ->
      $email_field = @$el.find('#user_email')
      $name_field = @$el.find('#user_name')
      $password_field = @$el.find('#user_password')

      pledges_checked = @$el.find('input[type="checkbox"]').length == @$el.find('input[type="checkbox"]:checked').length

      $submit_button_register = @$el.find('.user-accounts-complete-paperwork-footer input[type="submit"]')

      if pledges_checked && $email_field.is('.ui-state-valid') && $name_field.is('.ui-state-valid') && ($password_field.is('.ui-state-valid') || @model.authMethod() != 'email')
        $submit_button_register.removeAttr('disabled')
      else 
        $submit_button_register.attr 'disabled', 'true'

    registrationReturned : (ev, response, options) ->
      @trigger 'registration:returned', $.parseJSON(response.responseText)

  class Register.FixedLayout extends Register.PaperworkLayout

    dialog: -> 
      title : "Hi! Please create an account."

  class Register.PaperworkView extends App.Views.ItemView
    template: "#tpl_user_paperwork_card"

    serializeData : -> 
      _.extend {}, @model.attributes,
        auth_method : @model.authMethod()
        fixed : @options.fixed

    onShow : ->
      @$el.find('input[type="file"]').customFileInput()

      @$el.find('#user_email[placeholder]').simplePlaceholder() if !Modernizr.input.placeholder

      if !@options.fixed && 'email' of @options.params
        @model.set 'email', @options.params.email

      auth_method = @model.authMethod()
      if auth_method == 'email'
        @$el.find('.password_field').show() 
        if !Modernizr.input.placeholder
          #IE hack
          @$el.find('.name_field').prepend('<label for="user_name">Your name</label>')
          @$el.find('.email_field').prepend('<label for="user_email">Email address</label>')
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
          @$el.find('.avatar_field img.customfile-preview').attr('src', App.request("user:current:avatar", 'original', values))

    events : 
      'click [action="third_party_auth"]' : 'thirdPartyAuthRequest'


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
        $('.user-accounts-pledge-taken').fadeIn()
      else
        $('.user-accounts-pledge-taken').fadeOut()


  class Register.PaperworkFooterView extends App.Views.ItemView
    template: "#tpl_user_paperwork_footer"

