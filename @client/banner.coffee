require './tabs'




window.DEFAULT_BACKGROUND_COLOR = focus_blue # "#91d8f8"



###########################
# HOMEPAGE HEADER TEMPLATES

styles += """
  .toggle_switch_label {
    padding: 4px 12px;
    cursor: pointer;
    margin-left: 12px;
  }
  .toggle_switch_label div {
    font-size: 14px;
  }

"""

CustomizeGoogleTranslate = ReactiveComponent
  displayName: 'CustomizeGoogleTranslate'
  mixins: [SubdomainSaveRateLimiter]

  componentDidUpdate: -> 

    @save_customization_with_rate_limit
      fields: ['google_translate_style']
      config: fetch('/subdomain').customizations

  render: -> 
    is_light = is_light_background()
    subdomain = fetch '/subdomain'

    if subdomain.customizations.google_translate_style
      @local.google_translate_style ?= JSON.parse JSON.stringify subdomain.customizations.google_translate_style


    edit_forum = fetch 'edit_forum'
    is_admin = fetch('/current_user').is_admin

    trns = subdomain.customizations.google_translate_style


    DIV 
      style: 
        paddingTop: if trns?.callout && !edit_forum.editing then 48    


      if is_admin && edit_forum.editing   

        DIV 
          style:
            display: 'flex'
            justifyContent: 'center'
            paddingTop: if !subdomain.customizations.banner.background_image_url then 48

          
          LABEL 
            className: 'toggle_switch'

            INPUT 
              id: 'enable_google_translate'
              type: 'checkbox'
              name: 'enable_google_translate'
              checked: !!@local.google_translate_style && @local.google_translate_style != '*delete*'
              onChange: (ev) => 
                if ev.target.checked
                  @local.google_translate_style = 
                    prominent: true
                    callout: "¿No hablas ingles? Elige tu idioma:"
                    textAlign: "center"
                  save @local
                else
                  @local.google_translate_style = '*delete*'
                  save @local

            SPAN 
              className: 'toggle_switch_circle'

          LABEL 
            className: 'toggle_switch_label'
            style:
              backgroundColor: if is_light then 'rgba(255,255,255,.4)' else 'rgba(0,0,0,.4)'

            htmlFor: 'enable_google_translate'
            B null,
              'Enable Google Translate.'
            
            DIV null,
              "Helps support multi-lingual forums."


      if trns?.prominent && fetch('location').url == '/'
        DIV
          className: "translator"
          


          if trns.callout?
            DIV 
              style: 
                marginBottom: 16
                textAlign: 'center'
                color: 'black'

              if edit_forum.editing 
                AutoGrowTextArea 
                  className: 'banner_title'
                  defaultValue: @local.google_translate_style?.callout
                  style: 
                    color: 'inherit'
                    fontSize: 'inherit'
                    backgroundColor: 'transparent'
                    border: 'none'
                    width: '100%'
                  onChange: (e) =>
                    @local.google_translate_style.callout = e.target.value
                    save @local
              else 
                trns.callout

          DIV 
            className: 'google-translate-candidate-container'



CustomizeTitle = ReactiveComponent
  displayName: 'CustomizeTitle'
  mixins: [SubdomainSaveRateLimiter]

  componentDidUpdate: ->
    @save_customization_with_rate_limit
      fields: ['title']
      config: fetch('/subdomain').customizations.banner

  render : ->
    subdomain = fetch '/subdomain'
    edit_forum = fetch 'edit_forum'

    subdomain.customizations.banner ?= {}
    banner_config = subdomain.customizations.banner

    title = banner_config.title or @props.title

    is_admin = fetch('/current_user').is_admin


    DIV 
      className: 'CustomizeTitle'

      STYLE
        dangerouslySetInnerHTML: __html: """
          .CustomizeTitle > .banner_title {
            display: block;
            border: none;
            background-color: transparent;
            color: inherit;
            width: 100%;
            padding: 0px;
            line-height: 1.4;
          }
          .CustomizeTitle > .banner_title::placeholder {
            color: rgba(0,0,0,.4);
          }
          .dark .CustomizeTitle > .banner_title::placeholder, .with-image .CustomizeTitle > .banner_title::placeholder {
            color: rgb(255,255,255,.6);
          }

        """

      if is_admin && edit_forum.editing

        AutoGrowTextArea 
          id: 'banner_primary_input'
          className: 'banner_title'
          defaultValue: title
          style: @props.style
          onChange: (e) =>
            @local.title = e.target.value
            save @local

          placeholder: translator('banner.title.placeholder', 'A headline for your forum')

      else 
        DIV
          className: 'banner_title'
          style: @props.style
          dangerouslySetInnerHTML: __html: title or subdomain.name
          onDoubleClick: if is_admin then => 
            edit_forum.editing = true 
            save edit_forum
            int = setInterval => 
              textarea = document.getElementById('banner_primary_input')
              if textarea
                textarea.focus()
                textarea.setSelectionRange(-1, -1) # put cursor at end
                clearInterval(int)
            , 10


CustomizeDescription = ReactiveComponent
  displayName: 'CustomizeDescription'
  mixins: [SubdomainSaveRateLimiter]

  componentDidUpdate: ->
    @local.description = fetch("forum-description").html
    @save_customization_with_rate_limit
      fields: ['description']
      config: fetch('/subdomain').customizations.banner

  render : ->
    edit_forum = fetch 'edit_forum'

    is_admin = fetch('/current_user').is_admin

    description = customization('banner')?.description
    has_description = description?.trim().length > 0 && description.trim() != '<p><br></p>'

    is_light = is_light_background()

    focus_on_mount = @local.focus_on_mount
    @local.focus_on_mount = false

    if is_admin && edit_forum.editing
      DIV 
        id: 'edit_banner_description'
        className: 'CustomizeDescription'

        STYLE
          dangerouslySetInnerHTML: __html: """
            #edit_banner_description .ql-editor {
              min-height: 48px;
            }
            .wrapper.with-image .CustomizeDescription .ql-editor.ql-blank::before {
              color: rgba(255,255,255,.4);
            } 

          """
        WysiwygEditor
          editor_key: "forum-description"
          style: @props.style
          horizontal: true
          html: description
          placeholder: translator("banner.description.label", "Describe your forum. What is being discussed? Who is it for, and who are the hosts? How long will it be open?")
          focus_on_mount: focus_on_mount
          button_style: 
            backgroundColor: 'white'  
    else
      DIV null,              
        if has_description 
          DIV 
            className: 'wysiwyg_text'
            style: 
              fontSize: @props.style.fontSize or 18
              padding: @props.style.padding or '6px 8px'
              fontWeight: @props.style.fontWeight or 400
            dangerouslySetInnerHTML: __html: description
            onDoubleClick: if is_admin then => 
              edit_forum.editing = true 
              @local.focus_on_mount = true
              save edit_forum
              setTimeout => 
                @refs.primary_input?.focus()
                @refs.primary_input?.setSelectionRange(-1, -1) # put cursor at end
        else if @props.opts.supporting_text
          @props.opts.supporting_text()


UploadFileSVG = (opts) ->
  SVG
    dangerouslySetInnerHTML: __html: '<g><path d="M89.4,46.5c-2.3,0-4.1,1.8-4.1,4.1v28.2H14.6V50.5c0-2.3-1.8-4.1-4.1-4.1c-2.3,0-4.1,1.8-4.1,4.1v32.4   c0,2.3,1.8,4.1,4.1,4.1h78.9c2.3,0,4.1-1.8,4.1-4.1V50.5C93.5,48.3,91.7,46.5,89.4,46.5z"></path><path d="M52.7,14.2c-0.1-0.1-0.2-0.2-0.4-0.3c-0.1,0-0.1-0.1-0.3-0.2c-0.6-0.5-1.4-0.7-2.2-0.7c-0.5,0-1.1,0.1-1.6,0.3   c-0.5,0.2-1,0.5-1.4,0.8L26.8,34.3c-0.8,0.8-1.2,1.9-1.2,3c0,1.1,0.5,2,1.2,2.7c0.8,0.8,1.7,1.2,2.9,1.2s2.2-0.4,2.9-1.2l13-13.1   v41.6c0,2.3,1.8,4.1,4.1,4.1c2.3,0,4.1-1.8,4.1-4.1V26.9L67.1,40c0.8,0.8,1.7,1.2,2.9,1.2s2.2-0.4,2.9-1.2c0.8-0.8,1.2-1.9,1.2-3   c0-1.1-0.5-2-1.2-2.7L52.7,14.2z"></path></g>'
    height: opts.height or 100
    width: opts.height or 100
    fill: opts.fill or '#fff'
    x: 0
    y: 0
    viewBox: "0 0 100 100"
    style: 
      enableBackground: "new 0 0 100 100" 

UploadableLogo = (opts) ->
  edit_forum = fetch 'edit_forum'
  editing = edit_forum.editing

  has_logo = customization('banner')?.logo?.url

  icon_height = 50

  wrapper_style = {}

  is_light = is_light_background()

  if editing 
    wrapper_style = 
      position: 'relative'
      minWidth: if !has_logo then 100
      minHeight: if !has_logo then 100
      height: '100%'
      width: '100%'


  DIV 
    style: wrapper_style

    if has_logo
      IMG 
        style: opts.image_style
        src: opts.src

    if editing && has_logo # delete logo
      delete_size = 30
      BUTTON 
        style: 
          width: delete_size
          height: delete_size
          position: 'absolute'
          right: 4
          top: 4
          border: 'none'
          background: 'none'
          cursor: 'pointer'
          padding: 0
          zIndex: 1

        onClick: ->
          document.querySelector(opts.trigger_delete).click()

        SVG 
          height: delete_size
          width: delete_size
          fill: '#fff'
          x: 0
          y: 0
          viewBox: "0 0 511.995 511.995"
          style: 
            enableBackground: "new 0 0 511.995 511.995" 

          dangerouslySetInnerHTML: __html: """
            <g>
              <path d="M437.126,74.939c-99.826-99.826-262.307-99.826-362.133,0C26.637,123.314,0,187.617,0,256.005
                s26.637,132.691,74.993,181.047c49.923,49.923,115.495,74.874,181.066,74.874s131.144-24.951,181.066-74.874
                C536.951,337.226,536.951,174.784,437.126,74.939z M409.08,409.006c-84.375,84.375-221.667,84.375-306.042,0
                c-40.858-40.858-63.37-95.204-63.37-153.001s22.512-112.143,63.37-153.021c84.375-84.375,221.667-84.355,306.042,0
                C493.435,187.359,493.435,324.651,409.08,409.006z"/>
              <path d="M341.525,310.827l-56.151-56.071l56.151-56.071c7.735-7.735,7.735-20.29,0.02-28.046
                c-7.755-7.775-20.31-7.755-28.065-0.02l-56.19,56.111l-56.19-56.111c-7.755-7.735-20.31-7.755-28.065,0.02
                c-7.735,7.755-7.735,20.31,0.02,28.046l56.151,56.071l-56.151,56.071c-7.755,7.735-7.755,20.29-0.02,28.046
                c3.868,3.887,8.965,5.811,14.043,5.811s10.155-1.944,14.023-5.792l56.19-56.111l56.19,56.111
                c3.868,3.868,8.945,5.792,14.023,5.792c5.078,0,10.175-1.944,14.043-5.811C349.28,331.117,349.28,318.562,341.525,310.827z"/>
            </g>
            """

    if editing && !has_logo # upload icon
      DIV
        style: 
          height: icon_height
          width: icon_height
          position: 'absolute'
          left: '50%'
          top: '50%'
          marginLeft: -icon_height/2
          marginTop: -icon_height/2
          cursor: 'pointer'
          zIndex: 1
        onClick: ->
          document.querySelector(opts.trigger_upload).click()

        UploadFileSVG
          height: icon_height
          fill: if is_light then 'black' else 'white'


CustomizeLogo = ReactiveComponent
  displayName: 'CustomizeLogo'
  mixins: [SubdomainSaveRateLimiter]

  componentDidUpdate: ->
    @save_customization_with_rate_limit
      fields: ['height', 'left', 'top']
      config: fetch('/subdomain').customizations.banner.logo



  render : ->
    edit_forum = fetch 'edit_forum'
    edit_banner = fetch 'edit_banner'

    has_logo = edit_banner.logo_preview != '*delete*' && (edit_banner.logo_preview || customization('banner')?.logo?.url)
    has_masthead = edit_banner.masthead_preview != '*delete*' && (edit_banner.masthead_preview or customization('banner')?.background_image_url)

    return SPAN null if !has_logo && !edit_forum.editing
    return SPAN null if !fetch('/subdomain').name

    src = edit_banner.logo_preview or customization('banner')?.logo?.url

    if has_logo
      h = @local.height or customization('banner')?.logo?.height or 150
      height = parseInt(h)
    else 
      height = 150

    left = @local.left or customization('banner')?.logo?.left or 50
    top  = @local.top  or customization('banner')?.logo?.top  or 68

    is_light = is_light_background()

    style = _.defaults {}, @props.style, 
      left: left 
      top: top
      position: 'absolute'
      cursor: if edit_forum.editing then 'move'
      height: height + 2
      width: if !has_logo then 150
      zIndex: if @local.moving || @local.resizing then '999'
      overflow: 'hidden'


    onMouseDown = (ev) => 
      t = 0
      l = 0
      el = ev.target
      while el 
        t += el.offsetTop
        l += el.offsetLeft
        el = el.offsetParent

      @local.start_left = ev.pageX - l
      @local.start_top = ev.pageY - t
      @local.moving = true 
      save @local 


      document.addEventListener "mouseup", onMouseUp
      document.addEventListener "mousemove", onMouseMove

      ev.preventDefault()
      ev.stopPropagation()

    onMouseUp = (ev) => 
      @local.moving = @local.resizing = false 
      save @local 
      document.removeEventListener "mouseup", onMouseUp
      document.removeEventListener "mousemove", onMouseMove
      document.removeEventListener "mousemove", onMouseMoveResize

    onMouseMove = (ev) =>
      if @local.moving
        el = document.querySelector('#banner')
        banner_top = 0
        while el 
          banner_top += el.offsetTop
          el = el.offsetParent
        @local.left = Math.max 0, ev.pageX - @local.start_left
        if isNaN(@local.left)
          @local.left = 50 

        @local.top = Math.max 0, ev.pageY - banner_top - @local.start_top
        if isNaN(@local.top)
          @local.top = 50

        save @local
        ev.stopPropagation()
        ev.preventDefault()

    onMouseDownResize = (ev) => 
      @local.startY = ev.pageY
      @local.start_height = height
      @local.resizing = true
      save @local 

      document.addEventListener "mouseup", onMouseUp
      document.addEventListener "mousemove", onMouseMoveResize

      ev.preventDefault()
      ev.stopPropagation()

    onMouseMoveResize = (ev) =>
      if @local.resizing
        @local.height = @local.start_height + (ev.pageY - @local.startY)
        save @local

        ev.stopPropagation()        
        ev.preventDefault()



    # todo: add touch events
    if edit_forum.editing
      _.extend style, 
        borderStyle: if !has_logo then 'dashed' else 'solid'
        borderColor: if is_light then "rgba(0,0,0,.7)" else 'rgba(255,255,255,.7)'
        borderWidth: 1 
        left: style.left - 1
        top: style.top - 1

    DIV
      style: _.defaults {}, style,
        opacity: if !has_logo then 1

      onMouseUp:   if edit_forum.editing then onMouseUp        
      onMouseDown: if edit_forum.editing then onMouseDown
      onMouseMove: if edit_forum.editing then onMouseMove

      if has_logo || edit_forum.editing
        UploadableLogo 
          trigger_upload: 'input#logo'
          trigger_delete: 'button#delete_logo'
          src: src
          image_style: 
            height: height

      if edit_forum.editing
        DIV 
          style: 
            position: 'absolute'
            fontSize: 14
            color: if is_light then 'rgba(0,0,0)' else 'rgba(255,255,255)'
            zIndex: 1
            bottom: 0
            marginTop: 60
            width: '100%'
            textAlign: 'center'

          if !has_logo
            translator 'banner.logo_label', 'Logo (optional)'
          else 
            BUTTON 
              style: 
                color: 'inherit'
                border: 'none'
                textDecoration: 'underline'
                padding: 0
                backgroundColor: if !is_light then 'rgba(0,0,0,.3)' else 'rgba(255,255,255,.3)'

              onClick: ->
                document.querySelector('input#logo').click()

              translator 'banner.change_logo', 'change'


      if edit_forum.editing
        DIV 
          style: 
            backgroundColor: if has_masthead && !has_logo then (if !is_light then 'rgba(0,0,0,.4)' else 'rgba(255,255,255,.4)')
            position: 'absolute'
            left: 0
            top: 0
            width: '100%'
            height: '100%'
            pointerEvents: 'none'

      if has_logo && edit_forum.editing
        DIV # cut triangle in bottom right corner for dragging to resize
          onMouseDown: if edit_forum.editing then onMouseDownResize
          onMouseMove: if edit_forum.editing then onMouseMoveResize

          style: 
            backgroundColor: if is_light then "black" else "white"
            height: 17 * 2
            width: 17 * 2
            position: 'absolute'
            bottom: -17
            right: -17
            cursor: 'nwse-resize'
            transform: 'rotate(45deg)'
            zIndex: 2

DEFAULT_TEXT_BLOCK_COLOR = "#000000"
DEFAULT_TEXT_BLOCK_OPACITY = 255 * .8
CustomizeTextBlock = ReactiveComponent
  displayName: 'CustomizeTextBlock'

  mixins: [SubdomainSaveRateLimiter]

  componentDidUpdate: ->
    @save_customization_with_rate_limit
      fields: ['text_background_css', 'text_background_css_opacity']
      config: fetch('/subdomain').customizations.banner


  render : ->
    edit_forum = fetch 'edit_forum'
    has_masthead = customization('banner')?.background_image_url
    return SPAN null if !edit_forum.editing || !has_masthead

    DIV 
      style: 
        width: 80 
        position: 'absolute'
        right: 5
        bottom: 0

      INPUT 
        id: 'text_background_css'
        type: 'color'
        name: 'text_background_css'
        defaultValue: customization('banner')?.text_background_css or DEFAULT_TEXT_BLOCK_COLOR
        style: 
          width: '100%'
          display: 'block'
        onChange: (e) =>
          @local.text_background_css = e.target.value
          save @local

      INPUT 
        id: 'text_background_css_opacity'
        type: 'range'
        min: 0
        step: 1
        max: 255
        name: 'text_background_css_opacity'
        defaultValue: customization('banner')?.text_background_css_opacity or DEFAULT_TEXT_BLOCK_OPACITY
        style:
          width: '100%'
          display: 'block'
        onChange: (e) =>
          @local.text_background_css_opacity = e.target.value
          save @local

UploadBackgroundImageSVG = (opts) ->
  SVG 
    dangerouslySetInnerHTML: __html: '<g><path d="M64.3,53.9l-7.4-10.4c-0.6-0.8-1.7-0.9-2.4-0.2l-4.2,4.1c-0.7,0.7-1.8,0.6-2.4-0.2L37.5,33.3c-0.7-0.9-2-0.8-2.6,0.1     L17.9,60.3c-0.7,1,0.1,2.4,1.4,2.4H58C59.4,59.3,61.6,56.3,64.3,53.9z"></path><circle cx="59.3" cy="30.5" r="5.9"></circle><path d="M84.6,54V13.1c0-1.4-1.1-2.6-2.6-2.6H5.1c-1.4,0-2.6,1.1-2.6,2.6v60.7c0,1.4,1.2,2.6,2.6,2.6h57c2.2,7.5,9.1,13,17.3,13     c10,0,18.1-8.1,18.1-18.1C97.5,63.1,92,56.2,84.6,54z M7.6,15.7h71.8v37.6c0,0,0,0,0,0c-10,0-18.1,8.1-18.1,18.1H7.6V15.7z      M79.4,84.3c-7.1,0-13-5.8-13-13c0-7.1,5.8-13,13-13c7.1,0,13,5.8,13,13C92.4,78.5,86.6,84.3,79.4,84.3z"></path><path d="M84.9,68.8L81,63.6c-0.4-0.5-1-0.8-1.6-0.8c0,0,0,0,0,0c-0.6,0-1.2,0.3-1.6,0.8l-3.9,5.2c-0.5,0.6-0.5,1.4-0.2,2.1     c0.3,0.7,1,1.1,1.8,1.1h1.6v5.9c0,1.3,1,2.3,2.3,2.3c1.3,0,2.3-1,2.3-2.3V72h1.6c0.8,0,1.4-0.4,1.8-1.1     C85.5,70.2,85.4,69.4,84.9,68.8L84.9,68.8z"></path></g></g></g>'
    height: opts.height or 100
    width: opts.width or opts.height or 100
    fill: opts.fill or '#fff'
    x: "0px" 
    y: "0px" 
    viewBox: "0 0 100 100" 

CustomizeBackground = ReactiveComponent
  displayName: 'CustomizeBackground'

  mixins: [SubdomainSaveRateLimiter]

  componentDidUpdate: ->
    @save_customization_with_rate_limit
      fields: ['background_css']
      config: fetch('/subdomain').customizations.banner
      wait_for: 10


  render : ->
    edit_forum = fetch 'edit_forum'
    edit_banner = fetch 'edit_banner'

    src = edit_banner.masthead_preview or customization('banner')?.background_image_url
    has_masthead = edit_banner.masthead_preview != '*delete*' && src

    editing = edit_forum.editing 
    
    return SPAN(null) if !editing

    is_light = is_light_background()

    icon_height = 50
    color = if is_light then 'rgba(0,0,0,1)' else 'rgba(255,255,255,1)'

    compressed = CONTENT_WIDTH() < 1036

    DIV 
      style: 
        textAlign: if compressed then 'right'
      DIV
        style: 
          position: 'relative'
          # bottom: 50
          # width: 218
          float: if !compressed then 'right'
          backgroundColor: if is_light then 'rgba(255,255,255,.4)' else 'rgba(0,0,0,.4)'
          padding: '12px 24px'
          zIndex: 9
          marginTop: if compressed then 12 else if has_masthead && !compressed then -120 else -100
          display: 'inline-block'

        DIV 
          style: 
            display: 'flex'
            flexDirection: 'column'
          


          DIV
            style: 
              cursor: 'pointer'
              display: 'flex'
              alignItems: 'center'
              flexDirection: 'column'
              padding: 4
              border: "1px dashed #{if is_light then 'black' else 'white'}"
              borderRadius: 4

              
            onClick: ->
              document.querySelector('input#masthead').click()

            DIV
              style: 
                margin: 'auto'
                height: icon_height
                width: icon_height

              UploadBackgroundImageSVG
                height: icon_height
                fill: if is_light then 'black' else 'white'

            DIV 
              style: 
                fontSize: 14
                color: color
                marginBottom: 4


              if has_masthead
                DIV 
                  style: 
                    display: 'flex'

                  BUTTON 
                    className: 'like_link'
                    style: 
                      color: color
                      fontSize: 12
                    'change'

                  SPAN 
                    style: 
                      padding: '0px 4px'
                    '•'

                  BUTTON 
                    className: 'like_link'
                    style: 
                      cursor: 'pointer'
                      zIndex: 1
                      color: color
                      fontSize: 12
                      # marginTop: 12
                      # marginLeft: 4

                    onClick: (e) =>
                      e.stopPropagation()
                      e.preventDefault()
                      @local.background_css = DEFAULT_BACKGROUND_COLOR
                      save @local
                      document.querySelector('button#delete_masthead').click()

                    'remove'

              else 
                translator 'banner.upload_background_label', 'Set background pic'

          DIV 
            style: 
              fontSize: 14
              position: 'relative'


            if has_masthead

              LABEL 
                style: 
                  color: color
                  marginRight: 4
                  display: 'flex'
                  marginTop: 4
                  justifyContent: 'center'

                htmlFor: "background_color"

                SELECT 
                  id: 'background_color'
                  type: 'dropdown'
                  name: 'background_color'
                  value: is_light

                  onChange: (e) =>
                    @local.background_css = if e.target.value == 'true' then "rgb(255,255,255)" else 'rgb(0,0,0)'
                    save @local

                  OPTION 
                    value: true
                    'background is light'
                  OPTION 
                    value: false
                    'background is dark'
            

            else 
              LABEL 
                style: 
                  color: color
                  marginRight: 8
                  display: 'flex'
                  marginTop: 4
                  alignItems: 'center'
                  justifyContent: 'center'
                htmlFor: "background_color"

                translator("banner.background_css.label", "...or set to color") + ':'

                INPUT 
                  id: 'background_color'
                  type: 'color'
                  style: 
                    marginLeft: 4
                  name: 'background_color'
                  value: @local.background_css or customization('banner')?.background_css or DEFAULT_BACKGROUND_COLOR
                  onChange: (e) =>
                    @local.background_css = e.target.value
                    save @local




window.EditBanner = ReactiveComponent
  displayName: 'EditBanner'

  render : ->
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    edit_banner = fetch 'edit_banner'
    edit_forum = fetch 'edit_forum'

    if !current_user.is_admin
      return DIV null 

    is_light = is_light_background()

    delete_masthead = (e) =>
      edit_banner.masthead_preview = '*delete*' 
      @refs.masthead_file_input.value = ''
      @delete_masthead = true 
      save edit_banner

    delete_logo = (e) =>
      edit_banner.logo_preview = '*delete*' 
      @refs.logo_file_input.value = ''
      @delete_logo = true 
      save edit_banner



    DIV null, 
      if !edit_forum.editing
        EditForum()

      if @local.file_errors
        DIV style: {color: 'red'}, 'Error uploading files!'

      FORM 
        id: 'banner_files'
        action: '/update_images_hack'
        style: 
          display: 'none'

        INPUT 
          id: 'logo'
          type: 'file'
          name: 'logo'
          accept: "image/jpg, image/jpeg, image/pjpeg, image/png, image/x-png, image/gif, image/webp"          
          ref: 'logo_file_input'
          onChange: (ev) =>
            edit_banner.logo_preview = URL.createObjectURL ev.target.files[0]
            @delete_logo = false 
            save edit_banner

        INPUT 
          id: 'masthead'
          type: 'file'
          accept: "image/jpg, image/jpeg, image/pjpeg, image/png, image/x-png, image/gif, image/webp"          
          name: 'masthead'
          ref: 'masthead_file_input'
          onChange: (ev) =>
            edit_banner.masthead_preview = URL.createObjectURL ev.target.files[0]
            @delete_masthead = false

            # guess at whether this is predominantly a dark or light image
            img = document.createElement('img')
            img.crossOrigin = "Anonymous"
            tgt = ev.target
            files = tgt.files
            canvas = document.createElement("canvas")
            ctx = canvas.getContext("2d")

            if FileReader && files && files.length
              fr = new FileReader()
              fr.onload = -> 
                img.onload = -> 
                  canvas.width = img.width
                  canvas.height = img.height
                  ctx.drawImage(img, 0, 0, img.width, img.height)
                  image_data = ctx.getImageData(0, 0, img.width, img.height).data
                  is_light = is_image_mostly_light image_data, img.width, img.height

                  if is_light 
                    subdomain.customizations.banner.background_css = 'rgb(255,255,255)'
                  else 
                    subdomain.customizations.banner.background_css = 'rgb(0,0,0)'

                  save subdomain

                img.src = fr.result

              fr.readAsDataURL(files[0])

            save edit_banner


      BUTTON 
        onClick: delete_masthead
        id: 'delete_masthead'
        style: 
          display: 'none '

      if edit_banner.logo_preview != '*delete*' && (edit_banner.logo_preview || customization('banner')?.logo?.url)

        BUTTON 
          id: 'delete_logo'
          onClick: delete_logo
          style: 
            display: 'none'

  exit_edit: ->
    edit_banner = fetch 'edit_banner'

    for k,v of edit_banner
      if k != 'key'
        delete edit_banner[k]
    
    wysiwyg_description = fetch("forum-description")
    wysiwyg_description.html = null 

    save wysiwyg_description
    save edit_banner


  componentDidUpdate: -> 
    submit_masthead = @refs.masthead_file_input?.files?.length > 0
    submit_logo =     @refs.logo_file_input?.files?.length > 0
    
    if submit_masthead || submit_logo || @delete_logo || @delete_masthead
      @submit_files()

  submit_files: (cb) ->
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    data = 
      authenticity_token: current_user.csrf
    
    if @delete_logo
      data.logo = '*delete*'

    if @delete_masthead
      data.masthead = '*delete*'

    ajax_submit_files_in_form
      form: '#banner_files' 
      type: 'PUT'
      additional_data: data
      success: (response) =>
        @delete_logo = false 
        @delete_masthead = false     
        @refs.masthead_file_input?.value = null
        @refs.logo_file_input?.value = null

        try 
          resp = JSON.parse(response)
        catch 
          console.error "Could not parse server response", response
          resp = []

        for obj in resp
          arest.updateCache(obj)
        cb?(true)
      error: => 
        @local.file_errors = true
        save @local
        cb?(false)






window.PhotoBanner = (opts) -> 
  opts ?= {}
  
  homepage = EXPAND_IN_PLACE || fetch('location').url == '/'
  subdomain = fetch '/subdomain'
  edit_banner = fetch 'edit_banner'
  edit_forum = fetch 'edit_forum'

  return SPAN null if !subdomain.name 

  tab_background_color = (if edit_forum.editing then edit_banner.text_background_css) or customization('banner')?.text_background_css or '#666'

  if !homepage
    return  DIV
              style: 
                backgroundColor: 'white'

              DIV
                style:
                  margin: 'auto'
                  fontSize: 43
                  padding: '10px 20px' 

                back_to_homepage_button {fontSize: 32}, translator 'engage.back_to_homepage', 'Homepage'


  has_image_background = edit_banner.masthead_preview != '*delete*' && (edit_banner.masthead_preview || customization('banner')?.background_image_url)

  convert_opacity = (value) ->
    if !value
      '00'
    else 
      parseInt(value).toString(16)

  banner_config = subdomain.customizations.banner

  description = fetch("forum-description").html or banner_config?.description or opts.supporting_text
  has_description = opts.supporting_text || (description?.trim().length > 0 && description.trim() != '<p><br></p>')

  has_title = (banner_config.title or opts.title or subdomain.name)?.length > 0 

  has_translation_callout = subdomain.customizations.google_translate_style?.callout


  background_color = customization('banner')?.background_css or DEFAULT_BACKGROUND_COLOR

  is_dark_theme = !is_light_background()

  if has_image_background
    text_block_color = edit_banner.text_background_css or customization('banner')?.text_background_css or DEFAULT_TEXT_BLOCK_COLOR 
    text_block_opacity = parseInt(edit_banner.text_background_css_opacity or customization('banner')?.text_background_css_opacity or DEFAULT_TEXT_BLOCK_OPACITY)
    text_block_background = "#{text_block_color}#{convert_opacity(text_block_opacity)}" or 'rgba(0, 0, 0, .8)' 
    
    if text_block_opacity > 126
      text_block_is_dark = !is_light_background(text_block_color)
    else 
      text_block_is_dark = is_dark_theme

    text_color = if text_block_is_dark then 'white' else 'black'

  else  
    text_color = if is_light_background(background_color) then 'black' else 'white'



  DIV 
    id: 'banner'
    className: "PhotoBanner"

    STYLE
      dangerouslySetInnerHTML: __html: """
        .PhotoBanner {
          position: relative;
          color: black;
          padding-top: #{if edit_forum.editing then '54px' else '0px'};
        }
        .dark .PhotoBanner {
          color: white;
        }
        .PhotoBanner > .wrapper.with-image {
          background-image: url(#{edit_banner.masthead_preview or customization('banner')?.background_image_url});
          background-size: cover;
          background-position: center;
          padding-top: 120px;           
        }
        .PhotoBanner > .wrapper.no-image {
          background: #{background_color};
        }

        .PhotoBanner > .wrapper.with-image.with-translation-callout {
          padding-top: 64px;
        }

        .PhotoBanner > .wrapper .translator {
          padding: 16px;
          width: 380px;
          margin: 0 auto 36px auto; 
          background-color: rgba(255,255,255,.8);
          position: relative; 
          top: 36px;
        }

        .PhotoBanner > .wrapper > .text_block {
          padding: 64px 48px 48px 48px;
          width: #{HOMEPAGE_WIDTH()}px;
          max-width: #{720 + 48 * 2}px;
          margin: auto;
          color: #{text_color};
          position: relative;
          top: 0;          
        } 

        .PhotoBanner > .wrapper.with-image > .text_block {
          background-color: #{text_block_background};
        } 


        // .dark .PhotoBanner > .wrapper > .text_block, .PhotoBanner > .wrapper.with-image > .text_block {
        //  color: black;
        // }

        .PhotoBanner > .wrapper .CustomizeTitle .banner_title {
          font-size: 42px;
          font-weight: 700;
          font-family: #{header_font()};
          text-align: center;
          margin-bottom: #{if has_description || edit_forum.editing then 28 else 0}px;

          font-weight: 800;
          text-shadow: 0px 1px 2px rgba(0,0,0,.4);
        }

        .PhotoBanner #tabs {
          margin-top: 100px;
          top: 0;
          z-index: 0;
        }

        .PhotoBanner > .wrapper.no-image #tabs {
          margin-top: 48px;
          top: 0;
        }



        .PhotoBanner #tabs > ul {
        }
        .PhotoBanner #tabs > ul > li {
          margin: 2px 6px 0px 6px;
          background-color: #{tab_background_color};          
        }          
        .PhotoBanner #tabs > ul > li.selected {
          background-color: #{main_background_color};
        }
        .PhotoBanner #tabs > ul > li > h4 {
          //text-transform: uppercase;
          font-family: #{header_font()};
          font-weight: 600;
          font-size: 17px;
          padding: 10px 16px 4px;
        }
        .dark .PhotoBanner #tabs > ul > li > h4 {
        }
        .PhotoBanner #tabs > ul > li.selected > h4, .PhotoBanner #tabs > ul > li.selected > h4 {
          // color: black;        
        }
        """

    DIV 
      className: "wrapper #{if has_image_background then 'with-image' else 'no-image'} #{if has_translation_callout then 'with-translation-callout' else 'no-translation-callout'}"

      CustomizeLogo()


      CustomizeGoogleTranslate()


      if has_description || has_title || edit_forum.editing

        DIV
          className: 'text_block'
          style: opts.header_style

          CustomizeTextBlock()


          CustomizeTitle
            title: opts.header
            style: opts.header_text_style

          CustomizeDescription
            key: 'editable_description'
            opts: opts
            style: 
              border: if !has_description then (if has_image_background || is_dark_theme then '1px solid rgba(255,255,255,.5)' else '1px solid rgba(0,0,0,.5)')
              padding: "6px 8px"
              minHeight: 20
              fontSize: 16
              fontWeight: 600

      CustomizeBackground()


      HomepageTabs(opts)



window.MediaBanner = -> 
  homepage = fetch('location').url == '/'
  subdomain = fetch '/subdomain'
  edit_banner = fetch 'edit_banner'

  return SPAN null if !subdomain.name 

  if !homepage
    return  DIV
              style: 
                backgroundColor: 'white'

              DIV
                style:
                  margin: 'auto'
                  fontSize: 43
                  padding: '10px 20px' 

                back_to_homepage_button {fontSize: 32}, translator 'engage.back_to_homepage', 'Homepage'

  has_image_background = edit_banner.masthead_preview != '*delete*' && (edit_banner.masthead_preview || customization('banner')?.background_image_url)
  if has_image_background
    bg = edit_banner.masthead_preview or customization('banner')?.background_image_url

  convert_opacity = (value) ->
    if !value
      '00'
    else 
      parseInt(value).toString(16)
    
  DIV 
    id: 'banner'
    className: "MediaBanner"

    STYLE
      dangerouslySetInnerHTML: __html: """

        .MediaBanner {
          position: relative;
          color: black;
          background-color: #eee;
          padding: 0px 2px;
          border-bottom: 1px solid black;
        } .dark .MediaBanner {
          color: white;
        }
        .MediaBanner > .upper_wrapper {
          padding-top: 28px;
          background-color: white;
        }

        .MediaBanner > .upper_wrapper .CustomizeTitle .banner_title {
          font-size: 60px;
          font-weight: 700;
          font-family: #{header_font()};
          text-align: left;
          margin-left: 36px;
          margin-bottom: 22px;
        }
        .MediaBanner > .image_wrapper {
          padding: 20px 36px;
        } 
        .MediaBanner > .image_wrapper > img {
          object-fit: cover;
          display: block;
          height: 260px;
          width: 100%;
        }
        .MediaBanner #tabs {
          margin-top: 0;
          top: 0;
          border-top: 1px solid #ccc;
          box-shadow: 0 1px 3px rgba(0,0,0,.15);
        }
        .MediaBanner #tabs > ul {
          text-align: left;
          width: 100%;
          padding-left: 20px;          
        }
        .MediaBanner #tabs > ul > li {
          background-color: transparent;
          margin: 0px 6px;          
        }          
        .MediaBanner #tabs > ul > li > h4 {
          text-transform: uppercase;
          font-family: #{customization('font')};
          font-weight: 600;
          font-size: 16px;
          padding: 16px 8px 24px;
          color: black;
        }
        .dark .MediaBanner #tabs > ul > li > h4 {
          color: white;
        }

        .MediaBanner #tabs > ul > li.selected > h4, .MediaBanner #tabs > ul > li.hovered > h4 {
          color: black;
          text-decoration: underline;
        }
        .dark .MediaBanner #tabs > ul > li.selected > h4, .dark .MediaBanner #tabs > ul > li.hovered > h4 {
          color: white;
        }
      """

    DIV 
      className: 'upper_wrapper'

      # CustomizeLogo() 

      CustomizeGoogleTranslate()
      CustomizeTitle()

      CustomizeBackground()

      HomepageTabs()

    if has_image_background
      DIV 
        className: 'image_wrapper'

        IMG
          src: bg




# A small header with text and optionally a logo
window.ShortHeader = (opts) ->
  subdomain = fetch '/subdomain'   
  loc = fetch 'location'

  return SPAN null if !subdomain.name

  homepage = loc.url == '/'

  opts ||= {}
  _.defaults opts, (customization('forum_header') or {}),
    text: customization('banner')?.title or subdomain.name
    external_link: subdomain.external_project_url
    logo_src: customization('banner')?.logo?.url
    logo_height: 50
    min_height: 70
    padding: '8px 0'
    padding_left_icon: 20


  opts.background = 'transparent'
  background_is_light = true

  DIV 
    style:
      background: opts.background

    DIV
      style: 
        position: 'relative'
        padding: opts.padding
        minHeight: opts.min_height
        display: 'flex'
        flexDirection: 'row'
        justifyContent: 'flex-start'
        alignItems: 'center'
        width: if homepage then HOMEPAGE_WIDTH()
        margin: if homepage then 'auto'

      DIV 
        style: 
          paddingLeft: if !homepage then opts.padding_left_icon else 0
          paddingRight: 20
          height: if opts.logo_height then opts.logo_height
          display: 'flex'
          alignItems: 'center'


        if opts.logo_src
          A 
            href: if !homepage then '/' else opts.external_link
            style: 
              fontSize: 0
              cursor: if !homepage && !opts.external_link then 'default'
              verticalAlign: 'middle'
              display: 'block'

          
            IMG 
              src: opts.logo_src
              alt: "#{subdomain.name} logo"
              style: 
                height: opts.logo_height

        if !homepage

          DIV 
            style: 
              paddingRight: 18
              position: if opts.logo_src then 'absolute'
              bottom: if opts.logo_src then -30
              left: if opts.logo_src then 7
              

            back_to_homepage_button
              color: if !background_is_light && !opts.logo_src then 'white'
              fontSize: 18
              fontWeight: 600

            , TRANSLATE("engage.navigate_back_to_homepage" , 'homepage')


      if opts.text
        H2 
          style: 
            color: if !background_is_light then 'white'
            marginLeft: if opts.logo_src then 35
            paddingRight: 90
            fontSize: 32
            fontWeight: 400

          opts.text




window.HawaiiHeader = (opts) ->

  homepage = fetch('location').url == '/'
  subdomain = fetch '/subdomain'

  return SPAN null if !subdomain.name 

  background_color = opts.background_color or customization('banner')?.background_css or DEFAULT_BACKGROUND_COLOR
  is_light = is_light_background(background_color)

  opts ||= {}
  _.defaults opts, 
    background_color: background_color
    background_image_url: opts.background_image_url or customization('banner')?.background_image_url
    logo: customization('banner')?.logo?.url
    logo_width: 200
    title: '<title is required>'
    subtitle: null
    title_style: {}
    subtitle_style: {}
    tab_style: {}
    homepage_button_style: {}

  _.defaults opts.title_style,
    fontSize: 47
    color: if is_light then 'black' else 'white'
    fontWeight: 300
    display: 'inline-block'

  _.defaults opts.subtitle_style,
    position: 'relative'
    fontSize: 22
    color: if is_light then 'black' else 'white'
    marginTop: 0
    opacity: .7
    textAlign: 'center'  

  _.defaults opts.homepage_button_style,
    display: 'inline-block'
    color: if is_light then 'black' else 'white'
    # opacity: .7
    position: 'absolute'
    left: -80
    fontSize: opts.title_style.fontSize
    #top: 38
    fontWeight: 400
    paddingLeft: 25 # Make the clickable target bigger
    paddingRight: 25 # Make the clickable target bigger
    cursor: if fetch('location').url != '/' then 'pointer'


  DIV
    style:
      position: 'relative'
      padding: "30px 0"
      backgroundPosition: 'center'
      backgroundSize: 'cover'
      backgroundImage: "url(#{opts.background_image_url})"
      backgroundColor: opts.background_color


    STYLE null,
      '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
         p {margin-bottom: 1em}'''

    DIV 
      style: 
        margin: 'auto'
        width: HOMEPAGE_WIDTH()
        position: 'relative'
        textAlign: if homepage then 'center'


      back_to_homepage_button opts.homepage_button_style

      if homepage && opts.logo
        IMG 
          alt: opts.logo_alternative_text
          src: opts.logo
          style: 
            width: opts.logo_width
            display: 'block'
            margin: 'auto'
            paddingTop: 20


      H1 
        style: opts.title_style
        opts.title 

      if homepage && opts.subtitle
        subtitle_is_html = opts.subtitle.indexOf('<') > -1 && opts.subtitle.indexOf('>') > -1
        DIV
          style: opts.subtitle_style
          
          dangerouslySetInnerHTML: if subtitle_is_html then {__html: opts.subtitle}

          if !subtitle_is_html
            opts.subtitle       

      if homepage
        DIV 
          style: 
            position: 'relative'
            margin: if get_tabs() then '62px auto 0 auto'
            width: HOMEPAGE_WIDTH()
            

          HomepageTabs
            tab_style: opts.tab_style
            tab_wrapper_style: _.defaults {}, opts.tab_wrapper_style or {},
              backgroundColor: opts.tab_background_color # '#005596'
              margin: '0 6px'
            active_style: _.defaults {}, opts.tab_active_style or {},
              backgroundColor: 'white'
              color: 'black'
            active_tab_wrapper_style: _.defaults {}, opts.active_tab_wrapper_style or {},
              backgroundColor: opts.tab_background_color
            hovering_tab_wrapper_style: _.defaults {}, opts.active_tab_wrapper_style or {},
              backgroundColor: opts.tab_background_color
            wrapper_style: _.defaults {}, opts.tabs_wrapper_style or {},
              marginTop: 80
              top: 0
            list_style: opts.tabs_list_style or {}



window.SeattleHeader = (opts) -> 

  homepage = fetch('location').url == '/'
  subdomain = fetch '/subdomain'

  return SPAN null if !subdomain.name 

  opts ||= {}
  _.defaults opts, 

    external_link: subdomain.external_project_url

    background_color: '#fff'
    background_image_url: customization('banner')?.background_image_url

    external_link_style: {}
    quote_style: {}
    paragraph_style: {}
    section_heading_style: {}


  paragraph_style = _.defaults opts.paragraph_style,
    fontSize: 18
    color: '#444'
    paddingTop: 10
    display: 'block'

  quote_style = _.defaults opts.quote_style,
    fontStyle: 'italic'
    margin: 'auto'
    padding: "40px 40px"
    fontSize: paragraph_style.fontSize
    color: paragraph_style.color 

  section_heading_style = _.defaults opts.section_heading_style,
    display: 'block'
    fontWeight: 400
    fontSize: 28
    color: 'black'

  external_link_style = _.defaults opts.external_link_style, 
    display: 'block'
    position: 'absolute'
    top: 22
    left: 20
    color: "#0B4D92"


  if !homepage
    return  DIV
              style: 
                backgroundColor: 'white'
              DIV
                style:
                  width: HOMEPAGE_WIDTH()
                  margin: 'auto'
                  fontSize: 43
                  padding: '10px 0' 

                A
                  href: '/' 

                  '< '

                  SPAN
                    style:
                      fontSize: 32
                      position: 'relative'
                      left: 5
                    'Homepage'


  DIV
    style:
      position: 'relative'

    if opts.external_link
      A 
        href: opts.external_link
        target: '_blank'
        style: opts.external_link_style

        I 
          className: 'fa fa-chevron-left'
          style: 
            display: 'inline-block'
            marginRight: 5

        opts.external_link_anchor or opts.external_link

    if opts.background_image_url
      IMG
        alt: opts.background_image_alternative_text
        style: _.defaults {}, opts.image_style,
          width: '100%'
          display: 'block'
        src: opts.background_image_url

    DIV 
      style: 
        padding: '20px 0'

      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          margin: 'auto'

        if opts.quote 
            
          DIV  
            style: quote_style
            "“#{opts.quote.what}”"

            if opts.quote.who 
              DIV  
                style:
                  paddingLeft: '70%'
                  paddingTop: 10
                "– #{opts.quote.who}"

        DIV null,

          for section, idx in opts.sections 

            DIV 
              style: 
                marginBottom: 20                


              if section.label 
                HEADING = if idx == 0 then H1 else DIV
                HEADING
                  style: _.defaults {}, (section.label_style or {}), section_heading_style
                  section.label 

              DIV null, 
                for paragraph in (section.paragraphs or [])
                  SPAN 
                    style: paragraph_style
                    dangerouslySetInnerHTML: { __html: paragraph }

        if opts.salutation 
          DIV 
            style: _.extend {}, paragraph_style,
              marginTop: 10

            if opts.salutation.text 
              DIV 
                style: 
                  marginBottom: 18
                opts.salutation.text 

            A 
              href: if opts.external_link then opts.external_link
              target: '_blank'
              style: 
                display: 'block'
                marginBottom: 8

              if opts.salutation.image 
                IMG
                  src: opts.salutation.image 
                  alt: ''
                  style: 
                    height: 70
              else
                opts.salutation.from 

            if opts.salutation.after 
              DIV 
                style: _.extend {}, paragraph_style,
                  margin: 0
                dangerouslySetInnerHTML: { __html: opts.salutation.after }
                
        if opts.login_callout
          AuthCallout()

        if opts.closed 
          DIV 
            style: 
              marginTop: 40
              backgroundColor: "#F06668"
              color: 'white'
              fontSize: 28
              textAlign: 'center'
              padding: "30px 42px"

            "The comment period is now closed. Thank you for your input!"


      if true
        active_style = _.defaults {}, opts.tab_active_style or {},
          opacity: 1,
          borderColor: named_colors.teal,
          backgroundColor: 'white'
        DIV
          style: 
            borderBottom: if get_tabs() then "1px solid " + active_style.borderColor

          DIV
            style:
              width: HOMEPAGE_WIDTH()
              margin: 'auto'

            HomepageTabs
              tab_style: _.defaults {}, opts.tab_style or {},
                padding: '10px 30px 0px 30px',
                color: named_colors.teal,
                border: '1px solid',
                borderBottom: 'none',
                borderColor: 'transparent',
                fontSize: 18,
                fontWeight: 700,
                opacity: 0.3
              hover_style:
                opacity: 1
              
              tab_wrapper_style: _.defaults {}, opts.tab_wrapper_style or {},
                backgroundColor: opts.tab_background_color # '#005596'
              active_style: active_style
              active_tab_wrapper_style: _.defaults {}, opts.active_tab_wrapper_style or {},
                backgroundColor: opts.tab_background_color
              hovering_tab_wrapper_style: _.defaults {}, opts.active_tab_wrapper_style or {},
                backgroundColor: opts.tab_background_color
              wrapper_style: _.defaults {}, opts.tabs_wrapper_style or {}
              list_style: opts.tabs_list_style or {}



