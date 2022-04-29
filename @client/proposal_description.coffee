
##
# ProposalDescription
#
window.ProposalDescription = ReactiveComponent
  displayName: 'ProposalDescription'

  render : ->    
    current_user = fetch('/current_user')
    subdomain = fetch '/subdomain'
    proposal = fetch (@props.proposal or @proposal)

    @max_description_height = customization('collapse_proposal_description_at', proposal)

    editor = proposal_editor(proposal)


    title = proposal.name 
    body = proposal.description 

    title_style = _.defaults {}, customization('list_title_style'),
      fontSize: 32
      fontWeight: 700
      textAlign: if title.length < 45 then 'center'
      marginBottom: 24

    body_style = 
      padding: '1em 0px'
      position: 'relative'
      maxHeight: if @local.description_collapsed then @max_description_height
      overflow: if @local.description_collapsed then 'hidden'

    wrapper_style = {}
    if proposal.banner
      wrapper_style = 
        background: "url(#{proposal.banner}) no-repeat center top fixed"
        backgroundSize: 'cover'
        paddingTop: 240
    else 
      wrapper_style = 
        paddingTop: 24
        #backgroundColor: '#ffffff'
        # opacity: 0.2
        #backgroundImage:  "radial-gradient(circle at center center, #fafafa, #ffffff), repeating-radial-gradient(circle at center center, #fafafa, #fafafa, 8px, transparent 16px, transparent 8px)"
        paddingBottom: 16
        #backgroundBlendMode: "multiply"
        # background: "linear-gradient(0deg, rgb(255, 255, 255), rgb(236, 236, 236), rgb(255, 255, 255))"

    anonymized = !customization('show_proposer_icon', "list/#{proposal.cluster}") || customization('anonymize_everything')
    show_proposal_meta_data = customization('show_proposal_meta_data')


    list_key = "list/#{proposal.cluster or 'proposals'}"
    list = get_list_title list_key, true, subdomain

    other_proposals = get_proposals_in_list(list_key)


    if other_proposals?.length > 1
      curr_pos_in_list = null
      for pr, idx in other_proposals
        if pr.key == proposal.key
          curr_pos_in_list = idx 
          break

      prev_proposal = curr_pos_in_list - 1
      if prev_proposal < 0
        prev_proposal = other_proposals.length - 1
      next_proposal = curr_pos_in_list + 1 
      if next_proposal > other_proposals.length - 1
        next_proposal = 0






    DIV 
      style: wrapper_style

      DIV 
        style: 
          textAlign: 'center'
          #color: "#666"
          margin: "0 auto 8px auto"
          width: HOMEPAGE_WIDTH()


        SPAN 
          style:  
            position: 'relative'


          list or 'proposals'

          if other_proposals.length > 1

            A
              style: 
                textDecoration: 'none'
                position: 'absolute'
                left: -70
              href: "/#{other_proposals[prev_proposal].slug}?results=true"
              ChevronLeft(24)

          if other_proposals.length > 1

            A
              style: 
                textDecoration: 'none'
                position: 'absolute'
                right: -70
              href: "/#{other_proposals[next_proposal].slug}?results=true"
              ChevronRight(24)

      DIV           
        style: 
          width: HOMEPAGE_WIDTH()
          position: 'relative'
          margin: 'auto'
          padding: "24px 36px 12px 36px"
          marginBottom: 18 
          backgroundColor: considerit_gray #'white'
          boxShadow: "0 8px 6px -2px rgb(0 0 0 / 15%)" #"0 1px 3px rgba(0,0,0,.3)"
          borderRadius: 8

        if proposal.pic && !show_proposal_meta_data
          IMG 
            style:
              position: 'absolute'
              width: 124
              height: 124
              left: -28 - 124
              top: 'auto'
            src: proposal.pic

          
        DIV 
          style: 
            wordWrap: 'break-word'

          DIV 
            style: _.defaults {}, (title_style or {}),
              fontSize: POINT_FONT_SIZE()
              lineHeight: 1.2

            className: 'statement'

            title

          DIV null,
            if show_proposal_meta_data
              DIV 
                style: 
                  margin: "8px 0 18px 0"
                  fontSize: 14
                  color: "black"
                  textAlign: 'center'
                  display: 'flex'
                  justifyContent: 'center'
                  alignItems: 'center'

                if proposal.pic || !anonymized

                  DIV 
                    style: 
                      marginRight: 12

                    if proposal.pic 
                      IMG 
                        style:
                          width: 60
                          height: 60
                        src: proposal.pic
                    else if !anonymized
                      Avatar
                        key: if !proposal.pic && !customization('anonymize_everything') then editor 
                        style:
                          width: 60
                          height: 60
                        hide_popover: false 


                DIV null,
                  DIV 
                    style: 
                      fontWeight: '600'

                    if !customization('anonymize_everything')                
                      fetch(editor)?.name
                    else
                      translator('anonymous', 'Anonymous')

                  if !screencasting()
                    DIV 
                      style: 
                        color: '#666'

                      prettyDate(proposal.created_at)

                # TRANSLATE 
                #   id: "engage.proposal_meta_data"
                #   timestamp: prettyDate(proposal.created_at)
                #   author: fetch(editor)?.name
                #   "submitted {timestamp} by {author}"

            if proposal.under_review 
              DIV 
                style: 
                  color: 'white'
                  backgroundColor: 'orange'
                  fontSize: 14
                  padding: 2
                  marginTop: 8
                  display: 'inline-block'

                TRANSLATE 
                  id: 'engage.proposal_in_moderation_notice'
                  'Under review (like all new proposals)'


          DIV 
            className: 'wysiwyg_text'
            style:
              maxHeight: if @local.description_collapsed then @max_description_height
              overflowY: if @local.description_collapsed then 'hidden'

            if body 

              DIV 
                className: "statement"

                style: _.defaults {}, (body_style or {}),
                  wordWrap: 'break-word'
                  marginTop: '0.5em'
                  #fontWeight: 300

                if cust_desc = customization('proposal_description')
                  if typeof(cust_desc) == 'function'
                    cust_desc(proposal)
                  else if cust_desc[proposal.cluster] # is associative, indexed by list name


                    result = cust_desc[proposal.cluster] {proposal: proposal} # assumes ReactiveComponent. No good reason for the assumption.

                    if typeof(result) == 'function' && /^function \(props, children\)/.test(Function.prototype.toString.call(result))  
                                     # if this is a ReactiveComponent; this code is bad partially
                                     # because of customizations backwards compatibility. Hopefully 
                                     # cleanup after refactoring.
                      result = cust_desc[proposal.cluster]() {proposal: proposal}
                    else 
                      result

                  else 
                    DIV dangerouslySetInnerHTML:{__html: body}

                else 
                  DIV dangerouslySetInnerHTML:{__html: body}


          if @local.description_collapsed
            BUTTON
              id: 'expand_full_text'
              style:
                textDecoration: 'underline'
                cursor: 'pointer'
                padding: '24px 0px 10px 0px'
                fontWeight: 600
                textAlign: 'left'
                border: 'none'
                width: '100%'
                backgroundColor: 'transparent'

              onMouseDown: => 
                @local.description_collapsed = false
                save(@local)

              onKeyDown: (e) =>
                if e.which == 13 || e.which == 32 # ENTER or SPACE
                  @local.description_collapsed = false
                  e.preventDefault()
                  document.activeElement.blur()
                  save(@local)

              TRANSLATE 
                id: 'engage.show_full_proposal_description'
                'Show full text'




        if permit('update proposal', proposal) > 0 && !screencasting()
          DIV
            style: 
              marginTop: 5


            A 
              href: "#{proposal.key}/edit"
              style:
                marginRight: 10
                color: '#999'
                border: 'none'
                padding: 0
              TRANSLATE 'engage.edit_button', 'edit'

            if permit('delete proposal', proposal) > 0
              BUTTON
                className: 'like_link'
                style:
                  marginRight: 10
                  color: '#999'
                  fontWeight: 600

                onClick: => 
                  if confirm('Delete this proposal forever?')
                    destroy(proposal.key)
                    loadPage('/')
                TRANSLATE 'engage.delete_button', 'delete'



  componentDidMount : ->
    if (fetch(@props.proposal or @proposal).description && @max_description_height && !@local.description_collapsed? \
        && $('.wysiwyg_text').height() > @max_description_height)
      @local.description_collapsed = true 
      save(@local)

  componentDidUpdate : ->
    if (fetch(@props.proposal or @proposal).description && @max_description_height && !@local.description_collapsed? \
        && $('.wysiwyg_text').height() > @max_description_height)
      @local.description_collapsed = true
      save(@local)
