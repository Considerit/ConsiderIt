styles += """
  button.add_new_proposal {
    cursor: pointer;
    background-color: #{focus_blue};
    border: none;
    padding: 14px 36px 6px 9px;
    border-radius: 8px;
    margin-left: -9px;   
    color: white;
    text-decoration: none;
    display: flex;
  }

"""

window.NewProposal = ReactiveComponent
  displayName: 'NewProposal'

  render : -> 
    list_key = @props.list_key
    list_name = list_key.substring(5)

    list_state = fetch list_key
    loc = fetch 'location'

    current_user = fetch '/current_user'

    # if list_state.adding_new_proposal != list_key && \
    #    loc.query_params.new_proposal == list_key
    #   list_state.adding_new_proposal = list_key
    #   save list_state

    adding = list_state.adding_new_proposal == list_key && (!!@props.is_list_top == !!list_state.clicked_top)

    console.log 'adding', list_state.adding_new_proposal == list_key , !!@props.is_list_top == !!list_state.clicked_top
    if @props.combines_these_lists
      available_lists = (lst for lst in lists_current_user_can_add_to(@props.combines_these_lists) when lst != list_key)
      permitted = available_lists.length
    else 
      permitted = permit('create proposal', list_key)

    needs_to_login = permitted == Permission.NOT_LOGGED_IN
    permitted = permitted > 0


    return SPAN null if !permitted && !needs_to_login

    proposal_fields = customization('new_proposal_fields', list_key)()

    label_style = 
      fontWeight: 400
      fontSize: 14
      display: 'block'

    if customization('show_proposer_icon', list_key) && adding 
      editor = current_user.user
      # Person's icon
      bullet = Avatar
        key: editor
        user: editor
        img_size: 'large'
        style:
          height: 50
          width: 50
          marginRight: 8
          borderRadius: 0
          backgroundColor: '#ddd'

    else
      bullet =  SVG 
                  width: 8
                  viewBox: '0 0 200 200' 
                  style: 
                    marginRight: 7 + (if !adding then 6 else 0)
                    marginLeft: 6
                  CIRCLE cx: 100, cy: 100, r: 80, fill: '#000000'


    if !adding 
      BUTTON  
        name: "new_#{list_name}"
        className: 'add_new_proposal'

        
        onClick: (e) => 
          # loc.query_params.new_proposal = list_key
          # save loc
    
          if permitted
            list_state.adding_new_proposal = list_key; save(list_state)
            # setTimeout =>
            #   $("##{list_name}-name").focus()
            # , 0
          else 
            e.stopPropagation()
            reset_key 'auth', 
              form: 'create account'
              goal: 'Introduce yourself to share a response'
        
        # A name: "new_#{list_name}"
        SVG
          width: 30 
          height: 30
          style: 
            marginRight: 23
            marginLeft: 6
          fill: 'white'
          viewBox: "0 0 700 700" 

          dangerouslySetInnerHTML: __html: """
             <g>
              <path d="m350 28c-66.836 0-130.93 26.551-178.19 73.809-47.258 47.258-73.809 111.36-73.809 178.19s26.551 130.93 73.809 178.19c47.258 47.258 111.36 73.809 178.19 73.809s130.93-26.551 178.19-73.809c47.258-47.258 73.809-111.36 73.809-178.19 0-44.234-11.645-87.691-33.762-126-22.117-38.309-53.93-70.121-92.238-92.238-38.309-22.117-81.766-33.762-126-33.762zm0 470.4c-57.922 0-113.47-23.008-154.43-63.965-40.957-40.961-63.965-96.512-63.965-154.43s23.008-113.47 63.965-154.43c40.961-40.957 96.512-63.965 154.43-63.965s113.47 23.008 154.43 63.965c40.957 40.961 63.965 96.512 63.965 154.43s-23.008 113.47-63.965 154.43c-40.961 40.957-96.512 63.965-154.43 63.965z"/>
              <path d="m456.4 257.6h-84v-84h-44.797v84h-84v44.797h84v84h44.797v-84h84z"/>
             </g>
          """




        if permitted
          translator "engage.add_new_proposal_to_list", 'Add new response'
        else 
          translator "engage.login_to_add_new_proposal", 'Create an account to share a response'

    else 

      w = column_sizes().first
      
      DIV 
        style:
          position: 'relative'
          padding: '6px 8px'
          marginLeft: if customization('show_proposer_icon', list_key) then -76 + 68 else -36 + 68

        # A name: "new_#{list_name}"

        if customization('new_proposal_tips', list_key)
          @drawTips customization('new_proposal_tips', list_key)

        bullet

        DIV 
          style: 
            position: 'relative'
            display: 'inline-block'

          LABEL 
            style: _.extend {}, label_style, 
              position: 'absolute'
              left: 8
              top: -18
            htmlFor: "#{list_name}-name"

            proposal_fields.name



          CharacterCountTextInput 
            id: "#{list_name}-name-#{!!@props.is_list_top}"
            maxLength: 240
            name:'name'
            pattern: '^.{3,}'
            'aria-label': translator("engage.edit_proposal.summary.placeholder", 'Clear and concise summary')
            placeholder: translator("engage.edit_proposal.summary.placeholder", 'Clear and concise summary')
            required: 'required'
            focus_on_mount: !!@props.is_list_top == !!list_state.clicked_top

            count_style: 
              position: 'absolute'
              right: 0
              top: -18 
              fontSize: 14  

            style: 
              fontSize: if browser.is_mobile then 36 else 20
              width: w
              border: "1px solid #ccc"
              outline: 'none'
              padding: '6px 8px'
              fontWeight: 600
              #textDecoration: 'underline'
              #borderBottom: "1px solid #444"  
              color: '#000'
              minHeight: 75        
              resize: 'vertical'    

        DIV 
          style: 
            position: 'relative'
            marginLeft: if customization('show_proposer_icon', list_key) then 58 else 21


          # details 
          DIV null,

            LABEL 
              style: _.extend {}, label_style,
                marginLeft: 8

              htmlFor: "#{list_name}-details"

              proposal_fields.description

            WysiwygEditor
              id: "#{list_name}-details"
              key:"description-new-proposal-#{list_name}"
              #placeholder: translator("engage.edit_proposal.description.placeholder", 'Add details here')  
              'aria-label': translator("engage.edit_proposal.description.placeholder", 'Add details here')  
              container_style: 
                padding: '6px 8px'
                border: '1px solid #ccc'

              style: 
                fontSize: if browser.is_mobile then 36 else 16
                width: w - 8 * 2
                marginBottom: 8
                minHeight: 120

          for additional_field in proposal_fields.additional_fields 
            # details 
            DIV null,

              LABEL 
                style: _.extend {}, label_style,
                  marginLeft: 8

                htmlFor: "#{list_name}-#{additional_field}"

                proposal_fields[additional_field]

              WysiwygEditor
                id: "#{list_name}-#{additional_field}"
                key:"#{additional_field}-new-proposal-#{list_name}"
                'aria-label': proposal_fields[additional_field]
                container_style: 
                  padding: '6px 8px'
                  border: '1px solid #ccc'

                style: 
                  fontSize: 16
                  width: w - 8 * 2
                  marginBottom: 8
                  minHeight: 120

          if @props.combines_these_lists && available_lists.length > 0 
            DIV
              style: 
                marginTop: 12

              LABEL 
                htmlFor: 'category'
                translator('category')
              

              SELECT
                ref: 'category'
                id: "category"
                name: "category"
                style: 
                  fontSize: 18
                  display: 'block'
                defaultValue: available_lists[0]

                for list_key in available_lists
                  OPTION  
                    value: list_key
                    get_list_title(list_key, true)


          if @local.errors?.length > 0
            
            DIV
              role: 'alert'
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
              marginTop: 14

            BUTTON 
              className: 'btn'
              style: 
                backgroundColor: focus_color()

              onClick: => 
                name = document.getElementById("#{list_name}-name-#{!!@props.is_list_top}").value

                fields = 
                  description: fetch("description-new-proposal-#{list_name}").html

                for field in proposal_fields.additional_fields
                  fields[field] = fetch("#{field}-new-proposal-#{list_name}").html

                description = proposal_fields.create_description(fields)
                active = true 
                hide_on_homepage = false

                if @props.combines_these_lists && @refs.category
                  category = @refs.category.getDOMNode().value
                else 
                  category = list_key 
                category = category.substring(5)

                proposal =
                  key : '/new/proposal'
                  name : name
                  description : description
                  cluster : category
                  active: active
                  hide_on_homepage: hide_on_homepage

                InitializeProposalRoles(proposal)
                
                proposal.errors = []
                @local.errors = []
                save @local

                save proposal, => 
                  if proposal.errors?.length == 0
                    list_state.adding_new_proposal = null
                    list_state.clicked_top = null 
                    save list_state

                    if @props.is_list_top
                      set_sort_order('Date: Most recent first')
                    else 
                      set_sort_order('Date: Earliest first')

                    show_flash("Your response has been added")

                    ensure_in_viewport_when_appears("[data-name=\"#{slugify(proposal.name)}\"]")
                      


                    # delete loc.query_params.new_proposal
                    # save loc                      
                  else
                    @local.errors = proposal.errors
                    save @local

              translator 'engage.done_button', 'Done'

            BUTTON 
              className: 'like_link'
              style: 
                color: '#777'
                position: 'relative'
                top: 2
                marginLeft: 12
              onClick: => 
                list_state.adding_new_proposal = null
                list_state.clicked_top = null             
                save(list_state)
                # delete loc.query_params.new_proposal
                # save loc

              translator 'shared.cancel_button', 'cancel'




  drawTips : (tips) -> 
    # guidelines/tips for good points
    mobile = browser.is_mobile
    return SPAN null if mobile

    guidelines_w = if mobile then 'auto' else 330
    guidelines_h = 300

    DIV 
      style:
        position: if mobile then 'relative' else 'absolute'
        right: -guidelines_w - 20
        width: guidelines_w
        color: focus_color()
        zIndex: 1
        marginBottom: if mobile then 20
        backgroundColor: if mobile then 'rgba(255,255,255,.85)'
        fontSize: 14


      if !mobile
        SVG
          width: guidelines_w + 28
          height: guidelines_h
          viewBox: "-4 0 #{guidelines_w+20 + 9} #{guidelines_h}"
          style: css.crossbrowserify
            position: 'absolute'
            transform: 'scaleX(-1)'
            left: -20

          PATH
            stroke: focus_color() #'#ccc'
            strokeWidth: 1
            fill: "#FFF"

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
            fontSize: 24
          "Tips"

        UL 
          style: 
            listStylePosition: 'outside'
            marginLeft: 16
            marginTop: 5

          do ->
            tips = customization('new_proposal_tips')

            for tip in tips
              LI 
                style: 
                  paddingBottom: 3
                  fontSize: if PORTRAIT_MOBILE() then 24 else if LANDSCAPE_MOBILE() then 14
                tip  

