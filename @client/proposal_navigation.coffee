require './customizations'
require './shared'


window.GroupedProposalNavigation = (args) -> 
  proposals = fetch('/proposals').proposals

  heading_style = _.defaults {}, customization('list_title_style'),
    fontSize: 36
    fontWeight: 700
    textAlign: 'center'
    marginBottom: 18

  sections = get_tabs() 
  if !sections or sections.length == 0
    sections = [{
      name: 'all' 
      lists: get_all_lists()
    }]

  active_list = "list/#{args.proposal.cluster or 'Proposals'}"

  local = fetch 'popnav'
  if !local.show?
    local.show = {}
    local.show[active_list] = true 

  toggle_list = (lst) ->
    local.show[lst] = !local.show[lst]
    save local 

  loc = fetch 'location'
  hash = loc.url.split('/')[1].replace('-', '_')

  current_section = null

  DIV 
    style: {}

    H2
      style: heading_style

      TRANSLATE
        id: 'engage.navigate_elsewhere.groupednav.header'
        'Done? Navigate to a different question'

    if !proposals || proposals.length == 0 
      LOADING_INDICATOR

    else 

      UL 
        style:
          listStyle: 'none'
          padding: 0

        for section in sections 
          name = section.name
          lists = section.lists
          active_section = false 

          lists = lists_for_tab(name)

          total_proposals = 0
          for list in lists
            if active_list == list.key
              active_section = true 
              current_section = name
            total_proposals += (list.proposals or []).length            

          continue if total_proposals == 0 || name == 'Show all'

          LI 
            style: 
              marginBottom: 24


            if sections.length > 1
              H3
                style: {} 
                  

                A 
                  href: "/?tab=#{encodeURIComponent(name)}#active_tab"
                  style: 
                    fontSize: 28
                    backgroundColor: '#ddd'
                    cursor: 'pointer'
                    color: "#888"
                    fontWeight: 700
                    display: 'block'
                    marginLeft: -34
                    padding: '0 34px'

                  name

            if active_section

              UL 
                style: 
                  listStyle: 'none'
                  marginTop: 14

                for list in lists 
                  is_collapsed = !local.show[list.key] 
                  tw = if is_collapsed then 15 else 20
                  th = if is_collapsed then 20 else 15

                  heading_text = get_list_title(list.key, true)

                  continue if (list.proposals or []).length == 0 

                  do (list) => 
                    LI 
                      style: {}


                      if lists.length > 1 || sections.length == 1
                        H4 
                          style: 
                            marginBottom: 12 
                            cursor: 'pointer'
                            position: 'relative'

                          onKeyDown: (e) -> 
                            if e.which == 13 || e.which == 32 # ENTER or SPACE
                              toggle_list list.key
                              e.preventDefault()
                          onClick: -> 
                            toggle_list list.key
                            document.activeElement.blur()

                          if lists.length > 1
                            SPAN 
                              'aria-hidden': true
                              style: cssTriangle (if is_collapsed then 'right' else 'bottom'), (heading_style.color or 'black'), tw, th,
                                position: 'absolute'
                                left: -tw - 20
                                top: if is_collapsed then 10 else 13
                                width: tw
                                height: th
                                # display: if @local.hover_label or is_collapsed then 'inline-block' else 'none'
                                outline: 'none'

                          SPAN 
                            style: 
                              fontSize: 24

                            heading_text    


                      if local.show[list.key]


                        UL 
                          style: 
                            marginLeft: 0 #48

                          for proposal in list.proposals
                            active = proposal.slug == args.proposal.slug

                            [

                              if active 
                                DIV 
                                  style: 
                                    width: args.width 
                                    position: 'relative'
                                  DIV 
                                    style: 
                                      position: 'absolute'
                                      left: -150
                                      top: 0
                                    dangerouslySetInnerHTML: __html: "#{TRANSLATE('engage.navigation_helper_current_location', 'You are here')} &rarr;"

                              CollapsedProposal 
                                key: "collapsed#{proposal.key or proposal}"
                                proposal: proposal
                                show_category: true
                                width: args.width
                                hide_scores: true
                                hide_icons: true
                                hide_metadata: true
                                show_category: false
                                name_style: 
                                  fontSize: 16
                                wrapper_style: 
                                  backgroundColor: if active then "#eee"
                                icon: if proposal.your_opinion.published
                                        -> 
                                          SPAN 
                                            style: 
                                              position: 'relative'
                                              left: -22
                                              top: 3
                                            width: 8
                                            dangerouslySetInnerHTML: __html: '&#x2714;'
                                      else 
                                        -> 
                                          SPAN null 


                            ]




    DIV 
      style: 
        textAlign: 'right'
        fontSize: 22
        marginTop: 40

      TRANSLATE
        id: 'engage.back_to_homepage_option'
        link: 
          component: A 
          args: 
            href: if current_section && current_section != 'all' then "/?tab=#{encodeURIComponent(current_section)}##{hash}" else "/##{hash}"
            style: 
              textDecoration: 'underline'
              fontWeight: 600
        "…or go <link>back to the homepage</link>"




