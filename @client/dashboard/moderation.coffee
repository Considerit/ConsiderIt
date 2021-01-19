window.ModerationDash = ReactiveComponent
  displayName: 'ModerationDash'

  render : -> 
    moderations = @data().moderations
    subdomain = fetch '/subdomain'

    # todo: choose default more intelligently
    @local.model ||= 'Proposal'

    dash = fetch 'moderation_dash'

    all_items = {}

    for model in ['Point', 'Comment', 'Proposal']
      
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

      all_items[model] = [['Pending', reviewable, true], ['Quarantined', quarantined, true], ['Failed', failed, true], ['Passed', passed, false]]
    
    items = all_items[@local.model]
    @items = items 


    # We assume an ordering of the task categories where the earlier
    # categories are more urgent & shown higher up in the list than later categories.

    if !dash.selected_task && items.length > 0
      # Prefer to select a higher urgency task by default

      for [category, itms] in items
        if itms.length > 0
          dash.selected_task = itms[0].key
          save dash
          break

    # After a moderation is saved, that item will alert the dash
    # that we should move to the next moderation.
    # Need state history to handle this more elegantly
    if dash.transition
      @selectNext()

    DIV null,
      DIV null, 

        ModerationOptions()

        UL 
          style: 
            listStyle: 'none'
            margin: '20px auto'
            textAlign: 'center'

          for model in ['Point', 'Comment', 'Proposal']
            select_class = (model) => @local.model = model; save @local

            do (model) => 
              LI 
                style: 
                  display: 'inline-block'

                BUTTON 
                  style: 
                    backgroundColor: if @local.model == model then '#444' else 'transparent'
                    color: if @local.model == model then 'white' else '#aaa'
                    fontSize: 28
                    marginRight: 32
                    border: 'none'
                    borderRadius: 4
                    fontWeight: 700

                  onClick: => select_class(model)
                  onKeyPress: (e) => 
                    if e.which in [13, 32]
                      select_class(model); e.preventDefault()
                  "Review #{model}s"

                  " (#{all_items[model][0][1].length})"



        DIV null, 

          for [category, itms, default_show] in items

            if itms.length > 0
              show_category = (if @local["show_#{category}"]? then @local["show_#{category}"] else default_show)
              toggle_show = do (category, show_category) => =>
                @local["show_#{category}"] = !show_category
                save @local 

              DIV 
                style: 
                  marginTop: 20
                  key: category



                H1 
                  style: 
                    fontSize: 24
                    fontWeight: 700
                    textAlign: 'center'
                    backgroundColor: '#e0e0e0'
                    margin: '20px 0'
                    cursor: 'pointer'
                  onClick: toggle_show

                  category

                  " (#{itms.length})"


                  A 
                    style: 
                      #float: 'right'
                      color: '#aaa'
                      fontWeight: 400
                      verticalAlign: 'middle'
                      paddingRight: 10
                      paddingLeft: 40
                      textDecoration: 'underline'
                      
                    

                    if show_category
                      'Hide'

                    else 
                      'Show'


                if show_category
                  UL 
                    style: {}
                    for item in itms
                      LI 
                        'data-id': item.key
                        key: item.key
                        style: 
                          position: 'relative'
                          listStyle: 'none'

                        onClick: do (item) => => 
                          dash.selected_task = item.key
                          save dash
                          setTimeout => 
                            $("[data-id='#{item.key}']").ensureInView()
                          , 1


                        ModerateItem 
                          key: item.key
                          selected: dash.selected_task == item.key



  # select a different task in the list relative to data.selected_task
  selectNext: -> @_select(false)
  selectPrev: -> @_select(true)
  _select: (reverse) -> 
    dash = fetch 'moderation_dash'
    get_next = false
    all_items = if !reverse then @items else @items.slice().reverse()

    for [category, items, default_show] in all_items
      tasks = if !reverse then items else items.slice().reverse()
      show_category = (if @local["show_#{category}"]? then @local["show_#{category}"] else default_show)
      continue if !show_category

      for item in tasks
        if get_next
          dash.selected_task = item.key
          dash.transition = null
          save dash
          setTimeout => 
            $("[data-id='#{item.key}']").ensureInView()
          , 1
          return
        else if item.key == dash.selected_task
          get_next = true

  componentDidMount: ->
    $(document).on 'keyup.dash', (e) =>
      @selectNext() if e.keyCode == 40 # down
      @selectPrev() if e.keyCode == 38 # up
  componentWillUnmount: ->
    $(document).off 'keyup.dash'






ModerateItem = ReactiveComponent
  displayName: 'ModerateItem'

  render : ->
    item = @data()

    class_name = item.moderatable_type
    moderatable = fetch(item.moderatable)
    author = fetch(moderatable.user)
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
    
    selected = @props.selected 

    item_header = 
      fontWeight: 700
      fontSize: 22

    DIV 
      style: 
        cursor: if selected then 'auto' else 'pointer'
        margin: 'auto'
        borderLeft:  "4px solid #{if selected then focus_color() else 'transparent'}"
        padding: '8px 14px'
        maxWidth: 700
        marginBottom: if selected then 40 else 12



      DIV 
        style: 
          marginLeft: 70
          position: 'relative'

        DIV null, 

          if class_name == 'Comment' && selected #@local.show_conversation && selected
            DIV 
              style: 
                opacity: .5
              BUBBLE_WRAP 
                title: point.nutshell 
                anon: point.hide_name
                user: point.user
                body: point.text
                width: '100%'


              for comment in _.uniq( _.map(comments.comments, (c) -> c.key).concat(moderatable.key)) when comment != moderatable.key
                BUBBLE_WRAP 
                  title: fetch(comment).body
                  user: fetch(comment).user
                  width: '100%'

          BUBBLE_WRAP
            title: if selected then header else tease
            body: if selected then moderatable.description else ''
            anon: !!moderatable.hide_name
            user: moderatable.user
            width: '100%'

          DIV null,
            "by #{author.name}"


            if selected 
              A 
                style: 
                  textDecoration: 'underline'
                  padding: '0 8px'
                target: '_blank'
                href: href
                'data-nojax': true


                "View #{class_name}"

            if selected && !moderatable.hide_name && !@local.messaging
              BUTTON
                style: 
                  marginLeft: 8
                  textDecoration: 'underline'
                  backgroundColor: 'transparent'
                  border: 'none'
                onClick: => @local.messaging = moderatable; save(@local)
                'Message author'



        if selected && @local.messaging
          DirectMessage to: @local.messaging.user, parent: @local, sender_mask: 'Moderator'

      if selected && class_name == 'Proposal'
        # Category
        DIV 
          style: 
            marginTop: 8
            marginLeft: 63
                  
          SELECT
            style: 
              fontSize: 18
            value: proposal.cluster
            ref: 'category'
            onChange: (e) =>
              proposal.cluster = e.target.value
              save proposal

            for list_key in get_all_lists()
              OPTION  
                value: list_key.substring(5)
                get_list_title list_key, true

      if selected 

        judge = (judgement) => 
          # this has to happen first otherwise the dash won't 
          # know what the next item is when it transitions
          dash = fetch 'moderation_dash'
          dash.transition = item.key #need state transitions 
          save dash

          setTimeout => 
            item.status = judgement
            save item
          , 1

        # moderation area
        DIV 
          style:       
            margin: '10px 0px 20px 63px'
            position: 'relative'

          STYLE null, 
            """
            .moderation { font-weight: 600; border-radius: 8px; padding: 6px 12px; display: inline-block; margin-right: 10px; box-shadow: 0px 1px 2px rgba(0,0,0,.4)}
            .moderation label, .moderation input { font-size: 22px; cursor: pointer }
            """

          DIV 
            className: 'moderation',
            style: 
              backgroundColor: '#81c765'
            onClick: -> judge(1)

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'pass'
              defaultChecked: item.status == 1

            LABEL htmlFor: 'pass', 'Pass'

          DIV 
            className: 'moderation'
            style: 
              backgroundColor: '#ffc92a'

            onClick: -> judge(2)

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'quar'
              defaultChecked: item.status == 2
            LABEL htmlFor: 'quar', 'Quarantine'
          DIV 
            className: 'moderation'
            style: 
              backgroundColor: '#f94747'

            onClick: -> judge(0)

            INPUT 
              name: 'moderation'
              type: 'radio'
              id: 'fail'
              defaultChecked: item.status == 0

            LABEL htmlFor: 'fail', 'Fail'

      if selected 

        # status area
        DIV 
          style: 
            marginLeft: 63
            fontStyle: 'italic'


          if item.updated_since_last_evaluation
            SPAN style: {}, "Updated since last moderation"
          else if item.status == 1
            SPAN style: {}, "Passed by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"
          else if item.status == 2
            SPAN style: {}, "Quarantined by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"
          else if item.status == 0
            SPAN style: {}, "Failed by #{fetch(item.user).name} on #{new Date(item.updated_at).toDateString()}"





ModerationOptions = ReactiveComponent
  displayName: 'ModerationOptions'


  render: -> 
    subdomain = fetch '/subdomain'
    if subdomain.moderated_classes.length == 0 
      @local.edit_settings = true 

    expanded = @local.edit_settings

    DIV 
      style: 
        textAlign: if !expanded then 'right'
        paddingRight: if !expanded then 30


      if !expanded 
        BUTTON 
          style: 
            backgroundColor: 'transparent'
            fontSize: 24
            border: 'none'
            textDecoration: 'underline'
            color: '#aaa'
          onClick: => 
            @local.edit_settings = true
            save @local
          'Edit moderation settings'    

      else
        DIV 
          style: 
            padding: 50
                       
          for model in ['points', 'comments', 'proposals']
            # The order of the options is important for the database records
            moderation_options = [
              "Do not moderate #{model}", 
              "Do not publicly post #{model} until moderation", 
              "Post #{model} immediately, but withhold email notifications until moderation", 
              "Post #{model} immediately, catch bad ones afterwards"]

            FIELDSET style: {marginBottom: 12},
              LEGEND style: {fontSize: 24},
                capitalize model

              for field, idx in moderation_options
                DIV 
                  style: {marginLeft: 18, fontSize: 18, cursor: 'pointer'}
                  onClick: do (idx, model) => => 
                    subdomain["moderate_#{model}_mode"] = idx
                    save subdomain, -> 
                      #saving the subdomain shouldn't always dirty moderations 
                      #(which is expensive), so just doing it manually here
                      arest.serverFetch('/page/dashboard/moderate')  

                  INPUT 
                    style: {cursor: 'pointer'}
                    type: 'radio'
                    name: "moderate_#{model}_mode"
                    id: "moderate_#{model}_mode_#{idx}"
                    defaultChecked: subdomain["moderate_#{model}_mode"] == idx

                  LABEL 
                    style: {cursor: 'pointer', paddingLeft: 8 } 
                    htmlFor: "moderate_#{model}_mode_#{idx}"
                    field

          BUTTON 
            onClick: => 
              @local.edit_settings = false
              save @local
            'close'


# TODO: Refactor the below and make sure that the styles applied to the 
#       user generated fields are in sync with the styling in the 
#       wysiwyg editor. 
styles += """
.moderatable_item br {
  padding-bottom: 0.5em; }
.moderatable_item p, 
.moderatable_item ul, 
.moderatable_item ol, 
.moderatable_item table {
  margin-bottom: 0.5em; }
.moderatable_item td {
  padding: 0 3px; }
.moderatable_item li {
  list-style: outside; }
.moderatable_item ol li {
  list-style-type: decimal; }  
.moderatable_item ul,
.moderatable_item ol, {
  padding-left: 20px;
  margin-left: 20px; }
.moderatable_item a {
  text-decoration: underline; }
.moderatable_item blockquote {
  opacity: 0.7;
  padding: 10px 20px; }
.moderatable_item table {
  padding: 20px 0px; }
"""

DirectMessage = ReactiveComponent
  displayName: 'DirectMessage'

  render : -> 
    text_style = 
      width: 500
      fontSize: 16
      display: 'block'
      padding: '4px 8px'

    DIV style: {margin: '18px 0', padding: '15px 20px', backgroundColor: 'white', width: 550, backgroundColor: considerit_gray, boxShadow: "0 2px 4px rgba(0,0,0,.4)"}, 
      DIV style: {marginBottom: 8},
        LABEL null, 'To: ', fetch(@props.to).name

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

      Button {}, 'Send', @submitMessage
      BUTTON style: {marginLeft: 8, backgroundColor: 'transparent', border: 'none'}, onClick: (=> @props.parent.messaging = null; save @props.parent), 'cancel'

  submitMessage : -> 
    # TODO: convert to using arest create method; waiting on full dash porting
    $el = $(@getDOMNode())
    attrs = 
      recipient: @props.to
      subject: $el.find('.message_subject').val()
      body: $el.find('.message_body').val()
      sender_mask: @props.sender_mask or fetch('/current_user').name
      authenticity_token: fetch('/current_user').csrf

    $.ajax '/dashboard/message', data: attrs, type: 'POST', success: => 
      @props.parent.messaging = null
      save @props.parent