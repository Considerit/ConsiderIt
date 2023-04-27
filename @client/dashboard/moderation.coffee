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


styles += """

.moderation { 
  font-weight: 600; 
  display: inline-block; 
  margin-right: 10px; 
  font-size: 22px;
  padding: 0;
  box-shadow: 0px 1px 2px rgba(0,0,0,.4);  
  border-radius: 8px;         
}
.moderation label {
  display: inline-block;
  padding: 18px 24px; 
}
.moderation label, .moderation input { 
  font-size: 22px; 
  cursor: pointer;            
}

.moderation.btn input {
  display: none;
}

.moderation.btn {
  /* padding: 8px 18px; */
}

.moderate-item-wrapper {
  cursor: auto;
  padding: 8px 14px;
  max-width: 700px;
  margin-bottom: 20px;
}

.moderate-item-bubble-wrapper {
  margin-left: 70px;
  position: relative;
}

@media #{NOT_LAPTOP_MEDIA} {
  .moderation-content-wrapper {

  }
  .moderation.btn {
  }

  .moderation.btn label {
    font-size: 18px;
    padding: 8px 12px;    
  }

  .moderate-item-wrapper {
    padding: 8px 0px;
  }

  .moderate-item-bubble-wrapper {
    margin-left: 36px;
  }

}
"""


default_quarantine_message = null
default_fail_message = null

window.ModerationDash = ReactiveComponent
  displayName: 'ModerationDash'

  render : -> 
    moderations = @data().moderations
    subdomain = fetch '/subdomain'
    dash = fetch 'moderation_dash'


    default_quarantine_message ?= subdomain.customizations.moderation_default_quarantine_message
    default_fail_message ?= subdomain.customizations.moderation_default_fail_message


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
            maxWidth: '80vw'
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
            className: 'moderation-content-wrapper'        

            style: 
              marginLeft: 0 #-66
            for item in items[@local.show_category].items
              ModerateItem 
                key: item.key
                item: item.key



# When the moderator makes a judgment, /proposals and /lists/* are dirty. 
# However, returning them with each judgment is unnecessarily problematic 
# for performance. So we'll try to wait until after the moderator is back 
# on a dialogue page to finally fetch the dirty objects. 
delayed_fetch_timer = null
delayed_fetch_after_moderation_judgment = -> 
  if !delayed_fetch_timer
    delayed_fetch_timer = setInterval -> 
      if is_a_dialogue_page()
        live_update()
        clearInterval delayed_fetch_timer
        delayed_fetch_timer = null
    , 250

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
      href = "/#{proposal.slug}?selected=#{point.key}"
    else if class_name == 'Comment'
      point = fetch(moderatable.point)
      proposal = fetch(point.proposal)
      comments = fetch("/comments/#{point.id}")
      tease = "#{moderatable.body.substring(0, 120)}..."
      header = moderatable.body
      details = ''
      href = "/#{proposal.slug}?selected=#{point.key}"      
    else if class_name == 'Proposal'
      proposal = moderatable
      tease = "#{proposal.name.substring(0, 120)}..."
      header = proposal.name
      details = moderatable.description
      href = "/#{proposal.slug}"


    current_user = fetch('/current_user')
    
    judge = (e, immediate_with_message) => 
      if parseInt(e.target.value) == 1
        item.status = e.target.value
        save item, delayed_fetch_after_moderation_judgment
      else 
        @local.messaging = 
          from_prompt: true 
          ultimate_judgment: parseInt(e.target.value)
          moderatable: moderatable
          send_immediately: immediate_with_message
        save @local

    LI 
      'data-id': item.key
      key: item.key
      style: 
        position: 'relative'
        listStyle: 'none'




      DIV 
        className: 'moderate-item-wrapper'


        DIV 
          className: 'moderate-item-bubble-wrapper'

          DIV null, 

            if class_name == 'Comment'


              DIV 
                class_name: 'context'
                style: 
                  opacity: .5
                BUBBLE_WRAP 
                  key: point.key
                  title: point.nutshell 
                  anon: point.hide_name
                  user: point.user
                  body: point.text
                  width: 'min(100%, 700px)'
                  avatar_style: if TABLET_SIZE() then {width: 32, height: 32, left: -44}


                for comment in _.uniq( _.map(comments.comments, (c) -> c.key).concat(moderatable.key)) when comment != moderatable.key
                  BUBBLE_WRAP 
                    key: comment
                    title: fetch(comment).body
                    user: fetch(comment).user
                    width: 'min(100%, 700px)'
                    avatar_style: if TABLET_SIZE() then {width: 32, height: 32, left: -44}

            else if class_name == 'Point'

              DIV 
                class_name: 'context'
                style: 
                  opacity: .5
                BUBBLE_WRAP 
                  key: proposal.key
                  title: proposal.name 
                  user: proposal.user
                  body: proposal.description
                  width: 'min(100%, 700px)'
                  avatar_style: if TABLET_SIZE() then {width: 32, height: 32, left: -44}

            else if class_name == 'Proposal'
              list_key = get_list_for_proposal(proposal)
              DIV 
                class_name: 'context'
                style: 
                  opacity: .5


                BUBBLE_WRAP 
                  key: list_key
                  title: get_list_title(list_key) 
                  body: customization('list_description', list_key)
                  width: 'min(100%, 700px)'


            DIV 
              style: 
                position: 'relative'

              if class_name == 'Point'
                DIV
                  style: 
                    position: 'absolute'
                    left: "calc(100% + 16px)"
                    top: 4
                    fontSize: 12
                    zIndex: 999
                  if point.is_pro
                    translator 'point_labels.pro', 'pro'
                  else 
                    translator 'point_labels.con', 'con'

              BUBBLE_WRAP
                title: header
                body: moderatable.description
                anon: !!moderatable.hide_name
                user: moderatable.user
                width: 'min(100%, 700px)'
                avatar_style: if TABLET_SIZE() then {width: 32, height: 32, left: -44}


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
                    @local.messaging =
                      moderatable: moderatable
                      from_prompt: false
                    save(@local)

                  'Message author'



          if @local.messaging
            MESSAGE_WIDGET = DirectMessage

            default_message = null
            if @local.messaging.from_prompt
              default_message = if parseInt(@local.messaging.ultimate_judgment) == 0 then default_fail_message else default_quarantine_message
              MESSAGE_WIDGET = ModalDirectMessage

            MESSAGE_WIDGET 
              to: @local.messaging.moderatable.user
              parent: @local
              sender_mask: 'Moderator'
              default_message: default_message
              cancel_button_label: if @local.messaging.from_prompt then "skip message"
              title: if @local.messaging.from_prompt then "Inform author about moderation decision"
              send_immediately: @local.messaging.send_immediately
              callback: (message) => 
                if @local.messaging.ultimate_judgment?
                  judgment = parseInt(@local.messaging.ultimate_judgment)

                  if message
                    is_quarantine = judgment == 2
                    is_failure = judgment == 0
                    subdomain = fetch '/subdomain'

                    if is_failure && !subdomain.customizations.moderation_default_fail_message
                      default_fail_message = 
                        subject: message.subject
                        body: message.body
                    else if is_quarantine && !subdomain.customizations.moderation_default_quarantine_message
                      default_quarantine_message = 
                        subject: message.subject
                        body: message.body

                  item.status = judgment
                  save item, delayed_fetch_after_moderation_judgment

                @local.messaging = null
                save @local


        if class_name == 'Proposal'
          # Category
          DIV 
            style: 
              marginTop: 8
              marginLeft: if TABLET_SIZE() then 36 else 63
                    
            SELECT
              style: 
                fontSize: 18
                maxWidth: '60vw'
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
            marginLeft: if TABLET_SIZE() then 36 else 63
            position: 'relative'

          SPAN 
            className: 'moderation btn'
            style: 
              backgroundColor: '#81c765'


            LABEL 
              htmlFor: "pass-#{@props.item}"

              INPUT 
                name: 'moderation'
                type: 'button'
                id: "pass-#{@props.item}"
                value: 1
                onClick: judge

              'Pass'

          SPAN 
            className: 'moderation btn'
            style: 
              backgroundColor: '#ffc92a'

            LABEL 
              htmlFor: "quar-#{@props.item}"
              INPUT 
                name: 'moderation'
                type: 'button'
                id: "quar-#{@props.item}"
                value: 2
                onClick: judge

              'Quarantine'

          SPAN 
            className: 'moderation btn'
            style: 
              backgroundColor: '#f94747'

            LABEL 
              htmlFor: "fail-#{@props.item}"

              INPUT 
                name: 'moderation'
                type: 'button'
                id: "fail-#{@props.item}"
                value: 0
                onClick: judge

              'Fail'

          if fetch('/subdomain').customizations.moderation_default_fail_message
            SPAN 
              style: 
                position: 'relative'

              SPAN 
                className: 'moderation btn'
                style: 
                  backgroundColor: '#f94747'
                  minWidth: 150
                  display: 'inline-block'

                LABEL 
                  htmlFor: "failm-#{@props.item}"

                  INPUT 
                    name: 'moderation'
                    type: 'button'
                    id: "failm-#{@props.item}"
                    value: 0
                    onClick: (e) => 
                      judge(e, true)

                  'Fail'
              BR null
              SPAN 
                style: 
                  fontSize: 13
                  position: 'absolute'
                  right: 19
                  marginTop: 4
                "& send default message"


        # status area
        DIV 
          style: 
            marginLeft: if TABLET_SIZE() then 36 else 63
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
              save item, delayed_fetch_after_moderation_judgment

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
          maxWidth: 600
          marginTop: 36
          marginLeft: 24
        ban_explanation







DirectMessage = ReactiveComponent
  displayName: 'DirectMessage'

  render : -> 
    
    return SPAN null if !@props.to 

    user = fetch(@props.to)


    if @props.default_message
      {body, subject} = @props.default_message
    else 
      body = subject = null

    text_style = 
      width: "min(550px, 70vw)"
      fontSize: 16
      display: 'block'
      padding: '4px 8px'

    wrapper_style =
      width: "min(590px, calc(70vw + 40px))"

    if !@props.title
      _.defaults wrapper_style, 
        margin: '18px 0'
        padding: '15px 20px'
        backgroundColor: 'white'
        backgroundColor: considerit_gray
        boxShadow: "0 2px 4px rgba(0,0,0,.4)"

    DIV 
      style: wrapper_style


      if @props.title 
        H2 
          style: 
            fontSize: 24
            marginBottom: 18
          @props.title

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
          defaultValue: subject

      DIV style: {marginBottom: 8},
        LABEL htmlFor: 'message_body', 'Body'
        AutoGrowTextArea
          id: 'message_body'
          className: 'message_body'
          placeholder: 'Email message'
          min_height: 75
          style: text_style
          defaultValue: body

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
          @props.callback?()
        @props.cancel_button_label or 'cancel'

  componentDidMount: -> 
    if @props.send_immediately
      @submitMessage()    

  submitMessage : -> 
    el = ReactDOM.findDOMNode(@)

    new_message = 
      key: '/dashboard/message'
      recipient: @props.to
      subject: el.querySelector('#message_subject').value
      body: el.querySelector('#message_body').value 
      sender_mask: @props.sender_mask or fetch('/current_user').name
      # authenticity_token: arest.csrf()

    save new_message, =>
      @props.callback?(new_message)


ModalDirectMessage = ReactiveComponent
  displayName: 'ModalDirectMessage'
  mixins: [Modal]

  render : ->

    wrap_in_modal HOMEPAGE_WIDTH(), @props.done_callback, DIV null,


      DirectMessage @props  
