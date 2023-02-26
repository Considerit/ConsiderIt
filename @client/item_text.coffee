
COLLAPSED_MAX_HEIGHT = 50
EXPANDED_MAX_HEIGHT = 500

styles += """

  :root {
    --proposal_title_underline_color: #000000;
  }

  .ItemText .proposal-title {
    max-width: 700px;
  }

  .ItemText.has-description .proposal-title {
    margin-bottom: 8px;
  }

  .ItemText .proposal-title-text {
    # transition-property: transform;    
    transform: scale(1);
    transform-origin: 0 0;

    cursor: pointer;
  }

  .proposal-title-invert-container {
    position: relative;
    z-index: 1;
  } 

  .is_expanded .ItemText .proposal-title-invert-container {
    position: absolute;
  }


  .proposal-title-text-inline {
    border-bottom-width: 2px;
    border-style: solid;
    border-color: #{focus_blue + "ad"}; /* with some transparency */
    transition: border-color 1s;
    font-size: 20px;
    font-weight: 700;
    color: #111;    
  }

  @media #{PHONE_MEDIA} {
    .proposal-title-text-inline {
      font-size: 17px;
    }
  }

  .proposal-title-text-inline:hover,
  .proposal-title-text-inline:focus-within {
    border-color: #000;
  }


  .proposal-description {
    overflow: hidden;

    font-size: 15px;
    font-weight: 400;

    // max-height: 50px; /* this value will get overridden to min(estimated_desc_height, PROPOSAL_DESCRIPTION_MAX_HEIGHT_ON_EXPAND) in javascript */

    transition-property: color;

    // padding: 8px 0px;

    color: #555;
  }

  .is_collapsed .proposal-description {
    max-height: #{COLLAPSED_MAX_HEIGHT}px;
    color: #888;
  }

  .is_collapsed .proposal-description.hidden-by-customization {
    max-height: 0px;
  }


  .is_expanded .proposal-description {
    max-height: #{EXPANDED_MAX_HEIGHT}px;
  }

  .is_expanded .proposal-description.fully_expanded {
    max-height: 9999px;
  }

  .proposal-description.wysiwyg_text p {
    line-height: 1.5;
  }

  .is_expanded .proposal-description.wysiwyg_text p {
    /* max-width: var(--ITEM_TEXT_WIDTH); */
  }

  [data-widget="ListItems"]:not(.expansion_event) .is_collapsed .transparency_fade {
    background: linear-gradient(0deg, rgba(255,255,255,1) 0%, rgba(255,255,255,0) 100%); /* linear-gradient(0deg, rgba(255,255,255,1) 0%, rgba(255,255,255,1) 34%, rgba(255,255,255,0) 100%); */
    bottom: 0px;
    height: 22px;
    position: absolute;
    pointer-events: none;
    opacity: 1;
  }
  .transparency_fade {
    opacity: 0;
    transition: opacity #{ANIMATION_SPEED_ITEM_EXPANSION}s ease;
  }

  [data-widget="ListItems"].flipping .expand_full_text {
    opacity: 0;
  }
  .expand_full_text {
    text-decoration: underline;
    cursor: pointer;
    padding: 24px 0px 10px 0px;
    font-weight: 600;
    text-align: left;
    border: none;
    width: 100%;
    background-color: transparent;
  }


  .show_list_title .proposal-title-text::before {
    content: attr(data-list-title);
    color: var(--list-color);
    position: absolute;
    top: -16px;
    padding: 0;
    font-size: 12px;
    height: 16px;
    overflow: hidden;

    font-style: italic;
    font-weight: 500;

    /* 
    font-family: IBM Plex mono;
    */
  }       
"""







window.collapsed_height_initialized = {}

window.ItemText = ReactiveComponent
  displayName: 'ItemText'


  toggle_expand: -> 
    toggle_expand 
      proposal: @props.proposal

  render: -> 
    proposal = fetch @props.proposal
    subdomain = fetch '/subdomain'

    @is_expanded = @props.is_expanded

    has_description = proposal.description || customization('proposal_description')

    if !@is_expanded && @local.description_fully_expanded
      @local.description_fully_expanded = false

    if @props.show_list_title
      list_title = get_list_title(get_list_for_proposal(proposal), true)
      list_title_width = widthWhenRendered(list_title, {fontSize: "12px", fontWeight: "500", fontStyle: "italic"})
      tw = ITEM_TEXT_WIDTH()
      if list_title_width > tw
        list_title = "#{list_title.substring(0, (Math.floor(tw / list_title_width  * list_title.length) - 6))}..."

    FLIPPED
      flipId: "proposal-title-starter-#{proposal.key}"
      shouldFlip: @props.shouldFlip
      shouldFlipIgnore: @props.shouldFlipIgnore
      opacity: true
      onSpringUpdate: if @props.expansion_state_changed() && LIST_ITEM_EXPANSION_SCALE() != 1 then (value) => 
        if @props.expansion_state_changed()            
          start = if @is_expanded then 1 else LIST_ITEM_EXPANSION_SCALE() 
          end = if @is_expanded then LIST_ITEM_EXPANSION_SCALE() else 1 
          if @refs.proposal_title_text
            @refs.proposal_title_text.style.transform = "scale(#{ start + (end - start) * value })"

      DIV 
        id: "proposal-text-#{proposal.id}"
        "data-widget": 'ItemText'
        className: "ItemText #{if has_description then 'has-description' else 'no-description'}"
        ref: 'root'

        'data-visibility-name': 'ItemText'
        'data-receive-viewport-visibility-updates': 2
        'data-component': @local.key


        STYLE 
          dangerouslySetInnerHTML: __html: """

             .is_expanded .ItemText .proposal-title-text {
               transform: scale(#{LIST_ITEM_EXPANSION_SCALE()});
             } 

             .is_collapsed #proposal-text-#{proposal.id} .proposal-title {
               height: #{@local.collapsed_title_height}px;
             }

             .is_expanded #proposal-text-#{proposal.id} .proposal-title {
               height: #{LIST_ITEM_EXPANSION_SCALE() * @local.collapsed_title_height}px;
             }

             #proposal-text-#{proposal.id} .proposal-title-text, .transparency_fade {
                width: #{ITEM_TEXT_WIDTH()}px;
             }

             .is_collapsed #proposal-text-#{proposal.id} .proposal-description-wrapper {
                max-width: #{ITEM_TEXT_WIDTH()}px;
                position: relative; /* for transparency fade */
             }
             .is_expanded #proposal-text-#{proposal.id} .proposal-description-wrapper {
                max-width: #{ITEM_TEXT_WIDTH() * LIST_ITEM_EXPANSION_SCALE()}px;
             }

          """

        DIV null,

          FLIPPED 
            flipId: "proposal-title-placer-#{proposal.key}"
            shouldFlip: @props.shouldFlip
            shouldFlipIgnore: @props.shouldFlipIgnore

            DIV 
              ref: 'proposal_title'
              className: "prep_for_flip proposal-title"
              "data-proposal": proposal.key
              onClick: @toggle_expand
              onKeyPress: (e) => 
                if e.which == 32 || e.which == 13
                  @toggle_expand()

              FLIPPED 
                inverseFlipId: "proposal-title-placer-#{proposal.key}"
                shouldInvert: @props.shouldFlip
                shouldFlipIgnore: @props.shouldFlipIgnore

                DIV 
                  className: 'prep_for_flip proposal-title-invert-container' 
                          # a container for the flipper's transform to apply to w/o messing 
                          # with the transform applied to the title text

                  FLIPPED 
                    flipId: "proposal-title-#{proposal.key}"
                    shouldFlip: @props.shouldFlip
                    shouldFlipIgnore: @props.shouldFlipIgnore

                    DIV 
                      ref: 'proposal_title_text'
                      className: 'proposal-title-text'
                      "data-list-title": if @props.show_list_title then list_title
                      style: if !@props.show_list_title then {} else
                        "--list-color": @props.list_title_color or 'black'

                      SPAN 
                        className: 'proposal-title-text-inline'
                        proposal.name


          FLIPPED 
            flipId: "proposal-description-placer-#{proposal.key}"
            shouldFlip: @props.shouldFlip
            shouldFlipIgnore: @props.shouldFlipIgnore

            DIV 
              className: 'proposal-description-wrapper prep_for_flip'
              ref: 'proposal-description-wrapper'

              @draw_description()


          FLIPPED 
            flipId: "proposal-meta-placer-#{proposal.key}"
            translate: true
            shouldFlip: @props.shouldFlip
            shouldFlipIgnore: @props.shouldFlipIgnore

            DIV 
              className: 'prep_for_flip'

              @draw_metadata()




  waitForFonts: (cb) ->
    if !@fonts_loaded 
      @fonts_loaded = document.fonts.check "14px #{customization('font').split(',')[0]}"
      
      if !@fonts_loaded && !@wait_for_fonts 
        @wait_for_fonts = setInterval =>  
          cb?()

      if @fonts_loaded && @wait_for_fonts
        clearInterval @wait_for_fonts

      return @fonts_loaded
    true



  setCollapsedSizes: ->


    if !@waitForFonts(=> @setCollapsedSizes()) || (@local.collapsed_title_height? && @sized_at_window_width == WINDOW_WIDTH() && (!@description_has_media || @local.media_is_loaded))
      return

    proposal = fetch @props.proposal

    title_el = @refs.proposal_title_text

    changed = false 
    if @is_expanded
      collapsed_title_height = title_el.getBoundingClientRect().height
      if collapsed_title_height != @local.collapsed_title_height
        @local.collapsed_title_height = collapsed_title_height
        changed = true

    else 
      first_height_calc = title_el.clientHeight # There is a bug in at least Chrome, where for some reason after some updates, 
                                                # the first call to clientHeight incorrectly gives 0, but the next call gives 
                                                # correct value. 
      second_height_calc = title_el.clientHeight
      console.assert first_height_calc == second_height_calc, "First call to title_el.clientHeight was mysteriously wrong. First call: #{first_height_calc}, Second call: #{second_height_calc}"

      if @local.collapsed_title_height != second_height_calc
        @local.collapsed_title_height = second_height_calc
        changed = true

    @sized_at_window_width = WINDOW_WIDTH()
    save @local if changed



    if proposal.description 
      el = document.createElement 'div'
      el.classList.add 'proposal-description'

      @description_has_media = proposal.description.toLowerCase().indexOf('<img') > -1 || proposal.description.toLowerCase().indexOf('<video') > -1

      if @description_has_media && !@local.media_is_loaded
        desc = @refs.proposal_description

        @local.media_is_loaded = true
        for el in desc.querySelectorAll('img,video')
          if el.tagName == 'IMG'
            @local.media_is_loaded &&= el.complete
          else if el.tagName == 'VIDEO'
            @local.media_is_loaded &&= el.readyState >= 3
        if !@local.media_is_loaded
          setTimeout @setCollapsedSizes, 100
        else
          @local.media_is_loaded = true 
          save @local


      # do we need to show the transparency fade when collapsed?
      height = heightWhenRendered proposal.description.replace(/<p><br><\/p>/g, ''), \
                                  {width:"#{ITEM_TEXT_WIDTH()}px"}, el, @description_has_media

      @exceeds_collapsed_description_height = height >= COLLAPSED_MAX_HEIGHT

      # do we need to show a "show full text" button when expanded? 
      if LIST_ITEM_EXPANSION_SCALE() != 1
        height = heightWhenRendered proposal.description, \
                                    {width: "#{ITEM_TEXT_WIDTH() * LIST_ITEM_EXPANSION_SCALE()}px"}, el, @description_has_media

      @super_long_description = height >= EXPANDED_MAX_HEIGHT

    
    collapsed_height_initialized[proposal.key] = true
      


  componentDidMount: ->
    requestAnimationFrame =>
      loc = fetch 'location'
      @setCollapsedSizes()

  componentDidUpdate: ->
    requestAnimationFrame =>
      loc = fetch 'location'
      @setCollapsedSizes()


  draw_description: ->  
    proposal = fetch @props.proposal
    cust_desc = customization('proposal_description')

    return DIV null if !proposal.description && !cust_desc

    if cust_desc
      if typeof(cust_desc) == 'function'
        result = cust_desc(proposal)
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
        result = DIV dangerouslySetInnerHTML:{__html: proposal.description}

    else 
      result = DIV dangerouslySetInnerHTML:{__html: proposal.description.replace(/<p><br><\/p>/g, '')}

    DIV null,
      DIV 
        className: "proposal-description wysiwyg_text proposal_item_animation #{if @local.description_fully_expanded then 'fully_expanded' else ''} #{if customization('hide_collapsed_proposal_description') then 'hidden-by-customization' else ''}"
        ref: 'proposal_description'
        onClick: if @exceeds_collapsed_description_height && !@is_expanded then @toggle_expand

        DIV 
          style:
            # display: if embedded_demo() then 'none'
            position: 'relative'

          FLIPPED 
            inverseFlipId: "proposal-description-placer-#{proposal.key}"
            scale: true # this allows it to expand down, but also allows the description to move when sorting happens
            shouldInvert: @shouldFlip
            shouldFlipIgnore: @shouldFlipIgnore

            result

        if @exceeds_collapsed_description_height || cust_desc
          DIV className: 'transparency_fade'

      if @super_long_description && @props.is_expanded && !@local.description_fully_expanded && !embedded_demo()
        BUTTON
          className: 'expand_full_text'

          onMouseDown: => 
            @local.description_fully_expanded = true
            save(@local)

          onKeyDown: (e) =>
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              @local.description_collapsed = true
              e.preventDefault()
              document.activeElement.blur()
              save(@local)

          TRANSLATE 
            id: 'engage.show_full_proposal_description'
            'Show full text'



  draw_metadata: -> 
    proposal = fetch @props.proposal

    subdomain = fetch '/subdomain'
    icons = customization('show_proposer_icon', proposal, subdomain) && !@props.hide_icons && !customization('anonymize_everything')
    opinion_publish_permission = permit('publish opinion', proposal, subdomain)

    opinion_prompt = getOpinionPrompt {proposal}

    DIV
      className: 'proposal-metadata'   

      if customization('proposal_meta_data', null, subdomain)?
        customization('proposal_meta_data', null, subdomain)(proposal)

      else if !@props.hide_metadata && customization('show_proposal_meta_data', null, subdomain)
        show_author_name_in_meta_data = !icons && (editor = proposal_editor(proposal)) && editor == proposal.user && !customization('anonymize_everything')
        show_timestamp = !screencasting() && subdomain.name != 'galacticfederation'
        show_discussion_info = customization('discussion_enabled', proposal, subdomain)
        show_cluster = @props.show_list_title && proposal.cluster
        is_closed = opinion_publish_permission == Permission.DISABLED
        read_only = opinion_publish_permission == Permission.INSUFFICIENT_PRIVILEGES


        {weights, salience, groups} = compose_opinion_views(null, proposal)
        opinions = get_opinions_for_proposal opinions, proposal, weights
        overall_cnt = 0

        for o in opinions 
          continue if salience[o.user.key or o.user] < 1
          overall_cnt += 1


        [
          if show_timestamp
            SPAN 
              key: 'date'
              className: 'separated monospaced metadata-piece'
              style: 
                borderBottom: 'none'

              # if !show_author_name_in_meta_data
              #   TRANSLATE 'engage.proposal_metadata_date_added', "Added: "
              
              prettyDate(proposal.created_at)


          if show_author_name_in_meta_data
            SPAN 
              key: 'author name'
              className: 'separated monospaced metadata-piece'
              style: 
                borderBottom: 'none'

              TRANSLATE
                id: 'engage.proposal_author'
                name: fetch(editor)?.name 
                " by {name}"


          BUTTON 
            key: 'opinion-count'
            className: 'opinion-count metadata-piece separated like_link monospaced'
            onClick: => 
              toggle_expand
                proposal: proposal 
                prefer_personal_view: false                   
              
            onKeyPress: (e) => 
              if e.which == 32 || e.which == 13
                toggle_expand
                  proposal: proposal
                  prefer_personal_view: false                   

            TRANSLATE
              id: "engage.proposal_score_summary"
              num_opinions: overall_cnt 
              "{num_opinions, plural, =0 {no opinions} one {# opinion} other {# opinions} }"


          if show_discussion_info
            BUTTON
              key: 'proposal-link'
              className: 'pros_cons_count metadata-piece separated like_link monospaced'
              onClick: => 
                toggle_expand
                  proposal: proposal
                
              onKeyPress: (e) => 
                if e.which == 32 || e.which == 13
                  toggle_expand
                    proposal: proposal

              TRANSLATE
                id: "engage.point_count"
                cnt: proposal.point_count

                "{cnt, plural, one {# pro or con} other {# pros & cons}}"

          if opinion_prompt && !TABLET_SIZE()
            BUTTON 
              key: 'give-opinion'
              className: 'small-give-your-opinion metadata-piece separated like_link monospaced'
              onClick: => 
                toggle_expand
                  proposal: proposal 
                  prefer_personal_view: true                   
                
              onKeyPress: (e) => 
                if e.which == 32 || e.which == 13
                  toggle_expand
                    proposal: proposal
                    prefer_personal_view: true                   

              opinion_prompt

          if (your_opinion = proposal.your_opinion) && your_opinion.key && permit('update opinion', proposal, your_opinion) > 0
            remove_opinion = -> 
              your_opinion.stance = 0
              your_opinion.point_inclusions = []                   
              your_opinion.published = false 
              save your_opinion
                        
            BUTTON 
              key: 'remove_opinion'
              className: 'small-give-your-opinion metadata-piece separated like_link monospaced'
              onClick: remove_opinion

              translator "engage.remove_my_opinion", 'Remove your opinion'



        ]


      if is_closed
        SPAN 
          style: 
            position: 'relative'
            top: 2;
          "data-tooltip": translator 'engage.proposal_closed', 'Closed to new contributions.'
          
          closedIcon 
            size: 12
            fill: 'rgb(158, 35, 35)'

      else if read_only
        SPAN 
          style: 
            position: 'relative'
            top: 2;
          "data-tooltip": translator "engage.proposal_read_only.short", 'read-only'

          closedIcon 
            size: 12
            fill: 'rgb(158, 78, 35)'


window.getOpinionPrompt = ({proposal, prefer_drag_prompt}) ->
  proposal = fetch proposal

  perhaps_can_opinine = canUserOpine proposal

  return null unless (perhaps_can_opinine == Permission.NOT_LOGGED_IN || perhaps_can_opinine > 0)

  your_opinion = proposal.your_opinion
  no_opinion = !fetch('/current_user').logged_in || !your_opinion.key

  discussion_enabled = customization('discussion_enabled', proposal, fetch('/subdomain'))

  if no_opinion || !discussion_enabled
    # translator 
    #   id: "engage.log_in_to_give_your_opinion_button"
    #   'Log in to Give your Reasons'

    if !prefer_drag_prompt || !discussion_enabled
      translator "engage.give_your_opinion_button", 'Give your Opinion'
    else 
      translator "sliders.slide_prompt", 'Slide Your Overall Opinion'

  else if your_opinion.point_inclusions?.length > 0 
    translator "engage.update_your_opinion_button", 'Update your Reasons'

  else 
    translator "engage.give_your_reasons_button", 'Give your Reasons'


styles += """
  .ItemText .proposal-metadata  {
    margin-top: 8px;
  }


  .ItemText .proposal-metadata .separated {
    padding-right: 0px;
    margin-right: 14px;
    font-weight: 400;
  }

  .ItemText .proposal-metadata .separated.give-your-opinion {
    text-decoration: none;
    background-color: #f7f7f7;
    border-radius: 8px;
    padding: 4px 10px;
    border: 1px solid #eee;
    box-shadow: 0 1px 1px rgba(160,160,160,.8);
    white-space: nowrap;
  }


  .proposal-metadata .metadata-piece {
    font-size: 12px;
    color: #666;

    padding: 0;
    border-width: 0 0 1px 0;
    background: transparent;
    border-style: solid;
    border-color: #aaa;
    white-space: nowrap;
    transition: border-color 1s;
    cursor: pointer;
    text-decoration: none;
  } 
  .proposal-metadata .metadata-piece:hover,
  .proposal-metadata .metadata-piece:focus-within {
    border-color: #444;
  }

  /* 
  .proposal-metadata .small-give-your-opinion {
    color: white;
    background-color: #{focus_color()};
    font-weight: 600;
    cursor: pointer;
    font-family: #{customization('font')};
    border-radius: 8px;
    padding: 4px 12px;
    font-size: 10px;
  } */

  .is_expanded .proposal-metadata .small-give-your-opinion {
    display: none;
  }


"""


