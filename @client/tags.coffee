

UserTags = ReactiveComponent
  displayName: 'UserTags'

  render : -> 
    subdomain = fetch '/subdomain'
    users = fetch '/users'

    current_user = if @local.current_user then fetch(@local.current_user)

    change_current_user = (new_user) => 
      @local.new_tags = {}
      @local.current_user = new_user

      current_user = if @local.current_user then fetch(@local.current_user)
      if current_user
        for k,v of all_tags 
          if !current_user.tags[k]?
            @local.new_tags[k] = ""
      save @local


    all_tags = {}
    for user in users.users
      if user.tags? && Object.keys(user.tags).length > 0
        for tag,val of user.tags 
          all_tags[tag] ||= []
          all_tags[tag].push user 
      else 
        all_tags['no tags'] ||= []
        all_tags['no tags'].push user

    all_tags

    DIV 
      style: 
        padding: 50

      DIV 
        style: 
          marginBottom: 12

        H1 style: {fontSize: 28}, 
          "User tags"


      # Text input for adding new people to a role
      DIV null,
        INPUT 
          id: 'filter'
          type: 'text'
          style: {fontSize: 18, width: 350, padding: '3px 6px'}
          autoComplete: 'off'
          placeholder: "Name or email..."
          value: if current_user then current_user.name
          onChange: => 
            @local.filtered = $(@getDOMNode()).find('#filter').val()
            change_current_user null 
            save(@local)
          onKeyPress: (e) => 
            # enter key pressed...
            if e.which == 13
              e.preventDefault()
              change_current_user @local.hovered_user
              save @local
          onFocus: (e) => 
            @local.selecting = true
            save(@local)
            e.stopPropagation()
            $(document).on 'click.tags', (e) =>
              if e.target.id != 'filter'
                @local.selecting = false
                save @local
                $(document).off('click.tags')
            return false

      # Dropdown, autocomplete menu for adding existing users
      if @local.selecting
        available_users = _.filter users.users, (u) => 
            u.key != @local.current_user &&
             (!@local.filtered || 
              "#{u.name} <#{u.email}>".indexOf(@local.filtered) > -1)

        if available_users.length > 0
          UL 
            style: 
              width: 500
              position: 'absolute'
              zIndex: 99
              listStyle: 'none'
              backgroundColor: '#fff'
              border: '1px solid #eee'

            for user,idx in available_users
              do (user) => 
                LI 
                  className: 'invite_menu_item'
                  style: 
                    padding: '2px 12px'
                    fontSize: 18
                    cursor: 'pointer'
                    borderBottom: '1px solid #fafafa'
                  key: idx

                  onMouseEnter: (e) =>
                    @local.hovered_user = user.key
                    save @local
                  onMouseLeave: (e) => @local.hovered_user = null; save @local 

                  onClick: (e) => 
                    change_current_user @local.hovered_user
                    e.stopPropagation()

                  "#{user.name} <#{user.email}>"

      # the tags...
      if current_user
        
        DIV 
          style: 
            marginTop: 20

          for tags in [current_user.tags, @local.new_tags]
            for k,v of tags
              do (k,v) => 
                #k = k.split('.')[0]
                editing = @local.editing == k

                DIV 
                  style: {}
                  onFocus: (e) => @local.editing = k; save @local
                  onBlur: (e) => @local.editing = null; save @local

                  INPUT
                    ref: k
                    style: 
                      fontWeight: 600
                      padding: '5px 10px'
                      marginRight: 18
                      display: 'inline-block'
                      border: "1px solid #{ if editing then '#bbb' else 'transparent'}"
                      outline: 'none'
                      fontSize: 18
                      width: 400

                    defaultValue: k

                  INPUT
                    ref: "#{k}-val"
                    style: 
                      padding: '5px 10px'
                      display: 'inline-block'
                      border: "1px solid #{ if editing then '#bbb' else 'transparent'}"
                      outline: 'none'
                      fontSize: 18
                      width: 400

                    defaultValue: v

          DIV 
            style: 
              marginTop: 12

            INPUT 
              type: 'submit'
              style: 
                padding: '5px 10px'
                fontSize: 18

              value: 'new tag'
              onClick: => 
                i = 0
                while @local.new_tags["tag-#{i}"]
                  i++
                @local.new_tags["tag-#{i}"] = ""
                save @local

          DIV 
            style: 
              marginTop: 12

            INPUT 
              type: 'submit'
              style: 
                backgroundColor: focus_blue
                border: 'none'
                outline: 'none'
                color: 'white'
                padding: '5px 10px'
                borderRadius: 8
                fontSize: 18
              onClick: => 
                update = {}
                for tags in [current_user.tags, @local.new_tags]

                  for k,v of tags
                    new_k = @refs[k].getDOMNode().value
                    new_v = @refs["#{k}-val"].getDOMNode().value
                    if new_k?.length > 0 && new_v?.length > 0
                      update[new_k] = new_v

                current_user.tags = update 
                save current_user
                @local.new_tags = {}
                save @local


              value: 'Update'

      # all users...
      DIV 
        style: 
          marginTop: 12

        for tag_group, tag_users of all_tags 
          DIV
            style:
              width: 300
              display: 'inline-block'
              verticalAlign: 'top'
              padding: 10
              backgroundColor: '#eaeaea'
              borderRadius: 16
              marginRight: 10
              marginBottom: 10

            DIV 
              style:
                fontWeight: 600
                marginBottom: 4
                color: "#666"

              tag_group

            UL
              style: 
                listStyle: 'none'
                display: 'inline'
                fontSize: 0
                lineHeight: 0

              for user in tag_users 
                do (user) => 
                  Avatar 
                    key: user.key
                    style: 
                      width: 40
                      height: 40
                      cursor: 'pointer'
                    onClick: => change_current_user user.key      












window.UserTags = UserTags