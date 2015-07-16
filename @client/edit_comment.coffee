window.EditComment = ReactiveComponent
  displayName: 'EditComment'

  render : -> 
    permitted = permit 'create comment', @proposal

    DIV 
      className: 'comment_entry'

      

      # Comment author name
      DIV
        style:
          fontWeight: 'bold'
          color: '#666'
        (fetch('/current_user').name or 'You') + ':'

      # Icon
      Avatar
        style:
          position: 'absolute'
          width: 50
          height: 50
          backgroundColor: if permitted < 0 then 'transparent'
          border:          if permitted < 0 then '1px dashed grey'

        key: fetch('/current_user').user
        hide_tooltip: true

      if permitted == Permission.DISABLED
        SPAN 
          style: {position: 'absolute', margin: '14px 0 0 70px'}
          'Comments closed'

      else if permitted == Permission.INSUFFICIENT_PRIVILEGES
        SPAN 
          style: {position: 'absolute', margin: '14px 0 0 70px'}
          'Sorry, you do not have permission to comment'

      else if permitted < 0
        A
          style:
            position: 'absolute'
            margin: '14px 0 0 70px'
            cursor: 'pointer'
            zIndex: 1

          onTouchEnd: (e) => 
            e.stopPropagation()

          onClick: (e) =>
            e.stopPropagation()

            if permitted == Permission.NOT_LOGGED_IN
              reset_key 'auth', {form: 'login', goal: 'Write a Comment'}
            else if permitted == Permission.UNVERIFIED_EMAIL
              reset_key 'auth', {form: 'verify email', goal: 'Write a Comment'}
              current_user.trying_to = 'send_verification_token'
              save current_user

          if permitted == Permission.NOT_LOGGED_IN
            DIV null,
              SPAN 
                style: 
                  textDecoration: 'underline'
                  color: focus_blue
                  fontSize: if browser.is_mobile then 18
                'Log in to write a comment'
              if '*' not in @proposal.roles.commenter
                DIV style: {fontSize: 11},
                  'Only some email addresses are authorized to comment.'

          else if permitted == Permission.UNVERIFIED_EMAIL
            DIV null,
              SPAN
                style: { textDecoration: 'underline', color: focus_blue }
               'Verify your account'
              SPAN null, 'to write a comment'

      DIV 
        style: 
          marginLeft: 60   
                 
        AutoGrowTextArea
          ref: 'comment_input'
          placeholder: if permitted > 0 then 'Write a new comment' else ''
          disabled: permitted < 0
          onChange: (e) => @local.new_comment = e.target.value; save(@local)
          defaultValue: if @props.fresh then null else @data().body
          min_height: 80
          style:
            width: '100%'
            lineHeight: 1.4
            fontSize: if PORTRAIT_MOBILE() then 50 else if LANDSCAPE_MOBILE() then 30 else 16
            border: if permitted < 0 then 'dashed 1px'

      if permitted > 0

        Button 
          style: 
            marginLeft: 60
            padding: '8px 16px'
            fontSize: if browser.is_mobile then 24
          'data-action': 'save-comment'
          'Save comment'
          (e) =>
            e.stopPropagation()
            if @props.fresh
              comment =
                key: '/new/comment'
                body: @local.new_comment
                user: fetch('/current_user').user
                point: "/point/#{@props.point}"
            else
              comment = @data()
              comment.body = @local.new_comment
              comment.editing = false

            save comment, =>
              @local.new_comment = null
              save @local
            $(@refs.comment_input.getDOMNode()).val('')            

