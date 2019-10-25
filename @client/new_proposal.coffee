
window.NewProposal = ReactiveComponent
  displayName: 'NewProposal'

  render : -> 
    cluster_name = @props.cluster_name or 'Proposals'
    cluster_key = "list/#{cluster_name}"

    cluster_state = fetch(@props.local)
    loc = fetch 'location'

    return SPAN null if cluster_name == 'Blocksize Survey'

    current_user = fetch '/current_user'

    if cluster_state.adding_new_proposal != cluster_name && \
       loc.query_params.new_proposal == encodeURIComponent(cluster_name)
      cluster_state.adding_new_proposal = cluster_name
      save cluster_state

    adding = cluster_state.adding_new_proposal == cluster_name 
    cluster_slug = slugify(cluster_name)

    permitted = permit('create proposal')
    needs_to_login = permitted == Permission.NOT_LOGGED_IN
    permitted = permitted > 0

    @local.category ||= cluster_name

    return SPAN null if !permitted && !needs_to_login

    proposal_fields = customization('new_proposal_fields', cluster_name)()

    label_style = 
      fontWeight: 400
      fontSize: 14
      display: 'block'

    if customization('show_proposer_icon', cluster_key) && adding 
      editor = current_user.user
      # Person's icon
      bullet = Avatar
        key: editor
        user: editor
        img_size: 'large'
        style:
          #position: 'absolute'
          #left: -18 - 50
          height: 50
          width: 50
          marginRight: 8
          borderRadius: 0
          backgroundColor: '#ddd'

    # else if !adding

    #   bullet =  SVG 
    #               viewBox: "0 0 5 5"
    #               width: 20
    #               style: 
    #                 marginRight: 7
    #                 verticalAlign: 'top'
    #                 paddingTop: 6

    #               PATH 
    #                 fill: '#000000'
    #                 d: "M2 1 h1 v1 h1 v1 h-1 v1 h-1 v-1 h-1 v-1 h1 z"
    else
      bullet =  SVG 
                  width: 8
                  viewBox: '0 0 200 200' 
                  style: 
                    marginRight: 7 + (if !adding then 6 else 0)
                    marginLeft: 6
                    verticalAlign: 'top'
                    paddingTop: 13
                  CIRCLE cx: 100, cy: 100, r: 80, fill: '#000000'


    if !adding 
      BUTTON  
        name: "add_new_#{cluster_name}"
        className: 'add_new_proposal'
        style: _.defaults (@props.label_style or {}),
          cursor: 'pointer'
          backgroundColor: '#e7e7e7'
          border: 'none'
          fontSize: 20
          fontWeight: 600
          padding: '6px 36px 6px 16px'
          textDecoration: 'underline'
          borderRadius: 8
          marginLeft: -44
        
        onClick: (e) => 
          loc.query_params.new_proposal = encodeURIComponent cluster_name
          save loc

          if permitted
            cluster_state.adding_new_proposal = cluster_name; save(cluster_state)
            setTimeout =>
              $("##{cluster_slug}-name").focus()
            , 0
          else 
            e.stopPropagation()
            reset_key 'auth', {form: 'login', goal: 'add a new proposal', ask_questions: true}
        
        A name: "new_#{cluster_name}"
        bullet 

        if permitted
          T("lists/add new button", 'add new')
        else 
          t("login_to_add_new")
    else 

      w = column_sizes().first
      
      DIV 
        style:
          position: 'relative'
          padding: '6px 8px'
          marginLeft: if customization('show_proposer_icon', cluster_key) then -76 else -36

        A name: "new_#{cluster_name}"

        if customization('new_proposal_tips', cluster_key)
          @drawTips customization('new_proposal_tips', cluster_key)

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
            htmlFor: "#{cluster_slug}-name"

            proposal_fields.name



          CharacterCountTextInput 
            id: "#{cluster_slug}-name"
            maxLength: 240
            name:'name'
            pattern: '^.{3,}'
            'aria-label': t('proposal_summary_instr')
            placeholder: t('proposal_summary_instr')
            required: 'required'

            count_style: 
              position: 'absolute'
              right: 0
              top: -18 
              fontSize: 14  

            style: 
              fontSize: 20
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
            marginLeft: if customization('show_proposer_icon', cluster_key) then 58 else 21


          # details 
          DIV null,

            LABEL 
              style: _.extend {}, label_style,
                marginLeft: 8

              htmlFor: "#{cluster_slug}-details"

              proposal_fields.description

            WysiwygEditor
              id: "#{cluster_slug}-details"
              key:"description-new-proposal-#{cluster_slug}"
              #placeholder: t('optional') #"Add #{t('details')} here"
              'aria-label': "Add #{t('details')} here"
              container_style: 
                padding: '6px 8px'
                border: '1px solid #ccc'

              style: 
                fontSize: 16
                width: w - 8 * 2
                marginBottom: 8
                minHeight: 120

          for additional_field in proposal_fields.additional_fields 
            # details 
            DIV null,

              LABEL 
                style: _.extend {}, label_style,
                  marginLeft: 8

                htmlFor: "#{cluster_slug}-#{additional_field}"

                proposal_fields[additional_field]

              WysiwygEditor
                id: "#{cluster_slug}-#{additional_field}"
                key:"#{additional_field}-new-proposal-#{cluster_slug}"
                'aria-label': proposal_fields[additional_field]
                container_style: 
                  padding: '6px 8px'
                  border: '1px solid #ccc'

                style: 
                  fontSize: 16
                  width: w - 8 * 2
                  marginBottom: 8
                  minHeight: 120


          # Category

          do =>
            available_clusters = (clust for clust in get_all_clusters() when current_user.is_admin || customization('list_show_new_button', "list/#{clust}"))

            if !current_user.is_admin && available_clusters.length <= 1
              INPUT
                type: 'hidden'
                value: cluster_name
                ref: 'category'

            else 
              DIV null,
                DIV 
                  style: 
                    marginTop: 8

                                  
                  LABEL               
                    style: _.extend {}, label_style,
                      marginLeft: 8


                    htmlFor: "#{cluster_slug}-category"

                    t('category')
                  
                  SELECT
                    id: "#{cluster_slug}-category"
                    style: 
                      fontSize: 18
                      width: w
                    value: @local.category
                    ref: 'category'
                    onChange: (e) =>
                      @local.category = e.target.value
                      save @local

                    [
                      if current_user.is_admin

                        [
                          OPTION 
                            style: 
                              fontStyle: 'italic'
                            value: 'new category'
                            'Create new category'

                          OPTION 
                            disabled: "disabled"
                            '--------'
                        ]

                      for clust in available_clusters
                        OPTION  
                          value: clust
                          clust

                    ]

                if current_user.is_admin && @local.category == 'new category'
                  INPUT 
                    type: 'text'
                    ref: 'new_category'
                    placeholder: 'category name'
                    style: 
                      fontSize: 16
                      padding: '4px 6px'
                      #marginLeft: 4
                      marginTop: 4
                      display: 'block'



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
              className: 'submit_new_proposal'
              style: 
                backgroundColor: focus_color()
                color: 'white'
                cursor: 'pointer'
                # borderRadius: 16
                padding: '4px 16px'
                display: 'inline-block'
                marginRight: 12
                border: 'none'
                boxShadow: '0 1px 1px rgba(0,0,0,.9)'
                fontWeight: 600
                # fontSize: 'inherit'

              onClick: => 
                name = $(@getDOMNode()).find("##{cluster_slug}-name").val()

                fields = 
                  description: fetch("description-new-proposal-#{cluster_slug}").html

                for field in proposal_fields.additional_fields
                  fields[field] = fetch("#{field}-new-proposal-#{cluster_slug}").html

                description = proposal_fields.create_description(fields)
                slug = slugify(name)
                active = true 
                hide_on_homepage = false
                category = @refs.category.getDOMNode().value
                if current_user.is_admin && @local.category == 'new category'
                  category = @refs.new_category.getDOMNode().value or cluster_name

                proposal =
                  key : '/new/proposal'
                  name : name
                  description : description
                  cluster : category
                  slug : slug
                  active: active
                  hide_on_homepage: hide_on_homepage

                InitializeProposalRoles(proposal)
                
                proposal.errors = []
                @local.errors = []
                save @local

                save proposal, => 
                  if proposal.errors?.length == 0
                    cluster_state.adding_new_proposal = null 
                    save cluster_state
                    delete loc.query_params.new_proposal
                    save loc                      
                  else
                    @local.errors = proposal.errors
                    save @local

              t('Done')

            BUTTON 
              style: 
                color: '#888'
                cursor: 'pointer'
                backgroundColor: 'transparent'
                border: 'none'
                padding: 0
                fontSize: 'inherit'                  
              onClick: => 
                cluster_state.adding_new_proposal = null; 
                save(cluster_state)
                delete loc.query_params.new_proposal
                save loc

              t('cancel')

  componentDidMount : ->    
    @ensureIsInViewPort()

  componentDidUpdate : -> 
    @ensureIsInViewPort()

  ensureIsInViewPort : -> 
    loc = fetch 'location'
    local = fetch @props.local

    is_selected = loc.query_params.new_proposal == encodeURIComponent((@props.cluster_name or 'Proposals'))

    if is_selected
      if browser.is_mobile
        $(@getDOMNode()).moveToTop {scroll: false}
      else
        $(@getDOMNode()).ensureInView {scroll: false}




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

