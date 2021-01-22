#////////////////////////////////////////////////////////////
# Core considerit client code
#////////////////////////////////////////////////////////////



require './element_viewport_positioning'
require './activerest-m'
require 'dashboard/dashboard'
require './dock'
require './auth/auth'
require './avatar'
require './browser_hacks'
require './browser_location'
require './proposal_navigation'
require './bubblemouth'
require './edit_proposal'
require './customizations'
require './form'
require './histogram'
require './filter'
require './homepage'
require './shared'
require './opinion_slider'
require './state_dash'
require './tooltip'
require './development'
require './su'
require './edit_point'
require './edit_comment'
require './point'
require './legal'
require './statement'
require './proposal'



## ########################
## Initialize defaults for client data

fetch 'root',
  opinions_to_publish : []


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



# I don't think this component is used anymore
About = ReactiveComponent
  displayName: 'About'

  componentWillMount : ->
    @local.embed_html_directly = true
    @local.html = null
    @local.save

  componentDidMount : -> @handleContent()
  componentDidUpdate : -> @handleContent()

  handleContent : -> 
    $el = $(@getDOMNode())

    if @local.embed_html_directly
      # have to use appendChild rather than dangerouslysetinnerhtml
      # because scripts in the about page html won't get executed
      # when using dangerouslysetinnerhtml
      if @local.html
        $el.find('.embedded_about_html').html @local.html

    else
      # REACT iframes don't support onLoad, so we need to figure out when 
      #               to check the height of the loaded content ourselves      
      $el.prop('tagName').toLowerCase() == 'iframe'
      iframe = $el[0]
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
        DIV className: 'embedded_about_html'



LocationTransition = ReactiveComponent
  displayName: 'locationTransition'
  render : -> 
    loc = fetch 'location'

    if @last_location != loc.url 

      ######
      # Temporary technique for handling resetting root state when switching 
      # between routes. TODO: more elegant approach
      auth = fetch('auth')

      if auth.form
        reset_key auth

      #######

      if loc.url == '/'
        reset_selection_state('filtered')


      @last_location = loc.url
    SPAN null


AuthTransition = ReactiveComponent
  # This doesn't actually render anything.  It just processes state
  # changes to current_user for CSRF and logging in and out.
  displayName: 'Computer'
  render : ->
    current_user = fetch('/current_user')

    if current_user.csrf
      arest.csrf(current_user.csrf)

    # Publish pending opinions if we can
    if @root.opinions_to_publish.length > 0

      remaining_opinions = []

      for opinion_key in @root.opinions_to_publish
        opinion = fetch(opinion_key)
        can_opine = permit('publish opinion', opinion.proposal)

        if can_opine > 0 && !opinion.published
          opinion.published = true
          save opinion
        else 
          remaining_opinions.push opinion_key

          # TODO: show some kind of prompt to user indicating that despite 
          #       creating an account, they still aren't permitted to publish 
          #       their opinion.
          # if can_opine == Permission.INSUFFICIENT_PRIVILEGES
          #   ...

      if remaining_opinions.length != @root.opinions_to_publish.length
        @root.opinions_to_publish = remaining_opinions
        save @root

    # users following an email invitation need to complete 
    # registration (name + password)
    if current_user.needs_to_complete_profile
      subdomain = fetch('/subdomain')

      reset_key 'auth',
        key: 'auth'
        form: if subdomain.SSO_domain then 'edit profile' else 'create account via invitation'
        goal: 'Complete registration'
        ask_questions: true

      if subdomain.SSO_domain
        loadPage '/dashboard/edit_profile'
        
    # there's a required question this user has yet to answer
    else if current_user.logged_in && !current_user.completed_host_questions && !fetch('auth').form
      reset_key 'auth',
        form: 'user questions'
        goal: 'To start participating'
        ask_questions: true


    else if current_user.needs_to_verify && !window.send_verification_token
      current_user.trying_to = 'send_verification_token'
      save current_user

      window.send_verification_token = true 

      reset_key 'auth',
        key: 'auth'
        form: 'verify email'
        goal: 'confirm you control this email'
        ask_questions: false

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

    access_granted = @accessGranted()

    DIV null,
      STYLE 
        dangerouslySetInnerHTML: __html: customization('style')
        
      Header(key: 'page_header') if access_granted


      MAIN 
        role: 'main'
        style: 
          position: 'relative'
          zIndex: 1
          margin: 'auto'

        if auth.form
          Auth()

        else if !access_granted
          AccessDenied()

        else if loc.url.startsWith('/dashboard')
          Dashboard()

        else if loc.url.match(/(.+)\/edit/)
          EditProposal 
            key: loc.url.match(/(.+)\/edit/)[1]
            fresh: false


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
            when '/proposal/new'
              EditProposal key: "new_proposal", fresh: true      
            when '/accessibility_support'
              AccessibilitySupport()

            else
              if @page?.result == 'Not found'
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

              else 
                result = null

                if @page.proposal 
                  result = Proposal key: @page.proposal
                else if !@page.proposal? && arest.cache['/proposals']?.proposals?
                  # search to see if we already have this proposal loaded
                  for proposal in arest.cache['/proposals'].proposals
                    if '/' + proposal.slug == loc.url
                      result = Proposal key: "/proposal/#{proposal.id}"
                      break 

                result or LOADING_INDICATOR
                

      Footer(key: 'page_footer') if access_granted && !auth.form
    

Root = ReactiveComponent
  displayName: 'Root'

  render : -> 
    loc = fetch('location')
    subdomain = fetch '/subdomain'
    current_user = fetch('/current_user')

    fonts = customization('font')
    header_fonts = customization('header_font') or fonts
    DIV 
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

      StateDash()
      
      # state transition components
      AuthTransition()
      CustomizationTransition()      
      LocationTransition()
      HomepageTabTransition()
      BrowserLocation()

      STYLE 
        dangerouslySetInnerHTML: __html: """
          .content, .content input, .content button, .content textarea {
            font-family: #{fonts}; 
          }
          .content h1, .content h2, .content h3, .content h4, .content h1 button, .content h2 button, .content h3 button, .content h4 button {
            font-family: #{header_fonts};
          }
        """

      if !subdomain.name
        LOADING_INDICATOR

      else 
        

        DIV 
          style:
            backgroundColor: 'white'
            overflowX: 'hidden'

          # Avatars()
          
          BrowserHacks()

          Page key: "/page#{loc.url}"

      Tooltip()


      do -> 
        app = fetch('/application')      
        if app.dev
          Development()

        if current_user.is_super_admin || app.su
          SU()

  resetSelection: (e) ->
    # TODO: This is ugly. Perhaps it would be better to have components 
    #       register a callback when a click bubbles all the way to the
    #       top. There are global interdependencies to unwind as well.

    loc = fetch('location')
    page = fetch("/page#{loc.url}")

    if !fetch('auth').form && page.proposal

      hist = fetch namespaced_key('histogram', page.proposal)

      if get_selected_point()
        window.writeToLog
          what: 'deselected a point'
          details:
            point: get_selected_point()

        delete loc.query_params.selected
        save loc

      else if hist.selected_opinions || hist.selected_opinion || hist.originating_histogram
        reset_selection_state hist 

    if !fetch('auth').form && loc.url == '/'
      hist = fetch 'filtered'
      if hist.selected_opinions || hist.selected_opinion || hist.originating_histogram
        reset_selection_state hist


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


require './app_loader'

