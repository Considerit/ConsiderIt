require './questionaire'

# window.Cluster is temporary for hala.consider.it. After deployed, just need to change it in Hala's customization
window.List = window.Cluster = ReactiveComponent
  displayName: 'List'


  # list of proposals
  render: -> 
    list = @props.list

    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    # subscribe to a key that will alert us to when sort order has changed
    fetch('homepage_you_updated_proposal')

    collapsed = fetch 'collapsed_lists'
    is_collapsed = !!collapsed[@props.key]

    proposals = sorted_proposals(list.proposals, @local.key, true)

    return SPAN null if !proposals

    list_key = "list/#{list.name}"

    ARTICLE
      key: list.name
      id: if list.name && list.name then list.name.toLowerCase()
      style: 
        marginBottom: if !is_collapsed then 28
        position: 'relative'

      A name: if list.name && list.name then list.name.toLowerCase().replace(/ /g, '_')


      ManualProposalResort sort_key: @local.key

      ListHeading 
        list: list 
        proposals_count: proposals.length

      if customization('questionaire', list_key) && !is_collapsed
        Questionaire 
          list_key: list_key

      else if !is_collapsed
        UL null, 
          for proposal,idx in proposals

            CollapsedProposal 
              key: "collapsed#{proposal.key}"
              proposal: proposal

          if customization('list_show_new_button', list_key)
            LI 
              key: "new#{list_key}"
              style: 
                margin: 0 
                padding: 0
                listStyle: 'none'
                display: 'inline-block'
                marginBottom: 20
                marginTop: 6
                

              NewProposal 
                list_name: list.name
                local: @local.key
                label_style: {}

      if customization('footer', list_key) && !is_collapsed
        customization('footer', list_key)()


GearIcon = (opts) ->
  SVG 
    height: opts.size or '100px' 
    width: opts.size or '100px'  
    fill: opts.fill or "#888" 
    x: "0px" 
    y: "0px" 
    viewBox: "0 0 100 100"  
    dangerouslySetInnerHTML: __html: '<path d="M95.784,59.057c1.867,0,3.604-1.514,3.858-3.364c0,0,0.357-2.6,0.357-5.692c0-3.092-0.357-5.692-0.357-5.692  c-0.255-1.851-1.991-3.364-3.858-3.364h-9.648c-1.868,0-3.808-1.191-4.31-2.646s-1.193-6.123,0.128-7.443l6.82-6.82  c1.32-1.321,1.422-3.575,0.226-5.01L80.976,11c-1.435-1.197-3.688-1.095-5.01,0.226l-6.82,6.82c-1.32,1.321-3.521,1.853-4.888,1.183  c-1.368-0.67-5.201-3.496-5.201-5.364V4.217c0-1.868-1.514-3.604-3.364-3.859c0,0-2.6-0.358-5.692-0.358s-5.692,0.358-5.692,0.358  c-1.851,0.254-3.365,1.991-3.365,3.859v9.648c0,1.868-1.19,3.807-2.646,4.31c-1.456,0.502-6.123,1.193-7.444-0.128l-6.82-6.82  C22.713,9.906,20.459,9.804,19.025,11L11,19.025c-1.197,1.435-1.095,3.689,0.226,5.01l6.819,6.82  c1.321,1.321,1.854,3.521,1.183,4.888s-3.496,5.201-5.364,5.201H4.217c-1.868,0-3.604,1.514-3.859,3.364c0,0-0.358,2.6-0.358,5.692  c0,3.093,0.358,5.692,0.358,5.692c0.254,1.851,1.991,3.364,3.859,3.364h9.648c1.868,0,3.807,1.19,4.309,2.646  c0.502,1.455,1.193,6.122-0.128,7.443l-6.819,6.819c-1.321,1.321-1.423,3.575-0.226,5.01L19.025,89  c1.435,1.196,3.688,1.095,5.009-0.226l6.82-6.82c1.321-1.32,3.521-1.853,4.889-1.183c1.368,0.67,5.201,3.496,5.201,5.364v9.648  c0,1.867,1.514,3.604,3.365,3.858c0,0,2.599,0.357,5.692,0.357s5.692-0.357,5.692-0.357c1.851-0.255,3.364-1.991,3.364-3.858v-9.648  c0-1.868,1.19-3.808,2.646-4.31s6.123-1.192,7.444,0.128l6.819,6.82c1.321,1.32,3.575,1.422,5.01,0.226L89,80.976  c1.196-1.435,1.095-3.688-0.227-5.01l-6.819-6.819c-1.321-1.321-1.854-3.521-1.183-4.889c0.67-1.368,3.496-5.201,5.364-5.201H95.784  z M50,68.302c-10.108,0-18.302-8.193-18.302-18.302c0-10.107,8.194-18.302,18.302-18.302c10.108,0,18.302,8.194,18.302,18.302  C68.302,60.108,60.108,68.302,50,68.302z"></path>'

EditableTitle = ReactiveComponent
  displayName: 'EditableTitle'

  render: -> 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    list = @props.list 
    list_key = "list/#{list.name}"    

    edit_list = fetch "edit-#{list_key}"

    list_items_title = customization('list_items_title', list_key) or list.name or 'Proposals'

    # list_label is deprecated, will be migrated / removed
    title = (edit_list.editing and edit_list.list_title) or customization('list_title', list_key) or customization('list_label', list_key) or list_items_title

    if title == 'Show all'
      title = translator "engage.all_proposals_list", "All Proposals"
    else if title == "Proposals"
      title = translator "engage.default_proposals_list", "Proposals"
    else 
      title = translator 
                id: "proposal_list.#{title}"
                key: "/translations/#{subdomain.name}"
                title 

    heading_style = _.defaults {}, customization('list_label_style', list_key),
      fontSize: 36
      fontWeight: 700
      fontStyle: 'oblique'

    if title.replace(/^\s+|\s+$/g, '').length == 0 # trim whitespace
      heading_style.fontSize = 0 

    list_uncollapseable = customization 'list_uncollapseable', list_key
    TITLE_WRAPPER = if list_uncollapseable then DIV else BUTTON

    collapsed = fetch 'collapsed_lists'    
    is_collapsed = !!collapsed[list_key]

    tw = if is_collapsed then 15 else 20
    th = if is_collapsed then 20 else 15    

    toggle_list = ->
      if !list_uncollapseable
        collapsed[list_key] = !collapsed[list_key] 
        save collapsed

    is_admin = fetch('/current_user').is_admin
    title_style = 
      padding: 0 
      margin: 0 
      border: 'none'
      backgroundColor: 'transparent'
      textAlign: 'left'
      color: heading_style.color
      fontWeight: heading_style.fontWeight
      fontFamily: heading_style.fontFamily
      fontStyle: heading_style.fontStyle
      textDecoration: heading_style.textDecoration

    H1
      style: heading_style

      if edit_list.editing
        AutoGrowTextArea
          id: "title-#{list_key}"
          ref: 'input'
          style: _.extend {}, title_style, 
            fontSize: heading_style.fontSize
            width: '100%'
            lineHeight: 1.4

          defaultValue: title
          onChange: (e) ->
            edit_list.list_title = e.target.value 
            save edit_list
          placeholder: translator('engage.list_title_input-open.placeholder', 'Ask an open-ended question or set a list title')


      else 
        TITLE_WRAPPER 
          tabIndex: if !list_uncollapseable then 0
          'aria-label': "#{title}. #{translator('Expand or collapse list.')}"
          'aria-pressed': !collapsed[list_key]
          onMouseEnter: => @local.hover_label = true; save @local 
          onMouseLeave: => @local.hover_label = false; save @local
          style: _.extend {}, title_style, 
            cursor: if !list_uncollapseable then 'pointer'
            position: 'relative'

          onKeyDown: if !list_uncollapseable then (e) -> 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              toggle_list()
              e.preventDefault()
          onClick: if !list_uncollapseable then (e) -> 
            toggle_list()
            document.activeElement.blur()

          title 

          if current_user.is_admin
            SPAN 
              style: 
                position: 'absolute'
                right: -28

              onKeyDown: (e) => 
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  e.target.click()
                  e.preventDefault()

              onClick: if is_admin then (e) => 
                edit_list.editing = true 
                save edit_list
                e.preventDefault()
                e.stopPropagation()

                setTimeout => 
                  @refs.input?.getDOMNode().focus()
                  @refs.input?.getDOMNode().setSelectionRange(-1, -1) # put cursor at end

              GearIcon
                size: 20
                fill: '#888'


          if !list_uncollapseable
            SPAN 
              'aria-hidden': true
              style: cssTriangle (if is_collapsed then 'right' else 'bottom'), (heading_style.color or 'black'), tw, th,
                position: 'absolute'
                left: -tw - 20
                top: 16
                width: tw
                height: th
                display: if @local.hover_label or is_collapsed then 'inline-block' else 'none'
                outline: 'none'


EditableDescription = ReactiveComponent
  displayName: 'EditableDescription'
  render: -> 
    list = @props.list 

    list_key = "list/#{list.name}"    
    edit_list = fetch "edit-#{list_key}"

    description = edit_list.list_description or customization('list_description', list_key) or customization('list_one_line_desc', list_key)
    description_style = customization 'list_description_style', list_key

    current_user = fetch '/current_user'

    DIV
      style: _.defaults {}, (description_style or {}),
        fontSize: 18
        fontWeight: 400 
        color: '#444'
        marginTop: 6

      if _.isFunction description
        description()
      else 

        if current_user.is_admin && edit_list.editing
          DIV 
            id: 'edit_description'
            STYLE
              dangerouslySetInnerHTML: __html: """
                #edit_description .ql-editor {
                  min-height: 48px;
                }
              """

            WysiwygEditor
              key: "#{list_key}-description"
              horizontal: true
              html: customization('list_description', list_key) or customization('list_one_line_desc', list_key)
              placeholder: translator("engage.list_description", "(optional) Description")

        else 
          desc = description
          if typeof desc == 'string'
            desc = [description]

          for para, idx in desc
            DIV 
              key: idx
              style:
                marginBottom: 10
              dangerouslySetInnerHTML: {__html: para}


EditList = ReactiveComponent
  displayName: 'EditList'

  render: -> 
    list = @props.list 
    list_key = "list/#{list.name}"    

    current_user = fetch '/current_user'
    edit_list = fetch "edit-#{list_key}"

    return SPAN null if !current_user.is_admin || !edit_list.editing

    submit = =>
      subdomain = fetch '/subdomain'
      customizations = JSON.parse subdomain.customizations
      customizations[list_key] ?= {}
      list_config = customizations[list_key]

      fields = ['list_title', 'list_description']

      for f in fields
        val = edit_list[f]
        if val?
          list_config[f] = val

      description = fetch("#{list_key}-description").html
      list_config.list_description = description

      subdomain.customizations = JSON.stringify customizations, null, 2

      save subdomain, => 
        if subdomain.errors
          console.error "Failed to save list changes", subdomain.errors

        exit_edit()

    exit_edit = => 
      edit_list.editing = false 
      for k,v of edit_list
        if k != 'key'
          delete edit_list[k]

      save edit_list


    DIV 
      style: 
        position: 'absolute'
        top: -35
        left: 0

      BUTTON 
        style: 
          border: 'none'
          borderRadius: 8
          padding: '4px 8px'
        onClick: submit
        onKeyDown: (e) =>
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            @submit(e)  
            e.preventDefault()

        translator 'engage.save_changes_button', 'Save'

      BUTTON
        style: 
          backgroundColor: 'transparent'
          border: 'none'
          textDecoration: 'underline'
        onClick: exit_edit
        onKeyDown: (e) =>
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            @exit_edit(e)  
            e.preventDefault()

        translator 'engage.cancel_button', 'cancel'




window.ListHeading = ReactiveComponent
  displayName: 'ListHeading'

  render: -> 
    list = @props.list 
    list_key = "list/#{list.name}"    

    edit_list = fetch "edit-#{list_key}"

    collapsed = fetch 'collapsed_lists'    
    is_collapsed = !!collapsed[list_key]

    subdomain = fetch '/subdomain'

    description = edit_list.description or customization('list_description', list_key) or customization('list_one_line_desc', list_key)

    DIVIDER = customization 'list_divider', list_key

    DIV 
      style: 
        width: HOMEPAGE_WIDTH()
        marginBottom: 16 #24
        position: 'relative'

      DIVIDER?()

      DIV 
        style: 
          position: 'relative'

        EditList
          list: @props.list

        EditableTitle
          list: @props.list


        if !is_collapsed



          if description || edit_list.editing
            EditableDescription
              list: @props.list


          else if false && widthWhenRendered(heading_text, heading_style) <= column_sizes().first + column_sizes().gutter

            histo_title = customization('list_opinions_title', list_key)

            DIV
              style: 
                width: column_sizes().second
                display: 'inline-block'
                verticalAlign: 'top'
                marginLeft: column_sizes().margin
                whiteSpace: 'nowrap'
                position: 'absolute'
                top: 0
                right: 0
                textAlign: 'right'
                fontWeight: heading_style.fontWeight
                color: heading_style.color
                fontSize: heading_style.fontSize
                fontStyle: 'oblique'

              TRANSLATE
                id: "engage.list_opinions_title.#{histo_title}"
                key: if histo_title == customizations.default.list_opinions_title then '/translations' else "/translations/#{subdomain.name}"
                histo_title


      if @props.proposals_count > 0 && !customization('questionaire', list_key) && !is_collapsed && !customization('list_no_filters', list_key)
        list_actions
          list: list
          add_new: customization('list_show_new_button', list_key) && !is_collapsed && @props.proposals_count > 4
          can_sort: customization('homepage_show_search_and_sort') && @props.proposals_count > 8 





window.list_actions = (props) -> 

  add_new = props.add_new
  if add_new 
    permitted = permit('create proposal')
    add_new &&= permitted > 0 || permitted == Permission.NOT_LOGGED_IN

  DIV 
    style: 
      marginTop: 12
      marginBottom: 50

    if add_new

      SPAN null, 
        A
          style: 
            textDecoration: 'underline'
            fontSize: 20
            color: focus_color()
            fontFamily: customization('font')
            fontStyle: 'normal'
            fontWeight: 700
          onClick: (e) => 
            show_all = fetch('show_all_proposals')
            show_all.show_all = true 
            save show_all
            e.stopPropagation()

            setTimeout =>
              $("[name='add_new_#{props.cluster.name}']").ensureInView()
            , 1
          translator "engage.add_new_proposal_to_list", 'add new'

    if props.can_sort && add_new
      SPAN 
        style: 
          padding: '0 24px'
          fontSize: 20
        '|'

    if props.can_sort
      SortProposalsMenu()



    OpinionFilter
      style: 
        display: 'inline-block'
        float: 'right'
        maxWidth: column_sizes().second
        textAlign: 'right'
      enable_comparison_wrapper_style: 
        position: 'absolute'
        right: 0 
        bottom: -20
        fontSize: 14
        zIndex: 99
      

    DIV 
      style: 
        clear: 'both'