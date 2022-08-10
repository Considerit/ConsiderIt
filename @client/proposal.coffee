## ########################
## Initialize defaults for client data

require "./proposal_description"
require "./pro_con_widget"
require "./dock"
require "./opinion_views"



#######
# State stored in query params
# TODO: eliminate
window.get_proposal_mode = -> 
  loc = fetch('location')

  if loc.url == '/'
    return null
  else if (loc.query_params?.results && loc.query_params?.results != 'false') || TWO_COL()
    'results' 
  else 
    'crafting'

window.get_selected_point = -> 
  fetch('location').query_params.selected


window.updateProposalMode = (proposal_mode, triggered_by) ->
  loc = fetch('location')

  if proposal_mode == 'results' && loc.query_params.results ||
      proposal_mode == 'crafting' && !loc.query_params.results
    return

  if proposal_mode == 'results'
    loc.query_params.results = true
  else
    delete loc.query_params.results

  delete loc.query_params.selected

  save loc

  histo_el = document.querySelector('[data-widget="Proposal"] .histogram')

  if proposal_mode == 'results' && histo_el
    
    $$.ensureInView histo_el,
      offset_buffer: 0

  window.writeToLog
    what: 'toggle proposal mode'
    details: 
      from: get_proposal_mode()
      to: proposal_mode
      triggered_by: triggered_by 
  


#####################
# These are some of the major components and their relationships 
# when viewing a proposal. 
#
# Open the state graph in a running application by pressing cntrl-G to 
# examine relationships with live code. 
#
#                         Root
#                          |
#                         Page 
#                          |
#                       Proposal
#                   /      |           \            \
#    CommunityPoints   DecisionBoard   Histogram   OpinionSlider
#               |          |
#               |      YourPoints
#               |    /            \
#              Point             EditPoint


##
# Proposal
# Has proposal description, feelings area (slider + histogram), and reasons area
window.Proposal = ReactiveComponent
  displayName: 'Proposal'

  render : ->
    doc = fetch('document')
    proposal = fetch @props.proposal

    is_loading = !proposal.slug || !fetch("/page/#{proposal.slug}").proposal


    if doc.title != proposal.name
      doc.title = proposal.name
      save doc

    your_opinion = proposal.your_opinion
    if your_opinion.key 
      fetch your_opinion
    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    return DIV(null) if !proposal.roles

    mode = get_proposal_mode()

    if your_opinion.key
      can_opine = permit 'update opinion', proposal, your_opinion
    else
      can_opine = permit 'publish opinion', proposal

    # change to results page if user entered crafting page when it is not permitted
    if mode == 'crafting' && 
        !(can_opine in [Permission.PERMITTED, Permission.UNVERIFIED_EMAIL, \
                        Permission.NOT_LOGGED_IN, Permission.INSUFFICIENT_INFORMATION] || 
         (can_opine == Permission.DISABLED && your_opinion.key))
      updateProposalMode('results', 'permission not granted for crafting')
    
    
    opinion_views = fetch 'opinion_views'
    just_you = opinion_views?.active_views['just_you']

    ARTICLE 
      id: "proposal-#{proposal.id}"
      "data-proposal": proposal.key
      key: proposal.slug

      DIV null,

        ProposalDescription
          proposal: proposal.key

        ParticipationStatus {can_opine}

        if (customization('opinion_callout')?[proposal.cluster] or (customization('opinion_callout') && _.isFunction(customization('opinion_callout'))))
          (customization('opinion_callout')?[proposal.cluster] or customization('opinion_callout'))()
        else 
          H1
            style: _.defaults {}, customization('list_title_style'),
              fontSize: 32
              fontWeight: 500
              textAlign: 'center'
              marginTop: 18
              display: if embedded_demo() then 'none'

            if mode == 'crafting' || (just_you && current_user.logged_in)
              TRANSLATE
                id: "engage.opinion_header"
                'What do you think?'
            else 
              list_i18n().opinion_header("list/#{proposal.cluster}")


        if !embedded_demo()      
          OpinionViews
            more_views_positioning: 'centered'
            disable_switching: mode == 'crafting'
            style: 
              width: if get_participant_attributes().length > 0 then HOMEPAGE_WIDTH() else Math.max(660,PROPOSAL_HISTO_WIDTH()) # REASONS_REGION_WIDTH()
              margin: '8px auto 20px auto'
              position: 'relative'

        if mode != 'crafting' && !embedded_demo()
          DIV 
            style: 
              width: PROPOSAL_HISTO_WIDTH()
              margin: 'auto'
              position: 'relative'

            DIV 
              style: 
                position: 'absolute'
                zIndex: 1
                left: '100%'
                marginLeft: 30
                top: if screencasting() then 120 else 170

              HistogramScores
                proposal: proposal.key

        if is_loading
          LOADING_INDICATOR
        else
          
          Pro_Con_Widget 
            proposal: proposal.key
            can_opine: can_opine


      if true || mode == 'results' # && !embedded_demo()
        w = HOMEPAGE_WIDTH() + LIST_PADDING() * 2

        DIV 
          className: "main_background navigation_wrapper #{if ONE_COL() then 'one-col' else ''}"
          style: 
            marginTop: 88
            position: 'relative'

          STYLE 
            dangerouslySetInnerHTML: __html: """
              .navigation_wrapper:not(.one-col)::after {
                content: ' ';
                position: absolute;
                left: 0;
                width: 100%;
                top: -50px;
                z-index: 10;
                display: block;
                height: 50px;
                background-size: 50px 100%;
                background-image: linear-gradient(135deg, #{main_background_color} 25%, transparent 25%), linear-gradient(225deg, #{main_background_color} 25%, transparent 25%);
                background-position: 0 0;
                transform: scaleY(-1);
              }

              .navigation_wrapper:not(.one-col)::before {
                content: ' ';
                position: absolute;
                left: 0;
                width: 100%;
                top: -51px;
                z-index: 9;
                display: block;
                height: 51px;
                background-size: 50px 100%;
                background-image: linear-gradient(135deg, #babdc3 25%, transparent 25%), linear-gradient(225deg, #babdc3 25%, transparent 25%);
                background-position: 0 0;
                transform: scaleY(-1);
              }
            """


          DIV   
            style: 
              margin: '32px auto 0px auto'
              paddingBottom: 48
              width: w


            (customization('ProposalNavigation') or GroupedProposalNavigation) # or NextProposals)
              width: w
              proposal: proposal.key




ParticipationStatus = ReactiveComponent
  displayName: 'ParticipationStatus'
  render: -> 
    can_opine = @props.can_opine

    return SPAN null if can_opine > 0 || can_opine == Permission.NOT_LOGGED_IN || can_opine == Permission.DISABLED

    DIV 
      style: 
        textAlign: 'center'

      DIV
        style: 
          backgroundColor: attention_orange
          color: 'white'
          margin: 'auto'
          display: 'inline-block'
          padding: '4px 6px'
          fontWeight: 700

        if can_opine == Permission.DISABLED
          TRANSLATE
            id: 'engage.proposal_closed'
            'Closed to new contributions at this time.'

        else if can_opine == Permission.INSUFFICIENT_PRIVILEGES
          TRANSLATE
            id: 'engage.permissions.read_only'
            "Sorry, this proposal is read-only for you. The forum hosts specify who can participate."

        else if can_opine == Permission.UNVERIFIED_EMAIL
          A
            style:
              cursor: 'pointer'

            onTouchEnd: (e) => 
              e.stopPropagation()

            onClick: (e) =>
              e.stopPropagation()

              reset_key 'auth', 
                form: 'verify email'
                goal: 'To participate, please demonstrate you control this email.'
                
              current_user.trying_to = 'send_verification_token'
              save current_user

            translator 'engage.permissions.verify_account_to_participate', "Verify your account to participate"


