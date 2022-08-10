#////////////////////////////////////////////////////////////
# Core considerit client code
#////////////////////////////////////////////////////////////

require './element_viewport_positioning'
require './activerest-m'
require 'dashboard/dashboard'
require './dock'
require './edit_forum'
require './auth/auth'
require './avatar'
require './browser_hacks'
require './browser_location'
require './proposal_navigation'
require './bubblemouth'
require './edit_proposal'
require './edit_list'
require './edit_page'
require './customizations'
require './form'
require './histogram'
require './proposal_sort_and_search'
require './opinion_views'
require './tabs'
require './header'
require './footer'
require './shared'
require './homepage'
require './opinion_slider'
require './tooltip'
require './popover'
require './flash'
# require './development'
require './su'
require './edit_point'
require './edit_comment'
require './point'
require './legal'
require './statement'
require './proposal'
require './viewport_visibility_sensor'
require './icons'
require './google_translate'
require './new_forum_onboarding'

try 
  require './product_page/payment'
catch
  console.error 'no product page code'



## ########################
## Initialize defaults for client data

fetch 'root'


AccessibilitySupport = ReactiveComponent 
  displayName: 'AccessibilitySupport'

  render: -> 
    DIV   
      style: 
        width: HOMEPAGE_WIDTH()
        margin: 'auto'

      H1
        style: 
          fontSize: 32
          fontWeight: 600
          marginTop: 30
          marginBottom: 10


        TRANSLATE
          id: 'accessibility.heading'
          'Accessibility Support'

      P 
        style: 
          paddingBottom: 18
          fontSize: 24

        TRANSLATE 
          id: "accessibility.feedback_or_help"
          link: 
            component: A 
            args: 
              href: "mailto:accessibility@consider.it?subject=Accessibility support"
              style: 
                textDecoration: 'underline'

          "If you are having difficulty using Considerit to give feedback, contact us at <link>accessibility@consider.it</link>. We will help you personally."



# Legacy component (TODO: migrate where it is used)
About = ReactiveComponent
  displayName: 'About'

  UNSAFE_componentWillMount : ->
    @local.embed_html_directly = true
    @local.html = null
    @local.save

  componentDidMount : -> @handleContent()
  componentDidUpdate : -> @handleContent()

  handleContent : -> 
    el = ReactDOM.findDOMNode(@)

    if @local.embed_html_directly
      # have to use appendChild rather than dangerouslysetinnerhtml
      # because scripts in the about page html won't get executed
      # when using dangerouslysetinnerhtml
      if @local.html
        @refs.embedded_about_html.innerHTML = @local.html

    else
      # REACT iframes don't support onLoad, so we need to figure out when 
      #               to check the height of the loaded content ourselves      
      iframe = el
      _.delay ->
        try 
          iframe.height = iframe.contentWindow.document.body.scrollHeight + "px"
        catch e
          iframe.height = "2000px"
          console.error 'http/https mismatch for about page. Should work in production.'
          console.error e
      , 1000


  render : -> 
    subdomain = fetch('/subdomain') 

    if @local.embed_html_directly && !@local.html && subdomain.about_page_url
      # fetch the about page HTML directly
      $.get subdomain.about_page_url, \
            (response) => @local.html = response; save @local

    DIV style: {marginTop: 20},
      if !subdomain.about_page_url
        DIV null, 'No about page defined'
      else if !@local.embed_html_directly
        IFRAME 
          src: subdomain.about_page_url
          width: CONTENT_WIDTH()
          style: {display: 'block', margin: 'auto'}
      else
        DIV
          ref: 'embedded_about_html'
          className: 'embedded_about_html'



LocationTransition = ReactiveComponent
  displayName: 'locationTransition'
  render : -> 
    loc = fetch 'location'

    if loc.url == '/' && loc.query_params.edit_forum
      edit_forum = fetch 'edit_forum'
      edit_forum.editing = true
      save edit_forum      
      delete loc.query_params.edit_forum
      save loc


    if loc.query_params.flash
      show_flash loc.query_params.flash, 3000
      delete loc.query_params.flash

    if @last_location != loc.url 

      # resetting root state when switching routes
      auth = fetch('auth')

      if auth.form
        reset_key auth


      edit_forum = fetch 'edit_forum'
      if edit_forum.editing && loc.url != '/'
        stop_editing_forum()
        
      #######

      @last_location = loc.url
    SPAN null




######
# Page
# Decides which page to render by reading state (particularly location and auth). 
# Plays the role of an application router.
#
Page = ReactiveComponent
  displayName: 'Page'
  mixins: [AccessControlled]

  render: ->
    subdomain = fetch('/subdomain')
    loc = fetch('location')
    auth = fetch('auth')
    page = fetch @props.page

    access_granted = @accessGranted()


    DIV
      className: 'full_height'
      style: 
        display: 'flex' # this flex stuff forces the height to at least be size of viewport
        flexDirection: 'column'
      'aria-hidden': if auth.form then true
      
      STYLE 
        dangerouslySetInnerHTML: __html: customization('style')

      if access_granted
        Header
          key: 'page_header'
          


      MAIN 
        role: 'main'
        className: if loc.url == '/' || EXPAND_IN_PLACE then 'main_background'
        style: 
          position: 'relative'
          # zIndex: 1
          margin: 'auto'
          flexGrow: 1
          width: '100%'



        if !access_granted
          AccessDenied()

        else if loc.url.startsWith('/dashboard')
          Dashboard()


        else
          switch loc.url
            when '/'
              Homepage key: 'homepage'
            when '/about'
              About()
            when '/privacy_policy'
              PrivacyPolicy()
            when '/terms_of_service'
              TermsOfService()
            when '/accessibility_support'
              AccessibilitySupport()
            when '/histogram_test'
              HistogramTester()

            else
              if page?.result == 'Not found'
                DIV 
                  style: 
                    textAlign: 'center'
                    fontSize: 32
                    marginTop: 50

                  "There doesn't seem to be a proposal here"

                  DIV 
                    style: 
                      color: '#555'
                      fontSize: 16
                    "Check if the url is correct. The author may also have deleted it. Good luck!"

              else if EXPAND_IN_PLACE
                Homepage key: 'homepage'

              else 
                result = null

                if page.proposal 
                  result = Proposal key: page.proposal, proposal: page.proposal
                else if !page.proposal? && arest.cache['/proposals']?.proposals?
                  # search to see if we already have this proposal loaded
                  for proposal in arest.cache['/proposals'].proposals
                    if '/' + proposal.slug == loc.url
                      result = Proposal key: "/proposal/#{proposal.id}", proposal: "/proposal/#{proposal.id}"
                      break 

                result or LOADING_INDICATOR
                

      Footer(key: 'page_footer') if access_granted
    

Root = ReactiveComponent
  displayName: 'Root'

  render : -> 

    loc = fetch('location')
    app = fetch('/application')
    subdomain = fetch '/subdomain'
    current_user = fetch('/current_user')    
    page = fetch("/page#{loc.url}")


    setTimeout ->
      fetch '/users'
      if loc.url == '/'

        setTimeout ->
          fetch '/proposals'

    if !fetch('customizations_signature').signature || !app.web_worker
      return  DIV 
                className: 'full_height'

                CustomizationTransition()

                DIV 
                  style: 
                    position: 'absolute'
                    left: '48%'
                  LOADING_INDICATOR

    return ProposalsLoading() if !app.web_worker


    fonts = customization('font')
    header_fonts = customization('header_font') or fonts

    DIV 
      className: 'full_height'
      # Track whether the user is currently swipping. Used to determine whether
      # a touchend event should trigger a click on a link.
      # TODO: I'd like to have this defined at a higher level  
      onTouchMove: -> 
        window.is_swipping = true
        true
      onTouchEnd: -> 
        window.is_swipping = false
        true

      style: 
        width: DOCUMENT_WIDTH()

      
      onClick: @resetSelection

      
      # state transition components
      AuthTransition()
      CustomizationTransition()      
      LocationTransition()
      HomepageTabTransition()
      BrowserLocation()
      GoogleTranslate()



      STYLE 
        dangerouslySetInnerHTML: __html: """
          .content, .content input, .content button, .content textarea {
            font-family: #{fonts}; 
          }
          .content h1, .content h2, .content h3, .content h1 button, .content h2 button, .content h3 button, .content h4 button {
            font-family: #{header_fonts};
            // letter-spacing: -1px;
          }

          .monospaced {
            font-family: #{mono_font()};
          }
        """

      if !subdomain.name
        LOADING_INDICATOR

      else 
        

        DIV 
          className: 'full_height'
          

          if fetch('auth').form
            Auth()
          
          BrowserHacks()

          if EXPAND_IN_PLACE
            Page
              page: "/page#{loc.url}"
          else 
            Page 
              key: "/page#{loc.url}"
              page: "/page#{loc.url}"

      Tooltip()
      Popover()
      Flash()

      do -> 
        app = fetch('/application')   

        DIV null, 
          # if app.dev
          #   Development()

          if current_user.is_super_admin || app.su
            SU()

  resetSelection: (e) ->
    # TODO: This is ugly. Perhaps it would be better to have components 
    #       register a callback when a click bubbles all the way to the
    #       top. There are global interdependencies to unwind as well.

    loc = fetch('location')
    page = get_page()

    if !fetch('auth').form && page.proposal

      opinion_views = fetch 'opinion_views'

      if get_selected_point()
        window.writeToLog
          what: 'deselected a point'
          details:
            point: get_selected_point()

        delete loc.query_params.selected
        save loc

      else if opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected
        clear_histogram_managed_opinion_views opinion_views

    if !fetch('auth').form && loc.url == '/'
      opinion_views = fetch 'opinion_views'

      if opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected
        clear_histogram_managed_opinion_views opinion_views

    wysiwyg_editor = fetch 'wysiwyg_editor'
    if wysiwyg_editor.showing
      # We don't want to close the editor if there was a selection event whose click event
      # bubbled all the way up here.
      
      selected = document.getSelection()

      if selected.isCollapsed
        wysiwyg_editor.showing = false
        save wysiwyg_editor



# exports...
window.Franklin = Root

window.get_page = -> fetch("/page#{fetch('location').url}")

require './app_loader'

