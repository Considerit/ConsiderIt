

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


