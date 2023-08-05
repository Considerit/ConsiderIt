
window.ANIMATION_SPEED_ITEM_EXPANSION = 0.6

window.STAGE1_DELAY = 0
window.STAGE2_DELAY = ANIMATION_SPEED_ITEM_EXPANSION * 1.5
window.STAGE3_DELAY = ANIMATION_SPEED_ITEM_EXPANSION * .5

# window.PROPOSAL_ITEM_SPRING = # 4000 / 800 is decent
#   stiffness: 4000  #600
#   damping: 800

window.PROPOSAL_ITEM_SPRING = { stiffness: 130, damping: 17 } # 'gentle'

window.PROPOSAL_DESCRIPTION_MAX_HEIGHT_ON_EXPAND = 500

require './item_text'
require './item_opinion'
require './histogram_scores'




styles += """
  .prep_for_flip {
    transform-origin: 0px 0px;    
  }

  .proposal_item_animation {
    transition-duration: #{ANIMATION_SPEED_ITEM_EXPANSION}s;
    transition-timing-function: linear;
    transition-delay: 0ms;    
  }

  .ProposalItem, .show-all-proposals {
    position: relative;
  }


  .ProposalItem {
    min-height: 84px;
    list-style: none;    
    padding: 0px;
    margin: 0px 0px 32px 0px;

    top: 0;

    z-index: 1;
  }



  .is_expanded.ProposalItem {
    z-index: 3; /* put it above surrounding ProposalItems */

  } 

  @media #{LAPTOP_MEDIA} {
    .ProposalItem, .show-all-proposals {
      left: calc(-1 * var(--LIST_PADDING_LEFT));
      width: calc(100% + var(--LIST_PADDING_LEFT) + var(--LIST_PADDING_RIGHT) );
    }

    .show_list_title.ProposalItem {
      margin-bottom: 48px;
    }

  }

  @media #{NOT_LAPTOP_MEDIA} {
    .ProposalItem {
      margin-bottom: 64px;
    }

    .show_list_title.ProposalItem {
      margin-bottom: 78px;
    }

  }

  :not(.collapsing):not([data-in-viewport="true"]).is_collapsed.ProposalItem {
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


  /* partially implemented experimental lightbox */
  /* .is_expanded.ProposalItem:before {
    content: "";
    background-color: rgba(0,0,0,.15);
    position: absolute;
    height: 999999px;
    width: 999999px;
    top: -9999px;
    left: -9999px;
    z-index: 2;
  } */
"""



window.ProposalItem = ReactiveComponent
  displayName: 'ProposalItem'

  shouldFlipIgnore: -> 
    !(@local.in_viewport || (@list_order_state_changed && @props.num_proposals < 30))

  shouldFlip: ->
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
    if @expansion_state_updated() || el.classList.contains('animating-expansion')
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

  componentDidMount : -> @adjustExpansionBasedOnLocAndBackForwardButtons()
  componentDidUpdate : -> @adjustExpansionBasedOnLocAndBackForwardButtons()


  adjustExpansionBasedOnLocAndBackForwardButtons: ->
    # Toggle expand / collapse when the forward and back browser buttons are used, 
    # or for if an item is opened to directly
    loc = fetch('location')
    proposal = fetch @props.proposal

    already_toggling = @refs.proposal_item.classList.contains 'will-expand-toggle'

    if ((!@is_expanded && @props.accessed_by_url) || (@is_expanded && !@props.accessed_by_url)) && !@expansion_intv && !already_toggling && loc.triggered_by != 'toggle_expand'
      @expansion_intv = setInterval => 
        if collapsed_height_initialized[proposal.key]
          # wait to make the update so that we don't continuously trigger layout reflow
          requestAnimationFrame =>

            if ((@is_expanded && !@props.accessed_by_url) || (!@is_expanded && @props.accessed_by_url)) && !already_toggling              
              toggle_expand {proposal}

            clearInterval @expansion_intv
            @expansion_intv = null
      , 10 


  render : ->
    proposal = fetch @props.proposal
    loc = fetch('location') # subscribe to changes


    return if !proposal.name

    @is_expanded = @props.is_expanded

    @expansion_state_changed = (@expansion_state_changed? || @props.accessed_by_url) && @last_expansion != @is_expanded
    @list_order_state_changed = @list_order_state_changed? && @last_list_order != @props.list_order

    @last_expansion = @is_expanded
    @last_list_order = @props.list_order

    local_state = fetch shared_local_key proposal

    FLIPPED 
      key: proposal.key
      flipId: proposal.key
      # stagger: "item-wrapper-#{@props.list_key}"

      shouldInvert: @shouldFlip # still don't know why this needs to be shouldInvert, rather than shouldFlip...
      onStartImmediate: @onAnimationStart
      onComplete: @onAnimationDone

      shouldFlipIgnore: @shouldFlipIgnore


      LI
        ref: 'proposal_item'
        "data-widget": 'ProposalItem'
        key: proposal.key
        className: "ProposalItem #{if @is_expanded then 'is_expanded' else 'is_collapsed'} #{local_state.mode} #{if @props.show_list_title then 'show_list_title' else ''} prep_for_flip"
        "data-name": slugify(proposal.name)

        'data-visibility-name': 'ProposalItem'
        'data-receive-viewport-visibility-updates': 4
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
              show_list_title: @props.show_list_title
              list_title_color: @props.list_title_color

              shouldFlip: @shouldFlip
              shouldFlipIgnore: @shouldFlipIgnore

              expansion_state_changed: @expansion_state_updated

              hide_scores: @props.hide_scores
              accessed_by_url: @props.accessed_by_url




styles += """
  /* Container for the proposal */

  .proposal-block-container {
    display: flex;
    justify-content: center;
  }

  .is_collapsed .proposal-block-container {
    flex-direction: row;
  }

  .one-col .is_collapsed .proposal-block-container, 
  .is_expanded .proposal-block-container {
    flex-direction: column;
  }

  .proposal-block-wrapper {
    margin-top: 0;
    width: 100%;        
  }

  @media #{NOT_LAPTOP_MEDIA} {
    .proposal-block-wrapper {
      padding-bottom: 14px;
    }
  }


  /* The container for the opinion area */


  .opinion-block-wrapper {
    position: relative;
    z-index: 1;

    top: 10px;  /* move it down so that overflowing avatars don't get chopped off at the top */
  }

  .is_expanded .opinion-block-wrapper {
    margin-bottom: 24px;
    margin-top: 10px;
    padding-right: 0px;
    padding-bottom: 64px;    
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





  /* The wrapper for the expanded item */

  .opinion-block-wrapper::after {

    content: "";    
    opacity: 0;

    position: absolute;
    z-index: -1;

    top: 0px;
    height: 100%;

    box-shadow: 0px 0px 0px rgba(0,0,0,.25);    

    background-color: white;
    border-radius: 128px;

  }

  @media #{LAPTOP_MEDIA} {
    .opinion-block-wrapper, .opinion-block-wrapper::after {
      --EXPANDED_OPINION_BACKGROUND_GUTTER: 6px;
      --OPINION_BLOCK_WRAPPER_WIDTH: min( 1400px, 100vw - 2 * var(--EXPANDED_OPINION_BACKGROUND_GUTTER) );
    }

    .opinion-block-wrapper::after {
      --container_width: calc(var(--HOMEPAGE_WIDTH) + var(--LIST_PADDING_RIGHT) + var(--LIST_PADDING_LEFT));

      width: var(--OPINION_BLOCK_WRAPPER_WIDTH);
      left: calc( ( var(--container_width) - var(--OPINION_BLOCK_WRAPPER_WIDTH) ) / 2 );
    }

    .crafting .opinion-block-wrapper, .crafting .opinion-block-wrapper::after {
      --OPINION_BLOCK_WRAPPER_WIDTH: min( 2000px, max(95vw, min( 1300px, 100vw - 2 * var(--EXPANDED_OPINION_BACKGROUND_GUTTER) )) );
    }

    .is_expanded .opinion-block-wrapper::after {
      transition: opacity #{.5 * ANIMATION_SPEED_ITEM_EXPANSION}s, box-shadow #{.5 * ANIMATION_SPEED_ITEM_EXPANSION}s, width #{CRAFTING_TRANSITION_SPEED}ms, left #{CRAFTING_TRANSITION_SPEED}ms;
    }

  }  

  @media #{NOT_LAPTOP_MEDIA} {
    .opinion-block-wrapper::after {
      width: 100%;
      left: 0;
      border-radius: 64px;
    }
  }  


  .is_expanded .opinion-block-wrapper::after {
    opacity: 1;
    box-shadow: 0px 0px 3px rgba(0,0,0,.25);    
    transition: opacity #{.5 * ANIMATION_SPEED_ITEM_EXPANSION}s, box-shadow #{.5 * ANIMATION_SPEED_ITEM_EXPANSION}s;

  }

  .is_expanded:not(.flipping) .opinion-block-wrapper::after {
    background-image: linear-gradient(180deg, #f3f4f5 75px, #FFFFFF 150px, #FFFFFF 90%, #f3f4f5 96%);
  }


  .custom-shape-divider-top-1664224812 {
    pointer-events: none;
    position: absolute;
    top: -39px;
    left: 0;
    width: 100%;
    overflow: hidden;
    line-height: 0;
  }

  .custom-shape-divider-top-1664224812 svg {
    position: relative;
    display: block;
    width: calc(100% + 1.3px);
    height: 39px;
    transform: scaleY(-1);
    filter: drop-shadow(0px 1px 1px rgb(0 0 0 / 0.1));    
  }

  .is_expanded:not(.expanding) .custom-shape-divider-top-1664224812 svg {
    filter: drop-shadow(0px 0px 1px rgb(0 0 0 / 0.25));
  }
  .custom-shape-divider-top-1664224812 .shape-fill {
      fill: #f3f4f5;
  }


"""


ProposalItemWrapper = ReactiveComponent
  displayName: 'ProposalItemWrapper'

  render: ->
    proposal = fetch @props.proposal
    subdomain = fetch '/subdomain'
    # show_proposal_scores = !@props.hide_scores && customization('show_proposal_scores', proposal, subdomain) && WINDOW_WIDTH() > 955

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
                accessed_by_url: @props.accessed_by_url
                is_expanded: @props.is_expanded
                list_key: @props.list_key
                show_list_title: @props.show_list_title
                list_title_color: @props.list_title_color
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

          if @props.is_expanded
            DIV 
              className: "custom-shape-divider-top-1664224812"
              dangerouslySetInnerHTML: __html: """
                <svg data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 120" preserveAspectRatio="none">
                    <path d="M649.97 0L550.03 0 599.91 54.12 649.97 0z" class="shape-fill"></path>
                </svg>
                """

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
                hide_scores: @props.hide_scores


          BUTTON 
            className: 'bottom_closer'
            onClick: => 
              toggle_expand
                proposal: fetch @props.proposal
            onKeyPress: (e) => 
              if e.which == 32 || e.which == 13
                toggle_expand
                  proposal: fetch @props.proposal


            double_up_icon(40)

      



styles += """
  .ProposalBlock {
    display: flex;
  }

  .proposal-avatar-wrapper {
    flex-grow: 0;
    flex-shrink: 0;
    width: var(--PROPOSAL_AUTHOR_AVATAR_SIZE);
    transition-property: padding-top;    
  }
  .using_bullets .proposal-avatar-wrapper {
    width: 12px;
    padding-top: 2px;
  }
  .is_expanded .using_bullets .proposal-avatar-wrapper {
    padding-top: 9px;
  }

  .proposal-left-spacing {
    /* width: 1px;  // removing the spacing causes a bit of a jump when animating back */
    width: var(--LIST_PADDING_LEFT);
    flex-grow: 0;
    flex-shrink: 0;    
    position: relative;
  }

  .proposal-avatar-spacing {
    width: var(--PROPOSAL_AUTHOR_AVATAR_GUTTER);
    flex-grow: 0;
    flex-shrink: 0;
  }

  .proposal-slidergram-spacing {
    width: var(--PROPOSAL_AUTHOR_AVATAR_SIZE);
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


  .proposal-score-spacing {
    width: var(--LIST_PADDING_RIGHT);
    height: 2px;
    flex-grow: 0;
    flex-shrink: 0;        
  }

  @media #{TABLET_MEDIA} {
    .proposal-score-spacing {
      width: 20px;
    }
  }

  @media #{PHONE_MEDIA} {
    .proposal-score-spacing {
      width: 8px;
    }
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

    icons = customization('show_proposer_icon', proposal, subdomain)

  render: -> 
    proposal = fetch @props.proposal

    @is_expanded = @props.is_expanded

    icons = @should_use_avatar()


    DIV 
      className: "ProposalBlock #{if !icons then "using_bullets" else ''}"
      "data-widget": 'ProposalBlock'

      DIV 
        className: 'proposal-left-spacing'

        @draw_edit_and_delete()


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

        ItemText
          accessed_by_url: @props.accessed_by_url
          proposal: proposal.key
          is_expanded: @is_expanded
          list_key: @props.list_key
          show_list_title: @props.show_list_title
          list_title_color: @props.list_title_color
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
        top: if icons then 7
    
      if icons
        editor = proposal_editor(proposal)

        editor_opinion = _.findWhere proposal.opinions, {user: editor}    
        anonymous = proposal.hide_name  or  editor_opinion?.hide_name

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
            anonymous: anonymous

            style:
              height: PROPOSAL_AUTHOR_AVATAR_SIZE
              width: PROPOSAL_AUTHOR_AVATAR_SIZE

        else # no author specified
          SPAN 
            className: 'empty_pic'
            style: 
              height: "var(--PROPOSAL_AUTHOR_AVATAR_SIZE)"
              width: "var(--PROPOSAL_AUTHOR_AVATAR_SIZE)"
              display: 'inline-block'
              border: "2px dashed #ddd"
      else
        @props.icon?() or SVG 
          className: 'proposal_bullet'
          key: 'bullet'
          width: 8
          viewBox: '0 0 200 200' 
          CIRCLE cx: 100, cy: 100, r: 80, fill: '#000000'


  draw_edit_and_delete: ->
    proposal = fetch @props.proposal
    subdomain = fetch '/subdomain'
    can_edit = permit('update proposal', proposal, subdomain) > 0

    return SPAN null if !can_edit

    DIV
      className: 'edit_and_delete_block'


      BUTTON 
        className: 'like_link'   
        "aria-label": TRANSLATE 'engage.edit_button', 'edit'
        "data-tooltip": TRANSLATE 'engage.edit_button', 'edit'
        style: 
          marginRight: 4

        onClick: (e) => 
          proposal_editing = fetch('proposal_editing')
          proposal_editing.editing = proposal.key

          proposal_editing.callback = =>
            delete @local.collapsed_title_height
            save @local

          save proposal_editing

          e.stopPropagation()
          e.preventDefault()
          
        edit_icon 18, 18, '#444'

      if permit('delete proposal', proposal, subdomain) > 0
        BUTTON
          className: 'like_link'

          "data-tooltip": TRANSLATE 'engage.delete_button', 'delete'
          "aria-label": TRANSLATE 'engage.delete_button', 'delete'

          onClick: => 
            if confirm('Delete this proposal forever?')
              destroy(proposal.key)
              loadPage('/')


          trash_icon 18, 18, '#444'



styles += """
  .edit_and_delete_block {
    opacity: 0;
    transition: opacity 1s;
    position: absolute;
    padding-top: 12px;
  }

  .is_expanded .edit_and_delete_block, 
  .ProposalItem:hover .edit_and_delete_block,
  .ProposalItem:focus-within .edit_and_delete_block {
    opacity: 1;    
  }

  @media #{LAPTOP_MEDIA} {
    .edit_and_delete_block {
      top: 7px;
      left: 14px;
    }
    .is_expanded .edit_and_delete_block, 
    .ProposalItem:hover .edit_and_delete_block,
    .ProposalItem:focus-within .edit_and_delete_block {
      right: 12px;
      left: auto;
    }

  }  

  @media #{NOT_LAPTOP_MEDIA} {
    .edit_and_delete_block {
      left: calc(var(--PROPOSAL_AUTHOR_AVATAR_SIZE) / 2 - 18px / 2 + 4px);
      top: calc(var(--PROPOSAL_AUTHOR_AVATAR_SIZE) + 6px);
    }

  }  

  .edit_and_delete_block button {
    opacity: .3;
    transition: opacity .6s ease;
  }

  .edit_and_delete_block button:hover,
  .edit_and_delete_block button:focus-within {
    opacity: 1;
  }

"""







styles += """

  .animating-expansion .histoavatars-container {
    content-visibility: visible;
  }

"""



proposal_url = (proposal) ->
  proposal = fetch proposal
  return "/#{proposal.slug}"

window.personal_view_available = (proposal) ->
  proposal = fetch proposal  
  !TABLET_SIZE() && proposal.active && customization('discussion_enabled', proposal) 

window.toggle_expand = ({proposal, ensure_open, prefer_personal_view}) ->
  proposal = fetch proposal

  el = document.querySelector(".proposal-title[data-proposal='#{proposal.key}']")
  list_key = el.closest('.List').getAttribute('data-key')


  expanded_state = fetch "proposal_expansions-#{list_key}"

  return if ensure_open && expanded_state[proposal.key]

  current_user = fetch '/current_user'
  opinion_views = fetch 'opinion_views'
  just_you = opinion_views.active_views['just_you']

  personal_view_preferred = prefer_personal_view || (just_you && current_user.logged_in)

  mode = if personal_view_available(proposal) && personal_view_preferred then 'crafting' else 'results' 

  parent = el.closest('.ProposalItem')

  parent.classList.add 'will-expand-toggle'
  $$.ensureInView el,
    dom_possibly_shifting: true
    extra_height: if !expanded_state[proposal.key] then 4000 else 0
    force: mode == 'crafting'
    speed_mult: .5
    callback: =>
      loc = fetch 'location'
      expanded_state[proposal.key] = !expanded_state[proposal.key]
      parent.classList.remove 'will-expand-toggle'

      if !expanded_state[proposal.key]
        delete expanded_state[proposal.key]

        update_proposal_mode proposal, null
        loadPage "/", (if loc.query_params?.tab then {tab: loc.query_params.tab} else {}), 'toggle_expand'
      else 
        loadPage proposal_url(proposal), (if loc.query_params?.selected then {selected: loc.query_params.selected} else {}), 'toggle_expand'

        update_proposal_mode proposal, mode

      save expanded_state


