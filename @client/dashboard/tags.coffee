

UserTags = ReactiveComponent
  displayName: 'UserTags'

  render : -> 
    subdomain = fetch '/subdomain'
    users = fetch '/users'

    selected_user = if @local.selected_user then fetch(@local.selected_user)

    change_selected_user = (new_user) => 
      @local.new_tags = {}
      @local.selected_user = new_user

      selected_user = if @local.selected_user then fetch(@local.selected_user)
      if selected_user
        for k,v of all_tags when k != 'no tags'
          if !selected_user.tags[k]?
            @local.new_tags[k] = ""
      save @local

    tags_config = customization('user_tags')
    all_tags = {}
    tag_names = {}

    for vals in tags_config
      tag = vals.key
      all_tags[tag] = {
        not_answered: []
      }
      tag_names[tag] = vals.view_name or vals.self_report?.question or tag

      if vals.self_report
        if vals.self_report.options
          for option in vals.self_report.options
            all_tags[tag][option] = []
        else if vals.self_report.input == 'boolean'
            all_tags[tag][true] = []
            all_tags[tag][false] = []

    for user in users.users 
      user = fetch(user.key or user) # subscribe to changes
      for vals in tags_config 
        tag = vals.key
        if tag not of user.tags || user.tags[tag] == "" || user.tags[tag] == 'undefined'
          all_tags[tag].not_answered.push user

      for tag, val of user.tags 
        if val.self_report?.input == 'checklist'
          my_vals = val.split(',')
        else if val.self_report?.input == 'boolean' && (typeof val == 'string') && val.toLowerCase() in ["no", "false", "yes", "true"]
          if val.toLowerCase() in ["no", "false"]
            my_vals = [false]
          else
            my_vals = [true]

        else
          my_vals = [val] 

        for v in my_vals
          all_tags[tag][v] ?= []
          all_tags[tag][v].push user 

    if all_tags['considerit_terms']
      delete all_tags['considerit_terms']

    DIV 
      style: 
        paddingTop: 50

      DIV 
        style: 
          marginBottom: 12

        H1 style: {fontSize: 48}, 
          "Custom Participant Data"


      # Text input for selecting a participant to edit tags
      DIV null,
        INPUT 
          id: 'filter'
          type: 'text'
          style: {fontSize: 18, width: 350, padding: '3px 6px'}
          autoComplete: 'off'
          'aria-label': "Name or email..."
          placeholder: "Name or email..."
          value: if selected_user then selected_user.name else ""
          onChange: (ev) => 
            @local.filtered = ev.target.value?.toLowerCase()
            change_selected_user null 
            save(@local)
          onKeyPress: (e) => 
            # enter key pressed...
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              e.preventDefault()
              change_selected_user @local.hovered_user
              save @local
          onFocus: (e) => 
            @local.selecting = true
            save(@local)
            e.stopPropagation()
            e.preventDefault()

            @handle_click ?= (e) =>
              if e.target.id != 'filter'
                @local.selecting = false
                save @local
                document.removeEventListener 'click', @handle_click

            document.addEventListener 'click', @handle_click


      # Dropdown, autocomplete menu for adding existing users
      if @local.selecting
        available_users = _.filter users.users, (u) => 
            u.key != @local.selected_user &&
             (!@local.filtered || 
              "#{u.name} <#{u.email}>".toLowerCase().indexOf(@local.filtered) > -1)

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
                  key: user.key                
                  className: 'invite_menu_item'
                  style: 
                    padding: '2px 12px'
                    fontSize: 18
                    cursor: 'pointer'
                    borderBottom: '1px solid #fafafa'

                  onMouseEnter: (e) =>
                    @local.hovered_user = user.key
                    save @local
                  onMouseLeave: (e) => @local.hovered_user = null; save @local 

                  onClick: (e) => 
                    change_selected_user @local.hovered_user
                    e.stopPropagation()

                  "#{user.name} <#{user.email}>"

      # the tags...
      if selected_user
        DIV 
          style: 
            marginTop: 20

          for tags in [selected_user.tags, @local.new_tags]
            for k,v of tags
              do (k,v, tags) => 
                editing = @local.editing == k
                DIV 
                  key: "#{k}-#{v}"
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
                      fontSize: 18
                      width: 400

                    defaultValue: k

                  INPUT
                    ref: "#{k}-val"
                    style: 
                      padding: '5px 10px'
                      display: 'inline-block'
                      border: "1px solid #{ if editing then '#bbb' else 'transparent'}"
                      fontSize: 18
                      width: 400

                    defaultValue: v

          # Can't create a new tag at the moment. Needs to be updated to add the new tag to the user_tags config, and probably 
          # namespace it to this forum to prevent conflicts or hacks
          # DIV 
          #   style: 
          #     marginTop: 12

          #   INPUT 
          #     type: 'submit'
          #     style: 
          #       padding: '5px 10px'
          #       fontSize: 18

          #     value: 'new tag'
          #     onClick: => 
          #       i = 0
          #       while @local.new_tags["tag-#{i}"]
          #         i++
          #       @local.new_tags["tag-#{i}"] = ""
          #       save @local


          # Hack for designating an account as a sort of non-participating organizational account 
          # used for seeding content
          DIV 
            style: {}

            LABEL 
              style: {}
                        
              INPUT 
                type: 'checkbox'
                checked: selected_user.key in (customization('organizational_account') or [])
                onChange: (e) ->
                  orgs = customization('organizational_account') or []
                  if selected_user.key in orgs 
                    orgs = _.without orgs, selected_user.key
                  else 
                    orgs.push selected_user.key
                  subdomain.customizations['organizational_account'] = orgs
                  save subdomain

              "Designate as organizational account"

          DIV 
            style: 
              marginTop: 12

            INPUT 
              type: 'submit'
              style: 
                backgroundColor: focus_color()
                border: 'none'
                color: 'white'
                padding: '5px 10px'
                borderRadius: 8
                fontSize: 18
              onClick: => 
                update = {}
                for tags in [selected_user.tags, @local.new_tags]

                  for k,v of tags
                    new_k = @refs[k].value
                    new_v = @refs["#{k}-val"].value
                    if new_k?.length > 0 # && new_v?.length > 0
                      update[new_k] = new_v

                selected_user.tags = update 
                save selected_user
                @local.new_tags = {}
                save @local


              value: 'Update'

      # all users...
      DIV
        key: 'all users' 
        style: 
          marginTop: 12


        for tag, vals of all_tags 
          show_all = Object.keys(vals).length < 15 || !!@local.show_all?[tag]

          DIV 
            key: tag
            H2
              style: 
                fontSize: 36
                marginTop: 36

              dangerouslySetInnerHTML: __html: tag_names[tag]

            if !show_all

              DIV null, 

                DIV null, 
                  SPAN
                    style: 
                      fontStyle: 'italic'
                    "Lots of values."
                  BUTTON
                    style: 
                      backgroundColor: 'none'
                      border: 'none'
                      padding: 0
                      color: focus_color()
                      textDecoration: 'underline'
                      marginLeft: 12
                    onClick: do (tag) => =>
                      @local.show_all ?= {}
                      @local.show_all[tag] = true 
                      save @local 

                    "Break out by value"


                for v,users of vals
                  UL
                    key: v
                    style: 
                      listStyle: 'none'
                      display: 'inline'
                      fontSize: 0
                      lineHeight: 0
  
                    for user in users
                      do (user) => 
                        Avatar 
                          key: user.key
                          style: 
                            width: 40
                            height: 40
                            cursor: 'pointer'
                          alt: "<user>: #{v}"
                          onClick: => change_selected_user user.key      

            else 
              for v,users of vals 
                do (tag, v) =>
                  DIV 
                    key: "#{v}-#{tag}"
                    style: 
                      marginBottom: 18
                    onKeyDown: (e) => 
                      if e.which == 18 # alt/opt 
                        @local.control_depressed = true 
                    onKeyUp: (e) =>
                      @local.control_depressed = false 

                    onDragEnter: (e) => 
                      if @local.control_depressed
                        e.preventDefault()
                    onDragOver: (e) => 
                      if @local.control_depressed
                        e.preventDefault()
                    onDragLeave: (e) => 
                      if @local.control_depressed
                        e.preventDefault()
                    onDrop: (e) =>
                      if @local.control_depressed
                        e.preventDefault()
                        user = fetch e.dataTransfer.getData("text/plain")
                        user.tags[tag] = v 
                        save user                      


                    DIV
                      style:
                        fontWeight: 700
                        marginRight: 8

                      v

                    UL
                      style: 
                        listStyle: 'none'
                        display: 'inline'
                        fontSize: 0
                        lineHeight: 0

                      for user in users
                        do (user) => 
                          SPAN 
                            key: user.key
                            draggable: true  
                            onDragStart: (ev) =>
                              if @local.control_depressed
                                ev.dataTransfer.setData("text/plain", user.key)
                            style: 
                              width: 40
                              height: 40
                              cursor: 'move'

                            Avatar 
                              key: user.key
                              style: 
                                width: 40
                                height: 40
                              alt: "<user>: #{v}"
                              hide_popover: @local.control_depressed
                              onClick: (e) => 
                                if !@local.control_depressed
                                  change_selected_user user.key
                                  e.stopPropagation()
                                  e.preventDefault()




window.UserTags = UserTags