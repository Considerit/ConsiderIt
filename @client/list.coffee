require './modal'


window.styles += """
  .LIST-header {
    font-size: 28px;
    font-weight: 700;
    text-align: left;     
    padding: 0; 
    margin: 0; 
    border: none;
    background-color: transparent;
  }

  .LIST-header.LIST-smaller-header {
    font-size: 32px;
    font-weight: 500;
  }

  .LIST-fat-header-field {
    background-color: white;
    border: 1px solid #eaeaea;
    border-radius: 8px;
    outline-color: #ccc;
    line-height: 1.4;
    padding: 8px 12px;
    // margin-top: -9px;
    margin-left: -13px;

  }

  .LIST-field-edit-label {
    font-size: 14px;
    display: inline-block;
    font-weight: 400;
    margin-top: 18px;
  }

"""

list_link = (list_key) ->
  list_key.substring(5).toLowerCase().replace(/ /g, '_')

window.List = ReactiveComponent
  displayName: 'List'


  # list of proposals
  render: -> 
    current_user = fetch '/current_user'
    list = @props.list
    if !list.key?
      list = get_list(@props.list)


    list_key = list.key

    # subscribe to a key that will alert us to when sort order has changed
    fetch('homepage_you_updated_proposal')

    proposals = list.proposals or []

    list_state = fetch list_key
    list_state.show_first_num_items ?= @props.show_first_num_items or 12
    list_state.collapsed ?= customization('list_is_archived', list_key)

    is_collapsed = list_state.collapsed

    edit_list = fetch "edit-#{list_key}"


    ARTICLE
      key: list_key
      id: list_key.substring(5).toLowerCase()
      style: 
        marginBottom: if !is_collapsed then 40
        position: 'relative'

      A name: list_link(list_key)


      ListHeader 
        list: list
        combines_these_lists: @props.combines_these_lists 
        proposals_count: proposals.length
        fresh: @props.fresh
        allow_editing: !@props.allow_editing? || @props.allow_editing

      if !is_collapsed && !@props.fresh
        
        permitted = permit('create proposal', list_key)
        DIV null, 

          ListItems 
            list: list 
            key: "#{list.key}-items"
            fresh: @props.fresh
            show_first_num_items: if list_state.show_all_proposals then 999999 else list_state.show_first_num_items
            combines_these_lists: @props.combines_these_lists
            show_new_button: (list_state.show_all_proposals || proposals.length <= list_state.show_first_num_items) && \
               ((@props.combines_these_lists && lists_current_user_can_add_to(@props.combines_these_lists).length > 0) || (permitted > 0 || permitted == Permission.NOT_LOGGED_IN) ) && \
                !edit_list.editing

          if !list_state.show_all_proposals && proposals.length > list_state.show_first_num_items 
            BUTTON
              style:
                backgroundColor: '#f9f9f9'
                width: HOMEPAGE_WIDTH()
                textDecoration: 'underline'
                cursor: 'pointer'
                paddingTop: 10
                paddingBottom: 10
                fontWeight: 600
                textAlign: 'center'
                marginTop: 12
                marginBottom: 28
                border: 'none'
                fontSize: 22

              onMouseDown: => 
                list_state.show_all_proposals = true
                save list_state

              translator "engage.show_hidden_proposals", 'Show all'


      if customization('footer', list_key) && !is_collapsed
        customization('footer', list_key)()

ListItems = ReactiveComponent
  displayName: 'ListItems'

  render: ->
    list = @props.list 
    list_key = list.key

    sort_key = "sorted-proposals-#{list_key}"
    proposals = if !@props.fresh then sorted_proposals(list.proposals, sort_key, true) or [] else []

    RenderListItem = customization('RenderListItem') or CollapsedProposal

    if @props.combines_these_lists
      hues = getNiceRandomHues @props.combines_these_lists.length
      colors = {}
      for aggregated_list, idx in @props.combines_these_lists
        colors[aggregated_list] = hues[idx]

    DIV null, 

      UL null, 
        for proposal,idx in proposals
          continue if idx > @props.show_first_num_items - 1

          RenderListItem
            key: "collapsed#{proposal.key}"
            proposal: proposal.key
            show_category: !!@props.combines_these_lists
            category_color: if @props.combines_these_lists then hsv2rgb(colors["list/#{(proposal.cluster or 'Proposals')}"], .9, .8)

        if @props.show_new_button

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
              list_key: list_key
              combines_these_lists: @props.combines_these_lists




__remove_this_list = (list_key, page) ->
  subdomain = fetch '/subdomain'
  list_key = list_key.key or list_key
  tabs = get_tabs()

  customizations = subdomain.customizations

  if tabs
    page ?= get_current_tab_name()
    for tab in tabs
      if tab.name == page
        tab.lists.splice tab.lists.indexOf(list_key), 1
        break
  else if ol = customizations.lists
    ol.splice ol.indexOf(list_key), 1
    if ol.length == 0
      delete customizations.lists

  list_in_other_pages = false
  if tabs
    for tab in tabs
      if tab.lists.indexOf(list_key) > -1 
        list_in_other_pages = true 
        break

  if !list_in_other_pages
    delete customizations[list_key] 
          
  save subdomain


window.delete_list = (list_key, page, suppress_confirmation) ->
  subdomain = fetch '/subdomain'

  list_key = list_key.key or list_key

  tabs = get_tabs()

  list_in_num_pages = 0
  if tabs
    for tab in tabs
      if tab.lists.indexOf(list_key) > -1 
        list_in_num_pages += 1
  else 
    list_in_num_pages = 1 

  if list_in_num_pages <= 1

    proposals = get_proposals_in_list(list_key)

    if proposals?.length > 0 
      has_permission = true 
      for proposal in proposals 
        has_permission &&= permit('delete proposal', proposal) > 0 

      if !has_permission
        alert "You apparently don't have permission to delete one or more of the proposals in this list"
      else if has_permission && (suppress_confirmation || confirm(translator('engage.list-config-delete-confirm', 'Are you sure you want to delete this list? All of the proposals in it will also be permanently deleted. If you want to get rid of the list, but not delete the proposals, you could move the proposals first.')))
        for proposal in proposals
          destroy proposal.key
        __remove_this_list(list_key, page)  

    else if suppress_confirmation || confirm(translator('engage.list-config-delete-confirm-when-no-proposals', 'Are you sure you want to delete this list? This is irreversable.'))
      __remove_this_list(list_key, page)  

  else
    __remove_this_list(list_key, page)  











EditList = ReactiveComponent
  displayName: 'EditList'

  render: ->     
    list = @props.list

    list_key = list.key

    current_user = fetch '/current_user'
    edit_list = fetch "edit-#{list_key}"
    subdomain = fetch '/subdomain'


    return SPAN null if !current_user.is_admin



    admin_actions = [{action: 'edit', label: translator('edit')}, 
                     {action: 'list_order', label: translator('engage.list-configuration.copy_link', 'reorder lists')},
                     {action: 'delete', label: translator('delete')}, 
                     {action: 'close', label: translator('engage.list-configuration.close', 'close to participation')}, 
                     {action: 'copy_link', label: translator('engage.list-configuration.copy_link', 'copy link')}]

    DIV null,

      if !edit_list.editing 

        DropMenu
          options: admin_actions
          open_menu_on: 'activation'

          wrapper_style: 
            position: 'absolute'
            right: -42
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
            width: 220

          menu_when_open_style: 
            right: 0

          option_style: 
            padding: '6px 12px'
            borderBottom: "1px solid #ddd"
            display: 'block'

          active_option_style: 
            color: 'white'
            backgroundColor: focus_color()

          render_anchor: ->
            SPAN 
              "data-tooltip": translator "engage.list-config-icon-tooltip", "Configure list settings" 
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

            else if option.action == 'list_order'
              ef = fetch 'edit_forum'
              ef.editing = true 
              save ef 

            else if option.action == 'delete'
            
              delete_list list

            else if option.action == 'close'
              if confirm(translator('engage.list-config-close-confirm', 'Are you sure you want to close this list to participation? Any proposals in it will also be closed to further participation, though all existing dialogue will remain visible.'))
                
                # close existing proposals to further participation
                if list.proposals?.length > 0 
                  has_permission = true 
                  for proposal in list.proposals 
                    has_permission &&= permit('update proposal', proposal) > 0 
                  if !has_permission
                    alert "You apparently don't have permission to close one or more of the proposals in this list"
                  else 
                    for proposal in list.proposals 
                      proposal.active = false 
                      save proposal 

                customizations = subdomain.customizations

                # don't show a new button for this list anymore
                customizations[list_key].list_permit_new_items = false 

                # # add a note in the description that the list was closed to participation
                # customizations[list_key].list_description ?= ''
                # if customizations[list_key].list_description?.length > 0 
                #   customizations[list_key].list_description += "<br>" 
                # customizations[list_key].list_description += "<DIV style='font-style:italic'>Participation was closed by the host on #{new Date().toDateString()}</div>" 

                save subdomain
            else if option.action == 'copy_link'
              link = "#{location.origin}#{location.search}##{list_link(list_key)}"
              navigator.clipboard.writeText(link).then -> 
                show_flash("Link copied to clipboard")
              , (err) ->
                show_flash_error("Problem copying link to clipboard")
      else 
        ModalNewList
          list: list
          fresh: false
          combines_these_lists: @props.combines_these_lists

  componentDidMount: -> @setFocusOnTitle()

  componentDidUpdate: -> @setFocusOnTitle()

  setFocusOnTitle: ->
    edit_list = fetch "edit-#{@props.list.key}"
    focus_now = @last_edit_state != edit_list.editing && edit_list.editing
    @last_edit_state = edit_list.editing

    if focus_now
      setTimeout =>
        moveCursorToEnd @refs.input?.getDOMNode()




window.ListHeader = ReactiveComponent
  displayName: 'ListHeader'

  render: -> 
    list = @props.list 
    list_key = list.key
    list_state = fetch list_key

    edit_list = fetch "edit-#{list_key}"

    is_collapsed = list_state.collapsed

    subdomain = fetch '/subdomain'

    description = edit_list.description or customization('list_description', list_key, subdomain)

    DIVIDER = customization 'list_divider', list_key, subdomain

    wrapper_style = 
      width: HOMEPAGE_WIDTH()
      marginBottom: 16 #24
      position: 'relative'

    if edit_list.editing 
      _.extend wrapper_style, 
        backgroundColor: '#f3f3f3'
        marginLeft: -36
        marginTop: -36
        padding: "18px 36px 36px 36px"
        width: HOMEPAGE_WIDTH() + 36 * 2

    edit_list.discussion_enabled ?= customization('discussion_enabled', list_key)
    edit_list.list_is_archived ?= customization('list_is_archived', list_key)

    DIV 
      style: wrapper_style 

      DIVIDER?()

      DIV 
        style: 
          position: 'relative'


        DIV 
          style: 
            width:  HOMEPAGE_WIDTH()
            margin:  'auto'

          EditableTitle
            list: @props.list
            fresh: @props.fresh

          if edit_list.editing || !is_collapsed
            DIV null, 
              if description?.length > 0 || typeof(description) == 'function' || edit_list.editing
                EditableDescription
                  list: @props.list
                  fresh: @props.fresh


      if @props.allow_editing
        EditList
          list: @props.list
          fresh: @props.fresh
          combines_these_lists: @props.combines_these_lists

      if !edit_list.editing && @props.proposals_count > 0 && !customization('questionaire', list_key, subdomain) && !is_collapsed && !customization('list_no_filters', list_key, subdomain)
        list_actions
          list: @props.list
          add_new: !@props.combines_these_lists && customization('list_permit_new_items', list_key, subdomain) && !is_collapsed && @props.proposals_count > 4
          can_sort: customization('homepage_show_search_and_sort', null, subdomain) && @props.proposals_count > 1 
          fresh: @props.fresh



window.NewList = ReactiveComponent
  displayName: 'NewList'

  render: -> 
    subdomain = fetch '/subdomain'

    if !@local.edit_key
      @local.edit_key = "list/new-list-#{Math.round(Math.random() * 1000)}"
    
    list = 
      key: @local.edit_key 

    list_key = list.key
    edit_list = fetch "edit-#{list_key}"

    @local.hovering ?= false

    if edit_list.editing || @props.edit_immediately
      ModalNewList 
        fresh: true
        list: list
        done_callback: @props.done_callback

    else 
      BUTTON 
        style: 
          textAlign: 'left'
          marginTop: 35
          display: 'block'
          padding: '18px 24px'
          position: 'relative'
          left: -24
          width: '100%'
          borderRadius: 8
          backgroundColor: if @local.hovering then '#eaeaea' else '#efefef'
          border: '1px solid'
          borderColor: if @local.hovering then '#bbb' else '#ddd'

        onMouseEnter: =>
          @local.hovering = true 
          save @local 
        onMouseLeave: => 
          @local.hovering = false
          save @local 

        onClick: =>
          edit_list.editing = true
          save edit_list

        onKeyDown: (e) => 
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            e.target.click()
            e.preventDefault()              

        H1
          style: 
            fontSize: 28
            fontWeight: 700
            color: if @local.hovering then '#444' else '#666'

          translator 'engage.create_new_list_button', "Create a new list"

        DIV 
          style: 
            fontSize: 14
            marginTop: 4
          'A list defines a category like "Recommendations" or poses an open-ended question like "What are your ideas?"'




styles += """
  [data-widget="ModalNewList"] .LIST-fat-header-field {
    margin-left: 0;
  }

"""
window.ModalNewList = ReactiveComponent
  displayName: 'ModalNewList'
  mixins: [Modal]

  render: -> 
    list = @props.list
    list_key = list.key

    current_user = fetch '/current_user'
    edit_list = fetch "edit-#{list_key}"
    subdomain = fetch '/subdomain'


    return SPAN null if !current_user.is_admin


 

    submit = =>


      customizations = subdomain.customizations

      customizations[list_key] ?= {}
      list_config = customizations[list_key]

      fields = ['list_title', 'list_description', 'list_permit_new_items', 'list_category', 'slider_pole_labels', 'list_opinions_title', 'discussion_enabled', 'list_is_archived']

      for f in fields
        val = edit_list[f]

        if val?
          list_config[f] = val

      description = fetch("#{list_key}-description").html
      if description == "<p><br></p>"
        description = ""

      list_config.list_description = description


      if @props.fresh
        new_name = "#{slugify(list_config.list_title or list_config.list_category or 'Proposals')}-#{Math.round(Math.random() * 100)}"
        new_key = "list/#{new_name}"
        customizations[new_key] = customizations[list_key]
        _.defaults customizations[new_key], 
          created_by: current_user.user 
          created_at: Date.now()
        delete customizations[list_key]

        # if tabs are enabled, add it to the current tab
        if get_tabs()
          tab = get_tab() 
          if tab
            tab.lists.push new_key
          else
            console.error "Cannot add the list to the current tab #{current_tab}"
        else 
          customizations.lists ?= get_all_lists()
          if customizations.lists.indexOf('*') == -1 && customizations.lists.indexOf(new_key) == -1
            customizations.lists.push new_key
          console.log 'NEW CUSTOMZIATION', customizations.lists, new_key


      save subdomain, => 
        if subdomain.errors
          console.error "Failed to save list changes", subdomain.errors

        exit_edit()

    cancel_edit = => 
      customizations = subdomain.customizations

      if @props.fresh && list_key of customizations
        delete customizations[list_key] 
        save subdomain
      else 
        exit_edit()

    exit_edit = => 
      edit_list.editing = false 
      for k,v of edit_list
        if k != 'key' && k != 'editing'
          delete edit_list[k]

      save edit_list

      @props.done_callback?()

    edit_list.discussion_enabled ?= customization('discussion_enabled', list_key)
    edit_list.list_is_archived ?= customization('list_is_archived', list_key)

    title = get_list_title list_key, true, subdomain
    description = edit_list.description or customization('list_description', list_key, subdomain)
    if Array.isArray(description)
      description = description.join('\n')

    description_style = customization 'list_description_style', list_key

    option_block = 
      marginTop: 8

    children = \ 
        DIV 
          style: 
            marginTop: 24

          DIV null, 
            DIV 
              className: 'LIST-field-edit-label'

              TRANSLATE
                id: "engage.list-config-title"
                span: 
                  component: SPAN 
                  args: 
                    style: 
                      fontWeight: 700

                "<span>Title.</span> Usually an open-ended question like \"What are your ideas?\" or a list label like \"Recommended actions for mitigation\"."

            H1 
              className: 'LIST-header'

              AutoGrowTextArea
                id: "title-#{list_key}"
                className: 'LIST-header LIST-fat-header-field'
                ref: 'input'
                focus_on_mount: true
                style: _.defaults {}, customization('list_label_style', list_key, subdomain) or {}, 
                  fontFamily: header_font()
                  width: HOMEPAGE_WIDTH() + -200

                defaultValue: if !@props.fresh then title
                onChange: (e) ->
                  edit_list.list_title = e.target.value 
                  save edit_list


          DIV null, 
            if description?.length > 0 || typeof(description) == 'function' || edit_list.editing


              DIV
                style: _.defaults {}, (description_style or {})
                className: 'LIST-description'

                if typeof description == 'function'
                  description()        
                else 

                  DIV null,

                    DIV 
                      className: 'LIST-field-edit-label'

                      TRANSLATE
                        id: "engage.list-config-description"
                        span: 
                          component: SPAN 
                          args: 
                            style: 
                              fontWeight: 700

                        "<span>Description [optional].</span> Give any additional information or direction here."

                    DIV 
                      id: 'edit_description'
                      style:
                        # marginTop: -12
                        width:  HOMEPAGE_WIDTH() - 200

                      STYLE
                        dangerouslySetInnerHTML: __html: """
                          #edit_description .ql-editor {
                            min-height: 48px;
                            padding: 12px 12px;
                            border: 1px solid #eaeaea;
                            border-radius: 8px;
                            background-color: white;

                          }
                        """

                      WysiwygEditor
                        key: "#{list_key}-description"
                        horizontal: true
                        html: customization('list_description', list_key)
                        # placeholder: if !@props.fresh then translator("engage.list_description", "(optional) Description")
                        toolbar_style: 
                          right: 0
                        container_style: 
                          borderRadius: 8
                        style: 
                          fontSize: if browser.is_mobile then 32





          DIV null, 

            if !@props.combines_these_lists
              slider_input_style = 
                paddingTop: 2
                position: 'absolute'
                border: 'none'
                outline: 'none'
                color: '#444'
                fontSize: if browser.is_mobile then 16 else 12

              DIV 
                style: 
                  padding: '12px 0'

                LABEL
                  className: 'LIST-field-edit-label'


                  TRANSLATE
                    id: "engage.list-config-spectrum"
                    span: 
                      component: SPAN 
                      args: 
                        style: 
                          fontWeight: 700

                    "<span>Slider.</span> On what spectrum is each item evaluated?"


                DIV 
                  ref: 'slider_config'
                  style: 
                    padding: '18px 24px 0px 24px'
                    position: 'relative'
                    marginTop: 8
                    left: -24 - 1

                  DIV 
                    style: 
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
                      style: _.extend {}, slider_input_style, 
                        left: 0
                        textAlign: 'left'

                      ref: 'oppose_slider'
                      defaultValue: customization('slider_pole_labels', list_key, subdomain).oppose 
                      placeholder: translator 'engage.slider_config.negative-pole-placeholder', 'Negative pole'
                      onChange: (e) ->
                        edit_list.slider_pole_labels ?= {}
                        edit_list.slider_pole_labels.oppose = e.target.value 
                        save edit_list

                    INPUT
                      type: 'text'
                      style: _.extend {}, slider_input_style, 
                        textAlign: 'right'
                        right: 0

                      ref: 'support_slider'
                      defaultValue: customization('slider_pole_labels', list_key, subdomain).support
                      onChange: (e) ->
                        edit_list.slider_pole_labels ?= {}
                        edit_list.slider_pole_labels.support = e.target.value 
                        save edit_list
                      placeholder: translator 'engage.slider_config.positive-pole-placeholder', 'Positive pole'


                  DropMenu
                    options: [{support: '', oppose: ''}].concat (v for k,v of slider_labels)
                    open_menu_on: 'activation'

                    wrapper_style: 
                      left: 390
                      top: -8

                    anchor_style: 
                      color: 'inherit' #focus_color() #'inherit'
                      height: '100%'
                      padding: '4px 4px'
                      position: 'relative'
                      right: 0
                      cursor: 'pointer'

                    menu_style: 
                      width: column_sizes().second + 24 * 2
                      backgroundColor: '#fff'
                      border: "1px solid #aaa"
                      left: -99999
                      left: 'auto'
                      top: 24
                      fontWeight: 400
                      overflow: 'hidden'
                      boxShadow: '0 1px 2px rgba(0,0,0,.3)'
                      textAlign: 'left'

                    menu_when_open_style: 
                      left: 0

                    option_style: 
                      padding: '6px 0px'
                      display: 'block'
                      color: '#888'

                    active_option_style: 
                      color: 'black'
                      backgroundColor: '#efefef'


                    selection_made_callback: (option) => 
                      @refs.oppose_slider.getDOMNode().value = option.oppose
                      @refs.support_slider.getDOMNode().value = option.support


                      edit_list.slider_pole_labels = 
                        support: option.support 
                        oppose: option.oppose 
                      save edit_list


                      setTimeout =>
                        $(@refs.slider_config.getDOMNode()).ensureInView()

                        if option.oppose == ''
                          moveCursorToEnd @refs.oppose_slider.getDOMNode()

                      , 100


                    render_anchor: ->
                      SPAN null, 
                        LABEL 
                          style: 
                            color: focus_color()
                            fontSize: 14
                            marginRight: 12
                            cursor: 'pointer'
                          translator 'engage.list-config-spectrum-select', 'change spectrum'

                        SPAN style: _.extend cssTriangle 'bottom', focus_color(), 15, 9,
                          display: 'inline-block'

                    render_option: (option, is_active) ->
                      if option.oppose == ''
                        return  DIV 
                                  style: 
                                    fontSize: 16
                                    borderBottom: '1px dashed #ccc'
                                    textAlign: 'center'
                                    padding: '12px 0'

                                  translator "engage.list-config-custom-spectrum", "Custom Spectrum"

                      DIV 
                        style: 
                          margin: "12px 24px"
                          position: 'relative'
                          fontSize: 12

                        SPAN 
                          style: 
                            display: 'inline-block'
                            width: '100%'
                            borderBottom: '1px solid'
                            borderColor: '#666'

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




            if !@props.combines_these_lists
              DIV 
                style: 
                  padding: '12px 0'

                LABEL
                  className: 'LIST-field-edit-label'
                  htmlFor: 'list_permit_new_items'


                  TRANSLATE
                    id: "engage.list-config-who-can-add"
                    span: 
                      component: SPAN 
                      args: 
                        style: 
                          fontWeight: 700

                    "<span>Permissions.</span> Who can add items to this list?"

                DIV 
                  style: option_block

                  INPUT 
                    id: 'any-participant'
                    type: 'radio'
                    name: 'list_permit_new_items'
                    defaultChecked: customization('list_permit_new_items', list_key, subdomain)
                    onChange: (e) =>
                      edit_list.list_permit_new_items = true
                      save edit_list

                  LABEL
                    style: 
                      marginLeft: 4
                    htmlFor: 'any-participant'

                    translator "engage.list-config-who-can-add-anyone", "Any registered participant"

                DIV
                  style: option_block

                  INPUT 
                    id: 'host-only'
                    type: 'radio'
                    name: 'list_permit_new_items'
                    defaultChecked: !customization('list_permit_new_items', list_key, subdomain)
                    onChange: (e) =>
                      edit_list.list_permit_new_items = false
                      save edit_list

                  LABEL
                    style: 
                      marginLeft: 4
                    htmlFor: 'host-only'

                    translator "engage.list-config-who-can-add-only-hosts", "Only forum hosts or those granted permission"


            if !@props.combines_these_lists

              DIV 
                style:
                  marginTop: 24
                  marginBottom: 12



                if !@local.show_all_options 
                  BUTTON 
                    className: 'like_link'
                    style: 
                      textDecoration: 'underline'
                      fontWeight: 700
                      color: '#666'
                      fontSize: 14
                    onClick: (e) => 
                      @local.show_all_options = true 
                      save @local
                    onKeyPress: (e) => 
                      if e.which == 13 || e.which == 32 # ENTER or SPACE
                        e.preventDefault()
                        e.target.click()
                    'Show more options'
                else 
                  DIV null, 


                    DIV 
                      style:
                        marginBottom: 6
                      LABEL 
                        style: {}

                        INPUT 
                          type: 'checkbox'
                          defaultChecked: !edit_list.discussion_enabled
                          name: 'discussion_enabled'
                          onChange: (e) =>
                            edit_list.discussion_enabled = !edit_list.discussion_enabled
                            save edit_list

                        SPAN 
                          style: 
                            paddingLeft: 4
                          translator 'engage.list-config-discussion-enabled', 'Disable commenting. Spectrums only.'

                    DIV                   
                      style:
                        marginBottom: 6
                      LABEL 
                        style: {}

                        INPUT 
                          type: 'checkbox'
                          defaultChecked: edit_list.list_is_archived
                          name: 'list_is_archived'
                          onChange: (e) =>
                            edit_list.list_is_archived = !edit_list.list_is_archived
                            save edit_list

                        SPAN 
                          style: 
                            paddingLeft: 4
                          translator 'engage.list-config-archived', 'Close list by default on page load. Useful for archiving past issues.'








          BUTTON 
            className: 'btn'
            style: 
              backgroundColor: focus_color()
            disabled: !(edit_list.list_title?.length > 0)
            onClick: submit
            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                e.target.click()
                e.preventDefault()

            translator 'engage.save_changes_button', 'Save'

          BUTTON
            className: 'like_link'
            style: 
              color: '#777'
              fontSize: 18
              marginLeft: 12
              position: 'relative'
              top: 2
            onClick: cancel_edit
            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                e.target.click()
                e.preventDefault()

            translator 'shared.cancel_button', 'cancel'










    wrap_in_modal children, HOMEPAGE_WIDTH() + 72




EditableTitle = ReactiveComponent
  displayName: 'EditableTitle'

  render: -> 
    current_user = fetch '/current_user'

    list = @props.list 
    list_key = list.key

    list_state = fetch list_key
    is_collapsed = list_state.collapsed

    subdomain = fetch '/subdomain'

    title = get_list_title list_key, true, subdomain

    list_uncollapseable = customization 'list_uncollapseable', list_key, subdomain
    TITLE_WRAPPER = if list_uncollapseable then DIV else BUTTON

    tw = if is_collapsed then 15 else 20
    th = if is_collapsed then 20 else 15    

    toggle_list = ->
      if !list_uncollapseable
        list_state.collapsed = !list_state.collapsed
        save list_state


    DIV null, 

      H1 
        className: 'LIST-header'
        style: # ugly...we only want to show the expand/collapse icon
          fontSize: if title.replace(/^\s+|\s+$/g, '').length == 0 then 0

        TITLE_WRAPPER
          tabIndex: if !list_uncollapseable then 0
          'aria-label': "#{title}. #{translator('Expand or collapse list.')}"
          'aria-pressed': !is_collapsed
          onMouseEnter: => @local.hover_label = true; save @local 
          onMouseLeave: => @local.hover_label = false; save @local
          className: 'LIST-header'          
          style: _.defaults {}, customization('list_label_style', list_key, subdomain) or {}, 
            fontFamily: header_font()              
            cursor: if !list_uncollapseable then 'pointer'
            position: 'relative'
            textAlign: 'left'
            outline: 'none'

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
              style: 
                position: 'absolute'
                left: -tw - 20
                top: if is_collapsed then 0 else 3
                paddingRight: 20
                paddingTop: 12
                display: 'inline-block'

              SPAN 
                
                style: cssTriangle (if is_collapsed then 'right' else 'bottom'), ((customization('list_label_style', list_key, subdomain) or {}).color or 'black'), tw, th,
                  width: tw
                  height: th
                  opacity: if @local.hover_label or is_collapsed then 1 else .1
                  outline: 'none'
                  display: 'inline-block'
                  verticalAlign: 'top'

        


styles += """
  .LIST-description {
    font-size: 16px;
    font-weight: 400;
    color: black;
    margin-top: 8px;
  }

"""

EditableDescription = ReactiveComponent
  displayName: 'EditableDescription'
  render: -> 
    current_user = fetch '/current_user'

    list = @props.list 
    list_key = list.key

    description = customization('list_description', list_key)
    if Array.isArray(description)
      description = description.join('\n')

    description_style = customization 'list_description_style', list_key


    DIV
      style: _.defaults {}, (description_style or {})
      className: 'LIST-description'

      if typeof description == 'function'
        description()        
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
  list_key = props.list.key

  add_new = props.add_new
  if add_new 
    permitted = permit('create proposal', list_key)
    add_new &&= permitted > 0 || permitted == Permission.NOT_LOGGED_IN


  DIV   
    className: 'list_actions'
    style: 
      marginBottom: 50
      marginTop: 24
      display: 'flex'

    DIV 
      style: 
        width: column_sizes().first
        marginRight: column_sizes().gutter
        display: 'flex'

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
              list_state = fetch list_key
              list_state.show_all_proposals = true 
              save list_state
              e.stopPropagation()

              wait_for = ->
                add_new_button = $("[name='new_#{props.list.key.substring(5)}']")
                if add_new_button.length > 0 
                  add_new_button.ensureInView()
                  add_new_button.click()
                else 
                  setTimeout wait_for, 1

              wait_for()

            translator "engage.add_new_proposal_to_list", 'add new'

      if props.can_sort && add_new
        SPAN 
          style: 
            padding: '0 12px'

      if props.can_sort
        SortProposalsMenu()


      if !props.fresh
        sort_key = "sorted-proposals-#{list_key}"
        SPAN 
          style: 
            display: 'inline-block'
            marginLeft: 12
          
          ManualProposalResort {sort_key}

        

    OpinionViews
      style: 
        width: column_sizes().second
      more_views_positioning: 'right'

      additional_width: column_sizes().gutter + column_sizes().first




styles += """
  [data-widget="EditPage"] .radio_group {
    margin-top: 24px;
    margin-left: 0;
  }
  [data-widget="EditPage"] .field_explanation {
    font-size: 15px;
    margin-top: 3px;
  }
  [data-widget="EditPage"] .radio_group label {
    font-size: 18px;
    font-weight: 700;
  }

  [data-widget="EditPage"] .draggable-list {
    background-color: #f1f1f1;
    border: 1px solid #ddd;
    padding: 12px 24px 12px 12px;
    border-radius: 16px;
    margin: 4px 0;
    display: flex;
    align-items: start;
    position: relative;
  }

  [data-widget="EditPage"] .draggable-list[draggable="true"] {
    cursor: move;
  }

  [data-widget="EditPage"] .draggable-list.dragging {
    height: 6px;
    padding: 0;
    border: none;
  }

  [data-widget="EditPage"] .draggable-list.dragging * {
    display: none;
  }


  [data-widget="EditPage"] .draggable-wrapper::after, [data-widget="EditPage"] .draggable-wrapper::before {
    // border: 2px dotted #888;
    border-radius: 16px;
    // padding-bottom: 60px;
    height: 0px;
    display: block;
    content: "";
    margin: 0;
    transition: height 1s;
  }

  [data-widget="EditPage"] .draggable-wrapper.draggedOver.from_above::after, [data-widget="EditPage"] .draggable-wrapper.draggedOver.from_below::before {
    height: 60px;
    outline: 1px dotted #888;

  }


  [data-widget="EditPage"] .wildcard .draggable-list {
    background-color: #E3EDE0;
    border: 1px solid #CEDACA;
  }

  [data-widget="EditPage"] .draggable-list button {
    flex-shrink: 0;
    flex-grow: 0;
    display: inline-block;
    background-color: transparent;
    border: none;
  }
  [data-widget="EditPage"] .draggable-list .name {
    font-size: 16px; 
    font-weight: 500;
    padding-left: 24px;
    flex-grow: 1;
    cursor: move;
  }

  [data-widget="EditPage"] H2.list_header {
    font-size: 22px;
  }

  [data-widget="EditPage"] button.convert_page, [data-widget="EditPage"] button.add_new_list {
    padding: 8px 16px;
    border: 1px solid #ccc;
    border-radius: 8px;
    margin-top: 12px;
  }
   
"""

window.PAGE_TYPES =
  ABOUT: 'about'
  ALL: 'all'
  DEFAULT: 'default'

window.EditPage = ReactiveComponent
  displayName: "EditPage"

  mixins: [SubdomainSaveRateLimiter]

  drawAboutPage: -> 
    subdomain = fetch '/subdomain'

    return DIV null if @props.page_name != get_current_tab_name()

    DIV null, 
      I null, 
        "This is an About page."
      @renderPreamble()

  drawShowAllPage: -> 
    subdomain = fetch '/subdomain'

    return DIV null if @props.page_name != get_current_tab_name()

    DIV null, 
      I null, 
        "This page displays all lists shown on other pages in this forum."
      @renderPreamble()
      @renderSortOrder()



  drawDefaultPage: -> 
    subdomain = fetch '/subdomain'

    is_a_tab = !!get_tabs()

    edit_forum = fetch "edit_forum"

    if is_a_tab
      @ordered_lists = get_tab(@props.page_name)?.lists
      if !@ordered_lists
        console.error "No lists for tab. Returning"
        return DIV null
    else
      subdomain.customizations.lists ?= get_all_lists()
      @ordered_lists = subdomain.customizations.lists

    return DIV null if @props.page_name != get_current_tab_name()

    current_list_sort_method = get_list_sort_method(@props.page_name)


    drag_capabilities = ""
    if @ordered_lists.length > 1 && current_list_sort_method == 'fixed'
      drag_capabilities += "Drag lists to reorder them. "

    if get_tabs()?.length > 1 
      drag_capabilities += "Lists can be dragged to a different tab to move them."



    DIV {style: position: 'relative'},




      DIV 
        style: 
          marginTop: 36
          marginBottom: 24


        H2
          className: "list_header"

          'Lists'

          DIV 
            style:
              fontSize: 14
              fontWeight: 400
            'A list defines a category like "Recommendations" or poses an open-ended question like "What are your ideas?"'


        if @ordered_lists.length == 0
          DIV 
            style: 
              textAlign: 'center'
              padding: '36px 24px'
              border: '1px dotted #eee'
              backgroundColor: '#f1f1f1'

            "There are no lists here yet."

        else if @ordered_lists.length > 0 
          DIV 
            style: 
              fontSize: 14

            drag_capabilities

        UL 
          style: 
            marginTop: 24
            listStyle: 'none'
            # opacity: if current_list_sort_method != 'fixed' then .5
            # pointerEvents: if current_list_sort_method != 'fixed' then 'none'

          for lst, idx in @ordered_lists
            do (lst, idx) =>
              wildcard = lst in ['*', '*-']
              if wildcard
                lists_to_add = (ag_lst for ag_lst in get_all_lists() \
                                       when ag_lst not in @ordered_lists)

              LI 
                "data-idx": idx
                "data-list-key": lst
                className: "draggable-wrapper #{if wildcard then 'wildcard'}"


                DIV 
                  className: "draggable-list"
                  draggable: drag_capabilities.length > 0 
                  

                  if drag_capabilities.length > 0 
                    BUTTON 
                      "data-tooltip": drag_capabilities
                      style: 
                        cursor: 'move'

                      drag_icon 15, '#888'

                  DIV
                    className: 'name'

                    if wildcard
                      SPAN 
                        style: 
                          fontStyle: 'italic'
                        "All of the rest of the lists (#{lists_to_add.length} total)"
                    else 
                      get_list_title lst, true, subdomain


                  if wildcard 
                    if lists_to_add.length > 0 
                      disaggregate_wildcard = => 
                        for ag_lst in lists_to_add
                          @ordered_lists.splice idx, 0, ag_lst
                        save edit_forum
                                  
                      BUTTON 
                        className: 'disaggregate like_link'
                        onClick: disaggregate_wildcard
                        onKeyPress: (e) -> 
                          if e.which == 13 || e.which == 32 # ENTER or SPACE
                            e.preventDefault()
                            e.target.click()

                        'disaggregate'


                  BUTTON 
                    style: 
                      cursor: 'pointer'
                    "data-tooltip": "Edit list"
                    onClick: (e) =>
                      e.preventDefault()
                      e.stopPropagation()
                      @local.edit_list = lst
                      save @local

                    onKeyPress: (e) -> 
                      if e.which == 13 || e.which == 32 # ENTER or SPACE
                        e.preventDefault()
                        e.target.click()

                    edit_icon 18, 18, '#888'



                  BUTTON 
                    style:
                      position: 'absolute'
                      right: -36
                      cursor: 'pointer'
                    "data-tooltip": "Delete list"
                    onClick: (e) =>
                      if wildcard 
                        @refs.aggregate_checkbox.getDOMNode().click()
                      else 
                        @ordered_lists.splice( @ordered_lists.indexOf(lst), 1  )
                        delete_list(lst)


                    onKeyPress: (e) => 
                      if e.which == 13 || e.which == 32 # ENTER or SPACE
                        e.preventDefault()
                        e.target.click()
                    trash_icon 23, 23, '#888'


        if @local.add_new_list || @local.edit_list
          NewList
            edit_immediately: true
            list: @local.edit_list
            done_callback: => 
              @local.add_new_list = @local.edit_list = false 
              save @local

        else 
          BUTTON
            className: "add_new_list"
            "data-tooltip": "Create a new List"
            onClick: =>
              @local.add_new_list = true 
              save @local
            onKeyPress: (e) => 
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                e.preventDefault()
                e.target.click()
            "+ add new list"


      @renderSortOrder()
      @renderPreamble()

      @renderPageType()



  renderPageType: -> 
    is_a_tab = !!get_tabs()
    return SPAN null if !is_a_tab

    FIELDSET 
      style: 
        marginLeft: 0
        marginTop: 42
        border: "1px solid #ccc"
        padding: "0px 24px 18px 24px"

      LABEL 
        style: 
          fontSize: 17
          marginTop: 36
          fontWeight: 700
          marginBottom: 24
          backgroundColor: 'white'
          padding: "4px 8px"
          position: 'relative'
          top: -12

        "Convert this page"

      DIV null,

        DIV
          style: 
            marginTop: 0

          BUTTON 
            className: 'convert_page'
            onClick: => 
              if @ordered_lists.length == 0 || confirm "Are you sure you want to convert this page? You may want to move the existing lists to a different tab first."
                @ordered_lists.splice(0,@ordered_lists.length) 
                @ordered_lists.push '*'

                @local.type = PAGE_TYPES.ALL
                save @local
                save edit_forum

            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                e.target.click()
                e.preventDefault()
            "Change to a \"Show all\" page"

          DIV 
            style: 
              fontSize: 14
            "All lists, such as those in other tabs, are shown on this page too."

        DIV 
          style: 
            marginTop: 18

          BUTTON
            className: 'convert_page'
            onClick: => 
              if @ordered_lists.length == 0 || confirm "Are you sure you want to convert this page? You may want to move the existing lists to a different tab first."            
                @local.type = PAGE_TYPES.ABOUT
                save @local
                @ordered_lists.splice(0, @ordered_lists.length)
                save edit_forum()

            onKeyDown: (e) =>
              if e.which == 13 || e.which == 32 # ENTER or SPACE
                e.target.click()
                e.preventDefault()
            "Change to an \"About\" page"    
          DIV 
            style: 
              fontSize: 14
            "An About Page can help give participants additional background about the engagement."


  renderSortOrder: -> 
    current_list_sort_method = get_list_sort_method(@props.page_name)

    if @local.type == PAGE_TYPES.DEFAULT
      list_orderings = [
        {value: 'fixed', label: 'Fixed order', explanation: 'Lists always ordered as specified above.'}
        {value: 'newest_item', label: 'Order by most recent activity', explanation: 'The lists with the most recent activity are shown first.'}
        {value: 'randomized', label: 'Randomized', explanation: 'Lists are show in a random order on page load.'}
      ]
    else if @local.type == PAGE_TYPES.ALL
      list_orderings = [
        {value: 'by_tab', label: 'Fixed order', explanation: 'Lists ordered as they are in the other tabs.'}
        {value: 'newest_item', label: 'Order by most recent activity', explanation: 'The lists with the most recent activity are shown first.'}
        {value: 'randomized', label: 'Randomized', explanation: 'Lists are show in a random order on page load.'}
      ]
    else 
      list_orderings = null

    FIELDSET 
      style: 
        marginLeft: 0
        marginTop: 32

      LABEL 
        style: 
          fontSize: 17
          marginTop: 36
          fontWeight: 700
          marginRight: 12

        "List order:"


      SELECT
        defaultValue: current_list_sort_method
        style: 
          fontSize: 18
        onChange: (e) => 
          @local.list_sort_method = e.target.value
          save @local

        for option in list_orderings
          OPTION
            value: option.value
            option.label 

      if option.explanation
        for option in list_orderings
          if option.value == (@local.list_sort_method or current_list_sort_method)
            DIV 
              className: 'explanation field_explanation'
              option.explanation


  renderPreamble: -> 
    current_preamble = get_page_preamble(@props.page_name)
    preamble_text = fetch "#{@props.page_name}-preamble"

    if preamble_text.html? && preamble_text.html != @local.page_preamble
      @local.page_preamble = preamble_text.html
      save @local

    FIELDSET 
      style: 
        marginTop: 36
      B
        style: 
          display: 'inline-block'
          fontSize: 17

        if @local.type == PAGE_TYPES.ABOUT
          "Background Information"
        else 
          "Preamble"

      SPAN 
        style: 
          fontSize: 14
          fontWeight: 400
          paddingLeft: 6
        "optional"


      WysiwygEditor
        key: "#{@props.page_name}-preamble"
        horizontal: true
        html: current_preamble
        # placeholder: if !@props.fresh then translator("engage.list_description", "(optional) Description")
        toolbar_style: 
          right: 0
        container_style: 
          borderRadius: 8
          minHeight: 60
          width: '100%'     
          border: '1px solid #ccc'  
          marginTop: 4   
          padding: '8px 12px'
        style: 
          fontSize: 16


      DIV 
        style: 
          fontSize: 14
          marginTop: 2

        """This field supports HTML, with the exception of <script>, <iframe> and <style> tags (use inline styles instead)."""
        if @local.type == PAGE_TYPES.ABOUT
        
          """ If you need to embed a video, please contact help@consider.it."""


  render: -> 

    @local.type ?= get_tab(@props.page_name)?.type or PAGE_TYPES.DEFAULT
    
    console.assert !get_tabs() || @props.page_name, @props.page_name, @local

    if @local.type == PAGE_TYPES.DEFAULT
      @drawDefaultPage()
    else if @local.type == PAGE_TYPES.ALL
      @drawShowAllPage()
    else if @local.type == PAGE_TYPES.ABOUT
      @drawAboutPage()


  saveIfChanged: ->
    edit_forum = fetch 'edit_forum'
    customizations = fetch('/subdomain').customizations

    fields = ['list_sort_method', 'page_preamble']

    changed_here = false

    if get_tabs()
      config = get_tab(@props.page_name)

      if !config # this is usually fine
        console.error "Config not found, can't save subdomain"
        return

      if (config.type || @local.type != 'default') && @local.type != config.type
        config.type = @local.type
        changed_here = true
    else 
      config = customizations

    if !config
      console.error "Could not find a config, and thus could not save possible page changes #{@props.page_name}"
      return

    @save_customization_with_rate_limit {fields, config, force_save: changed_here}

  componentDidUpdate: ->
    @makeListsDraggable()
    @saveIfChanged()

  componentDidMount: -> 
    @makeListsDraggable()    

  makeListsDraggable: ->
    return if @props.page_name != get_current_tab_name()

    reorder_list_position = (from, to) => 
      edit_forum = fetch('edit_forum')
      moving = @ordered_lists[from]

      @ordered_lists.splice from, 1
      @ordered_lists.splice to, 0, moving

      save edit_forum

    drag_data = fetch 'list/tab_drag'


    @onDragStart ?= (e) =>

      _.extend drag_data,
        type: 'list'
        source_page: @props.page_name
        id: e.currentTarget.parentElement.getAttribute('data-idx')
      save drag_data

      document.body.classList.add('dragging-list')
      el = e.currentTarget
      setTimeout ->
        if !el.classList.contains('dragging')
          el.classList.add('dragging')

    @onDragEnd ?= (e) =>

      delete drag_data.type
      delete drag_data.source_page
      delete drag_data.id
      save drag_data

      document.body.classList.remove('dragging-list')
      if e.currentTarget.classList.contains('dragging')
        e.currentTarget.classList.remove('dragging')


    @onDragOver ?= (e) =>

      if drag_data.type == 'list'

        e.preventDefault()

        idx = parseInt e.currentTarget.getAttribute('data-idx')
        
        @draggedOver = idx
        if !e.currentTarget.classList.contains('draggedOver')
          e.currentTarget.classList.add('draggedOver')
          if drag_data.id < idx
            e.currentTarget.classList.remove('from_below')
            e.currentTarget.classList.add('from_above')
          else 
            e.currentTarget.classList.remove('from_above')            
            e.currentTarget.classList.add('from_below')

    @onDragLeave ?= (e) =>
      if drag_data.type == 'list'       
        e.preventDefault()
        if e.currentTarget.classList.contains('draggedOver')
          e.currentTarget.classList.remove('draggedOver')

    @onDrop ?= (e) =>
      if drag_data.type == 'list'

        reorder_list_position drag_data.id, @draggedOver
        if e.currentTarget.classList.contains('draggedOver')
          e.currentTarget.classList.remove('draggedOver')
        if e.currentTarget.classList.contains('from_above')
          e.currentTarget.classList.remove('from_above')
        if e.currentTarget.classList.contains('from_below')
          e.currentTarget.classList.remove('from_below')

      document.body.classList.remove('dragging-list')


    for list in @getDOMNode().querySelectorAll('[draggable]')
      list.removeEventListener('dragstart', @onDragStart) 
      list.removeEventListener('dragend', @onDragEnd) 
      list.addEventListener('dragstart', @onDragStart) 
      list.addEventListener('dragend', @onDragEnd)       

    for list in @getDOMNode().querySelectorAll('[data-idx]')
      list.removeEventListener('dragover', @onDragOver)
      list.removeEventListener('dragleave', @onDragLeave)      
      list.removeEventListener('drop', @onDrop) 

      list.addEventListener('dragover', @onDragOver)
      list.addEventListener('dragleave', @onDragLeave)      
      list.addEventListener('drop', @onDrop) 




  componentWillUnmount: -> 
    if @initialized
      for list in @getDOMNode().querySelectorAll('[draggable]')
        list.removeEventListener('dragstart', @onDragStart) 
        list.removeEventListener('dragend', @onDragEnd) 
        list.addEventListener('dragstart', @onDragStart) 
        list.addEventListener('dragend', @onDragEnd)       

      for list in @getDOMNode().querySelectorAll('[data-idx]')
        list.removeEventListener('dragover', @onDragOver)
        list.removeEventListener('dragleave', @onDragLeave)      
        list.removeEventListener('drop', @onDrop) 




window.get_list_title = (list_key, include_category_value, subdomain) -> 
  edit_list = fetch "edit-#{list_key}"

  if edit_list.editing
    title = edit_list.list_title

  title ?= customization('list_title', list_key, subdomain)
  if include_category_value
    title ?= category_value list_key, null, subdomain

  if title == 'Show all' || !title?
    title = translator "engage.all_proposals_list", "All Proposals"
  else if title == 'Proposals'
    title = translator "engage.default_proposals_list", "Proposals"

  title 


category_value = (list_key, fresh, subdomain) -> 

  edit_list = fetch "edit-#{list_key}"
  category = if edit_list.editing then edit_list.list_category
  category ?= customization('list_category', list_key, subdomain)
  if !category && !customization(list_key, null, subdomain) && !fresh # if we haven't customized this list, take the proposal category
    category ?= list_key.substring(5)
  category ?= translator 'engage.default_proposals_list', 'Proposals'
  category


histo_title = (list_key) -> 
  edit_list = fetch "edit-#{list_key}"
  opinion_title = if edit_list.editing then edit_list.list_opinions_title
  if !opinion_title? 
    opinion_title = customization('list_opinions_title', list_key)
  if !opinion_title?
    opinion_title = translator 'engage.header.Opinions', 'Opinions'
  opinion_title


GearIcon = (opts) ->
  SVG 
    height: opts.size or '100px' 
    width: opts.size or '100px'  
    fill: opts.fill or "#888" 
    x: "0px" 
    y: "0px" 
    viewBox: "0 0 100 100"  
    dangerouslySetInnerHTML: __html: '<path d="M95.784,59.057c1.867,0,3.604-1.514,3.858-3.364c0,0,0.357-2.6,0.357-5.692c0-3.092-0.357-5.692-0.357-5.692  c-0.255-1.851-1.991-3.364-3.858-3.364h-9.648c-1.868,0-3.808-1.191-4.31-2.646s-1.193-6.123,0.128-7.443l6.82-6.82  c1.32-1.321,1.422-3.575,0.226-5.01L80.976,11c-1.435-1.197-3.688-1.095-5.01,0.226l-6.82,6.82c-1.32,1.321-3.521,1.853-4.888,1.183  c-1.368-0.67-5.201-3.496-5.201-5.364V4.217c0-1.868-1.514-3.604-3.364-3.859c0,0-2.6-0.358-5.692-0.358s-5.692,0.358-5.692,0.358  c-1.851,0.254-3.365,1.991-3.365,3.859v9.648c0,1.868-1.19,3.807-2.646,4.31c-1.456,0.502-6.123,1.193-7.444-0.128l-6.82-6.82  C22.713,9.906,20.459,9.804,19.025,11L11,19.025c-1.197,1.435-1.095,3.689,0.226,5.01l6.819,6.82  c1.321,1.321,1.854,3.521,1.183,4.888s-3.496,5.201-5.364,5.201H4.217c-1.868,0-3.604,1.514-3.859,3.364c0,0-0.358,2.6-0.358,5.692  c0,3.093,0.358,5.692,0.358,5.692c0.254,1.851,1.991,3.364,3.859,3.364h9.648c1.868,0,3.807,1.19,4.309,2.646  c0.502,1.455,1.193,6.122-0.128,7.443l-6.819,6.819c-1.321,1.321-1.423,3.575-0.226,5.01L19.025,89  c1.435,1.196,3.688,1.095,5.009-0.226l6.82-6.82c1.321-1.32,3.521-1.853,4.889-1.183c1.368,0.67,5.201,3.496,5.201,5.364v9.648  c0,1.867,1.514,3.604,3.365,3.858c0,0,2.599,0.357,5.692,0.357s5.692-0.357,5.692-0.357c1.851-0.255,3.364-1.991,3.364-3.858v-9.648  c0-1.868,1.19-3.808,2.646-4.31s6.123-1.192,7.444,0.128l6.819,6.82c1.321,1.32,3.575,1.422,5.01,0.226L89,80.976  c1.196-1.435,1.095-3.688-0.227-5.01l-6.819-6.819c-1.321-1.321-1.854-3.521-1.183-4.889c0.67-1.368,3.496-5.201,5.364-5.201H95.784  z M50,68.302c-10.108,0-18.302-8.193-18.302-18.302c0-10.107,8.194-18.302,18.302-18.302c10.108,0,18.302,8.194,18.302,18.302  C68.302,60.108,60.108,68.302,50,68.302z"></path>'


window.get_all_lists = ->
  all_lists = []

  # Give primacy to specified order of lists in tab config or ordered_list customization
  subdomain = fetch('/subdomain')
  if get_tabs()
    for tab in get_tabs()
      all_lists = all_lists.concat (l for l in tab.lists when l != '*' && l != '*-')
  else if customization 'lists'
    all_lists = (l for l in customization('lists') when l != '*' && l != '*-')

  # lists might also just be defined as a customization, without any proposals in them yet
  subdomain_name = subdomain.name?.toLowerCase()
  config = customizations[subdomain_name]
  for k,v of config 
    if k.match( /list\// )
      all_lists.push k

  proposals = fetch '/proposals'
  all_lists = all_lists.concat("list/#{(p.cluster or 'Proposals').trim()}" for p in proposals.proposals)

  all_lists = _.uniq all_lists
  all_lists


get_list_sort_method = (tab) ->
  tab ?= get_current_tab_name()
  get_tab(tab)?.list_sort_method or customization('list_sort_method') or \
    (if customization('lists') || get_tabs() then 'fixed' else 'newest_item')



lists_ordered_by_most_recent_update = {}
lists_ordered_by_randomized = {}

window.get_lists_for_page = (tab) -> 
  homepage_tabs = fetch 'homepage_tabs'
  tab ?= get_current_tab_name()
  tabs_config = get_tabs()

  if tabs_config
    eligible_lists = get_tab(tab).lists
  else
    eligible_lists = customization 'lists'
    if eligible_lists && '*-' in eligible_lists
      console.error "Illegal wildcard *- in lists customization"
      

  if !eligible_lists
    eligible_lists = ['*']

  ##################################################
  # lists_in_tab will be the list_keys for the tab, in the specified 
  # fixed order, with wildcards substituted

  lists_in_tab = []

  for list in eligible_lists

    if list == '*' || (list == '*-' && !tabs_config)
      for ll in get_all_lists()
        if ll not in eligible_lists
          lists_in_tab.push ll      

    # '*-' matches all lists that are not already referenced in other tabs
    else if list == '*-'
      referenced_elsewhere = {}

      for a_tab in tabs_config
        continue if a_tab.name == tab
        for ll in a_tab.lists 
          if ll != '*' && ll != '*-'
            referenced_elsewhere[ll] = true

      for ll in get_all_lists()
        if ll not of referenced_elsewhere && ll not in eligible_lists
          lists_in_tab.push ll

    else 
      lists_in_tab.push list



  ######################################################
  # now we'll flesh the lists out with proposals
  proposals = fetch '/proposals'
  lists_with_proposals = {}

  for list_key in lists_in_tab
    lists_with_proposals[list_key] = 
      key: list_key
      proposals: []

  for proposal in proposals.proposals 
    list_key = "list/#{(proposal.cluster or 'Proposals').trim()}"
    if list_key of lists_with_proposals
      lists_with_proposals[list_key].proposals.push proposal


  ######################################################
  # ...and finally, let's sort the lists if there's a different sorted order other than fixed

  list_sort_method = get_list_sort_method(tab)

  lists_in_order = (lists_with_proposals[list_key] for list_key in lists_in_tab) # this is already fixed sort

  if list_sort_method == 'newest_item'

    # Sort lists by the newest of its proposals.
    # But we'll only do this on page load or if the number of lists has changed, 
    # so that lists don't move around when someone adds a new proposal.
    lists_ordered_by_most_recent_update[tab] ?= {}
    by_recency = lists_ordered_by_most_recent_update[tab]

    if Object.keys(by_recency).length != lists_in_order.length
      for lst in lists_in_order 
        by_recency[lst.key] = -1 # in case there aren't any proposals in it
        for proposal in lst.proposals 
          time = (new Date(proposal.created_at).getTime())
          if !by_recency[lst.key] || time > by_recency[lst.key]
            by_recency[lst.key] = time 

    for lst in lists_in_order
      if by_recency[lst.key] && by_recency[lst.key] > 0
        lst.order = (new Date()).getTime() - by_recency[lst.key]
      else 
        lst.order = 9999999999999

    lists_in_order.sort (a,b) -> a.order - b.order

  else if list_sort_method == 'randomized'
    lists_ordered_by_randomized[tab] ?= {}
    by_random = lists_ordered_by_randomized[tab]
    if Object.keys(by_random).length != lists_in_order.length
      for lst in lists_in_order
        by_random[lst.key] = Math.random()

    for lst in lists_in_order
      if by_random[lst.key]
        lst.order = by_random[lst.key]
      else 
        lst.order = 9999999999999

    lists_in_order.sort (a,b) -> a.order - b.order


  lists_in_order


window.get_proposals_in_list = (list_key) -> 
  proposals = fetch '/proposals'

  (p for p in proposals.proposals when "list/#{(p.cluster or 'Proposals').trim()}" == list_key)


window.get_list = (list_key) ->
  lst = _.extend {}, customization(list_key),
    key: list_key
    proposals: get_proposals_in_list(list_key)

window.lists_current_user_can_add_to = (lists) -> 
  appendable = []
  for list_key in lists 
    if permit('create proposal', list_key) > 0
      appendable.push list_key 
  appendable















