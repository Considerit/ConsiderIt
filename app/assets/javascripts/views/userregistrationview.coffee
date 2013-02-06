class ConsiderIt.RegistrationView extends Backbone.View

  @new_user_template : _.template( $("#tpl_new_user").html() )

  initialize : (options) -> 
    @parent = options.parent

  render : () -> 
    @$el.html(
      ConsiderIt.RegistrationView.new_user_template($.extend({}, @model.attributes, {

      }))
    )
    @$el.find('input[type="file"]').customFileInput()
    @$el.find('form').h5Validate({errorClass : 'error'});

    @stickit()
    this

  bindings : 
    '#site_registration .name_field input' : 'name'
    '#site_registration .email_field input' : 'email'
    '#identity .name_field input' : 'name'
    '#identity .email_field input' : 'email'    
    '#identity .avatar_field .selected_file' : 
      observe : 'avatar_file_name'
      onGet : (values) ->
        return if !values? || $.trim(values)==''
        $('.avatar_field .customfile-feedback').text(values)
        $('.avatar_field img.customfile-preview').attr('src', PaperClip.get_avatar_url(ConsiderIt.current_user, 'medium', values))


  events : 
    'ajax:complete .firstphase form' : 'new_user'
    'ajax:complete .secondphase form' : 'update_user'
    'click .firstphase .cancel' : 'first_phase_cancel'
    'click .secondphase .cancel' : 'second_phase_cancel'


  finish_first_phase : (user_data) ->
    ConsiderIt.update_current_user(user_data)
    if ConsiderIt.current_user.get('registration_complete')
      @remove()
    else
      @second_phase()

  new_user : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    if data.result == 'successful' || data.result == 'logged_in'
      @finish_first_phase(data)
    else if data.result == 'rejected' && data.reason == 'validation error'
      throw "Need to handle validation issues"
    else if data.result == 'rejected' && data.reason == 'user_exists'
      note = "<div class='note'>That email address is already taken.</div>"
      @$el.prepend(note)
    else 
      throw "Unrecognized return: #{data.result}, #{data.reason}"

  second_phase : () ->
    @$el.find('.firstphase').slideUp()
    @$el.find('.secondphase').slideDown()

  update_user : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    ConsiderIt.update_current_user($.parseJSON(data.user).user)
    @remove()

  cancel : () ->
    ConsiderIt.current_user.clear()
    @remove()

  first_phase_cancel : (ev) ->
    @cancel()

  second_phase_cancel : (ev) ->
    if ConsiderIt.current_user.get('registration_complete')
      $.get Routes.destroy_user_session_path(), (data) =>
        ConsiderIt.utils.update_CSRF(data.new_csrf)

    else
      $.ajax
        url : Routes.user_registration_path()
        type : 'DELETE'
        success : (data) =>
          ConsiderIt.utils.update_CSRF(data.new_csrf)

    @cancel()
