require './auth'

window.styles += """

"""

window.VerifyEmail = ReactiveComponent
  displayName: 'VerifyEmail'
  mixins: [AuthForm, Modal]

  render: -> 
    i18n = auth_translations()

    on_submit = (ev) =>
      @Submit ev,
        action: 'verify email'

    @Draw 
      task: translator 'auth.verify_email.heading', 'Verify Your Email'
      goal: if auth.goal then translator "auth.login_goal.#{auth.goal.toLowerCase()}", auth.goal
      on_submit: on_submit
      before_cancel: ->
        loadPage '/'
        setTimeout logout, 1

      DIV null,

        DIV
          style:
            color: auth_text_gray
            marginBottom: 18
          i18n.verification_sent_message

        @RenderInput
          label: i18n.code_label
          name: 'verification_code'
          on_submit: on_submit

        @ShowErrors()





















