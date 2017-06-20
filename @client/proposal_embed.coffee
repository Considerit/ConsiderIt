# require './element_viewport_positioning'

# require './vendor/iframe-resizer-inner.min'
require './activerest-m'
require './avatar'
require './browser_hacks'
require './bubblemouth'
require './customizations'
require './histogram'
require './shared'
require './tooltip'
require './translations'
# require './opinion_slider'


window.focus_color = -> 
  customization('focus_color') or focus_blue


# The containing window calls this to let us know that the containing window is allowing 
# for javascript to be run. In particular, that means the iframe can be resized, which 
# opens up more interactive possibilities. 
window.iFrameResizer =
  messageCallback: (message) -> 
    contact = fetch('contact')
    contact.contact = true 
    save contact

window.namespaced_key = (base_key, base_object) ->
  namespace_key = fetch(base_object).key 

  # don't store this on the server
  if namespace_key[0] == '/'
    namespace_key = namespace_key.substring(1, namespace_key.length)
  
  "#{namespace_key}_#{base_key}"

proposal_link = (proposal, results) -> 
  "#{location_origin()}/#{proposal.slug}#{if results then '?results=true' else ''}"


window.opinionsForProposal = (proposal) ->       
  opinions = fetch(proposal).opinions || []
  opinions


ProposalDescription = ReactiveComponent
  displayName: 'ProposalDescription'

  render : ->    
    @proposal ||= fetch @props.proposal

    if !@local.description_collapsed?
      @local.description_collapsed = true
      save(@local)


    if @proposal.description?.length > 0 

      div = document.createElement("div");
      div.innerHTML = @proposal.description
      len = div.innerText.trim().length

    loc = fetch 'location'
    DIV           
      style: 
        width: @props.width - 50
        position: 'relative'
        margin: 'auto'
        fontSize: 16
        marginBottom: 40


      # Proposal name
      DIV
        id: 'proposal_name'
        style:
          lineHeight: 1.2
          fontWeight: 700
          fontSize: 24
          paddingBottom: if len > 0 then 15

        A 
          href: proposal_link(@proposal, true) 
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

          if (editor = proposal_editor(@proposal)) && editor == @proposal.user && (!loc.query_params.hide_author || loc.query_params.hide_author == 'false')
            SPAN 
              style: {}

              " by #{fetch(editor)?.name}"
        
      if @local.description_collapsed && @proposal.description?.length > 100
        contact = !!fetch('contact').contact

        if contact 

          DIV
            style:
              backgroundColor: '#f9f9f9'
              cursor: 'pointer'
              paddingTop: 5
              paddingBottom: 5
              marginTop: -5
              textAlign: 'center'
              color: '#888'
              fontSize: 12
            onMouseDown: => 
              if window.parentIFrame
                @local.description_collapsed = false
                save(@local)
              else 

            'Show details'

        else 
          A
            style:
              backgroundColor: '#f9f9f9'
              cursor: 'pointer'
              paddingTop: 5
              paddingBottom: 5
              marginTop: -5
              textAlign: 'center'
              color: '#888'
              fontSize: 12
            target: '_blank'
            href: proposal_link(@proposal) 

            'Show details'


      else if @proposal.description?.length > 0 && len > 0 
        DIV
          className: 'proposal_details'
          style: 
            paddingTop: 5

          DIV dangerouslySetInnerHTML:{__html: @proposal.description}




Proposal = ReactiveComponent
  displayName: 'Root'

  render : -> 
    @proposal = fetch @props.key

    users = fetch '/users'

    return DIV(null, LOADING_INDICATOR) if !@proposal.name

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

        if @proposal.active 
          A 
            href: proposal_link(@proposal) 
            target: '_blank'          
            style: 
              color: focus_color()
              padding: '6px 12px'
              backgroundColor: focus_color()
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
                fill: focus_color()
                stroke: focus_color()
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

        drawLogo 
          height: @props.size + 5
          main_text_color: logo_red
          o_text_color: logo_red
          clip: false
          draw_line: true 
          line_color: logo_red
          i_dot_x: if @local.hover then 142 else null
          transition: true



# exports...
window.ProposalEmbed = Proposal

require './bootstrap_loader'

