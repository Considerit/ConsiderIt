require './shared'
require './customizations'
require './permissions'
require './browser_hacks' # for access to browser object
require './browser_location' # for loadPage
require './proposal_sort_and_search'
require './opinion_views'
require './browser_location'
require './new_proposal'
require './list'
require './tabs'


styles += """

  #homepagetab {
    position: relative;    
  }

  .Homepage {
    overflow: hidden;
  }

  @media #{LAPTOP_MEDIA} {
    .main_background {
      background-color: #{bg_container};
    }
    #homepagetab {
      width: calc(var(--HOMEPAGE_WIDTH) + var(--LIST_PADDING_RIGHT) + var(--LIST_PADDING_LEFT));
      padding: 24px 0px 140px 0;
      margin: 0px auto;
    }

    .embedded-demo #homepagetab {
      padding-top: 0;
    }

  }

  @media #{NOT_LAPTOP_MEDIA} {
    .main_background {
      background-color: #{bg_light};
    }
  }


  @media #{TABLET_MEDIA} {
    :root {
      --homepagetab_left_padding: 0px; /* 20px; */
    }
    #homepagetab {
      padding: 24px 0px 140px var(--homepagetab_left_padding);
    }
  }


  @media #{PHONE_MEDIA} {
    :root {
      --homepagetab_left_padding: 0px; /* 8px; */
    }    
    #homepagetab {
      padding: 24px 0px 140px var(--homepagetab_left_padding);
    }
  }


  .sized_for_homepage {
    margin: auto;
    /* width: var(--HOMEPAGE_WIDTH); */
    padding: 0px var(--LIST_PADDING_RIGHT) 0px var(--LIST_PADDING_LEFT);
  }

  @media #{NOT_LAPTOP_MEDIA} {
    .sized_for_homepage {
      width: var(--ITEM_TEXT_WIDTH);
    }
  }



"""
window.Homepage = ReactiveComponent
  displayName: 'Homepage'
  render: ->
    doc = bus_fetch 'document'
    subdomain = bus_fetch '/subdomain'

    return SPAN null if !subdomain.name

    title = customization('banner')?.title or "#{subdomain.name} considerit forum"

    if title.indexOf('<') > -1 
      tmp = document.createElement "DIV"
      tmp.innerHTML = title
      title = tmp.textContent or tmp.innerText or title

    if doc.title != title
      doc.title = title
      save doc


    messages = []
    phase = customization('contribution_phase')
    if phase == 'frozen'
      messages.push {style: {}, img: "snowflake2.png", label: translator("engage.frozen_message", "The forum host has frozen this forum so no changes can be made.")}
    else if phase == 'ideas-only'
      messages.push {style: {}, img: "lightning-bolt.png", label: translator("engage.ideas_only_message", "The forum host has set this forum to be ideas only. No opinions for now.")}
    else if phase == 'opinions-only'
      messages.push {style: {}, icon: magnifying_glass_icon, label: translator("engage.opinions_only_message", "The forum host has set this forum to be opinions only. No new ideas for now.")}

    if customization('anonymize_everything')
      if customization('anonymize_permanently')
        

        strong_privacy = TRANSLATE
          id: "engage.anonymize_permanently_message"
          privacy_link: 
            component: A 
            args: 
              key: 'privacy_link'
              href: '/docs/legal/privacy_policy'
              style: 
                textDecoration: 'underline'
                fontWeight: 400
          b:
            component: B 

          """
          <b>The host has permanently anonymized this forum</b>. The forum host will never have access to the 
          identity of participants. Identity information will continue to be stored on the Consider.it server, but as always, 
          will <privacy_link>never be provided to third-parties</privacy_link>. You can delete your identity information at 
          any time in your account settings.
          """


        messages.push {style: {}, img: 'venetian-mask.png', label: strong_privacy}
      else 
        weak_privacy = TRANSLATE
          id: "engage.anonymize_message"
          italic:
            component: I

          mask: 
            render: -> iconAnonymousMask(16)

          """
          The forum host has concealed the identities of others. No one except the hosts can currently see who 
          is saying what <italic>at this time</italic>. To ensure your identity is never revealed, anonymize your opinion on each proposal using 
          the <mask> </mask> button."""
        messages.push {style: {}, img: 'venetian-mask.png', label: weak_privacy}

    if customization('hide_opinions')
      messages.push {style: {}, img: 'hiding.png', label: translator("engage.hide_opinions_message", "The forum host has hidden the opinions of other participants for the time being.")}

    DIV 
      key: "homepage_#{subdomain.name}"      
      className: "Homepage main_background #{if TABLET_SIZE() then 'one-col' else ''} #{if embedded_demo() then 'embedded-demo' else ''}"

      DIV
        id: 'homepagetab'
        role: if get_tabs() then "tabpanel"


        if bus_fetch('edit_forum').editing
          for page in get_tabs() or [{name: null}]
            EditPage
              key: "#{page?.name}-#{!!get_tabs()}"
              page_name: page?.name
        else 
          DIV null,
            DIV 
              className: 'sized_for_homepage'                  

              if customization('auth_callout')
                DIV 
                  style: 
                    marginBottom: 36
                  AuthCallout()

              NewForumOnBoarding()

              for message in messages
                DIV 
                  key: message
                  style: _.defaults {}, (message.style or {}),
                    backgroundColor: bg_lightest_gray
                    border: "1px solid #{brd_light_gray}"
                    borderRadius: 12
                    padding: '4px 24px'
                    maxWidth: 700
                    margin: "0 auto 16px auto"
                    fontSize: 14
                    display: 'flex'
                    alignItems: 'center'
                    minHeight: 44
                    color: text_dark
                    # textAlign: 'center'

                  if message.img || message.icon
                    DIV 
                      style:
                        minWidth: 40
                        paddingRight: 36

                      if message.icon
                        message.icon(34, 34, text_dark)
                      else
                        IMG 
                          style: 
                            maxWidth: 34
                          src: "#{bus_fetch('/application').asset_host}/images/#{message.img}"


                  SPAN 
                    style:
                      paddingLeft: 12
                    message.label

              if preamble = get_page_preamble()
                DIV
                  className: 'wysiwyg_text'
                  style: 
                    marginBottom: 24
                    maxWidth: if preamble?.startsWith('<p>') then 720
                    margin: "0 auto 24px auto"
                  dangerouslySetInnerHTML: __html: preamble


            if (proposal_editing = bus_fetch('proposal_editing')).editing
              EditProposal 
                proposal: proposal_editing.editing
                done_callback: (e) =>
                  proposal_editing.editing = null
                  if proposal_editing.callback
                    proposal_editing.callback()
                    delete proposal_editing.callback
                  save proposal_editing


            get_current_tab_view()

            if get_tabs() && !embedded_demo()
              DIV 
                style: 
                  paddingTop: 68
                  paddingRight: if TABLET_SIZE() then 36

                DIV 
                  style: 
                    textAlign: 'center'
                    color: selected_color
                    fontWeight: 600
                  translator 'tabs.footer_label', "Explore more on these other pages:"
                  
                HomepageTabs
                  go_to_hash: 'active_tab'
                  active_style: 
                    backgroundColor: bg_dark_gray
                    color: text_light
                  tab_style: 
                    backgroundColor: 'transparent'
                    margin: 4
                    padding: "8px 20px"
                    color: text_gray


  typeset : -> 
    subdomain = bus_fetch('/subdomain')
    if subdomain.name == 'RANDOM2015' && !document.querySelector('.MathJax')
      MathJax.Hub.Queue(["Typeset", MathJax.Hub, ".proposal_homepage_name"])

  componentDidMount : -> @typeset()
  componentDidUpdate : -> @typeset()


window.proposal_editor = (proposal) ->
  editors = (e for e in proposal.roles.editor when e != '*')
  editors.push proposal.user if proposal.user
  editor = editors.length > 0 and editors[0]

  return editor != '-' and editor



window.TagHomepage = ReactiveComponent
  displayName: 'TagHomepage'

  render: -> 
    current_user = bus_fetch('/current_user')

    aggregate_list_key = "list/#{get_current_tab_name()}"
    proposals = bus_fetch('/proposals').proposals

    DIV null,

      List
        key: aggregate_list_key
        combines_these_lists: get_all_lists()
        list: 
          key: aggregate_list_key
          name: aggregate_list_key
          proposals: if proposals then (bus_fetch(p) for p in proposals)


#############
# SimpleHomepage
#
# Two column layout, with proposal name and mini histogram. 
# Divided into lists. 

window.SimpleHomepage = ReactiveComponent
  displayName: 'SimpleHomepage'

  render : ->
    current_user = bus_fetch('/current_user')
    current_tab = get_current_tab_name()
    
    lists = get_lists_for_page(current_tab)

    DIV null, 
      for list_key, index in lists or []
        List
          key: list_key
          list: list_key

      if current_user.is_admin && current_tab not in ['About', 'FAQ'] && get_tab(current_tab)?.type not in [PAGE_TYPES.ABOUT, PAGE_TYPES.ALL]
        NewList()
          



window.ProposalsLoading = ReactiveComponent
  displayName: 'ProposalLoading'

  render: ->  

    if !@cnt?
      @cnt = 0

    negative = Math.floor((@cnt / 284)) % 2 == 1

    DIV 
      style: 
        margin: 'auto'
        padding: '60px 0px'
        textAlign: 'center'
        fontStyle: 'italic'
        fontSize: 24

      DIV 
        ref: 'wrapper'
        style: 
          position: 'relative'
          top: 6
          left: 3

        
        drawLogo 
          height: 50
          main_text_color: logo_red
          o_text_color: logo_red
          clip: false
          draw_line: true 
          line_color: logo_red
          i_dot_x: if negative then 284 - @cnt % 284 else @cnt % 284
          transition: false


      translator "loading_indicator", "Loading...there is much to consider!"

  componentDidMount: ->     
    circle = @refs.wrapper.querySelector('circle')
    @int = setInterval =>
      negative = Math.floor((@cnt / 284)) % 2 == 1
      circle.setAttribute 'cx', if negative then 284 - @cnt % 284 else @cnt % 284
      @cnt += 1 
    , 25

  componentWillUnmount: -> 
    clearInterval @int 


