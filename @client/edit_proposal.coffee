window.EditProposal = ReactiveComponent
  displayName: 'EditProposal'

  render : ->
    user = fetch('/current_user')
    proposal = @data()
    subdomain = fetch '/subdomain'

    # defaultValue for React forms conflicts with statebus's method of 
    # just rerunning until things work. Namely, the default value
    # that is set before the proposal is loaded entirely sticks
    # even after the proposal is fully loaded from the server.
    # This code works around that problem by simply exiting the 
    # render if the proposal isn't loaded already. 
    if !@props.fresh && !proposal.id
      return SPAN null

    default_group = if subdomain.name == 'bitcoinfoundation'
                      'Our Actions'
                    else
                      null
    
    # check permissions
    permitted = if @props.fresh  
                  permit('create proposal')
                else
                  permit('update proposal', proposal)

    if permitted < 0
      recourse permitted, 'create a proposal'
      return DIV null

    block_style = 
      width: CONTENT_WIDTH()
      padding: '2px 0px'
      marginBottom: 12
      position: 'relative'

    description_field_style =
      fontSize: 18
      width: CONTENT_WIDTH()
      padding: 12
      marginBottom: 8
      border: '1px solid #ccc'

    input_style = _.extend {}, description_field_style, 
      display: 'block'

    label_style =
      fontSize: 24
      fontWeight: 600
      width: 240
      display: 'inline-block'
      color: focus_blue
      marginBottom: 3

    operation_style = 
      color: '#aaa'
      textDecoration: 'underline'
      fontSize: 14
      cursor: 'pointer'
      display: 'block'      




    if !@local.description_fields && (@props.fresh || @data().slug)
      @local.description_fields = if @data().description_fields 
                                    $.parseJSON(@data().description_fields) || [] 
                                  else 
                                    []
      @local.open_fields = []

      if @local.description_fields.length > 0
        if @local.description_fields[0].group
          # Right now, we just downgrade group syntax to flat description list syntax
          # TODO: when editing a proposal, support the proposal description groups 
          # syntax (or get rid of it)
          @local.description_fields = _.flatten \
                                         @local.description_fields.map \
                                            (group) -> group.items

        # Add unique identifiers to each field so we can hide/edit them
        for field,idx in @local.description_fields
          field.id = idx

      save @local

    toggleDescriptionFieldOpen = (field, field_open) =>
      if field_open
        @local.open_fields = _.without @local.open_fields, field.id
      else
        @local.open_fields.push field.id
      save @local

    DIV null, 
      DIV 
        style: 
          width: CONTENT_WIDTH()
          margin: 'auto'
          padding: '3em 0'
          position: 'relative'

        DIV 
          style: 
            fontSize: 28
            marginBottom: 20

          DIV
            style: 
              fontSize: 30
              fontWeight: 700
            if @props.fresh then t('create_new_proposal') else "#{capitalize(t('edit'))} '#{proposal.name}'"

          DIV 
            style: 
              fontSize: 18

            t('make_it') + ' ' 
            SPAN 
              style: 
                fontWeight: 600
              t("unambiguous")
            ' ' + t('and') + ' '
            SPAN 
              style: 
                fontWeight: 600
              t('error_free')
            '.'

        DIV style: block_style,
          LABEL htmlFor:'slug', style: label_style, 'URL:'

          BR null
          SPAN
            style: 
              fontSize: 20
              color: '#aaa'
            "#{location.origin}/"
          INPUT 
            id:'slug'
            name:'slug'
            pattern:'^.{3,}'
            placeholder: t('url_instr')
            required:'required'
            defaultValue: if @props.fresh then null else proposal.slug
            style: _.extend {}, input_style,
              width: 400
              display: 'inline-block'

        DIV style: block_style,
          LABEL htmlFor:'name', style: label_style, t('Summary') + ':'
          INPUT 
            id:'name'
            name:'name'
            pattern:'^.{3,}'
            placeholder: t('proposal_summary_instr')
            required:'required'
            defaultValue: if @props.fresh then null else proposal.name
            style: input_style

        DIV style: block_style,
          LABEL htmlFor:'description', style: label_style, t('details') + ':'
          
          WysiwygEditor
            key:"description-#{proposal.key}"
            style: input_style
            html: if @props.fresh then null else proposal.description

          # Expandable description fields

          DIV 
            style: 
              marginBottom: 20
              marginLeft: 45
              display: if not fetch('/current_user').is_admin then 'none'

            for field in @local.description_fields
              field_open = field.id in @local.open_fields
              DIV 
                key: "field-#{field.id}"
                style: _.extend({}, block_style, {width: ''}),

                I 
                  className: "fa fa-#{if field_open then 'minus' else 'plus'}-circle"
                  style: 
                    position: 'absolute'
                    left: -20
                    top: 18
                    color: '#414141'
                    cursor: 'pointer'
                  onClick: do (field, field_open) => => 
                    toggleDescriptionFieldOpen(field, field_open)

                if field_open
                  [INPUT
                    style: _.extend {}, description_field_style, \
                                    {width: description_field_style.width - 45}
                    type: 'text'
                    id:"field-#{field.id}-label"
                    name:"field-#{field.id}-label"
                    pattern:'^.{3,}'
                    placeholder:t('Label')
                    required:'required'
                    onChange: do(field) => (e) => 
                      field.label = e.target.value; save(@local)
                    value: field.label

                  WysiwygEditor
                    key:"field-#{field.id}-html-#{if @props.fresh then '/new/proposal' else proposal.key}"
                    name:"field-#{field.id}-html"
                    placeholder: t('expandable_body_instr')
                    style: _.extend {}, description_field_style,
                              width: description_field_style.width - 45
                    html: field.html]

                else
                  DIV 
                    style: 
                      fontSize: 18
                      fontWeight: 600
                      cursor: 'pointer'
                      marginTop: 12
                      marginLeft: 5
                      width: description_field_style.width - 45
                    onClick: do (field, field_open) => => 
                      toggleDescriptionFieldOpen(field, field_open)
                    field.label

                DIV 
                  style: 
                    position: 'absolute'
                    right: 150
                    top: 12

                  A
                    style: operation_style
                    onClick: do (field, field_open) => => 
                      toggleDescriptionFieldOpen(field, field_open)
                    if field_open then t('close') else t('edit')

                  A
                    style: operation_style
                    onClick: do (field) => =>
                      @local.description_fields = \
                        _.filter @local.description_fields, \
                                 (fld) -> fld.id != field.id
                      save @local
                    t('delete')

            SPAN
              style: 
                color: '#aaa'
                cursor: 'pointer'
                fontSize: 18
                marginLeft: -18

              onClick: => 
                new_id = 0
                for field in @local.description_fields
                  new_id += field.id  
                new_id += 1
                @local.description_fields.push {label: null, html: null, id: new_id}
                @local.open_fields.push new_id
                save @local

              "+ "
              SPAN 
                style: 
                  textDecoration: 'underline'
                  marginLeft: 7
                t('add_expandable')


        DIV
          style: block_style

          if user.is_admin

            [LABEL htmlFor:'cluster', style: label_style, t('category') + ' (' + t('optional') + '):'
            INPUT 
              id: 'cluster'
              name: 'cluster'
              pattern: '^.{3,}'
              placeholder: 'The proposal will be shown on the homepage under this category. (Default="Proposals")'
              defaultValue: if @props.fresh then default_group else proposal.cluster
              style: input_style
            ]
          else  
            clusters = fetch('/proposals').clusters
            groups = (c.name for c in clusters \
                     when !!c.name && !customization("archived", "cluster/#{c.name}"))

            [LABEL 
              htmlFor:'cluster'
              style: _.extend {}, label_style,
                width: 130
              t('Category') + ':'

            SELECT
              id: 'cluster'
              name: 'cluster'
              style: 
                fontSize: 30
              defaultValue: if @props.fresh then null else proposal.cluster
              for group,i in groups
                OPTION key: i, value: group, group
            ]

        DIV 
          style: _.extend {}, block_style,
            display: if !user.is_admin then 'none'

          LABEL htmlFor: 'listed_on_homepage', style: label_style, t('show_on_homepage')

          INPUT 
            id: 'listed_on_homepage'
            name: 'listed_on_homepage'
            type: 'checkbox'
            defaultChecked: if @props.fresh then true else !proposal.hide_on_homepage
            style: 
              fontSize: 24

        DIV
          style: _.extend {}, block_style,
            display: if !user.is_admin then 'none'

          LABEL 
            htmlFor: 'open_for_discussion'
            style: label_style
            t('open_for_discussion')

          INPUT 
            id: 'open_for_discussion'
            name: 'open_for_discussion'
            type: 'checkbox'
            defaultChecked: if @props.fresh then true else proposal.active
            style: {fontSize: 24}
          

        DIV 
          style: 
            display: if !user.is_admin then 'none'

          SPAN 
            style: _.extend {}, label_style,
              textDecoration: 'underline'
              cursor: 'pointer'
              width: 400
              position: 'relative'
            onClick: => 
              @local.edit_roles = !@local.edit_roles
              save @local
            I 
              className: 'fa-child fa'
              style: 
                position: 'absolute'
                left: -25
                top: 5

            t('permissions_and_invites')

          DIV 
            style: 
              width: CONTENT_WIDTH()
              backgroundColor: '#fafafa'
              padding: '10px 60px'
              display: if @local.edit_roles then 'block' else 'none' 
                  # roles has to be rendered so that default roles 
                  # are set on the proposal

            ProposalRoles 
              key: if @props.fresh then @local.key else proposal.key


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


        DIV null,
          INPUT 
            className:'button primary_button'
            type:'submit'
            style: 
              width: 400
              marginTop: 35
            value:"#{if @props.fresh then t('Publish') else t('Update')}"
            onClick: @saveProposal

          A 
            
            type:'submit'
            style: 
              marginTop: 10
              padding: 25
              marginLeft: 10
              fontSize: 22

            onClick: =>
              if @props.fresh 
                loadPage "/"
              else 
                loadPage "/#{proposal.slug}"

            t('cancel')

  saveProposal : -> 

    $el = $(@getDOMNode())

    name = $el.find('#name').val()
    description = fetch("description-#{@data().key}").html
    slug = $el.find('#slug').val()
    cluster = $el.find('#cluster').val()
    cluster = null if cluster == ""

    active = $el.find('#open_for_discussion:checked').length > 0
    hide_on_homepage = $el.find('#listed_on_homepage:checked').length == 0

    if @props.fresh
      proposal =
        key : '/new/proposal'
        name : name
        description : description
        cluster : cluster
        slug : slug
        active: active
        hide_on_homepage: hide_on_homepage

    else 
      proposal = @data()
      _.extend proposal, 
        cluster: cluster
        name: name
        slug: slug
        description: description
        active: active
        hide_on_homepage: hide_on_homepage

    if @local.roles
      proposal.roles = @local.roles
      proposal.invitations = @local.invitations

    if @local.description_fields
      for field in @local.description_fields
        edited_html = fetch("field-#{field.id}-html-#{proposal.key}")
        field.html = edited_html.html if edited_html.html
      proposal.description_fields = JSON.stringify(@local.description_fields)

    proposal.errors = []
    @local.errors = []
    save @local

    save proposal, => 
      if proposal.errors?.length == 0
        window.scrollTo(0,0)
        loadPage "/#{slug}"
      else
        @local.errors = proposal.errors
        save @local