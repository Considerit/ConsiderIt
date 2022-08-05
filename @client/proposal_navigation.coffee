require './customizations'
require './shared'



styles += """
  .GroupedProposalNavigation {
    padding-top: 36px;
  }
  .GroupedProposalNavigation #tabs {
    margin-top: 48px;
    top: -1px;
    z-index: 1;

  }

  .GroupedProposalNavigation #tabs > ul {
    width: auto;
  }
  .GroupedProposalNavigation #tabs > ul > li {
    margin: 2px 2px 0px 2px;
    background-color: transparent;          
  }          
  .GroupedProposalNavigation #tabs > ul > li.selected {
    background-color: transparent;
  }
  .GroupedProposalNavigation #tabs > ul > li > h4 {
    font-size: 14px;
    padding: 10px 16px 4px;
    color: #444;
    border: 1px solid transparent;
    border-bottom: none;     
    font-weight: 400;
  }

  .GroupedProposalNavigation #tabs > ul > li.selected > h4, .GroupedProposalNavigation #tabs > ul > li.selected > h4 {
    // color: black;  
    background-color: white; 
    border-radius: 8px 8px 0 0px;
    border-color: #ddd;
  }



"""


window.GroupedProposalNavigation = (args) -> 
  proposals = fetch('/proposals').proposals


  tabs = get_tabs() 
  if !tabs or tabs.length == 0
    tabs = [{
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

  current_tab = null
  for tab in tabs 
    if active_list in tab.lists
      tab_state = fetch 'homepage_tabs'
      if tab_state.active_tab != tab.name && !@initialized 
        tab_state.active_tab = tab.name
      current_tab = tab.name
      @initialized = true
      break

  DIV 
    className: "GroupedProposalNavigation"


    H2
      style: 
        fontSize: 32
        fontWeight: 400
        textAlign: 'center'
        marginBottom: 48
        paddingTop: 24


      TRANSLATE
        id: 'engage.navigate_elsewhere.groupednav.header'

        "Done with this #{customization('list_item_name', active_list)}?"

      
      DIV 
        style:       
          textAlign: 'center'
          fontSize: 17
          paddingTop: 12

        if embedded_demo()
          "Navigate to a different proposal below."
        else 
          [
            TRANSLATE
              id: 'engage.back_to_homepage_option'
              link: 
                component: A 
                args: 
                  key: 'linker'
                  href: if current_tab && current_tab != 'all' then "/?tab=#{encodeURIComponent(current_tab)}##{hash}" else "/##{hash}"
                  style: 
                    textDecoration: 'underline'
                    fontWeight: 600
              "Navigate to a different proposal below or go <link>back to the homepage</link>"  
            '.'
          ]



    HomepageTabs()

    if !proposals || proposals.length == 0 
      LOADING_INDICATOR


    else
      get_current_tab_view
        proposal_focused_on: args.proposal





  




