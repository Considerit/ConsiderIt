class ConsiderIt.RegistrationView extends Backbone.View

  @new_user_template : _.template( $("#tpl_new_user").html() )

  initialize : (options) -> 
    @parent = options.parent

  render : () -> 
    if ConsiderIt.pinned_user?

      @$el.html(
        _.template($("#tpl_new_pinned_user").html(), $.extend({}, @model.attributes, {
          auth_method : if ConsiderIt.pinned_user? then ConsiderIt.pinned_user.auth_method() else null
        }))
      )
    else
      @$el.html(
        ConsiderIt.RegistrationView.new_user_template($.extend({}, @model.attributes, {
        }))
      )

    @$el.find('input[type="file"]').customFileInput()
    @$el.find('form').h5Validate({errorClass : 'error'});

    @$el.find('[placeholder]').simplePlaceholder()

    @state = 1
    @stickit()
    this

  handle_third_party_callback : (user_data) ->
    if @state == 1
      @finish_first_phase(user_data.user, ConsiderIt.current_user.auth_method())
    else if @state == 2
      @$el.find('.customfile-preview').attr('src', user_data.avatar_url)
      @$el.find('.avatar_field input.avatar_url').val(user_data.avatar_url)

  bindings : 
    '.name_field input' : 'name'
    '.email_field input' : 'email'
    '.avatar_field .hide' : 
      observe : 'avatar_file_name'
      onGet : (values) ->
        return if !values? || $.trim(values)==''
        $('.avatar_field img.customfile-preview').attr('src', PaperClip.get_avatar_url(ConsiderIt.current_user, 'original', values))

  events : 
    'ajax:complete form' : 'update_user'    
    'click .m-user-accounts-login-option a' : 'login_option_choosen'
    'click .m-user-accounts-cancel' : 'cancel'
    'change .m-user-accounts-pledge input' : 'pledge_clicked'
    'click .m-user-terms-show' : 'show_terms_of_use'

  pledge_clicked : ->
    if $('.m-user-accounts-pledge input').length == $('.m-user-accounts-pledge input:checked').length
      $('.m-user-accounts-pledge-taken').fadeIn()
    else
      $('.m-user-accounts-pledge-taken').fadeOut()

  login_option_choosen : (ev) ->
    choice = $(ev.currentTarget).data('provider')

    @second_phase(choice)


  finish_first_phase : (user_data, signin_method) ->
    ConsiderIt.update_current_user(user_data)

    if ConsiderIt.current_user.get('registration_complete')
      @remove()
    else
      @second_phase(signin_method)

  # new_user : (ev, response, options) ->
  #   console.log 'new user'
  #   data = $.parseJSON(response.responseText)

  #   if data.result == 'successful' || data.result == 'logged_in'
  #     console.log 'finished'
  #     @finish_first_phase(data, 'email')
  #   else if data.result == 'rejected' && data.reason == 'validation error'
  #     throw "Need to handle validation issues"
  #   else if data.result == 'rejected' && data.reason == 'user_exists'
  #     note = "<div class='note'>That email address is already taken.</div>"
  #     @$el.prepend(note)
  #   else 
  #     throw "Unrecognized return: #{data.result}, #{data.reason}"

  second_phase : (signin_method) ->
    @state = 2
    if signin_method != 'email'
      @$el.find('.password_field').hide()
    else
      @$el.find('.password_field').show()

    @$el.find(".m-user-accounts-authorized-feedback").hide()
    @$el.find(".m-user-accounts-authorized-feedback[data-provider='#{signin_method}']").show()

    @$el.find('.m-user-accounts-choose-method').hide()
    @$el.find('.m-user-accounts-complete').show()

    if signin_method == 'email'
      @$el.find('#user_name').focus()


  update_user : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    ConsiderIt.update_current_user(data.user.user)
    if not ConsiderIt.current_user.id of ConsiderIt.users
      ConsiderIt.users[ConsiderIt.current_user.id] = ConsiderIt.current_user
    @remove()

  cancel : () ->
    ConsiderIt.current_user.clear()
    @remove()

  show_terms_of_use : ->
    @$el.find('.m-user-the-terms-of-use').slideToggle()

