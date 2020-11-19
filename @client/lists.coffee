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

    wrapper_style = 
      marginBottom: if !is_collapsed then 28
      position: 'relative'


    ARTICLE
      key: list.name
      id: if list.name && list.name then list.name.toLowerCase()
      style: wrapper_style

      A name: if list.name && list.name then list.name.toLowerCase().replace(/ /g, '_')

      if !@props.fresh
        ManualProposalResort sort_key: @local.key

      ListHeader 
        list: list 
        proposals_count: proposals.length
        fresh: @props.fresh
        allow_editing: !@props.allow_editing? || @props.allow_editing

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


      # error case where title is blank
      if !list_config.list_title 
        edit_list.missing_title = true 
        save edit_list
        return


      description = fetch("#{list_key}-description").html
      if description == "<p><br></p>"
        description = null
      list_config.list_description = description

      if @props.fresh
        new_key = "list/#{slugify(edit_list.list_title or list.title)}-#{Math.round(Math.random() * 100)}"
        customizations[new_key] = customizations[list_key]
        _.defaults customizations[new_key], 
          created_by: current_user.user 
          created_at: Date.now()
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

    admin_actions = [{action: 'edit', label: t('edit')}, {action: 'delete', label: t('delete')}, {action: 'close', label: translator('engage.list-configuration.close', 'close to participation')}]

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
            remove_list = -> 
              customizations = JSON.parse subdomain.customizations
              delete customizations[list_key] 
              subdomain.customizations = JSON.stringify customizations, null, 2
              save subdomain

            if list.proposals?.length > 0 
              has_permission = true 
              for proposal in list.proposals 
                has_permission &&= permit('delete proposal', proposal) > 0 

              if !has_permission
                alert "You apparently don't have permission to delete one or more of the proposals in this list"
              else if has_permission && confirm(translator('engage.list-config-delete-confirm', 'Are you sure you want to delete this list? All of the proposals in it will also be permanently deleted. If you want to get rid of the list, but not delete the proposals, you could move the proposals first.'))
                for proposal in list.proposals
                  destroy proposal.key
                remove_list()

            else 
              remove_list()
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

              customizations = JSON.parse subdomain.customizations

              # don't show a new button for this list anymore
              customizations[list_key].list_show_new_button = false 

              # add a note in the description that the list was closed to participation
              customizations[list_key].list_description ?= ''
              if customizations[list_key].list_description?.length > 0 
                customizations[list_key].list_description += "<br>" 
              customizations[list_description_key].list_description += "<DIV style='font-style:italic'>Participation was closed by the host on #{new Date().toDateString()}</div>" 

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
          marginTop: 24


        BUTTON 
          style: 
            backgroundColor: focus_color()
            fontSize: 18
            border: 'none'
            backgroundColor: '#555'
            color: 'white'
            fontWeight: 'bold'
            padding: '8px 32px'


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
            color: '#777'
            fontSize: 18
            marginLeft: 12
          onClick: cancel_edit
          onKeyDown: (e) =>
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              cancel_edit(e)  
              e.preventDefault()

          translator 'engage.cancel_button', 'cancel'


        if edit_list.missing_title
          DIV 
            style: 
              color: 'red'

            'Title field is required.'




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


    wrapper_style = 
      width: HOMEPAGE_WIDTH()
      marginBottom: 16 #24
      position: 'relative'

    if edit_list.editing
      _.extend wrapper_style, 
        backgroundColor: '#f3f3f3'
        marginLeft: -36
        marginTop: -36
        padding: "36px 36px"
        width: HOMEPAGE_WIDTH() + 36 * 2


    DIV 
      style: wrapper_style 

      DIVIDER?()

      DIV 
        style: 
          position: 'relative'


        EditableTitle
          list: @props.list
          fresh: @props.fresh


        if !is_collapsed



          if description?.length > 0 || edit_list.editing
            EditableDescription
              list: @props.list
              fresh: @props.fresh


          else if true || widthWhenRendered(heading_text, heading_style) <= column_sizes().first + column_sizes().gutter

            histo_title = customization('list_opinions_title', list_key)

            H2
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
                fontWeight: 700 # heading_style.fontWeight
                color: 'black' # heading_style.color
                fontSize: 36 #heading_style.fontSize

              TRANSLATE
                id: "engage.list_opinions_title.#{histo_title}"
                key: if histo_title == customizations.default.list_opinions_title then '/translations' else "/translations/#{subdomain.name}"
                histo_title

        if edit_list.editing

          list_config_label_style = 
            fontWeight: 600
            fontSize: 18
            marginTop: 8
            marginBottom: 4

          option_block = 
            marginLeft: 8
            marginTop: 8

          DIV null, 
            DIV 
              style: 
                padding: '12px 0'

              LABEL
                style: list_config_label_style
                htmlFor: 'list_show_new_button'

                translator "engage.list-config-who-can-add", "Who can add items to this list?"

              DIV 
                style: option_block

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
                    marginLeft: 4
                  htmlFor: 'any-participant'

                  translator "engage.list-config-who-can-add-anyone", "Any registered participant"

              DIV
                style: option_block

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
                    marginLeft: 4
                  htmlFor: 'host-only'

                  translator "engage.list-config-who-can-add-only-hosts", "Only forum hosts"

            DIV 
              style: 
                padding: '12px 0'

              LABEL
                style: list_config_label_style

                translator "engage.list-config-spectrum", "On what spectrum is each item evaluated?"



              DIV 
                ref: 'slider_config'
                style: 
                  padding: '24px 48px 32px 48px'
                  position: 'relative'
                  width: column_sizes().second + 48 * 2 + 50
                  color: focus_color() #'inherit'
                  border: "1px solid #ddd"
                  backgroundColor: 'white'
                  marginTop: 8
                  left: -12

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
                    style: 
                      position: 'absolute'
                      left: 0
                      border: '1px solid'
                      borderColor: if edit_list.slider_pole_labels && edit_list.slider_pole_labels.oppose == '' then '#eee' else 'transparent'
                      outline: 'none'
                      color: '#999'
                      fontSize: 16
                    ref: 'oppose_slider'
                    defaultValue: customization('slider_pole_labels', list_key).oppose 
                    placeholder: translator 'engage.slider_config.negative-pole-placeholder', 'Negative pole'
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
                      borderColor: if edit_list.slider_pole_labels && edit_list.slider_pole_labels.support == '' then 'eee' else 'transparent'
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
                    placeholder: translator 'engage.slider_config.positive-pole-placeholder', 'Positive pole'



                DropMenu
                  options: [{support: '', oppose: ''}].concat (v for k,v of slider_labels)
                  open_menu_on: 'activation'

                  wrapper_style: 
                    display: 'inline-block'
                    position: 'absolute'
                    right: 50
                    top: 0
                    height: '100%'
                    padding: '18px 4px'
                    borderLeft: "1px solid #eee"

                  anchor_style: 
                    color: 'inherit' #focus_color() #'inherit'
                    height: '100%'
                    padding: '18px 4px'
                    position: 'absolute'
                    top: 0
                    left: 0
                    width: 58

                  menu_style: 
                    width: column_sizes().second + 48 * 2 + 50
                    backgroundColor: '#fff'
                    border: "1px solid #aaa"
                    right: -99999
                    left: 'auto'
                    top: 51
                    fontWeight: 400
                    overflow: 'hidden'
                    boxShadow: '0 1px 2px rgba(0,0,0,.3)'

                  menu_when_open_style: 
                    right: -50

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
                    , 0


                  render_anchor: ->
                    SPAN style: _.extend cssTriangle 'bottom', focus_color(), 15, 9,
                      display: 'inline-block'

                  render_option: (option, is_active) ->
                    if option.oppose == ''
                      return  DIV 
                                style: 
                                  fontSize: 18
                                  borderBottom: '1px dashed #ccc'
                                  textAlign: 'center'
                                  padding: '12px 0'

                                translator "engage.list-config-custom-spectrum", "Custom Spectrum"

                    DIV 
                      style: 
                        margin: "12px #{48+28}px 12px 48px"
                        position: 'relative'
                        fontSize: 16

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



      if @props.allow_editing
        EditList
          list: @props.list
          fresh: @props.fresh




      if !edit_list.editing && @props.proposals_count > 0 && !customization('questionaire', list_key) && !is_collapsed && !customization('list_no_filters', list_key)
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

    @local.hovering ?= false

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
            fontSize: 36
            fontWeight: 700
            color: if @local.hovering then '#444' else '#666'

          translator 'engage.create_new_list_button', "Create new list"


EditableTitle = ReactiveComponent
  displayName: 'EditableTitle'

  render: -> 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    list = @props.list 
    list_key = "list/#{list.name}"    

    edit_list = fetch "edit-#{list_key}"

    list_items_title = list.name or 'Proposals'

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

    
    DIV null, 
      if @props.fresh && edit_list.editing 
        DIV 
          style: 
            fontSize: 14
            marginBottom: 12
            color: '#444'

          SPAN 
            style: 
              fontWeight: 700
            'Title.'
          SPAN 
            style:
              fontWeight: 400
            ' Can be a category title like "Ideas", or an open-ended question like "What are our values?"'

      H1
        style: heading_style



        if edit_list.editing
          AutoGrowTextArea
            id: "title-#{list_key}"
            ref: 'input'
            focus_on_mount: true
            style: _.extend {}, title_style, 
              fontSize: heading_style.fontSize
              width: HOMEPAGE_WIDTH() + 24
              lineHeight: 1.4
              padding: '8px 12px'
              marginTop: -8 - 1
              marginLeft: -12 - 1
              backgroundColor: 'white'
              border: '1px solid #eaeaea'
              borderRadius: 8
              outlineColor: '#ccc'
              borderColor: if edit_list.missing_title then 'red'
              outlineColor: if edit_list.missing_title then 'red'

            defaultValue: if !@props.fresh then title
            onChange: (e) ->
              edit_list.list_title = e.target.value 
              if edit_list.missing_title && (!edit_list.list_title || edit_list.list_title.length == 0)
                edit_list.missing_title = false 
                save edit_list  
              save edit_list
            placeholder: if !@props.fresh then translator('engage.list_title_input-open.placeholder', 'Ask an open-ended question or set a list title')


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
        fontWeight: 300 
        color: '#222'
        marginTop: 6

      if _.isFunction description
        description()
      else 

        if current_user.is_admin && edit_list.editing
          DIV null,

            if @props.fresh
              DIV 
                style: 
                  fontSize: 14
                  marginBottom: 12

                SPAN 
                  style: 
                    fontWeight: 700
                  'Description [optional].'
                SPAN 
                  style:
                    fontWeight: 400
                  ' Give any additional information or directions here.'

            DIV 
              id: 'edit_description'
              style:
                marginLeft: -13
                marginTop: -12

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
                placeholder: if !@props.fresh then translator("engage.list_description", "(optional) Description")
                toolbar_style: 
                  right: 0
                container_style: 
                  borderRadius: 8

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

