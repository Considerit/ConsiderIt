window.moderation_options = [
    {
      label: "No moderation"
      value: 0
    }
    
    {
      label: "Do not publicly post content until after approval"
      value: 1
      explanation: "Suggested only for extremely adversarial or sensitive forums. Hosts will receive email notifications when there is content to review. To keep the conversation flowing, hosts should be extremely responsive to reviewing new posts."
    } 
    
    {
      label: "Post content immediately, but withhold email notifications until after approval"
      value: 2
      explanation: "Suggested for most public engagement. All content is posted immediately, but won’t trigger email notifications, nor will the new posts be present in any email summary of recent activity. After review, they will be part of recent activity summaries. This policy will avoid the worst consequence of detrimental content: an enthusiastic participant getting an email linking them to a nasty attack on them, while at the same time lessening the pressure on moderators to review content promptly."
    } 
    
    {
      label: "Post content immediately, review later", 
      value: 3
      explanation: "Use this if you’re not very concerned about detrimental posts and/or you don’t have capacity to review new content in a timely fashion. Hosts will receive email notifications when there is content to review. Suggested for most engagement amongst people who have formal or communal ties."
    }
  ]


window.ModerationDash = ReactiveComponent
  displayName: 'ModerationDash'

  render : -> 
    moderations = @data().moderations
    subdomain = fetch '/subdomain'
    dash = fetch 'moderation_dash'

    @local.model ?= 'Proposal'

    models = ['Point', 'Comment', 'Proposal']
    all_items = {}

    moderation_enabled = subdomain.moderation_policy > 0 

    if !moderation_enabled
      DIV null, 
        "Moderation is disabled. You can turn on content moderation in the "
        A 
          href: '/dashboard/application'
          style: 
            textDecoration: 'underline'
            fontWeight: 700
          "forum settings"
        "."
    else 
      for option in moderation_options
        if option.value == subdomain.moderation_policy 
          moderation_policy = option 

    for model in models
      
      # Separate moderations by status
      passed = []
      reviewable = []
      quarantined = []
      failed = []

      moderations[model] ||= []

      moderations[model].sort (a,b) -> 
        new Date(fetch(b.moderatable).created_at) - new Date(fetch(a.moderatable).created_at)


      for i in moderations[model]
        # register a data dependency, else resort doesn't happen when an item changes
        fetch i.key

        if !i.status? || i.updated_since_last_evaluation
          reviewable.push i
        else if i.status == 1
          passed.push i
        else if i.status == 0
          failed.push i
        else if i.status == 2
          quarantined.push i

      all_items[model] = 
        pending: 
          name: 'pending'
          items: reviewable
        quarantined: 
          name: 'quarantined'
          items: quarantined
        failed: 
          name: 'failed'
          items: failed
        passed: 
          name: 'passed'
          items: passed

    
    items = all_items[@local.model]
    @items = items 


    # We assume an ordering of the task categories where the earlier
    # categories are more urgent & shown higher up in the list than later categories.

    @local.show_category ?= items.pending.name

    DIV null, 
      DIV 
        style: 
          marginBottom: 12 
          fontSize: 20
        # "Your moderation policy: "


        SELECT 
          style: 
            fontSize: 20
          defaultValue: subdomain.moderation_policy
          onChange: (ev) ->
            subdomain.moderation_policy = ev.target.value
            save subdomain, -> 
              #saving the subdomain shouldn't always dirty moderations 
              #(which is expensive), so just doing it manually here
              arest.serverFetch('/page/dashboard/moderate')  

          for option in moderation_options
            OPTION 
              key: option.value
              value: option.value
              option.label 

      if !screencasting()
        DIV 
          style: 
            marginBottom: 24      
            fontStyle: 'italic'
            fontSize: 14

          "Visit the "
          A 
            href: '/dashboard/application'
            style: 
              textDecoration: 'underline'
              fontWeight: 700
            "forum settings"
          " for an explanation of these moderation policies."


      UL 
        className: 'moderation_tabs'
        style: 
          listStyle: 'none'
          marginTop: 48

        for model in ['Proposal', 'Point', 'Comment', 'Ban']
          select_class = (model) => @local.model = model; save @local

          do (model) => 
            active = @local.model == model
            LI 
              key: model
              style: 
                display: 'inline-block'

              BUTTON 
                "data-model": model 
                style: 
                  backgroundColor: if active then 'white' else '#f0f0f0'
                  color: 'black'
                  fontSize: 18
                  marginLeft: 12
                  marginRight: 12
                  marginBottom: if active then -1
                  border: '1px solid #bbb'
                  borderBottom: 'none'
                  borderRadius: '4px 4px 0 0px'
                  padding: "6px 14px #{if active then 3 else 2}px 14px"

                onClick: => select_class(model)

                "#{if model == 'Proposal' then 'Review ' else ''}#{model}s"

                if model != 'Ban'
                  SPAN 
                    style: 
                      fontSize: 12
                      verticalAlign: 'top'
                      paddingLeft: 8
                    "[#{all_items[model].pending?.items?.length or 0}]"




      if @local.model == 'Ban'
        DIV 
          style: 
            borderTop: '1px solid #bbb'

          BanHammer {all_items}


      else 
        DIV 
          style: 
            borderTop: '1px solid #bbb'


          UL 
            style: 
              listStyle: 'none'
              margin: '12px 0 12px 10px'

            for category, definition of items
              do (definition) =>
                active = category == @local.show_category
                LI  
                  key: category
                  style:
                    display: 'inline'
                    marginLeft: 18

                  BUTTON
                    className: 'like_link'
                    style: 
                      fontSize: 14
                      fontWeight: if active then 700
                      color: if active then 'black' else '#666'

                    onClick: => 
                      @local.show_category = definition.name 
                      save @local 

                    category

                  SPAN
                    style: 
                      fontSize: 10
                      paddingLeft: 4
                      color: '#666'
                    "[#{definition.items?.length or 0}]"


          UL 
            style: 
              marginLeft: 0 #-66
            for item in items[@local.show_category].items
              ModerateItem 
                key: item.key
                item: item.key




styles += """
  .moderation { 
    font-weight: 600; 
    border-radius: 8px;  
    display: inline-block; 
    margin-right: 10px; 
    box-shadow: 0px 1px 2px rgba(0,0,0,.4);
    font-size: 22px;
  }
  .moderation label {
    display: inline-block;
    padding: 10px 14px;    
  }
  .moderation label, .moderation input { 
    font-size: 22px; 
    cursor: pointer;            
  }
"""

ModerateItem = ReactiveComponent
  displayName: 'ModerateItem'

  render : ->
    item = fetch @props.item

    class_name = item.moderatable_type
    moderatable = fetch(item.moderatable)
    author = if moderatable.user then fetch(moderatable.user) else null

    if class_name == 'Point'
      point = moderatable
      proposal = fetch(moderatable.proposal)
      tease = "#{moderatable.nutshell.substring(0, 120)}..."
      header = moderatable.nutshell
      details = moderatable.text 
      href = "/#{proposal.slug}?results=true&selected=#{point.key}"
    else if class_name == 'Comment'
      point = fetch(moderatable.point)
      proposal = fetch(point.proposal)
      comments = fetch("/comments/#{point.id}")
      tease = "#{moderatable.body.substring(0, 120)}..."
      header = moderatable.body
      details = ''
      href = "/#{proposal.slug}?results=true&selected=#{point.key}"      
    else if class_name == 'Proposal'
      proposal = moderatable
      tease = "#{proposal.name.substring(0, 120)}..."
      header = proposal.name
      details = moderatable.description
      href = "/#{proposal.slug}"


    current_user = fetch('/current_user')
    
    judge = (e) => 
      item.status = e.target.value
      save item

    LI 
      'data-id': item.key
      key: item.key
      style: 
        position: 'relative'
        listStyle: 'none'

      DIV 
        style: 
          cursor: 'auto'
          padding: '8px 14px'
          maxWidth: 700
          marginBottom: 20



        DIV 
          style: 
            marginLeft: 70
            position: 'relative'

          DIV null, 

            if class_name == 'Comment'
              DIV 
                style: 
                  opacity: .5
                BUBBLE_WRAP 
                  key: point.key
                  title: point.nutshell 
                  anon: point.hide_name
                  user: point.user
                  body: point.text
                  width: '100%'


                for comment in _.uniq( _.map(comments.comments, (c) -> c.key).concat(moderatable.key)) when comment != moderatable.key
                  BUBBLE_WRAP 
                    key: comment
                    title: fetch(comment).body
                    user: fetch(comment).user
                    width: '100%'

            BUBBLE_WRAP
              title: header
              body: moderatable.description
              anon: !!moderatable.hide_name
              user: moderatable.user
              width: '100%'

            DIV null,
              "by #{author?.name or anonymous_label()}"


              A 
                style: 
                  textDecoration: 'underline'
                  padding: '0 8px'
                target: '_blank'
                href: href
                'data-nojax': true


                "View #{class_name}"

              if !moderatable.hide_name && !@local.messaging
                BUTTON
                  style: 
                    marginLeft: 8
                    textDecoration: 'underline'
                    backgroundColor: 'transparent'
                    border: 'none'
                  onClick: => 
                    @local.messaging = moderatable
                    save(@local)
                    console.log moderatable

                  'Message author'



          if @local.messaging
            DirectMessage 
              to: @local.messaging.user
              parent: @local
              sender_mask: 'Moderator'

        if class_name == 'Proposal'
          # Category
          DIV 
            style: 
              marginTop: 8
              marginLeft: 63
                    
            SELECT
              style: 
                fontSize: 18
              value: proposal.cluster or ''
              ref: 'category'
              onChange: (e) =>
                proposal.cluster = e.target.value
                save proposal

              for list_key in get_all_lists()
                OPTION  
                  key: list_key
                  value: list_key.substring(5)
                  get_list_title list_key, true



        # moderation area
        DIV 
          style:       
            margin: '10px 0px 20px 63px'
            position: 'relative'

          SPAN 
            className: 'moderation btn'
            style: 
              backgroundColor: '#81c765'


            LABEL 
              htmlFor: "pass-#{@props.item}"

              INPUT 
                name: 'moderation'
                type: 'radio'
                id: "pass-#{@props.item}"
                value: 1
                defaultChecked: item.status == 1
                onChange: judge

              'Pass'

          SPAN 
            className: 'moderation btn'
            style: 
              backgroundColor: '#ffc92a'

            LABEL 
              htmlFor: "quar-#{@props.item}"
              INPUT 
                name: 'moderation'
                type: 'radio'
                id: "quar-#{@props.item}"
                value: 2
                defaultChecked: item.status == 2
                onChange: judge

              'Quarantine'

          SPAN 
            className: 'moderation btn'
            style: 
              backgroundColor: '#f94747'

            LABEL 
              htmlFor: "fail-#{@props.item}"

              INPUT 
                name: 'moderation'
                type: 'radio'
                id: "fail-#{@props.item}"
                value: 0
                defaultChecked: item.status == 0
                onChange: judge

              'Fail'

        # status area
        DIV 
          style: 
            marginLeft: 63
            fontStyle: 'italic'


          if item.updated_since_last_evaluation
            SPAN style: {}, "Updated since last moderation"
          else if item.status == 1
            SPAN style: {}, "Passed by #{if item.user then fetch(item.user).name else 'Unknown'} on #{new Date(item.updated_at).toDateString()}"
          else if item.status == 2
            SPAN style: {}, "Quarantined by #{if item.user then fetch(item.user).name else 'Unknown'} on #{new Date(item.updated_at).toDateString()}"
          else if item.status == 0
            SPAN style: {}, "Failed by #{if item.user then fetch(item.user).name else 'Unknown'} on #{new Date(item.updated_at).toDateString()}"





BanHammer = ReactiveComponent
  displayName: 'BanHammer'

  render: ->
    users = fetch '/users'
    subdomain = fetch '/subdomain'

    bans = subdomain.customizations.shadow_bans or []

    ban_user = (user) =>
      bans = (u.key or u for u in bans)
      bans.push user.key
      subdomain.customizations.shadow_bans = bans
      save subdomain



      # fail all posts by this account
      for model, categories of @props.all_items
        for moderation_status, items of categories when moderation_status != 'failed'
          for item in items.items
            if fetch(item.moderatable).user == user.key
              item.status = 0
              save item

    filtered_users = _.filter users.users, (u) =>  
                        bans.indexOf(u.key) < 0 &&
                         (!@local.filtered || 
                          "#{u.name} <#{u.email}>".indexOf(@local.filtered) > -1)

    ban_explanation = """
       If you are having insurmountable difficulties with a particular registered account, you can shadow ban them.
       A shadow ban will not prevent them from accessing the forum, nor will it block them from leaving opinions.
       It will automatically fail all their existing posts as well as any they might make in the future (e.g. new proposals, pro/con points, and comments).
       Their posts will not show up in activity digest emails. 
       It is a "shadow" ban because it will appear to them as if their posts are being publicly posted, when in reality the posts are only visible
       to them (unless they log out or access the forum from a different device). Shadow banning helps reduce the chance you will get into an 
       escalating conflict. 
    """


    DIV null,


      DIV 
        style: 
          position: 'relative'
          padding: '18px 24px'
          backgroundColor: '#f1f1f1'
          marginTop: 24


        LABEL 
          style: {}
          "Select an account to shadow ban: "

          SPAN null, 

            DropMenu
              options: filtered_users
              open_menu_on: 'activation'

              selection_made_callback: (user) =>

                if confirm("Are you sure you want to shadow ban '#{user.name}'? Their existing posts will be failed. This action is irrevocable.")
                  ban_user(user)
                  @local.filtered = null
                  save @local

              render_anchor: (menu_showing) =>
                INPUT 
                  id: 'filter'
                  type: 'text'
                  style: {fontSize: 18, width: 350, padding: '3px 6px'}
                  autoComplete: 'off'
                  placeholder: "Name or email..."
                  
                  onChange: => 
                    @local.filtered = document.getElementById('filter').value
                    save @local
                  
              render_option: (user) ->
                [
                  SPAN 
                    key: 'user name'
                    style: 
                      fontWeight: 600
                    user.name 

                  SPAN
                    key: 'user email'
                    style: 
                      opacity: .7
                      paddingLeft: 8

                    user.email  
                ]
     
              wrapper_style: 
                display: 'inline-block'
              menu_style: 
                backgroundColor: '#ddd'
                border: '1px solid #ddd'

              option_style: 
                padding: '4px 12px'
                fontSize: 18
                cursor: 'pointer'
                display: 'block'

              active_option_style:
                backgroundColor: '#eee'



      if bans.length > 0

        DIV 
          style:
            marginTop: 24
            marginLeft: 24

          "Accounts already banned:"

          DIV 
            style:
              marginTop: 8

            for user, idx in bans

              Avatar 
                key: user
                style: 
                  width: 35
                  height: 35
                  marginRight: 6




      DIV 
        style: 
          fontSize: 16
          width: 600
          marginTop: 36
          marginLeft: 24
        ban_explanation







DirectMessage = ReactiveComponent
  displayName: 'DirectMessage'

  render : -> 
    
    return SPAN null if !@props.to 

    user = fetch(@props.to)

    text_style = 
      width: 500
      fontSize: 16
      display: 'block'
      padding: '4px 8px'

    DIV style: {margin: '18px 0', padding: '15px 20px', backgroundColor: 'white', width: 550, backgroundColor: considerit_gray, boxShadow: "0 2px 4px rgba(0,0,0,.4)"}, 
      DIV style: {marginBottom: 8},
        LABEL null, 'To: ', user.name

      DIV style: {marginBottom: 8},
        LABEL htmlFor: 'message_subject', 'Subject'
        AutoGrowTextArea
          id: 'message_subject'
          className: 'message_subject'
          placeholder: 'Subject line'
          min_height: 25
          style: text_style

      DIV style: {marginBottom: 8},
        LABEL htmlFor: 'message_body', 'Body'
        AutoGrowTextArea
          id: 'message_body'
          className: 'message_body'
          placeholder: 'Email message'
          min_height: 75
          style: text_style

      BUTTON
        className: "btn"
        onClick: @submitMessage
        'Send'
        
      BUTTON 
        style: 
          marginLeft: 8
          backgroundColor: 'transparent'
          border: 'none'
        onClick: => 
          @props.parent.messaging = null
          save @props.parent
        'cancel'

  submitMessage : -> 
    el = ReactDOM.findDOMNode(@)

    new_message = 
      key: '/dashboard/message'
      recipient: @props.to
      subject: el.querySelector('#message_subject').value
      body: el.querySelector('#message_body').value 
      sender_mask: @props.sender_mask or fetch('/current_user').name
      # authenticity_token: fetch('/current_user').csrf

    save new_message, =>
      @props.parent.messaging = null
      save @props.parent
