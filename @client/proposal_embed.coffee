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

        @proposal.name

        if customization('show_meta')
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
        
      if @local.description_collapsed
        DIV
          style:
            backgroundColor: '#f9f9f9'
            # width: @props.width
            # position: 'absolute'
            # bottom: 0
            textDecoration: 'underline'
            cursor: 'pointer'
            paddingTop: 10
            paddingBottom: 10
            fontWeight: 600
            marginTop: -10
            textAlign: 'center'
            color: '#888'
          onMouseDown: => 
            @local.description_collapsed = false
            save(@local)
          'Read proposal'
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

    console.log "FETCHING", @proposal

    @proposal = fetch @props.key

    return LOADING_INDICATOR if !@proposal.name

    width = @getDOMNode().offsetWidth
    histo_width = width - 100

    DIV 
      style: 
        width: width
        backgroundColor: 'white'
        border: '1px solid #ccc'
        borderRadius: 16
        padding: '20px 20px'



      Avatars()
      Tooltip()

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


        # OpinionSlider
        #   key: namespaced_key('slider', @proposal)
        #   width: histo_width - 10
        #   your_opinion: @proposal.your_opinion
        #   proposal: @proposal
        #   focused: false
        #   backgrounded: false
        #   permitted: false
        #   pole_labels: [ \
        #     [customization("slider_pole_labels.group.oppose", @proposal),
        #      customization("slider_pole_labels.group.oppose_sub", @proposal)], \
        #     [customization("slider_pole_labels.group.support", @proposal),
        #      customization("slider_pole_labels.group.support_sub", @proposal)]]



# exports...
window.ProposalEmbed = Proposal

require './bootstrap_loader'

