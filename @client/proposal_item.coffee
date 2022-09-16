require './opinion_block'


window.ANIMATION_SPEED_ITEM_EXPANSION = 0.6
# window.PROPOSAL_ITEM_SPRING = # 4000 / 800 is decent
#   stiffness: 4000  #600
#   damping: 800

window.PROPOSAL_ITEM_SPRING = 'gentle'

window.PROPOSAL_DESCRIPTION_MAX_HEIGHT_ON_EXPAND = 500

styles += """
  .prep_for_flip {
    transform-origin: 0px 0px;    
  }

  .proposal_item_animation {
    transition-duration: #{ANIMATION_SPEED_ITEM_EXPANSION}s;
    transition-timing-function: linear;
    transition-delay: 0ms;    
  }

  .ProposalItem {
    min-height: 84px;
    position: relative;
    list-style: none;    
    padding: 0px;
    margin: 0;

    top: 0;

    left: calc(-1 * var(--LIST_PADDING-LEFT));
    width: calc(100% + var(--LIST_PADDING-LEFT) + var(--LIST_PADDING-RIGHT) );

  }

  .is_expanded.ProposalItem {
    left: calc(-4 * var(--LIST_PADDING-LEFT));
    width: calc(100% + 8 * var(--LIST_PADDING-LEFT) );

    top: -24px;

    z-index: 2; /* put it above surrounding ProposalItems */

  } 


  :not(.collapsing).is_collapsed.ProposalItem {
    content-visibility: auto; /* Content-visibility can be very expensive. Specifically, React Flip Toolkit
                                 has to call getBoundingClientRect on all Flipped elements to figure out how 
                                 to animate them. content-visibility will prevent the rendering
                                 of out-of-viewport items (as intended!), but this means that getBoundingClientRect
                                 call on an unpainted item will trigger a reflow and style re-calc. *for 
                                 each element*. This creates significant jank in the beginning of an animation
                                 when there are a decent number of out-of-viewport items.  
                                 Note: I've made a forked version of react-flip-trip that almost entirely
                                       eliminates this expense. But content-visibility is also expensive when
                                       scrolling long lists.
                                 */    
  }

  /* When changing list order, content-visibility: auto cuts things off */

  .list_order_event .is_collapsed.ProposalItem {
    content-visibility: visible;
  }


  /* The wrapper for the expanded item */

  .ProposalItem::after {
    content: "";    
    opacity: 0;

    transition-property: opacity;

    position: absolute;
    z-index: -1;

    left: 0px;
    top: 0px;
    width: 100%;
    height: 100%;

    background-image: linear-gradient(180deg, #F6F7F8 0%, #F6F7F8 4%, #FFFFFF 150px, #FFFFFF 92%, #F6F7F8 100%);
    box-shadow: 0 1px 3px rgba(0,0,0,.25);    
    border-radius: 4px;    
  }

  .is_expanded.animation-resting.ProposalItem::after {
    opacity: 1;
    transition-duration: #{1 * ANIMATION_SPEED_ITEM_EXPANSION}s;
  }

  .is_collapsed.ProposalItem::after {
    transition-duration: #{ANIMATION_SPEED_ITEM_EXPANSION / 10 }s;
  }

  .collapsing.ProposalItem::after {
    transition-duration: #{ANIMATION_SPEED_ITEM_EXPANSION / 10 }s;

    opacity: 0;
  }
"""





window.ProposalItem = ReactiveComponent
  displayName: 'ProposalItem'

  shouldFlipIgnore: -> 
    # !(@expansion_state_changed || @local.in_viewport || (@list_order_state_changed && @props.num_proposals < 30))
    !(@local.in_viewport || (@list_order_state_changed && @props.num_proposals < 30))

  shouldFlip: ->
    # # console.log "SHOULD FLIP?", @props.proposal, @expansion_state_changed || (@list_order_state_changed && @props.num_proposals < 30)
    # @expansion_state_changed || (@list_order_state_changed && @props.num_proposals < 30)
    # @expansion_state_changed || (@list_order_state_changed && @props.num_proposals < 30)
    @local.in_viewport || (@list_order_state_changed && @props.num_proposals < 30)

  expansion_state_updated: ->
    @expansion_state_changed

  onAnimationStart: (el) -> 
    if @expansion_state_updated()
      @animating = true
      direction = if @is_expanded then 'expanding' else 'collapsing'
      el.classList.add "animating-expansion", direction
      el.classList.remove "animation-resting"


  onAnimationDone: (el, dd) ->
    if @expansion_state_updated()

      direction = if @is_expanded then 'expanding' else 'collapsing'        
      el.classList.remove 'animating-expansion', direction
      el.classList.add "animation-resting"

      # Should only happen if the animation has completed, not if it is interrupted.
      # Otherwise the next animation will be messed up. 
      @animating = false 
      requestAnimationFrame => 
        if !@animating
          @expansion_state_changed = false 
          @list_order_state_changed = false


  render : ->
    proposal = fetch @props.proposal

    @is_expanded = @props.is_expanded

    @expansion_state_changed = (@expansion_state_changed? || @props.accessed_by_url) && @last_expansion != @is_expanded
    @list_order_state_changed = @list_order_state_changed? && @last_list_order != @props.list_order

    @last_expansion = @is_expanded
    @last_list_order = @props.list_order



    # console.log "RENDERING", @props.proposal, @expansion_state_changed #, @local.in_viewport, {safe_for_flip_to_ignore}
    FLIPPED 
      key: proposal.key
      flipId: proposal.key
      # stagger: "item-wrapper-#{@props.list_key}"

      shouldInvert: @shouldFlip # TODO: why should this be shouldInvert, rather than shouldFlip? 
      onStartImmediate: @onAnimationStart
      onComplete: @onAnimationDone

      shouldFlipIgnore: @shouldFlipIgnore


      LI
        "data-widget": 'ProposalItem'
        key: proposal.key
        className: "prep_for_flip ProposalItem #{if @is_expanded then 'is_expanded' else 'is_collapsed'}"
        "data-name": slugify(proposal.name)

        'data-visibility-name': 'ProposalItem'
        'data-receive-viewport-visibility-updates': 2
        'data-component': @local.key

        id: 'p' + (proposal.slug or "#{proposal.id}").replace('-', '_')  # Initial 'p' is because all ids must begin 
                                                                         # with letter. seeking to hash was failing 
                                                                         # on proposals whose name began with number.
        FLIPPED 
          inverseFlipId: proposal.key
          shouldInvert: @shouldFlip
          shouldFlipIgnore: @shouldFlipIgnore

          DIV 
            className: 'prep_for_flip'

            ProposalItemWrapper
              proposal: @props.proposal
              is_expanded: @is_expanded
              list_key: @props.list_key
              show_category: @props.show_category
              category_color: @props.category_color

              shouldFlip: @shouldFlip
              shouldFlipIgnore: @shouldFlipIgnore

              expansion_state_changed: @expansion_state_updated




styles += """
  /* Container for the proposal */

  .proposal-block-container {
    display: flex;
    justify-content: center;
    padding-bottom: 24px;
  }

  .is_collapsed .proposal-block-container {
    flex-direction: row;
  }
  .is_expanded .proposal-block-container {
    flex-direction: column;
  }

  .proposal-block-wrapper {
    margin-top: 0;
    width: 100%;        
  }

  .is_expanded .proposal-block-wrapper {
    margin-top: 24px;
  }


  /* The container for the opinion area */


  .opinion-block-wrapper {
    padding-right: 48px;

    position: relative;
    z-index: 1;

    top: 10px;  /* move it down so that overflowing avatars don't get chopped off at the top */
  }

  .is_expanded .opinion-block-wrapper {
    margin-bottom: 24px;
    margin-top: 10px;
    padding-right: 0px;
  }


  /* The double up arrow at the bottom of an expanded proposal that will collapse the proposal */

  .bottom_closer {
    position: absolute;
    left: calc(50% - 26px);
    bottom: -26px;
    cursor: pointer;
    background-color: transparent;
    border: none;
    opacity: 0;        
  }

  :not(.expanding).is_expanded .bottom_closer {
    transition: opacity #{2 * ANIMATION_SPEED_ITEM_EXPANSION}s;    
    opacity: 1;
    display: inline-block;    
  }
  .is_collapsed .bottom_closer {
    pointer-events: none;
  }



  .debugging .opinion-block-wrapper {
    background-color: #eee;    
  }
  .debugging .proposal-block-wrapper {
    background-color: #eaeaea;
  }


"""


ProposalItemWrapper = ReactiveComponent
  displayName: 'ProposalItemWrapper'

  toggle_expand: -> 
    toggle_expand(@props.list_key, @props.proposal)

  toggle_expand_key: (e) ->
    if e.which == 32 || e.which == 13
      toggle_expand(@props.list_key, @props.proposal)


  render: ->
    proposal = fetch @props.proposal

    DIV 
      className: "proposal-block-container"

      FLIPPED
        flipId: "proposal-block-#{proposal.key}"
        # stagger: "content-#{@props.list_key}"
        shouldFlip: @props.shouldFlip
        shouldFlipIgnore: @props.shouldFlipIgnore
        # delayUntil: proposal.key

        DIV 
          className: 'proposal-block-wrapper prep_for_flip'

          FLIPPED 
            inverseFlipId: "proposal-block-#{proposal.key}"
            shouldInvert: @props.shouldFlip
            shouldFlipIgnore: @props.shouldFlipIgnore

            DIV 
              className: 'prep_for_flip' # annoying empty DIV because FLIPPED doesn't seem to transfer to a new component

              ProposalBlock
                proposal: proposal.key
                is_expanded: @props.is_expanded
                list_key: @props.list_key
                show_category: @props.show_category
                category_color: @props.category_color
                shouldFlip: @props.shouldFlip
                shouldFlipIgnore: @props.shouldFlipIgnore
                expansion_state_changed: @props.expansion_state_changed

      DIV 
        className: "proposal-slidergram-spacing"


      FLIPPED
        flipId: "opinion-block-#{proposal.key}"
        # stagger: "content-#{@props.list_key}"
        shouldFlip: @props.shouldFlip
        shouldFlipIgnore: @props.shouldFlipIgnore
        # delayUntil: proposal.key

        DIV 
          className: 'prep_for_flip opinion-block-wrapper'

          FLIPPED 
            inverseFlipId: "opinion-block-#{proposal.key}"
            shouldInvert: @props.shouldFlip
            shouldFlipIgnore: @props.shouldFlipIgnore

            DIV 
              className: 'prep_for_flip' # annoying empty DIV because FLIPPED doesn't seem to transfer to a new component

              OpinionBlock
                proposal: proposal.key
                is_expanded: @props.is_expanded
                list_key: @props.list_key
                shouldFlip: @props.shouldFlip
                shouldFlipIgnore: @props.shouldFlipIgnore

      BUTTON 
        className: 'bottom_closer'
        onClick: @toggle_expand
          
        onKeyPress: @toggle_expand_key

        double_up_icon(40)

      



styles += """
  .ProposalBlock {
    display: flex;
  }

  .ProposalBlock .proposal-avatar-wrapper {
    flex-grow: 0;
    flex-shrink: 0;
    /* width: var(--PROPOSAL_AUTHOR_AVATAR_SIZE); */
    transition-property: padding-top;    
  }
  .is_expanded .using_bullets .proposal-avatar-wrapper {
    padding-top: 4px;
  }

  .proposal-left-spacing {
    /* width: 1px;  // removing the spacing causes a bit of a jump when animating back */
    width: var(--LIST_PADDING-LEFT);
    height: var(--PROPOSAL_AUTHOR_AVATAR_SIZE);
    flex-grow: 0;
    flex-shrink: 0;    
  }
  .is_expanded .proposal-left-spacing {
    width: calc(4 * var(--LIST_PADDING-LEFT));
  }

  .proposal-avatar-spacing {
    width: var(--PROPOSAL_AUTHOR_AVATAR_GUTTER);
    height: var(--PROPOSAL_AUTHOR_AVATAR_SIZE);
    flex-grow: 0;
    flex-shrink: 0;
  }

  .proposal-slidergram-spacing {
    width: var(--PROPOSAL_AUTHOR_AVATAR_SIZE);
    height: var(--PROPOSAL_AUTHOR_AVATAR_SIZE);
    flex-grow: 0;
    flex-shrink: 0;    
  }

  .is_expanded .proposal-slidergram-spacing {
    width: 0;
    height: 0;
  }


  .using_bullets .proposal-avatar-spacing {
    width: var(--PROPOSAL_BULLET_GUTTER);
  }



  .ProposalBlock .avatar, .ProposalBlock .proposal_pic {
    height: var(--PROPOSAL_AUTHOR_AVATAR_SIZE);
    width: var(--PROPOSAL_AUTHOR_AVATAR_SIZE);
    border-radius: 0;  
  }



  .ProposalBlock .proposal-text {
    flex-grow: 1;
    flex-shrink: 1; 
  }


"""









# ProposalBlock lays out the avatar/bullet, spacing, and the proposal text block
ProposalBlock = ReactiveComponent
  displayName: 'ProposalBlock'

  should_use_avatar: ->   # icon or bullet
    proposal = fetch @props.proposal
    subdomain = fetch '/subdomain'

    icons = customization('show_proposer_icon', proposal, subdomain) && !@props.hide_icons && !customization('anonymize_everything')

  render: -> 
    proposal = fetch @props.proposal

    @is_expanded = @props.is_expanded

    icons = @should_use_avatar()


    DIV 
      className: "ProposalBlock #{if !icons then "using_bullets" else ''}"
      "data-widget": 'ProposalBlock'

      DIV 
        className: 'proposal-left-spacing'

      FLIPPED  # needed for list-order change
        flipId: "proposal-avatars-#{proposal.key}"
        shouldFlip: @props.shouldFlip
        shouldFlipIgnore: @props.shouldFlipIgnore
        translate: true
        className: 'prep_for_flip'

        DIV 
          className: 'proposal-avatar-wrapper proposal_item_animation'
          @draw_avatar_or_bullet()

      DIV 
        className: "proposal-avatar-spacing"


      DIV 
        className: 'proposal-text'

        ProposalText
          proposal: proposal.key
          is_expanded: @is_expanded
          list_key: @props.list_key
          show_category: @props.show_category
          category_color: @props.category_color
          shouldFlip: @props.shouldFlip
          shouldFlipIgnore: @props.shouldFlipIgnore
          expansion_state_changed: @props.expansion_state_changed

  draw_avatar_or_bullet: ->
    proposal = fetch @props.proposal
    current_user = fetch '/current_user'

    icons = @should_use_avatar()

    DIV 

      style: 
        position: 'relative'
        top: if icons then 4


      if icons
        editor = proposal_editor(proposal)

        if proposal.pic 
          IMG
            className: 'proposal_pic'
            src: proposal.pic 

        else if editor
          # Person's icon

          Avatar
            key: editor
            user: editor
            img_size: 'large'
            style:
              height: PROPOSAL_AUTHOR_AVATAR_SIZE
              width: PROPOSAL_AUTHOR_AVATAR_SIZE

        else # no author specified
          SPAN 
            className: 'empty_pic'
            style: 
              height: 36
              width: 36
              display: 'inline-block'
              border: "2px dashed #ddd"
      else
        @props.icon?() or SVG 
          className: 'proposal_bullet'
          key: 'bullet'
          width: 8
          viewBox: '0 0 200 200' 
          CIRCLE cx: 100, cy: 100, r: 80, fill: '#000000'













TITLE_FONT_SIZE_COLLAPSED = 19

styles += """

  :root {
    --proposal_title_underline_color: #000000;
  }

  .ProposalText .proposal-title {
    max-width: 900px;
  }

  .ProposalText.has-description .proposal-title {
    margin-bottom: 8px;
  }

  .ProposalText .proposal-title-text {
    # transition-property: transform;    
    transform: scale(1);
    transform-origin: 0 0;

    font-size: #{TITLE_FONT_SIZE_COLLAPSED}px;
    font-weight: 700;
    cursor: pointer;
    color: #111;
  }

  .proposal-title-invert-container {
    position: relative;
    z-index: 1;
  } 

  .is_expanded .ProposalText .proposal-title-invert-container {
    position: absolute;
  }

  .is_expanded .ProposalText .proposal-title-text {
    transform: scale(1.5);
  } 


  .ProposalText .proposal-title-text-inline {
    border-bottom-width: 2px;
    border-style: solid;
    border-color: #{focus_blue + "ad"}; /* with some transparency */
    transition: border-color 1s;


  }

  .ProposalText .proposal-title-text-inline:hover {
    border-color: #000;
  }

  .ProposalText .proposal-description-wrapper {
    max-width: 600px;  
  }


  .ProposalText .proposal-description {
    overflow: hidden;

    font-size: 16px;
    font-weight: 400;

    // max-height: 50px; /* this value will get overridden to min(estimated_desc_height, PROPOSAL_DESCRIPTION_MAX_HEIGHT_ON_EXPAND) in javascript */

    transition-property: color;

    // padding: 8px 0px;

    color: #333;
  }

  .is_collapsed .ProposalText .proposal-description {
    max-height: 50px;
    color: #555;
  }

  .is_expanded .ProposalText .proposal-description {
    max-height: 500px;
  }

  .is_expanded .ProposalText .proposal-description.fully_expanded {
    max-height: 9999px;
  }


  .edit_and_delete_block {
    opacity: 0;
    transition: opacity 1s;
  }
  .ProposalItem:hover .edit_and_delete_block, .is_expanded .edit_and_delete_block {
    opacity: 1;
  }

"""

proposal_url = (proposal, prefer_crafting_page) ->
  # The special thing about this function is that it only links to
  # "?results=true" if the proposal has an opinion.

  proposal = fetch proposal
  result = "/#{proposal.slug}"
  subdomain = fetch '/subdomain'

  if TWO_COL() || !proposal.active || (!customization('show_crafting_page_first', proposal, subdomain) && !prefer_crafting_page) || !customization('discussion_enabled', proposal, subdomain)
    result += '?results=true'

  return result

toggle_expand = (list_key, proposal, ensure_open) ->
  proposal = fetch proposal
  expanded_state = fetch "proposal_expansions-#{list_key}"

  return if ensure_open && expanded_state[proposal.key]

  el = document.querySelector(".proposal-title[data-proposal='#{proposal.key}']")
  $$.ensureInView el,
    callback: =>
      expanded_state[proposal.key] = !expanded_state[proposal.key]
      if !expanded_state[proposal.key]
        delete expanded_state[proposal.key]
        loadPage "/"
      else 
        loadPage proposal_url(proposal)

      save expanded_state



collapsed_item_width = null

# Whenever the window resizes, we need to invalidate the stored sizes
requestAnimationFrame ->
  window.addEventListener "resize", ->
    collapsed_item_width = null
    for k,v of arest.cache
      if k[0] != '/' && v.collapsed_title_height?
        delete v.collapsed_title_height
        save v



ProposalText = ReactiveComponent
  displayName: 'ProposalText'


  toggle_expand: -> 
    toggle_expand(@props.list_key, @props.proposal)

  render: -> 
    proposal = fetch @props.proposal

    @is_expanded = @props.is_expanded

    has_description = proposal.description || customization('proposal_description')

    FLIPPED
      flipId: "proposal-title-starter-#{proposal.key}"
      shouldFlip: @props.shouldFlip
      shouldFlipIgnore: @props.shouldFlipIgnore
      opacity: true
      onSpringUpdate: if @props.expansion_state_changed() then (value) => 
        if @props.expansion_state_changed()            
          start = if @is_expanded then 1 else 1.5 
          end = if @is_expanded then 1.5 else 1 
          @refs.proposal_title_text.style.transform = "scale(#{ start + (end - start) * value })"

      DIV 
        id: "proposal-text-#{proposal.id}"
        "data-widget": 'ProposalText'
        className: "ProposalText #{if has_description then 'has-description' else 'no-description'}"
        ref: 'root'

        'data-visibility-name': 'ProposalText'
        'data-receive-viewport-visibility-updates': 2
        'data-component': @local.key


        STYLE 
          dangerouslySetInnerHTML: __html: """
             .is_collapsed #proposal-text-#{proposal.id} .proposal-title {
               height: #{@local.collapsed_title_height}px;
             }

             .is_expanded #proposal-text-#{proposal.id} .proposal-title {
               height: #{1.5 * @local.collapsed_title_height}px;
             }

             #proposal-text-#{proposal.id} .proposal-title-text {
                width: #{collapsed_item_width}px;
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
                flipId: "proposal-title-placer-#{proposal.key}"
                shouldInvert: @props.shouldFlip
                shouldFlipIgnore: @props.shouldFlipIgnore


                DIV 
                  className: 'prep_for_flip proposal-title-invert-container' 
                          # a container for the flipper's transform to apply to w/o messing 
                          # with the transform applied to the title text

                  DIV 
                    ref: 'proposal_title_text'
                    className: 'proposal-title-text'              

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

              @draw_edit_and_delete()


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



  setCollapsedSizes: (expand_after_set) ->
    return if !@waitForFonts(=> @setCollapsedSizes(expand_after_set)) || @local.collapsed_title_height? || !@local.in_viewport #!@refs.root.closest(".ProposalItem[data-in-viewport='true']")
    
    title_el = @refs.proposal_title_text

    if !@is_expanded && !collapsed_item_width?
      collapsed_item_width = title_el.clientWidth

    
    if @is_expanded
      @local.collapsed_title_height = title_el.getBoundingClientRect().height

    else 
      @local.collapsed_title_height = title_el.clientHeight      

    save @local

    # wait to make the update so that we don't continuously trigger layout reflow
    if expand_after_set
      requestAnimationFrame => 
        # If we've loaded this item by url, ensure that it is expanded
        # Doing this here because we have to do it after we capture the
        # collapsed size.
        toggle_expand @props.list_key, fetch(@props.proposal), true


  componentDidMount: ->
    requestAnimationFrame =>
      loc = fetch 'location'
      @setCollapsedSizes(loc.url == "/#{fetch(@props.proposal).slug}")

  componentDidUpdate: ->
    requestAnimationFrame =>
      loc = fetch 'location'
      @setCollapsedSizes()




  draw_description: ->  
    proposal = fetch @props.proposal

    return DIV null if !proposal.description

    if cust_desc = customization('proposal_description')
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
      result = DIV dangerouslySetInnerHTML:{__html: proposal.description}

    DIV 
      className: 'proposal-description wysiwyg_text proposal_item_animation'
      ref: 'proposal_description'

      DIV 
        style:
          # maxHeight: if @local.description_collapsed then @max_description_height
          # overflow: if @local.description_collapsed then 'hidden'
          display: if embedded_demo() then 'none'

        FLIPPED 
          inverseFlipId: "proposal-description-placer-#{proposal.key}"
          scale: true # this allows it to expand down, but also allows the description to move when sorting happens
          shouldInvert: @shouldFlip
          shouldFlipIgnore: @shouldFlipIgnore

          result


  draw_metadata: -> 
    proposal = fetch @props.proposal

    subdomain = fetch '/subdomain'
    icons = customization('show_proposer_icon', proposal, subdomain) && !@props.hide_icons && !customization('anonymize_everything')
    opinion_publish_permission = permit('publish opinion', proposal, subdomain)

    # FLIPPED
    #   flipId: "proposal-metadata-#{proposal.key}"
    #   translate: true
    #   scale: false
    #   shouldFlip: @shouldFlip


    DIV
      className: 'proposal-metadata monospaced'   

      if customization('proposal_meta_data', null, subdomain)?
        customization('proposal_meta_data', null, subdomain)(proposal)

      else if !@props.hide_metadata && customization('show_proposal_meta_data', null, subdomain)
        show_author_name_in_meta_data = !icons && (editor = proposal_editor(proposal)) && editor == proposal.user && !customization('anonymize_everything')
        show_timestamp = !screencasting() && subdomain.name != 'galacticfederation'
        show_discussion_info = customization('discussion_enabled', proposal, subdomain)
        show_cluster = @props.show_category && proposal.cluster
        is_closed = opinion_publish_permission == Permission.DISABLED
        read_only = opinion_publish_permission == Permission.INSUFFICIENT_PRIVILEGES

        [
          if show_timestamp
            SPAN 
              key: 'date'
              className: 'separated'

              # if !show_author_name_in_meta_data
              #   TRANSLATE 'engage.proposal_metadata_date_added', "Added: "
              
              prettyDate(proposal.created_at)


          if show_author_name_in_meta_data
            SPAN 
              key: 'author name'
              className: 'separated'

              TRANSLATE
                id: 'engage.proposal_author'
                name: fetch(editor)?.name 
                " by {name}"

          if show_discussion_info
            [
              SPAN
                key: 'proposal-link'
                # href: proposal_url(proposal)
                # "data-no-scroll": EXPAND_IN_PLACE
                # className: 'separated'
                className: 'separated pros_cons_count monospaced'
                onClick: => toggle_expand(@props.list_key, proposal)
                  
                onKeyPress: (e) => 
                  if e.which == 32 || e.which == 13
                    toggle_expand(@props.list_key, proposal)

                TRANSLATE
                  key: 'point-count'
                  id: "engage.point_count"
                  cnt: proposal.point_count

                  "{cnt, plural, one {# pro or con} other {# pros & cons}}"

              if false && proposal.active && permit('create point', proposal, subdomain) > 0 && WINDOW_WIDTH() > 955

                SPAN 
                  key: 'give-opinion'
                  className: 'pros_cons_count'
                  # style: 
                  #   color: focus_blue
                  #   borderColor: focus_blue      
                  onClick: => toggle_expand(@props.list_key, proposal)
                    
                  onKeyPress: (e) => 
                    if e.which == 32 || e.which == 13
                      toggle_expand(@props.list_key, proposal)


                  
                  TRANSLATE
                    id: "engage.add_your_own"

                    "give your opinion"
                  SPAN 
                    style: 
                      borderBottom: 'none'
                    " >>"
            ]
        ]



      if show_cluster
        SPAN 
          style: 
            padding: '1px 2px'
            color: @props.category_color or 'black'
            fontWeight: 500

          get_list_title "list/#{proposal.cluster}", true, subdomain

      if is_closed
        SPAN 
          style: 
            padding: '0 16px'
          TRANSLATE "engage.proposal_closed.short", 'closed'

      else if read_only
        SPAN 
          style: 
            padding: '0 16px'
          TRANSLATE "engage.proposal_read_only.short", 'read-only'


  draw_edit_and_delete: ->
    proposal = fetch @props.proposal
    subdomain = fetch '/subdomain'
    can_edit = permit('update proposal', proposal, subdomain) > 0

    return SPAN null if !can_edit

    DIV
      className: 'edit_and_delete_block'

      BUTTON 
        className: 'like_link'              
        onClick: (e) => 
          proposal_editing = fetch('proposal_editing')
          proposal_editing.editing = proposal.key

          proposal_editing.callback = =>
            delete @local.collapsed_title_height
            save @local

          save proposal_editing

          e.stopPropagation()
          e.preventDefault()
          
        style:
          marginRight: 10
          color: focus_color()
          padding: 0
          fontSize: 12
          fontWeight: 600
        TRANSLATE 'engage.edit_button', 'edit'

      if permit('delete proposal', proposal, subdomain) > 0
        BUTTON
          className: 'like_link'
          style:
            marginRight: 10
            color: focus_color()
            padding: 0
            fontSize: 12
            fontWeight: 600

          onClick: => 
            if confirm('Delete this proposal forever?')
              destroy(proposal.key)
              loadPage('/')
          TRANSLATE 'engage.delete_button', 'delete'




styles += """
  .ProposalText .proposal-metadata {
    font-size: 12px;
    color: #555;
    margin-top: 8px;
    height: 20px;
  }


  .ProposalText .proposal-metadata .separated {
    padding-right: 4px;
    margin-right: 12px;
    font-weight: 400;
  }

  .ProposalText .proposal-metadata .separated.give-your-opinion {
    text-decoration: none;
    background-color: #f7f7f7;
    border-radius: 8px;
    padding: 4px 10px;
    border: 1px solid #eee;
    box-shadow: 0 1px 1px rgba(160,160,160,.8);
    white-space: nowrap;
  }


  .proposal-metadata .pros_cons_count {
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
  .proposal-metadata .pros_cons_count:hover {
    border-color: #444;
  }


"""


styles += """

  .animating-expansion .histoavatars-container {
    content-visibility: visible;
  }

  .slider {
    opacity: 1;
  }
  .flipping .slider {
    opacity: 0; 
  }
"""



