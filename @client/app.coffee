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
require './bubblemouth'
require './edit_proposal'
require './edit_list'
require './edit_page'
require './customizations'
require './form'
# require './histogram'
require './histogram-canvas'
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
require './development'
require './su'
require './edit_point'
require './edit_comment'
require './point'
require './document'
require './statement'
require './item'
require './viewport_visibility_sensor'
require './icons'
require './google_translate'
require './new_forum_onboarding'

try 
  require './product_page/payment'
catch
  console.error 'no product page code'


styles += """
  #content {
    min-width: 320px;
  }


"""


## ########################
## Initialize defaults for client data

bus_fetch 'root'


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

          "If you are having difficulty using Considerit, please contact us at <link>accessibility@consider.it</link>. We will personally help you."



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
    subdomain = bus_fetch('/subdomain') 

    if @local.embed_html_directly && !@local.html && subdomain.about_page_url
      # bus_fetch the about page HTML directly
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
    loc = bus_fetch 'location'

    if is_a_dialogue_page() && loc.query_params.edit_forum
      edit_forum = bus_fetch 'edit_forum'
      edit_forum.editing = true
      save edit_forum      
      delete loc.query_params.edit_forum
      save loc


    if loc.query_params.flash
      show_flash loc.query_params.flash, 3000
      delete loc.query_params.flash

    if @last_location != loc.url 

      # resetting root state when switching routes
      auth = bus_fetch('auth')

      if auth.form
        reset_key auth


      edit_forum = bus_fetch 'edit_forum'
      if edit_forum.editing && !is_a_dialogue_page()
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
    subdomain = bus_fetch('/subdomain')
    loc = bus_fetch('location')
    auth = bus_fetch('auth')
    page = bus_fetch @props.page

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
        className: "#{if is_a_dialogue_page() then 'main_background' else ''} #{if embedded_demo() then 'embedded-demo' else ''}"
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
        else if loc.url.startsWith('/docs/')
          DocumentationGroup()
        else
          switch loc.url
            when '/'
              Homepage key: 'homepage'
            when '/about'
              About()
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

              else
                Homepage key: 'homepage'
                

      Footer(key: 'page_footer') if access_granted
    

Root = ReactiveComponent
  displayName: 'Root'

  render : -> 

    loc = bus_fetch('location')
    app = bus_fetch('/application')
    subdomain = bus_fetch '/subdomain'
    current_user = bus_fetch('/current_user')    
    page = bus_fetch("/page#{loc.url}")

    setTimeout ->
      bus_fetch '/users'


    if !bus_fetch('customizations_signature').signature || !app.web_worker
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
    condensed_fonts = customization('condensed_font') or header_fonts

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

      
      onClick: @resetSelection

      
      # state transition components
      AuthTransition()
      CustomizationTransition()      
      LocationTransition()
      HomepageTabTransition()
      BrowserLocation()
      GoogleTranslate()
      LoadAvatars?()



      STYLE 
        dangerouslySetInnerHTML: __html: """
          .content, input, button, textarea {
            font-family: #{fonts}; 
          }
          .content h1, .content h2, .content h3, .content h1 button, .content h2 button, .content h3 button, .content h4 button {
            font-family: #{header_fonts};
            // letter-spacing: -1px;
          }

          .monospaced {
            font-family: #{mono_font()};
          }

          .condensed {
            font-family: #{condensed_fonts};
          }
        """

      if !subdomain.name
        LOADING_INDICATOR

      else 
        

        DIV 
          className: 'full_height'
          

          if bus_fetch('auth').form
            Auth()
          
          BrowserHacks()

          Page
            page: "/page#{loc.url}"


      Tooltip()
      Popover()
      Flash()
      CompletionWidget()


      do -> 
        app = bus_fetch('/application')   

        DIV null, 
          if app.dev
            Development()

          if current_user.is_super_admin || app.su
            SU()

  resetSelection: (e) ->
    # TODO: This is ugly. Perhaps it would be better to have components 
    #       register a callback when a click bubbles all the way to the
    #       top. There are global interdependencies to unwind as well.

    loc = bus_fetch('location')
    page = get_page()


    if !bus_fetch('auth').form && page.proposal

      opinion_views = bus_fetch 'opinion_views'

      if get_selected_point()
        delete loc.query_params.selected
        save loc

      else if opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected
        clear_histogram_managed_opinion_views opinion_views

    if !bus_fetch('auth').form && loc.url == '/'
      opinion_views = bus_fetch 'opinion_views'

      if opinion_views.active_views.single_opinion_selected || opinion_views.active_views.region_selected
        clear_histogram_managed_opinion_views opinion_views

    wysiwyg_editor = bus_fetch 'wysiwyg_editor'
    if wysiwyg_editor.showing
      # We don't want to close the editor if there was a selection event whose click event
      # bubbled all the way up here.
      
      selected = document.getSelection()

      if selected.isCollapsed
        wysiwyg_editor.showing = false
        save wysiwyg_editor




# exports...
window.Franklin = Root

window.get_page = -> bus_fetch("/page#{bus_fetch('location').url}")

require './app_loader'

