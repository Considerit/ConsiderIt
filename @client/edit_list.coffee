


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

    current_user = bus_fetch '/current_user'
    edit_list = bus_fetch "edit-#{list_key}"
    subdomain = bus_fetch '/subdomain'

    return SPAN null if !current_user.is_admin

    admin_actions = [
      {action: 'edit', label: translator('edit', 'edit')}
      {action: 'copy_link', label: translator('engage.list-configuration.copy_link', 'copy link')}
      {action: 'list_order', label: translator('engage.list-configuration.reorder_topics', 'reorder')}
      {action: 'close', label: translator('engage.list-configuration.close', 'close to participation')}
      {action: 'delete', label: translator('delete', 'delete')}
    ]

    DIV null,

      if !edit_list.editing

        DropMenu
          className: 'default_drop'

          options: admin_actions
          open_menu_on: 'activation'

          wrapper_style: 
            position: 'absolute'
            right: if PHONE_SIZE() then -6 else 0
            top: 12
            minWidth: 'auto'

          anchor_tooltip: translator "engage.list-config-icon-tooltip", "Configure list settings" 
          render_anchor: ->

            ThreeDotsIcon              
              size: 26
              fill: text_neutral

          render_option: (option, is_active) ->
            SPAN 
              key: option.action
              "data-option": option.action
              option.label


          selection_made_callback: (option) =>
            if option.action == 'edit' 
              edit_list.editing = true 
              save edit_list

            else if option.action == 'list_order'
              ef = bus_fetch 'edit_forum'
              ef.editing = true 
              save ef 

            else if option.action == 'delete'
            
              delete_list list

            else if option.action == 'close'
              if confirm(translator('engage.list-config-close-confirm', """Are you sure you want to close this list to participation? 
                                                                           Any proposals in it will also be closed to further participation, 
                                                                           though all existing dialogue will remain visible."""))
                
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
                      save_proposal(proposal)

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
                show_flash(translator("engage.list-configuration.link-copied", "Link copied to clipboard"))
              , (err) ->
                show_flash_error(translator("engage.list-configuration.problem-copying-link", "Problem copying link to clipboard"))
      else 
        EditNewList
          list: list
          fresh: false
          combines_these_lists: @props.combines_these_lists
          done_callback: => 
            edit_list.editing = false 
            save edit_list




styles += """
  .EditingNewList .ListHeader-wrapper {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;    
  }

  .EditingNewList .LIST-title {
    width: 100%;
  }

  .EditingNewList .LIST-description {
    margin-top: 24px;
  }

  .LIST-fat-header-field {
    border-radius: 8px;
    line-height: 1.4;
    padding: 8px 12px;
  }

  .LIST-field-edit-label {
    display: block;
    font-weight: 400;
    margin-top: 36px;
    margin-bottom: 4px;
    color: #{focus_color};
    font-size: 18px;
  }

  .LIST-option-block {    
      display: flex;
      align-items: center;
      margin-top: 8px;
  }

  .LIST-option-block input[type="radio"] {
    height: 18px; 
    width: 18px;
    margin-right: 12px;
    flex-shrink: 0;
  }

  .LIST-option-block .permissions_explanation {
    color: #{text_gray};
    font-weight: 400;
    margin-left: 24px;
    font-size: 12px;
  }

  @media #{PHONE_MEDIA} {
    .LIST-option-block .permissions_explanation {
      display: none;
    }
  }

  .LIST-slider-input {
    padding-top: 2px;
    position: absolute;
    border: none;
    outline: none;
    color: #{text_gray};
    font-size: 12px;
  }

  #edit_description .ql-editor {
    min-height: 48px;
    padding: 12px 12px;
    text-align: inherit;
  }

  .LIST-fat-header-field, #edit_description .ql-editor {
    border: 1px solid #{brd_light_gray};
    background-color: #{bg_light};

  }

  #edit_description .ql-editor.ql-blank::before {
    width: 100%;
  }

  #edit_description.single-line .ql-editor.ql-blank::before {
    transform: translateX(-50%);
  }

  .LIST_additional_options label {
    display: flex;
    align-items: center;
  }
  

  .LIST_additional_options input[type="checkbox"] {
    width: 18px;
    height: 18px;
    margin-right: 12px;
    flex-shrink: 0;
  }


  .list_advanced_options {
    margin: 36px 0 12px 0;
  }
  .list_advanced_option {
    margin-bottom: 24px;
  }

  .list_advanced_option label span {
    padding-left: 4px;
  }

"""


window.EditNewList = ReactiveComponent
  displayName: 'EditNewList'
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

    current_user = bus_fetch '/current_user'
    edit_list = bus_fetch "edit-#{list_key}"
    subdomain = bus_fetch '/subdomain'


    return SPAN null if !current_user.is_admin

    WINDOW_WIDTH() # subscribe to window size changes for alignment

 

    submit = =>


      customizations = subdomain.customizations

      customizations[list_key] ?= {}
      list_config = customizations[list_key]

      fields = ['list_title', 'list_description', 'list_permit_new_items', 'list_item_name', 'list_category', \
                'slider_pole_labels', 'list_opinions_title', 'discussion_enabled', 'list_is_archived', 'show_first_n_proposals']

      for f in fields
        val = edit_list[f]

        if val?
          list_config[f] = val

      description = bus_fetch("#{list_key}-description").html
      if description == "<p><br></p>"
        description = ""

      list_config.list_description = description


      if @props.fresh
        name = slugify(list_config.list_title or list_config.list_category or 'Proposals')
        if name.length > 140
          name = name.substring(0,140)
        new_name = "#{name}-#{Math.round(Math.random() * 100)}"
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
    edit_list.show_first_n_proposals ?= customization('show_first_n_proposals', list_key)

    title = edit_list.title or get_list_title list_key, true, subdomain

    if !@props.fresh
      edit_list.list_title ?= title 

    description = @getDescription()

    description_style = customization 'list_description_style', list_key



    children = \ 
        DIV 
          className: 'List EditingNewList'

          DIV 
            className: 'ListHeader-wrapper'

            DIV 
              className: 'text-wrapper'

              H1 
                className: 'LIST-title'



                AutoGrowTextArea
                  id: "title-#{list_key}"
                  className: 'LIST-title LIST-fat-header-field LIST-title-wrapper condensed'
                  ref: 'input'
                  focus_on_mount: true
                  style: _.defaults {}, customization('list_label_style', list_key, subdomain) or {}, 
                    width: '100%'
                  placeholder: translator "engage.list-config-title", "An open-ended question like \"What are your ideas?\" or a category like \"Recommendations\"."


                  defaultValue: if !@props.fresh then title
                  onChange: (e) ->
                    edit_list.list_title = e.target.value 
                    save edit_list



              if typeof description == 'function'
                DIV
                  style: _.defaults {}, (description_style or {})

                  description()        
              else 
                
                DIV 
                  id: 'edit_description'
                  className: "LIST-description"
                  ref: 'description'

                  style: _.extend {}, (description_style or {}),  
                    # marginTop: -12
                    width:  "100%" # HOMEPAGE_WIDTH() - 200

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
                    placeholder: translator "engage.list-config-description", "Optional: Additional information"
   

            DIV 
              style:
                maxWidth: 465
              @drawNameAnItem()
              @drawPermissionToAdd()
              @drawDefineSpectrum()
              @drawAdditionalOptions()



            BUTTON 
              className: 'btn'
              style: 
                backgroundColor: focus_color
                fontSize: 24
                maxWidth: 465
                width: '100%'
                marginTop: 36
                borderRadius: 16
              disabled: (edit_list.list_title or "").length == 0
              onClick: submit

              if @props.fresh 
                translator 'engage.create_list_button', 'Publish New Focus'
              else 
                translator 'engage.update_list_button', 'Update Focus'

            BUTTON
              className: 'like_link'
              style: 
                color: text_light_gray
                marginTop: 14
                

              onClick: cancel_edit

              translator 'shared.cancel_button', 'cancel'


    if @props.wrap_in_modal
      wrap_in_modal HOMEPAGE_WIDTH() + 72, cancel_edit, children
    else 
      children

  drawNameAnItem: -> 
    list_key = @get_list_key()
    edit_list = bus_fetch "edit-#{list_key}"
    subdomain = bus_fetch '/subdomain'

    DIV 
      style:
        marginBottom: 24

      LABEL 
        style: {}


        DIV 
          className: 'LIST-field-edit-label'

          translator 'engage.edit_list_item_name', 'What do you call a response to this focus?'

        INPUT 
          ref: 'list_item_name'
          type: 'text'
          defaultValue: edit_list.list_item_name or translator('shared.proposal', 'proposal')
          name: 'list_item_name'
          style: 
            padding: '4px 6px'
            fontSize: 'inherit'
            border: "1px solid #{brd_light_gray}"
          onChange: (e) =>
            edit_list.list_item_name = e.target.value
            save edit_list


  drawPermissionToAdd: -> 
    return SPAN null if @props.combines_these_lists

    list_key = @get_list_key()
    subdomain = bus_fetch '/subdomain'
    edit_list = bus_fetch "edit-#{list_key}"

    permit_new_items = customization('list_permit_new_items', list_key, subdomain)

    DIV 
      style: {}

      LABEL
        className: 'LIST-field-edit-label LIST-permissions'
        htmlFor: 'list_permit_new_items'


        TRANSLATE
          id: "engage.list-config-who-can-add"
          ITEM_NAME: edit_list.list_item_name or translator('shared.proposal', 'proposal')

          "Who is allowed to add a new {ITEM_NAME}?"

      DIV 
        className: 'LIST-option-block'

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

          SPAN
            className: 'permissions_explanation'

            translator "engage.ideation-description", "For community ideation"

      DIV
        className: 'LIST-option-block'

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

          translator "engage.list-config-who-can-add-only-hosts", "Only forum hosts"


          SPAN
            className: 'permissions_explanation'

            translator "engage.closed-description", "For feedback on pre-defined proposals"


  drawDefineSpectrum: -> 
    return SPAN null if @props.combines_these_lists
    list_key = @get_list_key()
    subdomain = bus_fetch '/subdomain'
    edit_list = bus_fetch "edit-#{list_key}"


    DIV null,

      LABEL
        className: 'LIST-field-edit-label'


        TRANSLATE
          id: "engage.list-config-spectrum"
          ITEM_NAME: edit_list.list_item_name or translator('shared.proposal', 'proposal')

          "On what spectrum is each {ITEM_NAME} evaluated?"


      DIV 
        ref: 'slider_config'
        style: 
          paddingTop: 18
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
            borderColor: brd_mid_gray
            maxWidth: 500
          
          INPUT 
            type: 'text'
            className: 'LIST-slider-input'
            style: 
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
            className: 'LIST-slider-input'
            style: 
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
            top: -13

          anchor_style: 
            color: 'inherit' 
            height: '100%'
            padding: '0px 4px'
            position: 'relative'
            right: 0
            cursor: 'pointer'
            whiteSpace: 'nowrap'

          menu_style: 
            width: 420
            backgroundColor: bg_light
            border: "1px solid #{brd_mid_gray}"
            right: -99999
            left: 'auto'
            top: 24
            fontWeight: 400
            overflow: 'hidden'
            boxShadow: "0 1px 2px #{shadow_dark_25}"
            textAlign: 'left'

          menu_when_open_style: 
            right: 0

          option_style: 
            padding: '8px 18px 12px 18px'
            display: 'block'
            color: text_dark
            fontWeight: 400

          active_option_style: 
            color: text_dark
            backgroundColor: bg_lightest_gray


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
                  color: focus_color
                  fontSize: 14
                  marginRight: 12
                  cursor: 'pointer'
                translator 'engage.list-config-spectrum-select', 'presets'

              SPAN style: _.extend cssTriangle 'bottom', focus_color, 13, 8,
                display: 'inline-block'

          render_option: (option, is_active) ->
            if option.oppose == ''
              return  DIV 
                        style: 
                          fontSize: 16
                          borderBottom: "1px dashed #{brd_light_gray}"
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
                  color: text_light_gray

              SPAN 
                style:
                  display: 'inline-block' 
                  width: 140
                  textAlign: 'left'
                  paddingLeft: 10                        
                "#{option.support}" 



  drawAdditionalOptions: -> 
    return SPAN null if @props.combines_these_lists
    list_key = @get_list_key()
    subdomain = bus_fetch '/subdomain'
    edit_list = bus_fetch "edit-#{list_key}"

    DIV 
      className: 'LIST_additional_options'
      style:
        marginTop: 24
        marginBottom: 12

      if !@local.show_all_options 
        BUTTON 
          className: 'like_link'
          style: 
            textDecoration: 'underline'
            color: focus_color
            marginBottom: 24
            marginTop: 8
            display: if screencasting() then 'none'
          onClick: (e) => 
            @local.show_all_options = true 
            save @local
          translator "engage.show_advanced_options", 'Show advanced options'

      else 
        DIV 
          className: 'list_advanced_options'


          DIV 
            className: 'list_advanced_option'
            LABEL null,
              INPUT 
                type: 'checkbox'
                defaultChecked: !edit_list.discussion_enabled
                name: 'discussion_enabled'
                onChange: (e) =>
                  edit_list.discussion_enabled = !edit_list.discussion_enabled
                  save edit_list

              SPAN null,
                translator 
                  id: 'engage.list-config-discussion-enabled'
                  ITEM_NAME: edit_list.list_item_name or translator('shared.proposal', 'proposal')

                  'Disable pro/con commenting on each {ITEM_NAME}. Spectrums only.'

          DIV       
            className: 'list_advanced_option'
            LABEL null,
              INPUT 
                type: 'checkbox'
                defaultChecked: edit_list.list_is_archived
                name: 'list_is_archived'
                onChange: (e) =>
                  edit_list.list_is_archived = !edit_list.list_is_archived
                  save edit_list

              SPAN null,
                translator 'engage.list-config-archived', 'Closed by default. Useful for archiving.'

          DIV       
            className: 'list_advanced_option'
            LABEL null,
              INPUT 
                type: 'checkbox'
                defaultChecked: edit_list.show_first_n_proposals && edit_list.show_first_n_proposals != SHOW_FIRST_N_PROPOSALS
                name: 'show_first_n_proposals'
                onChange: (e) =>
                  if edit_list.show_first_n_proposals != SHOW_FIRST_N_PROPOSALS
                    edit_list.show_first_n_proposals = SHOW_FIRST_N_PROPOSALS
                  else 
                    edit_list.show_first_n_proposals = 999

                  save edit_list

              SPAN null,
                translator 
                  id: 'engage.list-config-show_first_n_proposals'
                  DEFAULT: SHOW_FIRST_N_PROPOSALS
                  'Show all proposals in this focus, without forcing people to click "show all". The default is to show the first {DEFAULT}.'


  componentDidMount: -> 
    @setFocusOnTitle()
    @setAlignmentOnDescription()

  componentDidUpdate: -> 
    @setFocusOnTitle()
    @setAlignmentOnDescription()

  setFocusOnTitle: ->
    if !@initialized && @refs.input?
      setTimeout =>
        moveCursorToEnd ReactDOM.findDOMNode(@refs.input)
      @initialized = true


  getDescription: -> 

    list_key = @get_list_key()

    edit_list = bus_fetch "edit-#{list_key}"

    description = edit_list.description or customization('list_description', list_key)
    if Array.isArray(description)
      description = description.join('\n')

    description

  setAlignmentOnDescription: ->
    list_key = @get_list_key()    
    description = bus_fetch("#{list_key}-description").html or @getDescription()
    is_func = typeof description == 'function'

    if !is_func
      return if !@refs.description
      height = @refs.description.clientHeight
      single_line = height < 60
      if single_line
        @refs.description.classList.add 'single-line'
      else
        @refs.description.classList.remove 'single-line'

