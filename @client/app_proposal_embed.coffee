require './activerest-m'
require './avatar'
require './browser_hacks'
require './bubblemouth'
require './customizations'
require './histogram-canvas'
require './shared'
require './tooltip'
require 'dashboard/translations'
require './item'

# The containing window calls this to let us know that the containing window is allowing 
# for javascript to be run. In particular, that means the iframe can be resized, which 
# opens up more interactive possibilities. 
window.iFrameResizer =
  messageCallback: (message) -> 
    contact = bus_fetch('contact')
    contact.contact = true 
    save contact

window.namespaced_key = (base_key, base_object) ->
  namespace_key = bus_fetch(base_object).key 

  # don't store this on the server
  if namespace_key[0] == '/'
    namespace_key = namespace_key.substring(1, namespace_key.length)
  
  "#{namespace_key}_#{base_key}"

proposal_link = (proposal) -> 
  "#{location_origin()}/#{proposal.slug}"


window.opinionsForProposal = (proposal) ->       
  opinions = bus_fetch(proposal).opinions || []
  opinions


ProposalDescription = ReactiveComponent
  displayName: 'ProposalDescription'

  render : ->    
    @proposal ||= bus_fetch @props.proposal

    if !@local.description_collapsed?
      @local.description_collapsed = true
      save(@local)


    if @proposal.description?.length > 0 

      div = document.createElement("div");
      div.innerHTML = @proposal.description
      len = div.innerText.trim().length

    loc = bus_fetch 'location'
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
            color: "var(--text_light_gray)"
            fontStyle: 'italic'
            paddingTop: 0

          prettyDate(@proposal.created_at)

          if (editor = proposal_editor(@proposal)) && editor == @proposal.user && (!loc.query_params.hide_author || loc.query_params.hide_author == 'false')
            SPAN 
              style: {}

              " by #{bus_fetch(editor)?.name}"
        
      if @local.description_collapsed && @proposal.description?.length > 100
        contact = !!bus_fetch('contact').contact

        if contact 

          DIV
            style:
              backgroundColor: "var(--bg_speech_bubble)"
              cursor: 'pointer'
              paddingTop: 5
              paddingBottom: 5
              marginTop: -5
              textAlign: 'center'
              color: "var(--text_light_gray)"
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
              backgroundColor: "var(--bg_speech_bubble)"
              cursor: 'pointer'
              paddingTop: 5
              paddingBottom: 5
              marginTop: -5
              textAlign: 'center'
              color: "var(--text_light_gray)"
              fontSize: 12
            target: '_blank'
            href: proposal_link(@proposal) 

            'Show details'


      else if @proposal.description?.length > 0 && len > 0 
        DIV
          className: 'wysiwyg_text'
          style: 
            paddingTop: 5

          DIV dangerouslySetInnerHTML:{__html: @proposal.description}




Proposal = ReactiveComponent
  displayName: 'Root'

  render : -> 
    @proposal = bus_fetch @props.proposal

    users = bus_fetch '/users'

    return DIV(null, LOADING_INDICATOR) if !@proposal.name

    width = ReactDOM.findDOMNode(@).offsetWidth
    histo_width = width - 100

    w = 34
    h = 24

    DIV 
      style: 
        width: width
        backgroundColor: "var(--bg_item)"
        border: "1px solid var(--brd_light_gray)"
        borderRadius: '16px 16px 18px 18px'

      Tooltip()
      Popover()

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
            histo_key: namespaced_key('histogram', @proposal)
            proposal: @proposal
            opinions: opinionsForProposal(@proposal)
            width: histo_width
            height: 80
            enable_individual_selection: false
            enable_range_selection: false
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
              color: "var(--text_light)"
              padding: '6px 12px'
              backgroundColor: "var(--focus_color)"
              borderRadius: 16
              color: "var(--text_light)"
              position: 'relative'

            SPAN 
              key: 'slider_bubblemouth'
              style:
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
                fill: "var(--focus_color)"
                stroke: "var(--focus_color)"
                stroke_width: 0
                dash_array: "none"


            "Add your opinion" 


      DIV 
        style: 
          textAlign: 'center' 
          borderRadius: '0 0 16px 16px'
          backgroundColor: "var(--bg_speech_bubble)"

        
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
        href: "https://#{bus_fetch('/application').base_domain}"
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

require './app_loader'

