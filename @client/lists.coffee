require './questionaire'

window.List = ReactiveComponent
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

    proposals = if !@props.fresh then sorted_proposals(list.proposals, @local.key, true) or [] else []

    list_key = "list/#{list.name}"

    edit_list = fetch "edit-#{list_key}"

    ARTICLE
      key: list.name
      id: if list.name && list.name then list.name.toLowerCase()
      style: 
        marginBottom: if !is_collapsed then 28
        position: 'relative'

      A name: if list.name && list.name then list.name.toLowerCase().replace(/ /g, '_')


      if !@props.fresh
        ManualProposalResort sort_key: @local.key

      ListHeader 
        list: list 
        proposals_count: proposals.length
        fresh: @props.fresh

      if customization('questionaire', list_key) && !is_collapsed
        Questionaire 
          list_key: list_key

      else if !is_collapsed && !@props.fresh
        UL null, 
          for proposal,idx in proposals
            CollapsedProposal 
              key: "collapsed#{proposal.key}"
              proposal: proposal

          if customization('list_show_new_button', list_key) && !edit_list.editing
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

EditList = ReactiveComponent
  displayName: 'EditList'

  render: ->     
    list = @props.list 
    list_key = "list/#{list.name}"    

    current_user = fetch '/current_user'
    edit_list = fetch "edit-#{list_key}"
    subdomain = fetch '/subdomain'

    if @props.fresh && !edit_list.editing
      edit_list.editing = true

    return SPAN null if !current_user.is_admin

    submit = =>
      customizations = JSON.parse subdomain.customizations

      customizations[list_key] ?= {}
      list_config = customizations[list_key]

      fields = ['list_title', 'list_description', 'list_show_new_button', 'slider_pole_labels']

      for f in fields
        val = edit_list[f]
        if val?
          list_config[f] = val

      description = fetch("#{list_key}-description").html
      list_config.list_description = description

      if @props.fresh
        new_key = "list/#{slugify(list.title)}-#{Math.round(Math.random() * 100)}"
        customizations[new_key] = customizations[list_key]
        delete customizations[list_key]

      subdomain.customizations = JSON.stringify customizations, null, 2

      save subdomain, => 
        if subdomain.errors
          console.error "Failed to save list changes", subdomain.errors

        exit_edit()

    cancel_edit = => 
      customizations = JSON.parse subdomain.customizations

      if @props.fresh && list_key of customizations
        delete customizations[list_key] 
        subdomain.customizations = JSON.stringify customizations, null, 2
        save subdomain
      else 
        exit_edit()

    exit_edit = => 
      edit_list.editing = false 
      for k,v of edit_list
        if k != 'key'
          delete edit_list[k]

      save edit_list

    admin_actions = [{action: 'edit', label: t('edit')}, {action: 'delete', label: t('delete')}]

    if !edit_list.editing 

      DropMenu
        options: admin_actions
        open_menu_on: 'activation'

        render_anchor: ->
          GearIcon
            size: 20
            fill: '#888'

        render_option: (option, is_active) ->
          SPAN null, 
            option.label


        selection_made_callback: (option) =>
          if option.action == 'edit' 
            edit_list.editing = true 
            save edit_list

            setTimeout => 
              @refs.input?.getDOMNode().focus()
              @refs.input?.getDOMNode().setSelectionRange(-1, -1) # put cursor at end
          else if option.action == 'delete'
            # TODO: what to do if there are proposals?
            customizations = JSON.parse subdomain.customizations
            delete customizations[list_key] 
            subdomain.customizations = JSON.stringify customizations, null, 2
            save subdomain
            

        wrapper_style: 
          position: 'absolute'
          right: -28
          top: 16

        anchor_style: {}

        menu_style: 
          backgroundColor: '#eee'
          border: "1px solid #{focus_color()}"
          right: -9999
          top: 18
          borderRadius: 8
          fontWeight: 400
          overflow: 'hidden'
          boxShadow: '0 1px 2px rgba(0,0,0,.3)'
          fontSize: 18
          fontStyle: 'normal'

        menu_when_open_style: 
          right: 0

        option_style: 
          padding: '6px 12px'
          borderBottom: "1px solid #ddd"
          display: 'block'

        active_option_style: 
          color: 'white'
          backgroundColor: focus_color()

    else 

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
          onClick: cancel_edit
          onKeyDown: (e) =>
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              cancel_edit(e)  
              e.preventDefault()

          translator 'engage.cancel_button', 'cancel'

window.ListHeader = ReactiveComponent
  displayName: 'ListHeader'

  render: -> 
    list = @props.list 
    list_key = "list/#{list.name}"    

    edit_list = fetch "edit-#{list_key}"

    collapsed = fetch 'collapsed_lists'    
    is_collapsed = !!collapsed[list_key]

    subdomain = fetch '/subdomain'

    description = edit_list.description or customization('list_description', list_key)

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
          fresh: @props.fresh

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

        if edit_list.editing
          DIV null, 
            DIV 
              style: 
                padding: '12px 0'

              LABEL
                style: 
                  marginRight: 4
                htmlFor: 'list_show_new_button'

                translator "engage.list-config-who-can-add", "Who can add responses to this list?"

              DIV null, 
                INPUT 
                  id: 'any-participant'
                  type: 'radio'
                  name: 'list_show_new_button'
                  defaultChecked: customization('list_show_new_button', list_key)
                  onChange: (e) =>
                    edit_list.list_show_new_button = true
                    save edit_list

                LABEL
                  style: 
                    marginRight: 4
                  htmlFor: 'any-participant'

                  translator "engage.list-config-who-can-add-anyone", "Any registered participant"

              DIV null, 
                INPUT 
                  id: 'host-only'
                  type: 'radio'
                  name: 'list_show_new_button'
                  defaultChecked: !customization('list_show_new_button', list_key)
                  onChange: (e) =>
                    edit_list.list_show_new_button = false
                    save edit_list

                LABEL
                  style: 
                    marginRight: 4
                  htmlFor: 'host-only'

                  translator "engage.list-config-who-can-add-only-hosts", "Only forum hosts"

            DIV 
              style: 
                padding: '12px 0'

              LABEL
                style: {}

                translator "engage.list-config-spectrum", "On what spectrum is each response evaluated?"



              DIV 
                ref: 'slider_config'
                style: 
                  margin: '12px 48px'
                  position: 'relative'
                  width: column_sizes().second

                SPAN 
                  style: 
                    display: 'block'
                    width: '100%'
                    borderBottom: '1px solid'
                    borderColor: '#999'
                
                INPUT 
                  type: 'text'
                  style: 
                    position: 'relative'
                    left: 0
                    border: '1px solid'
                    borderColor: if edit_list.slider_pole_labels && edit_list.slider_pole_labels.oppose == '' then '#ccc' else 'transparent'
                    outline: 'none'
                    color: '#999'
                  ref: 'oppose_slider'
                  defaultValue: customization('slider_pole_labels', list_key).oppose 
                  onChange: (e) ->
                    edit_list.slider_pole_labels ?= {}
                    edit_list.slider_pole_labels.oppose = e.target.value 
                    save edit_list

                INPUT
                  type: 'text'
                  style: 
                    position: 'absolute'
                    right: 0
                    border: '1px solid'
                    borderColor: if edit_list.slider_pole_labels && edit_list.slider_pole_labels.support == '' then '#ccc' else 'transparent'
                    outline: 'none'
                    textAlign: 'right'
                    color: '#999'

                  ref: 'support_slider'
                  defaultValue: customization('slider_pole_labels', list_key).support
                  onChange: (e) ->
                    edit_list.slider_pole_labels ?= {}
                    edit_list.slider_pole_labels.support = e.target.value 
                    save edit_list



              DropMenu
                options: (v for k,v of slider_labels).concat({support: '', oppose: ''})
                open_menu_on: 'activation'
                selection_made_callback: (option) => 
                  @refs.oppose_slider.getDOMNode().value = option.oppose
                  @refs.support_slider.getDOMNode().value = option.support
                  edit_list.slider_pole_labels = 
                    support: option.support 
                    oppose: option.oppose 
                  save edit_list

                  setTimeout =>
                    $(@refs.slider_config.getDOMNode()).ensureInView()
                  , 0


                render_anchor: ->

                  DIV 
                    ref: 'slider_config'
                    style: 
                      padding: '18px 48px 32px 48px'
                      position: 'relative'
                      width: column_sizes().second + 48 * 2


                    DIV 
                      style: 
                        position: 'relative'

                      SPAN 
                        style: 
                          display: 'block'
                          width: '100%'
                          borderBottom: '1px solid'
                          borderColor: '#999'


                      
                      INPUT 
                        type: 'text'
                        style: 
                          position: 'absolute'
                          left: 0
                          border: '1px solid'
                          borderColor: if edit_list.slider_pole_labels && edit_list.slider_pole_labels.oppose == '' then '#ccc' else 'transparent'
                          outline: 'none'
                          color: '#999'
                          fontSize: 16
                        ref: 'oppose_slider'
                        defaultValue: customization('slider_pole_labels', list_key).oppose 
                        onChange: (e) ->
                          edit_list.slider_pole_labels ?= {}
                          edit_list.slider_pole_labels.oppose = e.target.value 
                          save edit_list

                      INPUT
                        type: 'text'
                        style: 
                          position: 'absolute'
                          right: 0
                          border: '1px solid'
                          borderColor: if edit_list.slider_pole_labels && edit_list.slider_pole_labels.support == '' then '#ccc' else 'transparent'
                          outline: 'none'
                          color: '#999'
                          fontSize: 16
                          textAlign: 'right'

                        ref: 'support_slider'
                        defaultValue: customization('slider_pole_labels', list_key).support
                        onChange: (e) ->
                          edit_list.slider_pole_labels ?= {}
                          edit_list.slider_pole_labels.support = e.target.value 
                          save edit_list

                    SPAN 
                      style: 
                        fontWeight: 700
                        position: 'absolute'
                        right: 8
                        top: 13

                      SPAN style: _.extend cssTriangle 'bottom', focus_color(), 15, 9,
                        display: 'inline-block'
                        marginLeft: 4   
                        marginBottom: 2

                render_option: (option, is_active) ->
                  if option.oppose == ''
                    return  DIV 
                              style: 
                                fontSize: 22

                              'Custom'

                  DIV 
                    style: 
                      margin: '12px 48px'
                      position: 'relative'
                      fontSize: 16

                    SPAN 
                      style: 
                        display: 'inline-block'
                        width: '100%'
                        borderBottom: '1px solid'
                        borderColor: if is_active then 'white' else '#999'

                    BR null
                    SPAN
                      style: 
                        position: 'relative'
                        left: 0

                      option.oppose 

                    SPAN
                      style: 
                        position: 'absolute'
                        right: 0
                      option.support

                # wrapper_style: 
                #   display: 'inline-block'
                #   position: 'absolute'
                #   right: -38

                anchor_style: 
                  fontWeight: 600
                  padding: 0
                  # display: 'inline-block'
                  color: focus_color() #'inherit'
                  textTransform: 'lowercase'
                  borderRadius: 16
                  border: "1px solid #{focus_color()}"

                menu_style: 
                  width: column_sizes().second + 48 * 2
                  backgroundColor: '#eee'
                  border: "1px solid #{focus_color()}"
                  left: -9999
                  top: 51
                  borderRadius: 8
                  fontWeight: 400
                  overflow: 'hidden'
                  boxShadow: '0 1px 2px rgba(0,0,0,.3)'

                menu_when_open_style: 
                  left: 0

                option_style: 
                  padding: '6px 0px'
                  # borderBottom: "1px solid #ddd"
                  display: 'block'

                active_option_style: 
                  color: 'white'
                  backgroundColor: focus_color()






      if @props.proposals_count > 0 && !customization('questionaire', list_key) && !is_collapsed && !customization('list_no_filters', list_key)
        list_actions
          list: list
          add_new: customization('list_show_new_button', list_key) && !is_collapsed && @props.proposals_count > 4
          can_sort: customization('homepage_show_search_and_sort') && @props.proposals_count > 8 

window.NewList = ReactiveComponent
  displayName: 'NewList'

  render: -> 
    subdomain = fetch '/subdomain'

    if !@local.edit_key
      @local.edit_key = "new-list-#{Math.round(Math.random() * 1000)}"
    
    list = 
      name: @local.edit_key 

    list_key = "list/#{list.name}"    
    edit_list = fetch "edit-#{list_key}"

    if edit_list.editing
      List 
        fresh: true
        list: list 
          


    else 
      BUTTON 
        style: 
          textAlign: 'left'
          marginTop: 35
          display: 'block'
          padding: '18px 24px'
          position: 'relative'
          left: -24
          border: 'none'
          width: '100%'
          borderRadius: 8

        onClick: =>
          edit_list.editing = true
          save edit_list

        onKeyDown: (e) => 
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            e.target.click()
            e.preventDefault()              

        H1
          style: 
            fontSize: 36
            fontWeight: 700
            fontStyle: 'oblique'
            color: '#888'
          translator 'engage.create_new_list_button', "Create new list"


EditableTitle = ReactiveComponent
  displayName: 'EditableTitle'

  render: -> 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    list = @props.list 
    list_key = "list/#{list.name}"    

    edit_list = fetch "edit-#{list_key}"

    list_items_title = customization('list_items_title', list_key) or list.name or 'Proposals'

    title = (edit_list.editing and edit_list.list_title) or customization('list_title', list_key) or list_items_title

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

    description = edit_list.list_description or customization('list_description', list_key)
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
              html: customization('list_description', list_key)
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
              $("[name='add_new_#{props.list.name}']").ensureInView()
              $("[name='add_new_#{props.list.name}']").click()
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


GearIcon = (opts) ->
  SVG 
    height: opts.size or '100px' 
    width: opts.size or '100px'  
    fill: opts.fill or "#888" 
    x: "0px" 
    y: "0px" 
    viewBox: "0 0 100 100"  
    dangerouslySetInnerHTML: __html: '<path d="M95.784,59.057c1.867,0,3.604-1.514,3.858-3.364c0,0,0.357-2.6,0.357-5.692c0-3.092-0.357-5.692-0.357-5.692  c-0.255-1.851-1.991-3.364-3.858-3.364h-9.648c-1.868,0-3.808-1.191-4.31-2.646s-1.193-6.123,0.128-7.443l6.82-6.82  c1.32-1.321,1.422-3.575,0.226-5.01L80.976,11c-1.435-1.197-3.688-1.095-5.01,0.226l-6.82,6.82c-1.32,1.321-3.521,1.853-4.888,1.183  c-1.368-0.67-5.201-3.496-5.201-5.364V4.217c0-1.868-1.514-3.604-3.364-3.859c0,0-2.6-0.358-5.692-0.358s-5.692,0.358-5.692,0.358  c-1.851,0.254-3.365,1.991-3.365,3.859v9.648c0,1.868-1.19,3.807-2.646,4.31c-1.456,0.502-6.123,1.193-7.444-0.128l-6.82-6.82  C22.713,9.906,20.459,9.804,19.025,11L11,19.025c-1.197,1.435-1.095,3.689,0.226,5.01l6.819,6.82  c1.321,1.321,1.854,3.521,1.183,4.888s-3.496,5.201-5.364,5.201H4.217c-1.868,0-3.604,1.514-3.859,3.364c0,0-0.358,2.6-0.358,5.692  c0,3.093,0.358,5.692,0.358,5.692c0.254,1.851,1.991,3.364,3.859,3.364h9.648c1.868,0,3.807,1.19,4.309,2.646  c0.502,1.455,1.193,6.122-0.128,7.443l-6.819,6.819c-1.321,1.321-1.423,3.575-0.226,5.01L19.025,89  c1.435,1.196,3.688,1.095,5.009-0.226l6.82-6.82c1.321-1.32,3.521-1.853,4.889-1.183c1.368,0.67,5.201,3.496,5.201,5.364v9.648  c0,1.867,1.514,3.604,3.365,3.858c0,0,2.599,0.357,5.692,0.357s5.692-0.357,5.692-0.357c1.851-0.255,3.364-1.991,3.364-3.858v-9.648  c0-1.868,1.19-3.808,2.646-4.31s6.123-1.192,7.444,0.128l6.819,6.82c1.321,1.32,3.575,1.422,5.01,0.226L89,80.976  c1.196-1.435,1.095-3.688-0.227-5.01l-6.819-6.819c-1.321-1.321-1.854-3.521-1.183-4.889c0.67-1.368,3.496-5.201,5.364-5.201H95.784  z M50,68.302c-10.108,0-18.302-8.193-18.302-18.302c0-10.107,8.194-18.302,18.302-18.302c10.108,0,18.302,8.194,18.302,18.302  C68.302,60.108,60.108,68.302,50,68.302z"></path>'

