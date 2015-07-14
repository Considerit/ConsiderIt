##
# EditPoint
# Form for editing or creating a point. Used by NewPoint component & when someone
# edits their point. 
window.EditPoint = ReactiveComponent
  displayName: 'EditPoint'

  render : ->
    @local = @data @local_key,
      sign_name : if @props.fresh then true else !@data().hide_name
      add_details : false

    mobile = browser.is_mobile

    if mobile
      textarea_style = 
        width: '100%'
        overflow: 'hidden'
        fontSize: if PORTRAIT_MOBILE() then 50 else 30
        padding: '4px 6px'

      # full page mode if we're on mobile      
      parent = $("#proposal-#{@proposal.id}")
      parent_offset = if parent.length > 0 then parent.offset().top else 0
      style = 
        position: 'absolute'
        top: 0
        left: 50
        height: '100%'
        width: WINDOW_WIDTH() - 100
        backgroundColor: 'rgba(255,255,255,.85)'
        fontSize: 20
        zIndex: 99999999
        padding: "#{@scrollY - parent_offset}px 50px 100px 50px"

    else 
      textarea_style = 
        width: if mobile then '75%' else '100%'
        overflow: 'hidden'
        fontSize: if mobile then 30 else 14
        padding: '4px 6px'

      style = 
        position: 'relative'
        fontSize: 14
        zIndex: 1
        marginTop: if TWO_COL() then 40
        marginBottom: 15


    DIV
      className: 'edit_point'
      style: style

      DIV
        style: 
          position: 'relative'

        @drawTips()


        CharacterCountTextInput 
          id: 'nutshell'
          maxLength: 180
          name: 'nutshell'
          pattern: '^.{3,}'
          placeholder: 'A succinct summary of your point.'
          required: 'required'
          defaultValue: if @props.fresh then null else @data().nutshell
          style: _.extend {}, textarea_style,
            minHeight: 75
          count_style: 
            position: 'absolute'
            right: 0
            top: -21   

        INPUT 
          id:'is_pro'
          name: 'is_pro'
          type: 'hidden'
          value: "#{@props.valence == 'pros'}"

      
      DIV null,
          
        AutoGrowTextArea 
          id:'text'
          name:'text'
          placeholder:'Add background or evidence.'
          min_height: if PORTRAIT_MOBILE() then 150 else 100
          defaultValue: if @props.fresh then null else @data().text
          style: textarea_style
          onHeightChange: => 
            s = fetch('reasons_height_adjustment')
            s.edit_point_height = $(@getDOMNode()).height()            
            save s

      if @local.errors?.length > 0
        
        DIV
          style:
            fontSize: 18
            color: 'darkred'
            backgroundColor: '#ffD8D8'
            padding: 10
            marginTop: 10
          for error in @local.errors
            DIV null, 
              I
                className: 'fa fa-exclamation-circle'
                style: {paddingRight: 9}

              SPAN null, error

      DIV 
        style: 
          marginTop: 3
          marginBottom: '.5em'

        if !@proposal.active
          DIV 
            style: {color: '#777', fontSize: 12}
            'New points disabled for this proposal'
        else
          DIV 
            className: 'primary_button'
            'data-action': 'submit-point'
            onClick: @savePoint
            style: 
              marginTop: 0
              display: 'inline-block'
              fontSize: if PORTRAIT_MOBILE() then 50 else if LANDSCAPE_MOBILE() then 36 else 24
              padding: '4px 35px'
              float: 'left'
            'Done'

        A 
          onTouchEnd: @done
          onClick: @done
          style:
            display: 'inline-block'
            color: '#888888'
            cursor: 'pointer'
            zIndex: 1
            top: if mobile then 0 else 12
            fontSize: if PORTRAIT_MOBILE() then 50 else if LANDSCAPE_MOBILE() then 36 else 16
            right: if mobile then -10 else 20
            position: 'relative'
            float: if mobile then 'left' else 'right'
            padding: if mobile then 10
          'cancel'  

        DIV 
          style: 
            clear: 'both'

      if @proposal.active
        DIV 
          style: 
            position: 'relative'

          INPUT
            className: 'newpoint-anonymous'
            type:      'checkbox'
            id:        "sign_name-#{@props.valence}"
            name:      "sign_name-#{@props.valence}"
            checked:   @local.sign_name
            onChange: =>
              @local.sign_name = !@local.sign_name
              save(@local)
          LABEL 
            htmlFor: "sign_name-#{@props.valence}"
            title:'Signing your name lends your point more weight with peers.'
            'Sign your name'

  componentWillMount : ->
    # save scroll position and keep it there
    if browser.is_mobile
      @scrollY = window.scrollY

  componentDidMount : ->
    if @proposal.active 
      $el = $(@getDOMNode())
      $el.find('#nutshell').focus() if !browser.is_mobile # iOS messes this up
      $el.find('[data-action="submit-point"]').ensureInView {scroll: false, position: 'bottom'}

  componentWillUnmount : -> 
    s = fetch('reasons_height_adjustment')
    s.edit_point_height = 0       
    save s    

  drawTips : -> 
    # guidelines/tips for good points
    mobile = browser.is_mobile

    guidelines_w = if mobile then 'auto' else 230
    guidelines_h = 238

    singular =  if @props.valence == 'pros' 
                  customization('point_labels.pro', @proposal)
                else 
                  customization('point_labels.con', @proposal)

    plural =  if @props.valence == 'pros' 
                customization('point_labels.pros', @proposal)
              else 
                customization('point_labels.cons', @proposal)


    DIV 
      style:
        position: if mobile then 'relative' else 'absolute'
        left: if !mobile then (if @props.valence == 'pros' then -guidelines_w - 25 else POINT_CONTENT_WIDTH() + 15)
        width: guidelines_w
        color: focus_blue
        zIndex: 1
        marginBottom: if mobile then 20
        backgroundColor: if mobile then 'rgba(255,255,255,.85)'


      if !mobile
        SVG
          width: guidelines_w + 28
          height: guidelines_h
          viewBox: "-4 0 #{guidelines_w+20 + 9} #{guidelines_h}"
          style: css.crossbrowserify
            position: 'absolute'
            transform: if @props.valence == 'cons' then 'scaleX(-1)'
            left: if @props.valence == 'cons' then -20

          DEFS null,
            svg.dropShadow 
              id: "guidelines-shadow"
              dx: '0'
              dy: '2'
              stdDeviation: "3"
              opacity: .5

          PATH
            stroke: focus_blue #'#ccc'
            strokeWidth: 1
            fill: "#FFF"
            filter: 'url(#guidelines-shadow)'

            d: """
                M#{guidelines_w},33
                L#{guidelines_w},0
                L1,0
                L1,#{guidelines_h} 
                L#{guidelines_w},#{guidelines_h} 
                L#{guidelines_w},58
                L#{guidelines_w + 20},48
                L#{guidelines_w},33 
                Z
               """
      DIV 
        style: 
          padding: if !mobile then '14px 18px'
          position: 'relative'
          marginLeft: 5

        SPAN 
          style: 
            fontWeight: 600
            fontSize: if PORTRAIT_MOBILE() then 70 else if LANDSCAPE_MOBILE() then 36
          "Write a "
          capitalize singular
          ' (or question) for this proposal'

        UL 
          style: 
            listStylePosition: 'outside'
            marginLeft: 16
            marginTop: 5

          do ->
            tips = ["Make one coherent point. Add multiple #{capitalize(plural)} if you have more.",
                    "Be direct. The summary is your main point.",
                    "Review your language. Don’t be careless.",
                    "No personal attacks."
                   ]

            for tip in tips
              LI 
                style: 
                  paddingBottom: 3
                  fontSize: if PORTRAIT_MOBILE() then 24 else if LANDSCAPE_MOBILE() then 14
                tip  

  done : ->
    your_points = fetch @props.your_points_key

    if @props.fresh
      your_points.adding_new_point = false
    else
      your_points.editing_points = _.without your_points.editing_points, @props.key

    save your_points

  savePoint : (ev) ->
    $form = $(@getDOMNode())

    nutshell = $form.find('#nutshell').val()
    text = $form.find('#text').val()
    hide_name = !$form.find("#sign_name-#{@props.valence}").is(':checked')

    if !@props.fresh
      # If we're updating an existing point, we just have to update
      # some of the fields from the form
      point = @data()
      point.nutshell = nutshell
      point.text = text
      point.hide_name = hide_name
    else
      current_user = fetch('/current_user').user
      point =
        key : '/new/point'
        is_pro : @props.valence == 'pros'
        user : current_user
        comment_count : 0
        includers : [current_user]
        proposal : @proposal.key
        nutshell : nutshell
        text : text
        hide_name : hide_name

    point.errors = []
    save point, => 
      if point.errors?.length == 0
        @done()
      else
        @local.errors = point.errors
        save @local

    # # This is a kludge cause activerest sucks for pre-rendering
    # # changes before the server returns them
    # fetch(@proposal.your_opinion).point_inclusions.push(point.key)
    # re_render([@proposal.your_opinion])

