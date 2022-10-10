## ########################
## Initialize defaults for client data

require "./proposal_description"
require "./pro_con_widget"
require "./dock"
require "./opinion_views"







  


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

    # TODO: get this to work again without getting in re-render infinite loop
    # if doc.title != proposal.name
    #   doc.title = proposal.name
    #   save doc


    your_opinion = proposal.your_opinion
    if your_opinion.key 
      fetch your_opinion
    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    return DIV(null) if !proposal.roles


    if your_opinion.key
      can_opine = permit 'update opinion', proposal, your_opinion
    else
      can_opine = permit 'publish opinion', proposal

    mode = get_proposal_mode()


    # # change to results page if user entered crafting page when it is not permitted
    if mode == 'crafting' && 
        !(can_opine in [Permission.PERMITTED, Permission.UNVERIFIED_EMAIL, \
                        Permission.NOT_LOGGED_IN, Permission.INSUFFICIENT_INFORMATION] || 
         (can_opine == Permission.DISABLED && your_opinion.key))
      update_proposal_mode('results', 'permission not granted for crafting')
    
    
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


