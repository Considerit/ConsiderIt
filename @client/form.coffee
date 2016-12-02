####
# Form.coffee
#
# Components to help build forms.
#
require './shared'
require './dock'

window.Button = (props, text, callback) ->
  style =
    backgroundColor: focus_blue
    borderRadius: 8
    color: 'white'
    padding: '3px 10px'
    display: 'inline-block'
    fontWeight: 600
    textAlign: 'center'
    cursor: 'pointer'
    border: 'none'
  props.style = _.extend(style, (props.style or {}))
  props.onClick = callback
  props.onKeyDown = (e) -> 
    if e.which == 13 || e.which == 32 # ENTER or SPACE
      callback(e)
      e.stopPropagation()
      e.preventDefault()

  BUTTON props, text


window.AutoGrowTextArea = ReactiveComponent
  displayName: 'AutoGrowTextArea'  

  # You can pass an onChange() handler in to props that will get
  # called
  onChange: (e) ->
    @props.onChange?(e)
    @checkAndSetHeight()

  componentDidMount : -> @checkAndSetHeight()
  componentDidUpdate : -> @checkAndSetHeight()

  checkAndSetHeight : ->
    scroll_height = @getDOMNode().scrollHeight
    max_height = @props.max_height or 600
    if scroll_height > @getDOMNode().clientHeight

      h = Math.min scroll_height + 5, max_height
      if h != @local.height
        @local.height = h

        if @props.onHeightChange
          @props.onHeightChange()
        save(@local)

  render : -> 
    if !@local.height
      @local.height = @props.min_height

    @transferPropsTo TEXTAREA
      onChange: @onChange
      style: _.extend (@props.style || {}),
        height: @local.height
        padding: '4px 8px'


window.CharacterCountTextInput = ReactiveComponent
  displayName: 'CharacterCountTextInput'

  render : -> 
    if !@local.count?
      @local.count = (@props.defaultValue or "").length

    count_style = @props.count_style or {}

    class_name = "is_counted"
    DIV 
      style: 
        position: 'relative' 

      SPAN 
        'aria-hidden': true
        style: count_style
        @props.maxLength - @local.count

      SPAN 
        className: 'hidden'
        "#{@props.maxLength - @local.count} characters left"

      @transferPropsTo TEXTAREA 
        className: class_name
        onChange: =>
         @local.count = $(@getDOMNode()).find('textarea').val().length
         save(@local)



Quill = require './vendor/quill-1.0.js'

window.WysiwygEditor = ReactiveComponent
  displayName: 'WysiwygEditor'

  render : ->

    my_data = fetch @props.key
    subdomain = fetch '/subdomain'
    wysiwyg_editor = fetch 'wysiwyg_editor'

    @supports_Quill = Quill && new Quill()

    if !@local.initialized
      # We store the current value of the HTML at
      # this component's key. This allows the  
      # parent component to fetch the value outside 
      # of this generic wysiwyg component. 
      # However, we "dangerously" set the html of the 
      # editor to the original @props.html. This is 
      # because we don't want to interfere with the 
      # wysiwyg editor's ability to manage e.g. 
      # the selection location. 
      my_data.html = @props.html
      @local.initialized = true
      save @local; save my_data

    @show_placeholder = (!my_data.html || (@editor?.getText().trim().length == 0)) && !!@props.placeholder

    toolbar_items = [
      {
        className: "ql-list fa fa-list-ul",
        value: 'bullet',
        title: 'Bulleted list'
      },{
        className: "ql-list fa fa-list-ol",
        value: 'ordered',
        title: 'Numbered list'
      },{
        className: "ql-bold fa fa-bold",
        title: 'Bold selected text'
      },{
        className: "ql-link fa fa-link",
        title: 'Hyperlink selected text'
      }, 
      # {
      #   className: "ql-image fa fa-image", 
      #   title: 'Insert image'
      # },
    ]

    if fetch('/current_user').is_admin
      toolbar_items.push 
        className: 'fa fa-code'
        title: 'Directly edit HTML'
        onClick: => @local.edit_code = true; save @local

    DIV 
      id: @props.key
      style: 
        position: 'relative'

      onClick: (ev) -> 
        # Catch any clicks within the editor area to prevent the 
        # toolbar from being hidden via the root level 
        # show_wysiwyg_toolbar state
        ev.stopPropagation()

      if @local.edit_code || !@supports_Quill
        AutoGrowTextArea
          style: 
            width: '100%'
            fontSize: 18
          defaultValue: fetch(@props.key).html
          onChange: (e) => 
            my_data = fetch(@props.key)
            my_data.html = e.target.value
            save my_data

      else

        DIV null,

          Dock
            dock_on_zoomed_screens: true
            skip_jut: true
            dummy: wysiwyg_editor.showing
              
            # Toolbar
            DIV 
              ref: 'toolbar'
              role: 'toolbar'
              'title': 'Rich text markup'
              'aria-orientation': 'vertical'
              id: 'toolbar'
              tabIndex: 0
              style: 
                position: 'absolute'
                width: 30
                left: -32
                top: 0
                display: 'block'
                visibility: if wysiwyg_editor.showing != @props.key then 'hidden'

              onFocus: (e) => 
                if !@local.focused_toolbar_item && !@local.just_unfocused

                  if !@local.focused_toolbar_item?
                    @local.focused_toolbar_item = 0 
                    save @local

                  @refs["toolbaritem-#{@local.focused_toolbar_item}"].getDOMNode().focus()

              onKeyDown: (e) => 
                if e.which in [37, 38, 39, 40]
                  # focus prev...
                  i = @local.focused_toolbar_item
                  if e.which in [37, 38] # left or down
                    i-- 
                    if i < 0 
                      i = toolbar_items.length - 1 
                  else 
                    i++ 
                    if i > toolbar_items.length - 1 
                      i = 0
                  @local.focused_toolbar_item = i
                  save @local 
                  @refs["toolbaritem-#{i}"].getDOMNode().focus()
                  e.preventDefault()

              for button, idx in toolbar_items
                do (idx) =>
                  BUTTON
                    ref: "toolbaritem-#{idx}"
                    tabIndex: if @local.focused_toolbar_item == idx then 0 else -1
                    className: button.className
                    'aria-label': button.title
                    style: 
                      fontSize: 14
                      width: 28
                      textAlign: 'center'
                      cursor: 'pointer'
                      padding: 2
                      border: '1px solid #aaa'
                      borderRadius: 3
                      backgroundColor: 'transparent'
                    title: button.title
                    value: if button.value then button.value 
                    onClick: if button.onClick then button.onClick
                    onFocus: (e) => 
                      @local.focused_toolbar_item = idx; 
                      save @local
                      e.stopPropagation()

                    onBlur: (e) => 
                      e.stopPropagation()
                      @local.focused_toolbar_item = null 
                      @local.just_unfocused = true
                      setTimeout =>
                        @local.just_unfocused = false 
                      , 0
                      save @local 

                      # if the focus isn't still on an element inside of this menu, 
                      # then we should close the menu                
                      setTimeout => 
                        if $(document.activeElement).closest(@getDOMNode()).length == 0
                          wysiwyg_editor = fetch 'wysiwyg_editor'
                          wysiwyg_editor.showing = false
                          save wysiwyg_editor
                      , 0

          DIV 
            style: @props.container_style
            className: 'proposal_details' # for formatting like proposals 
          
          

            DIV 
              id: 'editor'
              dangerouslySetInnerHTML:{__html: @props.html}
              onFocus: (e) => 
                # Show the toolbar on focus
                # showing is global state for the toolbar to be 
                # shown. It gets set to null when someone clicks outside the 
                # editor area. This is handled at the root level
                # in the same way that clicking outside a point closes it. 
                # See Root.resetSelection.
                wysiwyg_editor = fetch 'wysiwyg_editor'
                wysiwyg_editor.showing = @props.key
                save wysiwyg_editor

              onBlur: => 
                # if the focus isn't still on an element inside of this menu, 
                # then we should close the menu                
                setTimeout => 
                  if $(document.activeElement).closest(@getDOMNode()).length == 0
                    wysiwyg_editor = fetch 'wysiwyg_editor'
                    wysiwyg_editor.showing = false
                    save wysiwyg_editor
                , 0

              style: _.extend @props.style, 
                outline: if fetch('wysiwyg_editor').showing == @props.key then "2px solid #{focus_blue}"

        

  componentDidMount : -> 
    return if !@supports_Quill

    getHTML = => 
      @getDOMNode().querySelector(".ql-editor").innerHTML

    # Attach the Quill wysiwyg editor
    @editor = new Quill $(@getDOMNode()).find('#editor')[0],    
      modules: 
        toolbar: 
          container: $(@getDOMNode()).find('#toolbar')[0]
      styles: true #if/when we want to define all styles, set to false
      placeholder: if @show_placeholder then @props.placeholder else ''

    keyboard = @editor.getModule('keyboard')
    delete keyboard.bindings[9]    # 9 is the key code for tab; restore tabbing for accessibility

    @editor.on 'text-change', (delta, source) => 
      my_data = fetch @props.key
      my_data.html = getHTML()

      if source == 'user' && my_data.html.indexOf(' style') > -1
        # strip out any style tags the user may have pasted into the html

        removeStyles = (el) ->
          el.removeAttribute 'style'
          if el.childNodes.length > 0
            for child in el.childNodes
              removeStyles child if child.nodeType == 1

        node = @editor.root
        removeStyles node
        my_data.html = getHTML()

      save my_data

# Some overrides to Quill base styles
styles += """
html .ql-container{
  font-family: inherit;
  font-size: inherit;
  line-height: inherit;
  padding: 0;
  overflow-x: visible;
  overflow-y: visible;
}
.ql-editor {
  min-height: 120px;
  outline: none;
}
.ql-clipboard {
  display: none;
}
.ql-editor.ql-blank::before{
  content: attr(data-placeholder);
  pointer-events: none;
  position: absolute;
  color: rgba(0,0,0,.4);
  font-weight: 500;

}
"""

