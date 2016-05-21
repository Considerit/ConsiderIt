require './element_viewport_positioning'

# require './vendor/jquery.touchpunch'

require './vendor/modernizr' 
require './activerest-m'
require './avatar'
require './browser_hacks'
# require './browser_location'
require './bubblemouth'
require './customizations'
require './histogram'
# require './roles'
# require './filter'
# require './tags'
# require './homepage'
require './shared'
require './tooltip'
require './translations'
# require './opinion_slider'


window.namespaced_key = (base_key, base_object) ->
  namespace_key = fetch(base_object).key 

  # don't store this on the server
  if namespace_key[0] == '/'
    namespace_key = namespace_key.substring(1, namespace_key.length)
  
  "#{namespace_key}_#{base_key}"

proposal_url = (proposal, results) -> 
  "#{location.origin}/#{proposal.slug}#{if results then '?results=true' else ''}"


window.opinionsForProposal = (proposal) ->       
  filter_func = customization("homie_histo_filter", proposal)
  opinions = fetch(proposal).opinions || []
  # We'll only pass SOME opinions to the histogram
  opinions = (opinion for opinion in opinions when \
               !filter_func or filter_func(fetch(opinion.user)))
  opinions


ProposalDescription = ReactiveComponent
  displayName: 'ProposalDescription'

  render : ->    
    @proposal ||= fetch @props.proposal

    if !@local.description_collapsed?
      @local.description_collapsed = true
      save(@local)

    DIV           
      style: 
        width: @props.width - 50
        position: 'relative'
        margin: 'auto'
        fontSize: 16
        marginBottom: 18


      # Proposal name
      DIV
        id: 'proposal_name'
        style:
          lineHeight: 1.2
          fontWeight: 700
          fontSize: 24
          paddingBottom: 15

        A 
          href: proposal_url(@proposal, true) 
          style: 
            textDecoration: 'underline'
          target: '_blank'
          @proposal.name

        DIV 
          style: 
            fontSize: 12
            color: "#888"
            fontStyle: 'italic'
            paddingTop: 0

          prettyDate(@proposal.created_at)

          if (editor = proposal_editor(@proposal)) && editor == @proposal.user
            SPAN 
              style: {}

              " by #{fetch(editor)?.name}"

      # DIV
      #   className: 'proposal_details'
      #   style:
      #     position: 'relative'
      #     maxHeight: if @local.description_collapsed then @max_description_height
      #     overflow: if @local.description_collapsed then 'hidden'
        
      if @local.description_collapsed && @proposal.description?.length > 100
        DIV
          style:
            backgroundColor: '#f9f9f9'
            # width: @props.width
            # position: 'absolute'
            # bottom: 0
            # textDecoration: 'underline'
            cursor: 'pointer'
            paddingTop: 5
            paddingBottom: 5
            #fontWeight: 600
            marginTop: -5
            textAlign: 'center'
            color: '#888'
            fontSize: 12
          onMouseDown: => 
            @local.description_collapsed = false
            save(@local)
          'Show details'
      else 
        DIV
          className: 'proposal_details'
          style: 
            padding: '5px 0 20px 0'

          DIV dangerouslySetInnerHTML:{__html: @proposal.description}
      

  componentDidUpdate : ->
    subdomain = fetch('/subdomain')
    if subdomain.name == 'RANDOM2015' && @local.description_fields && $('#description_fields').find('.MathJax').length == 0
      MathJax.Hub.Queue(["Typeset",MathJax.Hub,"description_fields"])




Proposal = ReactiveComponent
  displayName: 'Root'

  render : -> 
    console.log window, location
    @proposal = fetch @props.key

    return LOADING_INDICATOR if !@proposal.name

    width = @getDOMNode().offsetWidth
    histo_width = width - 100

    w = 34
    h = 24

    DIV 
      style: 
        width: width
        backgroundColor: 'white'
        border: '1px solid #ccc'
        borderRadius: '16px 16px 18px 18px'


      Avatars()
      Tooltip()

      DIV 
        style: 
          padding: '20px 20px'

        ProposalDescription 
          proposal: @proposal 
          width: width

        DIV 
          style: 
            position: 'relative'
            zIndex: 1
            margin: 'auto'
            width: histo_width
              
          Histogram
            key: namespaced_key('histogram', @proposal)
            proposal: @proposal
            opinions: opinionsForProposal(@proposal)
            width: histo_width
            height: 80
            enable_selection: false
            backgrounded: false
            draw_base_labels: true 
            draw_base: true

      DIV 
        style: 
          textAlign: 'center' 
          marginBottom: 20
          position: 'relative'





        A 
          href: proposal_url(@proposal) 
          target: '_blank'          
          style: 
            color: focus_blue
            padding: '6px 12px'
            backgroundColor: focus_blue
            borderRadius: 16
            color: 'white'
            position: 'relative'

          SPAN 
            key: 'slider_bubblemouth'
            style: css.crossbrowserify
              left: 35 - w / 2
              top: 8
              position: 'absolute'
              width: w
              height: h 
              zIndex: 10
              transform: "translate(0, -25px) scale(.5) "

            Bubblemouth 
              apex_xfrac: .2
              width: w
              height: h
              fill: focus_blue
              stroke: focus_blue
              stroke_width: 0
              dash_array: "none"


          "Add your opinion" 


      DIV 
        style: 
          textAlign: 'center' 
          borderRadius: '0 0 16px 16px'
          backgroundColor: '#f9f9f9'

        
        TechnologyByConsiderit
          size: 12
        

require './logo'
TechnologyByConsiderit = ReactiveComponent
  displayName: 'TechnologyByConsiderit'
  render : -> 
    @props.size ||= 20
    DIV 
      style: 
        textAlign: 'left'
        display: 'inline-block'
        fontSize: @props.size
        padding: '3px 0 6px 0'
      "Technology by "
      A 
        onMouseEnter: => 
          @local.hover = true
          save @local
        onMouseLeave: => 
          @local.hover = false
          save @local
        href: 'http://consider.it'
        target: '_blank'
        style: 
          position: 'relative'
          top: 5
          left: 3
        
        drawLogo @props.size + 5, logo_red, logo_red, false, true, logo_red, (if @local.hover then 142 else null), true




# exports...
window.ProposalEmbed = Proposal

require './bootstrap_loader'

