HISTOGRAM_HEIGHT_COLLAPSED = 40
HISTOGRAM_HEIGHT_EXPANDED = 170

require "./pro_con_widget"


styles += """
  .OpinionBlock {
    position: relative;
  }

  .is_expanded .OpinionBlock {
    padding-top: 48px;
  }

  .fast-thought {
    display: flex;
    flex-direction: row;    
    position: relative;
  }

  .is_expanded .fast-thought {
    justify-content: center;
  }

  @media #{NOT_LAPTOP_MEDIA} {
    .is_expanded .fast-thought .proposal-left-spacing, 
    .is_expanded .fast-thought .proposal-left-spacing, 
    .is_expanded .fast-thought .proposal-avatar-wrapper, 
    .is_expanded .fast-thought .proposal-avatar-spacing {
      display: none;
    }

  }

  .OpinionBlock .slidergram_wrapper {
    display: flex;
  }

  .is_collapsed .OpinionBlock .slidergram_wrapper {
    margin-right: var(--LIST_PADDING_RIGHT);
  }

  .is_expanded .OpinionBlock .slidergram_wrapper {
    justify-content: center;
    align-items: center;
    flex-direction: column;
    margin-right: 0;
  }


  .proposal_scores {
    position: absolute;
  }

  .is_collapsed .proposal_scores {
    left: calc(100% - 80px);
    top: 23px;    
  }

  .is_expanded .proposal_scores {
    left: calc(50% + var(--ITEM_OPINION_WIDTH) / 2 * 2 + 36px);
    bottom: 16px;
  }


  .opinion-views-container {
    position: relative;
    z-index: 1;
    opacity: 0;     
    margin-bottom: 8px;     
  }

  :not(.expanding).is_expanded .opinion-views-container {
    opacity: 1;
    transition: opacity #{6 * ANIMATION_SPEED_ITEM_EXPANSION}s ease #{STAGE3_DELAY}s;              
  }


  .heading-container {
    opacity: 0;

  }

  .is_expanded .heading-container {
    opacity: 1;
    transition: opacity #{2 * ANIMATION_SPEED_ITEM_EXPANSION}s linear #{STAGE1_DELAY}s;              
  }

  .is_collapsed .heading-container {
    overflow: hidden;
    height: 0;
    width: var(--ITEM_OPINION_WIDTH);
  }


  .opinion-heading {
    font-size: 30px;
    font-weight: 400;
    text-align: center;
    margin-bottom: 8px;
  }


  @media #{TABLET_MEDIA} {
    .opinion-heading {
      font-size: 24px;
    }
  }

  @media #{PHONE_MEDIA} {
    .opinion-heading {
      font-size: 22px;
    }
  }





"""


window.OpinionBlock = ReactiveComponent
  displayName: 'OpinionBlock'


  render: ->
    proposal = bus_fetch @props.proposal 
    subdomain = bus_fetch '/subdomain'
    current_user = bus_fetch '/current_user'

    @is_expanded = @props.is_expanded

    mode = getProposalMode(proposal)

    show_proposal_scores = (!@is_expanded || mode != 'crafting') && !@props.hide_scores && customization('show_proposal_scores', proposal, subdomain) && WINDOW_WIDTH() > 955

    opinion_views = bus_fetch 'opinion_views'
    just_you = opinion_views.active_views['just_you']


    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", proposal, subdomain)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", proposal, subdomain)}"
      else 
        translator "sliders.feedback-short.neutral", "Neutral"


    DIV 
      className: 'OpinionBlock'

      FLIPPED 
        flipId: "participation-status-#{proposal.key}"
        shouldFlipIgnore: @props.shouldFlipIgnore
        shouldFlip: @props.shouldFlip
        DIV null,
          if @is_expanded
            ParticipationStatus
              proposal: proposal.key

      FLIPPED 
        flipId: "proposal_heading-#{proposal.key}"
        shouldFlipIgnore: @props.shouldFlipIgnore
        shouldFlip: @props.shouldFlip

        DIV 
          className: 'heading-container'

          if (customization('opinion_callout')?[proposal.cluster] or (customization('opinion_callout') && _.isFunction(customization('opinion_callout'))))
            (customization('opinion_callout')?[proposal.cluster] or customization('opinion_callout'))()
          else 
            H1
              className: 'opinion-heading'
              style: _.defaults {}, customization('list_title_style') # ,
                #display: if embedded_demo() then 'none'    

                

              if mode == 'crafting' || (just_you && current_user.logged_in)
                TRANSLATE
                  id: "engage.opinion_header"
                  'What do you think?'
              else 
                list_i18n().opinion_header("list/#{proposal.cluster}")


      # feelings
      SECTION 
        className: 'fast-thought'

        if TABLET_SIZE()
          [
            DIV key: 'left', className: 'proposal-left-spacing'
            DIV key: 'avatar', className: 'proposal-avatar-wrapper'
            DIV key: 'right', className: 'proposal-avatar-spacing'
          ]


        DIV 
          className: 'slidergram_wrapper'

          if @is_expanded && !PHONE_SIZE()
            DIV 
              className: 'opinion-views-container'

              OpinionViews
                ui_key: "opinion-views-#{proposal.key}"
                disable_switching: mode == 'crafting'
                style: 
                  margin: '8px auto 20px auto'
                  position: 'relative'

              OpinionViewInteractionWrapper
                ui_key: "opinion-views-#{proposal.key}"              
                more_views_positioning: 'centered'
                width: HOMEPAGE_WIDTH()

          Slidergram @props


      
      if @is_expanded
        Reasons @props





styles += """
  .Slidergram {
    position: relative;
  }

  .is_collapsed .Slidergram {
    margin-top: -26px;    
  }
"""

window.Slidergram = ReactiveComponent
  displayName: "Slidergram"

  render: ->

    @is_expanded = @props.is_expanded

    proposal = bus_fetch @props.proposal 
    subdomain = bus_fetch '/subdomain'
    current_user = bus_fetch '/current_user'

    # watching = current_user.subscriptions[proposal.key] == 'watched'
    # return if !watching && bus_fetch('homepage_filter').watched

    your_opinion = proposal.your_opinion
    if your_opinion.key 
      bus_fetch your_opinion.key 

    permitted_to_opine = -> canUserOpine proposal

    can_opine = permitted_to_opine()

    slider_regions = customization('slider_regions', proposal, subdomain)

    opinions = opinionsForProposal(proposal)

    draw_slider = can_opine > 0

    mode = getProposalMode(proposal)

    backgrounded = @is_expanded && mode == 'crafting'

    if draw_slider
      slider = bus_fetch "homepage_slider#{proposal.key}"
    else 
      slider = null 


    opinion_views = bus_fetch 'opinion_views'
    just_you = opinion_views.active_views['just_you']

    width = ITEM_OPINION_WIDTH() * (if @is_expanded && !TABLET_SIZE() then 2 else 1)

    namespaced_slider_key = namespaced_key('slider', proposal)

    opinion_focus_elsewhere = (opinion_views.active_views.region_selected || (opinion_views.active_views.single_opinion_selected && !just_you) )


    # feelings
    DIV 
      className: 'Slidergram'


      H2
        className: 'hidden'

        translator
          id: "engage.opinion_spectrum_explanation"
          negative_pole: get_slider_label("slider_pole_labels.oppose", proposal)
          positive_pole: get_slider_label("slider_pole_labels.support", proposal)
          proposal_name: proposal.name
          "Evaluations on spectrum from {negative_pole} to {positive_pole} of the proposal {proposal_name}"

      if opinion_views.active_views.group_by && bus_fetch('opinion_views_ui').aggregate_into_groups
        AggregatedHistogram 
          proposal: proposal.key
          width: width
          height: if !@is_expanded then HISTOGRAM_HEIGHT_COLLAPSED else HISTOGRAM_HEIGHT_EXPANDED
          flip: true
          shouldFlip: @props.shouldFlip
          shouldFlipIgnore: @props.shouldFlipIgnore

      
      else
        Histogram
          histo_key: "histogram-#{proposal.slug}"
          proposal: proposal.key
          opinions: opinions
          width: width
          height: if !@is_expanded then HISTOGRAM_HEIGHT_COLLAPSED else HISTOGRAM_HEIGHT_EXPANDED
          enable_individual_selection: !@props.disable_selection && (!PHONE_SIZE() && (!TABLET_SIZE() || @props.is_expanded))
          enable_range_selection: !just_you && !browser.is_mobile && !TABLET_SIZE()
          # draw_base: true
          draw_base_labels: !slider_regions
          backgrounded: backgrounded

          flip: true
          shouldFlip: @props.shouldFlip
          shouldFlipIgnore: @props.shouldFlipIgnore

      OpinionSlider
        key: namespaced_slider_key
        slider_key: namespaced_slider_key
        proposal: @props.proposal
        width: width
        your_opinion: your_opinion
        focused: @is_expanded && mode == 'crafting'
        draw_handle: !opinion_focus_elsewhere && (can_opine == Permission.NOT_LOGGED_IN || can_opine > 0)
        permitted: permitted_to_opine

        base_height: if !@is_expanded then 1 else 2

        handle: if !@is_expanded 
                  slider_handle.triangley
                else if false 
                  slider_handle.flat 
                else 
                  customization('slider_handle', proposal) or slider_handle.flat

        handle_height: if !@is_expanded then 30 else if TABLET_SIZE() then 44 else 36
        handle_width: if !@is_expanded then 33

        offset: !@is_expanded

        pole_labels: [ \
          get_slider_label("slider_pole_labels.oppose", proposal),
          get_slider_label("slider_pole_labels.support", proposal)]

        flip: !!@props.shouldFlip
        shouldFlip: @props.shouldFlip
        shouldFlipIgnore: @props.shouldFlipIgnore

        is_expanded: @props.is_expanded

        show_val_highlighter: !opinion_focus_elsewhere && (can_opine == Permission.NOT_LOGGED_IN || can_opine > 0)

        show_reasons_callout: (!opinion_focus_elsewhere || TABLET_SIZE()) && !@props.is_expanded




ParticipationStatus = ReactiveComponent
  displayName: 'ParticipationStatus'
  render: -> 
    can_opine = canUserOpine @props.proposal

    return SPAN null if can_opine > 0 || can_opine == Permission.NOT_LOGGED_IN # || can_opine == Permission.DISABLED

    DIV 
      style: 
        textAlign: 'center'

      DIV
        style: 
          backgroundColor: "var(--attention_orange)"
          color: "var(--text_light)"
          margin: '0px auto 8px auto'
          display: 'inline-block'
          padding: '4px 6px'
          fontWeight: 700

        if can_opine == Permission.DISABLED
          TRANSLATE
            id: 'engage.proposal_closed'
            'Closed to new contributions.'

        else if can_opine == Permission.INSUFFICIENT_PRIVILEGES
          TRANSLATE
            id: 'engage.permissions.read_only'
            "This proposal is read-only. The forum hosts specify who can participate."

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

            onKeyPress: (e) => 
              if e.which == 32 || e.which == 13
                reset_key 'auth', 
                  form: 'verify email'
                  goal: 'To participate, please demonstrate you control this email.'
                  
                current_user.trying_to = 'send_verification_token'
                save current_user

            translator 'engage.permissions.verify_account_to_participate', "Verify your account to participate"





window.canUserOpine = (proposal) ->
  proposal = bus_fetch proposal
  your_opinion = proposal.your_opinion

  if your_opinion.key
    can_opine = permit 'update opinion', proposal, your_opinion
  else
    can_opine = permit 'publish opinion', proposal

  can_opine

window.couldUserMaybeOpine = (proposal) ->
  can_opine = canUserOpine(proposal)
  can_opine > 0 || can_opine in [Permission.NOT_LOGGED_IN, Permission.UNVERIFIED_EMAIL]  



