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
    color: var(--text_gray);
  }

  [data-widget="EditPage"] .radio_group label {
  }


  [data-widget="EditPage"] .draggable-list {
    padding: 12px 24px 24px 12px;
    margin: 12px 0; 
    display: flex;
    align-items: center;
    position: relative;
  }


  [data-widget="EditPage"] [data-widget="NewList"] {
    margin-top: 12px;
    margin-bottom: 12px;
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
    border-radius: 16px;
    height: 0px;
    display: block;
    content: "";
    margin: 0;
    transition: height 1s;
  }

  [data-widget="EditPage"] .draggable-wrapper.draggedOver.from_above::after, [data-widget="EditPage"] .draggable-wrapper.draggedOver.from_below::before {
    height: 60px;
    outline: 1px dotted var(--brd_dark_gray);

  }


  [data-widget="EditPage"] .wildcard.draggable-wrapper {
  }

  [data-widget="EditPage"] .draggable-list button {
    flex-shrink: 0;
    flex-grow: 0;
    display: inline-block;
  }
  [data-widget="EditPage"] .draggable-list .LIST-title {
    padding-left: 24px;
    flex-grow: 1;
  }

  [data-widget="EditPage"] H2.list_header {
    font-size: 22px;
  }

  [data-widget="EditPage"] button.convert_page {
    padding: 8px 16px;
    border: 1px solid var(--brd_light_gray);
    border-radius: 8px;
    margin-top: 12px;
  }

  [data-widget="EditPage"] .action_explanation {
    font-size: 14px;
    margin-top: 3px;
  }

  .not-editing.draggable-source--is-dragging {
    opacity: .5;
  }

  .not-editing.draggable-mirror {
    z-index: 99999;
    background-color: var(--bg_light_trans_80) !important;
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
    subdomain = bus_fetch '/subdomain'

    return DIV null if @props.page_name != get_current_tab_name()

    DIV null, 
      I null, 
        "This is an About page."
      @renderPreamble()
      @renderPageType()
      @renderMakeDefaultPage()



  drawShowAllPage: -> 
    subdomain = bus_fetch '/subdomain'

    return DIV null if @props.page_name != get_current_tab_name()

    DIV null, 
      I null, 
        "This page displays all proposal lists shown on other pages throughout this forum."
      @renderSortOrder()

      @renderPreamble()

      @renderPageType()

      @renderMakeDefaultPage()


  drawDefaultPage: -> 
    subdomain = bus_fetch '/subdomain'

    is_a_tab = !!get_tabs()

    edit_forum = bus_fetch "edit_forum"

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

        UL 
          ref: 'draggable-list-wrapper'
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
                className: "draggable-wrapper #{if wildcard then 'wildcard' else ''} #{if lst == @local.edit_list then 'editing' else 'not-editing'}"


                if lst == @local.edit_list
                  EditNewList
                    list: @local.edit_list
                    fresh: false
                    combines_these_lists: @props.combines_these_lists
                    done_callback: => 
                      @local.edit_list = false 
                      save @local
                else 

                  DIV 
                    className: "draggable-list"                    

                    if drag_capabilities.length > 0 
                      BUTTON 
                        className: "icon"
                        "data-tooltip": drag_capabilities
                        "aria-label": drag_capabilities
                        style: 
                          cursor: 'move'
                          position: 'relative'
                          left: 7

                        drag_icon 15, "var(--text_neutral)"
                    else 
                      DIV 
                        style: 
                          width: 22

                    DIV
                      className: 'LIST-title'

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
                          className: 'like_link'
                          onClick: disaggregate_wildcard

                          'disaggregate'

                    if !wildcard 
                      BUTTON 
                        className: "icon"
                        "data-tooltip": "Edit"
                        "aria-label": 'Edit'
                        onClick: (e) =>
                          e.preventDefault()
                          e.stopPropagation()
                          @local.edit_list = lst
                          save @local

                        edit_icon 23, 23, "var(--text_neutral)"


                    if !wildcard 
                      BUTTON 
                        className: "icon"
                        "aria-label": 'Delete'
                        style:
                          position: 'absolute'
                          right: -36
                        "data-tooltip": "Delete"
                        onClick: (e) =>
                          @ordered_lists.splice( @ordered_lists.indexOf(lst), 1  )
                          delete_list(lst)

                        trash_icon 23, 23, "var(--text_neutral)"


        if !@local.edit_list
          NewList
            wrapper_clss: 'draggable-list'

      


      DIV 
        style:
          marginTop: 36


        if !@local.show_all_options 
          BUTTON 
            className: 'like_link'
            style: 
              fontWeight: 700
              color: "var(--text_light_gray)"
            onClick: (e) => 
              @local.show_all_options = true 
              save @local
            'Advanced settings for this page'
        else 
          FIELDSET 
            style: 
              marginLeft: 0
              marginTop: 42
              border: "1px solid var(--brd_light_gray)"
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
                color: "var(--text_gray)"

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
      {id: PAGE_TYPES.ALL,     label: '"Show all" page', description: "Aggregate and show all proposal lists from other pages."}
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
                @ordered_lists ?= get_tab(@props.page_name)?.lists

                if option.id == PAGE_TYPES.DEFAULT 

                  @local.type = PAGE_TYPES.DEFAULT
                  idx = @ordered_lists.indexOf('*')
                  if idx > -1
                    if @ordered_lists.length > 1
                      @ordered_lists.splice idx, 1
                    else 
                      # If there is only a '*' in the show all configuration, add
                      # all lists that would have been showing up here and are not 
                      # present elsewhere, so the user can filter it down to the 
                      # ones it wants to show here.
                      @ordered_lists.splice 0, @ordered_lists.length
                      for l in get_all_lists_not_configured_for_a_page()
                        @ordered_lists.push l
                  save @local


                else 

                  if @ordered_lists.length == 0 || confirm "Are you sure you want to convert this page? You may want to move the existing lists to a different page first. You can do that by dragging them to a different tab above."
                    @ordered_lists.splice(0,@ordered_lists.length) 
                    if option.id == PAGE_TYPES.ALL 
                      @ordered_lists.push '*'
                    @local.type = option.id
                    save @local
                  else 
                    document.getElementById("page_type#{@local.type}").checked = true


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
    preamble_text = bus_fetch "#{@props.page_name}-preamble"

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
          border: "1px solid var(--brd_light_gray)"  
          marginTop: 4   
          padding: '8px 12px'
          backgroundColor: "var(--bg_light)"
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
            marginBottom: 6
            display: 'block'

          "Default landing page"

        SELECT
          defaultValue: default_tab
          style: 
            fontSize: 18
            display: 'block'
          onChange: (e) => 
            subdomain = bus_fetch '/subdomain'
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
    customizations = bus_fetch('/subdomain').customizations

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
    active_page = @props.page_name == get_current_tab_name()

    if active_page && @lists_sortable
      @lists_sortable = false
      @sortable?.destroy()

    return if !active_page || @lists_sortable

    @lists_sortable = true
    last_mouse_over_target = null

    reorder_list_position = (from, to) => 
      edit_forum = bus_fetch('edit_forum')
      moving = @ordered_lists[from]

      @ordered_lists.splice from, 1
      @ordered_lists.splice to, 0, moving

      save edit_forum
      save bus_fetch('/subdomain') # required to get the new order saved via @ordered_lists

    reassign_list_to_page = (source, target, dragging) =>
      subdomain = bus_fetch '/subdomain'


      dragging = parseInt(dragging)
      source_lists = get_tab(source).lists
      target_lists = get_tab(target).lists

      list_key = source_lists[dragging]

      if source_lists && target_lists
        source_lists.splice dragging, 1
        if target_lists.indexOf(list_key) == -1
          target_lists.push list_key 
        save subdomain
      else 
        console.error "Could not move list #{list_key} from #{source} to #{target}"
    
    @sortable = new Draggable.Sortable @refs['draggable-list-wrapper'],
      draggable: '.not-editing'
      distance: 1 # don't start drag unless moved a bit, otherwise click event gets swallowed up

    @sortable.on 'sortable:start', =>
      document.body.classList.add('dragging-list')


    @sortable.on 'drag:move', (evt) =>
      current_target = evt.sensorEvent.target?.closest('[data-accepts-lists="true"]')
      if last_mouse_over_target != current_target
        if last_mouse_over_target
          last_mouse_over_target.classList.remove 'draggedOver-by_list'
        if current_target
          current_target.classList.add 'draggedOver-by_list' 
      last_mouse_over_target = current_target

    @sortable.on 'sortable:stop', ({data}) => 
      document.body.classList.remove('dragging-list')
      from = data.oldIndex

      if last_mouse_over_target
        reassign_list_to_page @props.page_name, last_mouse_over_target.getAttribute('data-page-name'), from
      else 
        to = data.newIndex
        reorder_list_position from, to


  componentWillUnmount: ->
    if @lists_sortable
      @lists_sortable = false
      @sortable.destroy()



