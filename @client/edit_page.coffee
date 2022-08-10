require "./tabs"

styles += """
  [data-widget="EditPage"] .input_group {
    margin: 36px 0;
  }
  [data-widget="EditPage"] .input_group fieldset {
    padding-left: 30px;
  }
  [data-widget="EditPage"] .radio_group {
    margin-top: 16px;
    margin-left: 0px;
  }
  [data-widget="EditPage"] .field_explanation {
    font-size: 14px;
    margin-top: 6px;
    color: #444;
  }

  [data-widget="EditPage"] .radio_group label {
  }


  [data-widget="EditPage"] .draggable-list {
    padding: 24px 24px 24px 12px;
  }


  [data-widget="EditPage"] [data-widget="NewList"] {
    margin-top: 12px;
    padding: 32px 24px 26px 60px;
    margin-bottom: 12px;
  }

  [data-widget="EditPage"] .draggable-list {
    /* background-color: #f1f1f1;
    border: 1px solid #ddd;
    border-radius: 16px;*/
    margin: 12px 0; 

    
    display: flex;
    align-items: center; /* start; */
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
    /* font-size: 16px; 
    font-weight: 500; */
    padding-left: 24px;
    flex-grow: 1;
  }

  [data-widget="EditPage"] H2.list_header {
    font-size: 22px;
  }
  [data-widget="EditPage"] button.add_new_list {
    border: none;
    background-color: transparent;
    margin-top: 12px;
    padding: 8px 16px;
    font-size: 24px;
    margin-left: 26px;
  }

  [data-widget="EditPage"] button.convert_page {
    padding: 8px 16px;
    border: 1px solid #ccc;
    border-radius: 8px;
    margin-top: 12px;
  }

  [data-widget="EditPage"] .action_explanation {
    font-size: 14px;
    margin-top: 3px;
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
      @renderPageType()
      @renderMakeDefaultPage()



  drawShowAllPage: -> 
    subdomain = fetch '/subdomain'

    return DIV null if @props.page_name != get_current_tab_name()

    DIV null, 
      I null, 
        "This page displays all proposal lists shown on other pages throughout this forum."
      @renderSortOrder()

      @renderPreamble()

      @renderPageType()

      @renderMakeDefaultPage()


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

    drag_enabled = get_tabs()?.length > 1
    if drag_enabled 
      drag_capabilities += "Lists can be dragged to a different tab to move them."



    DIV {style: position: 'relative'},




      DIV 
        style: 
          marginTop: 36
          marginBottom: 24


        # H2
        #   className: "list_header"

        #   # 'Questions and Categories'
        #   'Calls for ideas or feedback'

        #   # DIV 
        #   #   style:
        #   #     fontSize: 14
        #   #     fontWeight: 400
        #   #   'A Topic collects proposals under a category like "Recommendations" or in response to an open-ended question like "What are your ideas?"'


        # if @ordered_lists.length == 0
        #   DIV 
        #     style: 
        #       textAlign: 'center'
        #       padding: '36px 24px'
        #       border: '1px dotted #eee'
        #       backgroundColor: '#f1f1f1'

        #     "None defined yet."

        # else if @ordered_lists.length > 0 
        #   DIV 
        #     style: 
        #       fontSize: 14

        #     drag_capabilities

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
                key: lst
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
                        position: 'relative'
                        left: 7

                      drag_icon 15, '#888'
                  else 
                    DIV 
                      style: 
                        width: 22

                  DIV
                    className: 'name LIST-header'

                    if wildcard
                      SPAN 
                        style: 
                          fontStyle: 'italic'
                        "All of the rest (#{lists_to_add.length} total)"
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

                        'disaggregate'

                  if !wildcard 
                    BUTTON 
                      style: 
                        cursor: 'pointer'
                      "data-tooltip": "Edit"
                      onClick: (e) =>
                        e.preventDefault()
                        e.stopPropagation()
                        @local.edit_list = lst
                        save @local

                      edit_icon 18, 18, '#888'


                  if !wildcard 
                    BUTTON 
                      style:
                        position: 'absolute'
                        right: -36
                        cursor: 'pointer'
                      "data-tooltip": "Delete"
                      onClick: (e) =>
                        @ordered_lists.splice( @ordered_lists.indexOf(lst), 1  )
                        delete_list(lst)

                      trash_icon 23, 23, '#888'


        if @local.edit_list

          ModalNewList
            list: @local.edit_list
            fresh: false
            combines_these_lists: @props.combines_these_lists
            done_callback: => 
              @local.edit_list = false 
              save @local

        else 

          NewList
            no_padding: true

          # BUTTON
          #   className: "add_new_list"
          #   "data-tooltip": list_i18n().explanation

          #   onClick: =>
          #     @local.add_new_list = true 
          #     save @local
          #   "+ "  
          #   SPAN 
          #     style: 
          #       textDecoration: 'underline'
          #     list_i18n().button


      


      DIV 
        style:
          marginTop: 36


        if !@local.show_all_options 
          BUTTON 
            className: 'like_link'
            style: 
              textDecoration: 'underline'
              fontWeight: 700
              color: '#666'
            onClick: (e) => 
              @local.show_all_options = true 
              save @local
            'Advanced settings for this page'
        else 
          FIELDSET 
            style: 
              marginLeft: 0
              marginTop: 42
              border: "1px solid #ccc"
              padding: "0px 48px 48px 48px"
              borderRadius: 8

            LABEL 
              className: "main_background"
              style: 
                fontSize: 17
                marginTop: 36
                marginBottom: 24
                padding: "4px 8px"
                position: 'relative'
                top: -12
                color: '#333'

              "Advanced settings for this page"


            DIV null, 

              @renderSortOrder()

              @renderPreamble()

              @renderPageType()

              @renderMakeDefaultPage()




  renderPageType: -> 
    is_a_tab = !!get_tabs()
    return SPAN null if !is_a_tab



    page_types = [
      {id: PAGE_TYPES.DEFAULT, label: "Standard page",    description: "Displays the proposal lists configured above."}
      {id: PAGE_TYPES.ABOUT,   label: 'Background page',  description: "Give supplementary background information about the engagement."}
      {id: PAGE_TYPES.ALL,     label: '"Show all" page"', description: "Aggregate and show all proposal lists from other pages."}
    ]

    DIV 
      className: 'FORUM_SETTINGS_section input_group'

      B 
        style: 
          fontSize: 17

        'This page is a...'

      DIV
        className: 'explanation'

        """
        """

      FIELDSET null,

        for option in page_types
          DIV 
            key: option.id

            DIV 
              className: 'radio_group'
              style: 
                cursor: 'pointer'

              onChange: do (option) => (ev) => 

                if option.id == PAGE_TYPES.DEFAULT 
                  @local.type = PAGE_TYPES.DEFAULT
                  idx = @ordered_lists.indexOf('*')
                  if idx > -1
                    @ordered_lists.splice idx, 1

                else 

                  if @ordered_lists.length == 0 || confirm "Are you sure you want to convert this page? You may want to move the existing lists to a different page first. You can do that by dragging them to a different tab above."
                    @ordered_lists.splice(0,@ordered_lists.length) 
                    if option.id == PAGE_TYPES.ALL 
                      @ordered_lists.push '*'
                    @local.type = option.id

                save @local



              INPUT 
                style: 
                  cursor: 'pointer'
                type: 'radio'
                name: "page_type"
                id: "page_type#{option.id}"
                defaultChecked: @local.type == option.id

              LABEL 
                style: 
                  cursor: 'pointer'
                  display: 'block'
                htmlFor: "page_type#{option.id}"
                
                option.label


            if option.description
              DIV 
                className: 'explanation field_explanation'
                option.description




  renderSortOrder: -> 
    current_list_sort_method = get_list_sort_method(@props.page_name)
    

    groups_sorts = 
      newest:       {value: 'newest_item', label: 'By most recent activity', explanation: 'The proposal lists with the most recent activity are shown first.'}
      randomized:   {value: 'randomized', label: 'Randomized', explanation: 'Proposal lists are show in a random order on page load.'}
      fixed:        {value: 'fixed', label: 'Fixed order', explanation: 'Proposal lists will be ordered as specified above.'}
      fixed_by_tab: {value: 'by_tab', label: 'Fixed order', explanation: 'Proposal lists ordered as they are in the other pages.'}

    if @local.type == PAGE_TYPES.DEFAULT      
      list_orderings = [groups_sorts.fixed, groups_sorts.newest, groups_sorts.randomized]
    else if @local.type == PAGE_TYPES.ALL
      list_orderings = [groups_sorts.fixed_by_tab, groups_sorts.newest, groups_sorts.randomized]

    else 
      list_orderings = null

    FIELDSET 
      style: 
        marginLeft: 0
        marginTop: 32

      LABEL 
        style: 
          fontSize: 17
          fontWeight: 700

        "Order of the proposal lists#{if @local.type != PAGE_TYPES.ALL then " defined above" else ''}"


      SELECT
        defaultValue: current_list_sort_method
        style: 
          fontSize: 18
          display: 'block'
          marginTop: 4
        onChange: (e) => 
          @local.list_sort_method = e.target.value
          save @local

        for option in list_orderings
          OPTION
            key: option.value
            value: option.value
            option.label 

      if option.explanation
        for option in list_orderings
          if option.value == (@local.list_sort_method or current_list_sort_method)
            DIV
              key: option.value 
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
        editor_key: "#{@props.page_name}-preamble"
        horizontal: true
        html: current_preamble
        allow_html: true
        # placeholder: if !@props.fresh then translator("engage.list_description", "(optional) Description")
        toolbar_style: 
          right: 0
        container_style: 
          borderRadius: 8
          minHeight: 42
          width: '100%'     
          border: '1px solid #ccc'  
          marginTop: 4   
          padding: '8px 12px'
          backgroundColor: 'white'
        style: 
          fontSize: 16



      DIV 
        className: 'action_explanation'

        if @local.type != PAGE_TYPES.ABOUT
          """The preamble is displayed at the top of the page. """

        SPAN 
          dangerouslySetInnerHTML: __html: """
            To use HTML, click <span class='monospaced'>&lt;/&gt;</span> in the upper right. 
            <span class='monospaced'>&lt;script&gt;</span>, <span class='monospaced'>&lt;iframe&gt;</span> and 
            <span class='monospaced'>&lt;style&gt;</span> tags are not allowed. 
            Use inline styles instead.
          """

        if @local.type == PAGE_TYPES.ABOUT
        
          """ If you need to embed a video, please contact help@consider.it."""

  renderMakeDefaultPage: -> 
    default_tab = customization('homepage_default_tab') # or get_tabs()[0]?.name or 'Show all'

    return SPAN null if !get_tabs()
    DIV null,
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

          "Default landing page"

        SELECT
          defaultValue: default_tab
          style: 
            fontSize: 18
            display: 'block'
          onChange: (e) => 
            subdomain = fetch '/subdomain'
            subdomain.customizations.homepage_default_tab = e.target.value
            save subdomain

          for tab in get_tabs()
            OPTION
              key: tab.name
              value: tab.name
              tab.name 

        DIV 
          className: 'explanation field_explanation'
          "When someone arrives at #{location.origin} they will be shown the '#{default_tab or get_tabs()[0]?.name}' page by default."



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
      save fetch('/subdomain') # required to get the new order saved via @ordered_lists

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


    for list in ReactDOM.findDOMNode(@).querySelectorAll('[draggable]')
      list.removeEventListener('dragstart', @onDragStart) 
      list.removeEventListener('dragend', @onDragEnd) 
      list.addEventListener('dragstart', @onDragStart) 
      list.addEventListener('dragend', @onDragEnd)       

    for list in ReactDOM.findDOMNode(@).querySelectorAll('[data-idx]')
      list.removeEventListener('dragover', @onDragOver)
      list.removeEventListener('dragleave', @onDragLeave)      
      list.removeEventListener('drop', @onDrop) 

      list.addEventListener('dragover', @onDragOver)
      list.addEventListener('dragleave', @onDragLeave)      
      list.addEventListener('drop', @onDrop) 




  componentWillUnmount: -> 
    if @initialized
      for list in ReactDOM.findDOMNode(@).querySelectorAll('[draggable]')
        list.removeEventListener('dragstart', @onDragStart) 
        list.removeEventListener('dragend', @onDragEnd) 
        list.addEventListener('dragstart', @onDragStart) 
        list.addEventListener('dragend', @onDragEnd)       

      for list in ReactDOM.findDOMNode(@).querySelectorAll('[data-idx]')
        list.removeEventListener('dragover', @onDragOver)
        list.removeEventListener('dragleave', @onDragLeave)      
        list.removeEventListener('drop', @onDrop) 


