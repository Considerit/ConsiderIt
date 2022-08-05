


styles += """
  [data-widget="EditList"] .default_drop[data-widget="DropMenu"] .dropmenu-menu {
    right: -9999;
    left: auto;
  }

  [data-widget="EditList"] .default_drop[data-widget="DropMenu"] .dropmenu-menu.dropmenu-menu-open {
    right: 0;
    left: auto;
  }


  [data-widget="EditList"] .default_drop[data-widget="DropMenu"] .dropmenu-menu {
    width: 250px;
  }

  [data-widget="EditList"] .default_drop[data-widget="DropMenu"] .menu-item {
    text-align: right;
  }  

"""
window.EditList = ReactiveComponent
  displayName: 'EditList'

  render: ->     
    list = @props.list

    list_key = list.key

    current_user = fetch '/current_user'
    edit_list = fetch "edit-#{list_key}"
    subdomain = fetch '/subdomain'

    return SPAN null if !current_user.is_admin

    admin_actions = [
      {action: 'edit', label: translator('edit', 'edit')}
      {action: 'copy_link', label: translator('engage.list-configuration.copy_link', 'copy link')}
      {action: 'list_order', label: translator('engage.list-configuration.reorder_topics', 'reorder lists')}
      {action: 'close', label: translator('engage.list-configuration.close', 'close to participation')}
      {action: 'delete', label: translator('delete', 'delete')}
    ]

    DIV null,

      if !@local.editing

        DropMenu
          className: 'default_drop'

          options: admin_actions
          open_menu_on: 'activation'

          wrapper_style: 
            position: 'absolute'
            right: -LIST_PADDING() + 10
            top: 12
            minWidth: 'auto'
            paddingLeft: 40

          render_anchor: ->
            SPAN 
              "data-tooltip": translator "engage.list-config-icon-tooltip", "Configure list settings" 
              GearIcon
                size: 20
                fill: '#888'

          render_option: (option, is_active) ->
            SPAN 
              key: option.action
              "data-option": option.action
              option.label


          selection_made_callback: (option) =>
            if option.action == 'edit' 
              @local.editing = true 
              save @local

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
          done_callback: => 
            @local.editing = false 
            save @local




styles += """
  .LIST-fat-header-field {
    background-color: white;
    border: 1px solid #eaeaea;
    border-radius: 8px;
    outline-color: #ccc;
    line-height: 1.4;
    padding: 8px 12px;
  }

  .LIST-field-edit-label {
    font-size: 14px;
    display: inline-block;
    font-weight: 400;
    margin-top: 18px;
  }
"""


window.ModalNewList = ReactiveComponent
  displayName: 'ModalNewList'
  mixins: [Modal]

  get_list_key: -> 
    if @props.fresh 
      @local.edit_key ?= "list/new-list-#{Math.round(Math.random() * 1000)}"
      list_key = @local.edit_key
    else 
      list_key = @props.list.key or @props.list
    list_key

  render: -> 

    list_key = @get_list_key()

    current_user = fetch '/current_user'
    edit_list = fetch "edit-#{list_key}"
    subdomain = fetch '/subdomain'


    return SPAN null if !current_user.is_admin


 

    submit = =>


      customizations = subdomain.customizations

      customizations[list_key] ?= {}
      list_config = customizations[list_key]

      fields = ['list_title', 'list_description', 'list_permit_new_items', 'list_item_name', 'list_category', 'slider_pole_labels', 'list_opinions_title', 'discussion_enabled', 'list_is_archived']

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

      exit_edit()

    exit_edit = => 
      for k,v of edit_list
        if k != 'key'
          delete edit_list[k]

      save edit_list

      @props.done_callback?()

    edit_list.list_category ?= customization('list_category', list_key)
    edit_list.list_item_name ?= customization('list_item_name', list_key)
    edit_list.discussion_enabled ?= customization('discussion_enabled', list_key)
    edit_list.list_is_archived ?= customization('list_is_archived', list_key)

    title = edit_list.title or get_list_title list_key, true, subdomain

    if !@props.fresh
      edit_list.list_title ?= title 

    description = edit_list.description or customization('list_description', list_key, subdomain)
    if Array.isArray(description)
      description = description.join('\n')

    description_style = customization 'list_description_style', list_key


    permit_new_items = customization('list_permit_new_items', list_key, subdomain)

    option_block = 
      display: 'flex'
      alignItems: 'center'
      marginTop: 8

    children = \ 
        DIV null,

          DIV null, 
            DIV 
              className: 'LIST-field-edit-label'

              TRANSLATE
                id: "engage.list-config-title"
                span: 
                  component: SPAN 
                  args: 
                    key: 'title'
                    style: 
                      fontWeight: 700

                "<span>Heading.</span> An open-ended question like \"What are your ideas?\" or a category like \"Recommendations\"."

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

            DIV
              style: _.defaults {}, (description_style or {})

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
                          key: 'span'
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
                      editor_key: "#{list_key}-description"
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
                        key: 'span'
                        style: 
                          fontWeight: 700

                    "<span>Slider.</span> On what spectrum is each proposal evaluated?"


                DIV 
                  ref: 'slider_config'
                  style: 
                    padding: '18px 0px 0px 12px'
                    position: 'relative'
                    marginTop: 8
                    left: 0
                    display: 'flex'

                  DIV 
                    style: 
                      position: 'relative'
                      flexGrow: 2
                      width: '100%'
                      borderTop: '1px solid'
                      borderColor: '#999'
                      maxWidth: 500
                    
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
                      position: 'relative'
                      flexGrow: 0
                      paddingLeft: 18

                    anchor_style: 
                      color: 'inherit' #focus_color() #'inherit'
                      height: '100%'
                      padding: '0px 4px'
                      position: 'relative'
                      right: 0
                      cursor: 'pointer'
                      whiteSpace: 'nowrap'

                    menu_style: 
                      width: 420
                      backgroundColor: '#fff'
                      border: "1px solid #aaa"
                      right: -99999
                      left: 'auto'
                      top: 24
                      fontWeight: 400
                      overflow: 'hidden'
                      boxShadow: '0 1px 2px rgba(0,0,0,.3)'
                      textAlign: 'left'

                    menu_when_open_style: 
                      right: 0

                    option_style: 
                      padding: '8px 18px 12px 18px'
                      display: 'block'
                      color: 'black'
                      fontWeight: 400

                    active_option_style: 
                      color: 'black'
                      backgroundColor: '#efefef'


                    selection_made_callback: (option) => 
                      @refs.oppose_slider.value = option.oppose
                      @refs.support_slider.value = option.support


                      edit_list.slider_pole_labels = 
                        support: option.support 
                        oppose: option.oppose 
                      save edit_list


                      setTimeout =>
                        $$.ensureInView @refs.slider_config

                        if option.oppose == ''
                          moveCursorToEnd @refs.oppose_slider

                      , 100


                    render_anchor: ->
                      SPAN null, 
                        LABEL 
                          style: 
                            color: focus_color()
                            fontSize: 14
                            marginRight: 12
                            cursor: 'pointer'
                          translator 'engage.list-config-spectrum-select', 'preset spectrums'

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
                        className: 'monospaced'
                        style: 
                          fontSize: 14
                          textAlign: 'center'

                        SPAN 
                          style:
                            display: 'inline-block' 
                            width: 140
                            textAlign: 'right'
                            paddingRight: 10
                          "#{option.oppose}"
                        SPAN 
                          dangerouslySetInnerHTML: __html: "&#10231;"
                          style: 
                            fontSize: 32
                            color: '#888'

                        SPAN 
                          style:
                            display: 'inline-block' 
                            width: 140
                            textAlign: 'left'
                            paddingLeft: 10                        
                          "#{option.support}" 


                      # DIV 
                      #   style: 
                      #     margin: "12px 24px"
                      #     position: 'relative'
                      #     fontSize: 12

                      #   SPAN 
                      #     style: 
                      #       display: 'inline-block'
                      #       width: '100%'
                      #       borderBottom: '1px solid'
                      #       borderColor: '#666'

                      #   BR null
                      #   SPAN
                      #     style: 
                      #       position: 'relative'
                      #       left: 0

                      #     option.oppose 

                      #   SPAN
                      #     style: 
                      #       position: 'absolute'
                      #       right: 0
                      #     option.support




            if !@props.combines_these_lists
              DIV 
                style: {}

                LABEL
                  className: 'LIST-field-edit-label LIST-permissions'
                  htmlFor: 'list_permit_new_items'


                  TRANSLATE
                    id: "engage.list-config-who-can-add"
                    span: 
                      component: SPAN 
                      args: 
                        key: 'span'
                        style: 
                          fontWeight: 700

                    "<span>Who can add proposals to this list?</span>"

                DIV 
                  style: option_block

                  INPUT 
                    id: 'any-participant'
                    type: 'radio'
                    name: 'list_permit_new_items'
                    defaultChecked: permit_new_items
                    style: 
                      marginTop: 0
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
                    defaultChecked: !permit_new_items
                    style: 
                      marginTop: 0                    
                    onChange: (e) =>
                      edit_list.list_permit_new_items = false
                      save edit_list

                  LABEL
                    style: 
                      marginLeft: 4
                    htmlFor: 'host-only'

                    translator "engage.list-config-who-can-add-only-hosts", "Only forum hosts or those granted special permission"


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
                      marginBottom: 24
                      display: if screencasting() then 'none'
                    onClick: (e) => 
                      @local.show_all_options = true 
                      save @local
                    'Show more options'
                else 
                  DIV null, 

                    DIV 
                      style:
                        marginBottom: 24

                      LABEL 
                        style: {}


                        DIV null,

                          translator 'engage.edit_list_item_name', 'What do you call each proposal in this list?'

                        INPUT 
                          type: 'text'
                          defaultValue: edit_list.list_item_name or translator('shared.proposal', 'proposal')
                          name: 'list_item_name'
                          style: 
                            padding: '8px 12px'
                            fontSize: 18
                          onChange: (e) =>
                            edit_list.list_item_name = e.target.value
                            save edit_list

                    DIV 
                      style:
                        marginBottom: 24
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
                          translator 'engage.list-config-discussion-enabled', 'Disable pro/con commenting on each proposal in this list. Spectrums only.'

                    DIV                   
                      style:
                        marginBottom: 36
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
                          translator 'engage.list-config-archived', 'This list should be closed by default. Useful for archiving.'


          BUTTON 
            className: 'btn'
            style: 
              backgroundColor: focus_color()
            disabled: (edit_list.list_title or "").length == 0
            onClick: submit

            if @props.fresh 
              translator 'engage.create_list_button', 'Create List'
            else 
              translator 'engage.update_list_button', 'Update List'

          BUTTON
            className: 'like_link'
            style: 
              color: '#777'
              fontSize: 18
              marginLeft: 12
              position: 'relative'
              top: 2
            onClick: cancel_edit

            translator 'shared.cancel_button', 'cancel'



    wrap_in_modal HOMEPAGE_WIDTH() + 72, cancel_edit, children



  componentDidMount: -> @setFocusOnTitle()

  componentDidUpdate: -> @setFocusOnTitle()

  setFocusOnTitle: ->
    if !@initialized && @refs.input?
      setTimeout =>
        moveCursorToEnd ReactDOM.findDOMNode(@refs.input)
      @initialized = true


