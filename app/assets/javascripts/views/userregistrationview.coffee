class ConsiderIt.RegistrationView extends Backbone.View

  @new_user_template : _.template( $("#tpl_new_user").html() )

  initialize : (options) -> 
    @parent = options.parent

  render : () -> 
    if ConsiderIt.limited_user?

      @$el.html(
        _.template($("#tpl_new_limited_user").html(), $.extend({}, @model.attributes, {
          auth_method : if ConsiderIt.limited_user? then ConsiderIt.limited_user.auth_method() else null
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

    @signin_method = null
    @stickit()
    this

  handle_third_party_callback : (user_data) ->
    if !@signin_method
      @finish_first_phase(user_data)
    else
      # if using third party auth method to get profile picture
      console.log user_data
      @update_avatar_file(user_data.user.avatar_url || user_data.user.avatar_remote_url)

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

  update_avatar_file : (avatar_url) ->
    @$el.find('.customfile-preview').attr('src', avatar_url)
    @$el.find('.avatar_field input.avatar_url').val(avatar_url)

  pledge_clicked : ->
    if $('.m-user-accounts-pledge input').length == $('.m-user-accounts-pledge input:checked').length
      $('.m-user-accounts-pledge-taken').fadeIn()
    else
      $('.m-user-accounts-pledge-taken').fadeOut()

  login_option_choosen : (ev) ->
    choice = $(ev.currentTarget).data('provider')
    @second_phase(choice) if choice == 'email'


  finish_first_phase : (user_data) ->
    ConsiderIt.update_current_user(user_data)

    if ConsiderIt.current_user.get('registration_complete')
      @remove()
    else
      @second_phase(ConsiderIt.current_user.auth_method())

  second_phase : (signin_method) ->
    @signin_method = signin_method

    @$el.find('.password_field').hide() if signin_method != 'email'
    @$el.find('.password_field').show() if signin_method == 'email'

    @$el.find(".m-user-accounts-authorized-feedback").hide()
    @$el.find(".m-user-accounts-authorized-feedback[data-provider='#{signin_method}']").show()

    @$el.find('.m-user-accounts-choose-method').hide()

    if @signin_method in ['facebook', 'twitter']
      @$el.find('.import_from_third_party').hide()    
    @$el.find('.m-user-accounts-complete').show()

    @update_avatar_file(ConsiderIt.current_user.attributes.avatar_url)

    if signin_method == 'email'
      @$el.find('#user_name').focus()


  update_user : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    ConsiderIt.update_current_user(data.user)
    if not ConsiderIt.current_user.id of ConsiderIt.users
      ConsiderIt.users[ConsiderIt.current_user.id] = ConsiderIt.current_user
    @remove()

  cancel : () ->
    ConsiderIt.current_user.clear()
    @remove()

  show_terms_of_use : ->
    @$el.find('.m-user-the-terms-of-use').slideToggle()

