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

  .is_expanded .OpinionBlock .proposal-score-spacing {
    width: 0;
  }

  .OpinionBlock .slidergram_wrapper {
    display: flex;
  }

  .is_expanded .OpinionBlock .slidergram_wrapper {
    justify-content: center;
    align-items: center;
    flex-direction: column;
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
    top: #{HISTOGRAM_HEIGHT_EXPANDED + 55}px; /* 55 is for the height of the opinionviews */
  }


  .opinion-views-container {
    position: relative;
    z-index: 1;
    opacity: 0;     
    margin-bottom: 8px;     
  }

  :not(.expanding).is_expanded .opinion-views-container {
    opacity: 1;
    transition: opacity #{4 * ANIMATION_SPEED_ITEM_EXPANSION}s ease #{STAGE3_DELAY}s;              
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
    font-size: 34px;
    font-weight: 400;
    text-align: center;
    margin-bottom: 8px;
  }






"""


window.OpinionBlock = ReactiveComponent
  displayName: 'OpinionBlock'


  render: ->
    proposal = fetch @props.proposal 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    @is_expanded = @props.is_expanded

    mode = get_proposal_mode(proposal)

    show_proposal_scores = (!@is_expanded || mode != 'crafting') && !@props.hide_scores && customization('show_proposal_scores', proposal, subdomain) && WINDOW_WIDTH() > 955

    opinion_views = fetch 'opinion_views'
    just_you = opinion_views.active_views['just_you']


    slider_interpretation = (value) => 
      if value > .03
        "#{(value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.support", proposal, subdomain)}"
      else if value < -.03 
        "#{-1 * (value * 100).toFixed(0)}% #{get_slider_label("slider_pole_labels.oppose", proposal, subdomain)}"
      else 
        translator "engage.slider_feedback.neutral", "Neutral"


    DIV 
      className: 'OpinionBlock'


      # for allowing people to drop a point in their list outside to remove it
      onDrop: if @is_expanded then (ev) =>
        # point_key = ev.dataTransfer.getData('text/plain')
        point_key = fetch('point-dragging').point

        return if !point_key
        point = fetch point_key


        validate_first = point.user == fetch('/current_user').user && point.includers.length < 2


        if !validate_first || confirm('Are you sure you want to remove your point? It will be gone forever.')

          your_opinion = proposal.your_opinion

          if your_opinion.point_inclusions && point.key in your_opinion.point_inclusions
            idx = your_opinion.point_inclusions.indexOf point.key
            your_opinion.point_inclusions.splice(idx, 1)
            save your_opinion

            window.writeToLog
              what: 'removed point'
              details: 
                point: point.key

        ev.preventDefault()

      onDragEnter: if @is_expanded then (ev) =>
        ev.preventDefault()

      onDragOver: if @is_expanded then (ev) => 
        ev.preventDefault() # makes it droppable, according to html5 DnD spec


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

        if ONE_COL()
          [
            DIV key: 'left', className: 'proposal-left-spacing'
            DIV key: 'avatar', className: 'proposal-avatar-wrapper'
            DIV key: 'right', className: 'proposal-avatar-spacing'
          ]


        DIV 
          className: 'slidergram_wrapper'

          if @is_expanded
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


        # always create the spacing, as the spacing also acts as the right padding
        DIV 
          className: 'proposal-score-spacing'

      
        # little score feedback
        if show_proposal_scores        

          FLIPPED 
            flipId: "proposal_scores-#{proposal.key}"
            shouldFlipIgnore: @props.shouldFlipIgnore
            shouldFlip: @props.shouldFlip

            DIV 
              className: 'proposal_scores'

              HistogramScores
                proposal: proposal.key

      if @is_expanded
        Reasons @props





styles += """
  .Slidergram {
    position: relative;
  }

  .is_collapsed .Slidergram {
    top: -26px;    
  }
"""

window.Slidergram = ReactiveComponent
  displayName: "Slidergram"

  render: ->

    @is_expanded = @props.is_expanded

    proposal = fetch @props.proposal 
    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    # watching = current_user.subscriptions[proposal.key] == 'watched'
    # return if !watching && fetch('homepage_filter').watched

    your_opinion = proposal.your_opinion
    if your_opinion.key 
      fetch your_opinion.key 

    permitted_to_opine = ->
      if your_opinion.published
        can_opine = permit 'update opinion', proposal, your_opinion, subdomain
      else
        can_opine = permit 'publish opinion', proposal, subdomain

    can_opine = permitted_to_opine()

    slider_regions = customization('slider_regions', proposal, subdomain)

    opinions = opinionsForProposal(proposal)

    draw_slider = can_opine > 0

    mode = get_proposal_mode(proposal)

    backgrounded = @is_expanded && mode == 'crafting'

    if draw_slider
      slider = fetch "homepage_slider#{proposal.key}"
    else 
      slider = null 


    opinion_views = fetch 'opinion_views'
    just_you = opinion_views.active_views['just_you']

    width = ITEM_OPINION_WIDTH() * (if @is_expanded && !ONE_COL() then 2 else 1)

    namespaced_slider_key = namespaced_key('slider', proposal)



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

         
      Histogram
        histo_key: "histogram-#{proposal.slug}"
        proposal: proposal.key
        opinions: opinions
        width: width
        height: if !@is_expanded then HISTOGRAM_HEIGHT_COLLAPSED else HISTOGRAM_HEIGHT_EXPANDED
        enable_individual_selection: !@props.disable_selection && !browser.is_mobile
        enable_range_selection: !just_you && !browser.is_mobile && !ONE_COL()
        # draw_base: true
        draw_base_labels: !slider_regions
        backgrounded: backgrounded

        flip: true
        shouldFlip: @props.shouldFlip
        shouldFlipIgnore: @props.shouldFlipIgnore


      # Dock
      #   key: 'slider-dock'
      #   dock_key: "slider-dock-#{proposal.key}"
      #   docked_key: namespaced_slider_key 
      #   dock_on_zoomed_screens: true
      #   constraints : ['decisionboard-dock']
      #   skip_jut: mode == 'results'
      #   dockable: => 
      #     @is_expanded && draw_slider && mode == 'crafting'
      #   dummy: @is_expanded
      #   dummy2: WINDOW_WIDTH()
      #   dummy3: mode

      #   do =>
      OpinionSlider
        key: namespaced_slider_key
        slider_key: namespaced_slider_key
        proposal: @props.proposal
        width: width
        your_opinion: your_opinion
        focused: @is_expanded && mode == 'crafting'
        backgrounded: false
        draw_handle: can_opine == Permission.NOT_LOGGED_IN || can_opine > 0
        permitted: permitted_to_opine

        base_height: if !@is_expanded then 1 else 2

        handle: if !@is_expanded 
                  slider_handle.triangley
                else if false 
                  slider_handle.flat 
                else 
                  customization('slider_handle', proposal) or slider_handle.flat

        handle_height: if !@is_expanded then 18 else if TWO_COL() then 55 else 36
        handle_width: if !@is_expanded then 21

        offset: !@is_expanded

        pole_labels: [ \
          get_slider_label("slider_pole_labels.oppose", proposal),
          get_slider_label("slider_pole_labels.support", proposal)]

        flip: !!@props.shouldFlip
        shouldFlip: @props.shouldFlip
        shouldFlipIgnore: @props.shouldFlipIgnore

        is_expanded: @props.is_expanded

        show_val_highlighter: true





