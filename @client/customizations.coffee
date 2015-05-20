#######################
# Customizations.coffee
#
# Tailor considerit applications by subdomain
#

require './browser_location' # for loadPage
require './shared'
require './swapables'
require './profile_menu'
require './slider'
require './header'


#######
# PUBLIC API
#
# The customization method returns the proper value of the field for this 
# subdomain, or the default value if it hasn't been defined for the subdomain.
#
# Nested customizations can be fetched with . notation, by passing e.g. 
# "auth.use_footer" or with a bracket, like "auth.use_footer['on good days']"
#
# object_or_key is optional. If passed, customization will additionally check for 
# special configs for that object (object.key) or key.

window.customization = (field, object_or_key) -> 
  subdomain = fetch('/subdomain')

  subdomain_name = subdomain.name.toLowerCase()

  value = undefined

  key = if object_or_key 
          if object_or_key.key then object_or_key.key else object_or_key
        else 
          null

  ########
  # The chain of customizations: 
  #  1) any object-specific configuration
  #  2) subdomain configuration
  #  3) global default configuration

  chain_of_configs = []

  if customizations[subdomain_name]?

    subdomain_config = fetch("customizations/#{subdomain_name}")

    # object-specific config
    if key 

      if subdomain_config[key]?
        chain_of_configs.push subdomain_config[key]

      # cluster-level config for proposals
      if key.match(/\/proposal\//)
        proposal = object_or_key
        cluster_key = "cluster/#{proposal.cluster}"
        if subdomain_config[cluster_key]?
          chain_of_configs.push subdomain_config[cluster_key]

    # subdomain config
    chain_of_configs.push subdomain_config

  # global default config
  chain_of_configs.push fetch('customizations/default')

  for config in chain_of_configs
    value = customization_value(field, config)

    break if value?

  if !value?
    console.error "Could not find a value for #{field} #{if key then key else ''}"

  value


# Checks to see if this configuration is defined for a customization field
customization_value = (field, config) -> 
  val = config

  fields = field.split('.')

  for f, idx in fields

    if f.indexOf('[') > 0
      brackets = f.match(/\[(.*?)\]/g)
      f = f.substring(0, f.indexOf('['))

    if val[f]? || idx == fields.length - 1        
      val = val[f]

      if brackets?.length > 0
        for b in brackets
          f = b.substring(2,b.length - 2)
          if val? && val[f]?
            val = val[f]

          else
            return undefined

    else 
      return undefined

  val



###########
# Private storage
customizations = {}



#####
# common options


# pro/con labels

pro_con = 
  pro: 'pro'
  pros: 'pros' 
  con: 'con'
  cons: 'cons'
  your_header: "Give your --valences--" 
  other_header: "Others' --valences--" 
  top_header: "Top --valences--" 

strengths_weaknesses = 
  pro: 'strength'
  pros: 'strengths' 
  con: 'weakness'
  cons: 'weaknesses'
  your_header: "--valences-- you observe" 
  other_header: "--valences-- observed" 
  top_header: "Foremost --valences--" 

challenge_justify = 
  pro: 'justification'
  pros: 'justifications' 
  con: 'challenge'
  cons: 'challenges'
  your_header: "Give your --valences--" 
  other_header: "--valences-- identified" 
  top_header: "Top --valences--" 

support_challenge_claim = 
  pro: 'supporting claim'
  pros: 'supporting claims' 
  con: 'challenging claim'
  cons: 'challenging claims'
  your_header: "--valences-- you recognize" 
  other_header: "--valences-- identified" 
  top_header: "Top --valences--" 

# slider poles

support_oppose = 
  individual: 
    support: 'Support'
    oppose: 'Oppose'
    support_sub: ''
    oppose_sub: ''
  group: 
    support: 'Supporters'
    oppose: 'Opposers'
    support_sub: ''
    oppose_sub: ''

yes_no = 
  individual: 
    support: 'Yes'
    oppose: 'No'
  group: 
    support: 'Yes'
    oppose: 'No'

ready_not_ready = 
  individual: 
    support: 'Ready'
    oppose: 'Not ready'
  group: 
    support: 'Ready'
    oppose: 'Not ready'  

agree_disagree = 
  individual: 
    support: 'Agree'
    oppose: 'Disagree'
  group: 
    support: 'Agree'
    oppose: 'Disagree'  

plus_minus = 
  individual: 
    support: '+'
    oppose: '–'
  group: 
    support: '+'
    oppose: '–'

# application options
conference_config = 
  slider_pole_labels :
    individual: 
      support: 'Accept'
      oppose: 'Reject'
    group: 
      support: 'Accept'
      oppose: 'Reject'

  homie_histo_title: "PC's ratings"


################################
# DEFAULT CUSTOMIZATIONS
# 
# TODO: refactor config & document

customizations.default = 


  # Proposal options

  opinion_value: (o) -> o.stance

  show_crafting_page_first: false

  point_labels : pro_con


  show_slider_feedback: true
  slider_pole_labels : support_oppose


  docking_proposal_header : false

  slider_handle: slider_handle.face

  show_proposer_icon: false
  collapse_descriptions_at: false
  homie_histo_filter: false

  # default cluster options
  # TODO: put them in their own object
  homie_histo_title: 'Opinions'
  archived: false
  closed: false
  label: false
  description: false

  # Other options
  auth: 
    additional_auth_footer: null
    user_questions: []

  Homepage : SimpleHomepage
  ProposalHeader : SimpleProposalHeading

  HomepageHeader : DefaultHeader
  NonHomepageHeader: ShortHeader

  Footer : DefaultFooter

  ThanksForYourOpinion: false





##########################
# SUBDOMAIN CONFIGURATIONS

################
# sosh
customizations['sosh'] = 
  point_labels : strengths_weaknesses
  slider_pole_labels : yes_no

################
# schools
customizations['schools'] = 
  homie_histo_title: "Students' opinions"
  point_labels : challenge_justify
  slider_pole_labels : agree_disagree

#################
# allsides

customizations['allsides'] = 
  'cluster/Classroom Discussions':
    homie_histo_title: "Students' opinions"
  'cluster/Civics':
    homie_histo_title: "Citizens' opinions"

  Homepage: LearnDecideShareHomepage

  homepage_heading_columns : [ 
    {heading: 'Questions', details: null}, \
    {heading: null}, \
    {heading: 'Community', details: null}, \
    {heading: '', details: ''}]

#################
# humanities-los

essential_questions = 
  homie_histo_title: "Student responses"
  slider_pole_labels: agree_disagree
  point_labels: challenge_justify

monuments = 
  point_labels : strengths_weaknesses
  slider_pole_labels : ready_not_ready
  homie_histo_title: "Students' feedback"


customizations['humanities-los'] = 

  show_slider_feedback: false

  point_labels : strengths_weaknesses
  slider_pole_labels : ready_not_ready
  homie_histo_title: "Students' feedback"

  "cluster/Essential Questions 8-2": essential_questions

  "cluster/Essential Questions 8-1": essential_questions

  "Monuments 8-2" : monuments
  "Monuments 8-1" : monuments

#################
# RANDOM2015

customizations['random2015'] = conference_config
customizations['program-committee-demo'] = conference_config


#################
# Relief International

customizations.ri = 
  show_crafting_page_first: true

  slider_pole_labels : agree_disagree

#################
# Enviroissues

customizations.enviroissues = 
  show_crafting_page_first: true

  slider_pole_labels : agree_disagree


  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      DIV
        style:
          height: 130
          width: PAGE_WIDTH
          margin: '60px auto'


        IMG
          src: asset('enviroissues/logo.png')

        ProfileMenu()

customizations.enviroissues.NonHomepageHeader = customizations.enviroissues.HomepageHeader

##############
# ECAST

ecast_highlight_color =  "#73B3B9"  #"#CB7833"
customizations.ecastonline = customizations['ecast-demo'] = 
  show_crafting_page_first: true

  slider_pole_labels : agree_disagree

  ProposalHeader: ProposalHeaderWithMenu
  docking_proposal_header : true

  auth: 

    additional_auth_footer: -> 

      auth = fetch('fetch')
      if auth.ask_questions && auth.form != 'edit profile'
        return DIV 
          style:
            fontSize: 13
            color: auth_text_gray
            padding: '16px 0' 
          """
          The demographic data collected from participants in this project will be used for research purposes, for 
          example, to identify the demographic and other characteristics of the people who participated in the 
          deliberation.  This information can be used in analyzing the results of this online forum.  
          No email addresses, demographic data, or personally-identifying information will be displayed to 
          other visitors to this site.  Any comments you submit will be identified only by the display name 
          you enter below.  By completing this registration, you acknowledge that your participation in this 
          project is entirely voluntary and you agree that the data provided may be used for research. If you 
          have any questions or concerns at any time, please 
          """
          A 
            href: 'mailto:info@ecastonline.org'
            target: "_blank"
            style: 
              textDecoration: 'underline'
             "Contact Us"
          "."
      else 
        SPAN null, ''

    user_questions : [
      { 
        tag: 'zip.editable'
        question: 'My zip code is'
        input: 'text'
        required: true
        input_style: 
          width: 85
        validation: (zip) ->
          return /(^\d{5}$)|(^\d{5}-\d{4}$)/.test(zip)
      }, {
        tag: 'gender.editable'
        question: 'My gender is'
        input: 'dropdown'
        options:['Male', 'Female']
        required: true
      }, {
        tag: 'age.editable'
        question: 'My age is'
        input: 'text'
        required: true
        input_style: 
          width: 50
        validation: (age) -> 
          return /^[1-9]?[0-9]{1}$|^100$/.test(age)
      }, {
        tag: 'ethnicity.editable'
        question: 'My ethnicity is'
        input: 'dropdown'
        options:['African American', 'Asian', 'Latino/Hispanic', 'White', 'Other']
        required: true
      }, {
        tag: 'education.editable'
        question: 'My formal education is'
        input: 'dropdown'
        options:['Did not graduate from high school', 'Graduated from high school or equivalent', 'Attended, but did not graduate from college', 'College degree', 'Graduate professional degree']
        required: true
      }]

  homie_histo_title: "Citizens' opinions"


  NonHomepageHeader : ReactiveComponent
    displayName: 'NonHomepageHeader'

    render: ->
      DIV 
        style: 
          backgroundColor: 'black'
          width: '100%'
          position: 'relative'
          borderBottom: "2px solid #{ecast_highlight_color}"
          padding: "10px 0"
          backgroundImage: "url(#{asset('ecast/bg-small.png')})"
          height: 98

        A 
          href: "http://ecastonline.org/"
          target: '_blank'
          IMG 
            style: 
              height: 75
              position: 'absolute'
              left: 50
              top: 10

            src: asset('ecast/ecast-small.png')

        A 
          style: 
            fontSize: 30
            fontWeight: 600
            color: 'white'
            textShadow: '0 2px 4px rgba(0,0,0,.5)'       
            position: 'relative'
            top: 20
            left: 250 
          href: '/'
          "Informing NASA's Asteroid Initiative: A Citizen Forum"



        ProfileMenu()

  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render : ->
      window.lefty = true

      paragraph_style = 
        marginBottom: 20
        textShadow: '0 1px 1px rgba(255,255,255,.5)'
        fontWeight: 600

      DIV 
        style: 
          backgroundColor: 'black'
          height: 685
          overflow: 'hidden'
          width: '100%'
          position: 'relative'
          borderBottom: "5px solid #{ecast_highlight_color}"

        IMG 
          style: 
            position: 'absolute'
            width: 1300
          src: asset('ecast/bg-small.png')

        # Title of site
        DIV 
          style: 
            position: 'absolute'
            left: 50
            top: 38

          DIV 
            style: 
              fontSize: 42
              fontWeight: 600
              color: 'white'
              textShadow: '0 2px 4px rgba(0,0,0,.5)'

            A 
              href: '/'
              "Informing NASA's Asteroid Initiative"

          DIV
            style: 
              fontSize: 24
              fontWeight: 600         
              color: 'white'
              textAlign: 'center'
              marginTop: -5
 
            A
              href: '/'
              "A Citizen Forum"

        # Credits
        DIV 
          style:
            position: 'absolute'
            top: 61
            left: 790

          DIV 
            style: 
              fontSize: 18
              color: 'white'
            'hosted by'

          A 
            href: "http://ecastonline.org/"
            target: '_blank'
            IMG 
              style: 
                display: 'block'
                marginTop: 4
                width: 215
              src: asset('ecast/ecast-small.png')

          # DIV 
          #   style: 
          #     fontSize: 18
          #     color: 'white'
          #     marginTop: 12              
          #   'supported by'

          # A 
          #   href: "http://www.nasa.gov/"
          #   target: '_blank'

          #   IMG 
          #     style: 
          #       display: 'block'
          #       marginTop: 4
          #       width: 160

          #     src: asset('ecast/nasa.png')

        # Video callout
        DIV
          style: 
            position: 'absolute'
            left: 434
            top: 609
            color: ecast_highlight_color
            fontSize: 17
            fontWeight: 600
            width: 325

          I 
            className: 'fa fa-film'
            style: 
              position: 'absolute'
              left: -27
              top: 3
          'Learn more first! Watch this video from the public forums that ECAST hosted.'

          SPAN
            style: 
              position: 'absolute'
              top: 24
              right: -15

            I
              className: 'fa fa-angle-right'
              style: 
                paddingLeft: 10
            I
              className: 'fa fa-angle-right'
              style: 
                paddingLeft: 5
            I
              className: 'fa fa-angle-right'
              style: 
                paddingLeft: 5


        # Video
        IFRAME
          position: 'absolute'
          type: "text/html" 
          width: 370
          height: 220
          src: "//www.youtube.com/embed/6yImAjIws9A?autoplay=0"
          frameborder: 0
          style:
            top: 460
            left: 790
            zIndex: 99
            position: 'absolute'
            border: "5px solid #{ecast_highlight_color}"
            borderBottom: 'none'


        # Text in bubble
        DIV 
          style: 
            fontSize: 17
            position: 'absolute'
            top: 156
            left: 97
            width: 600

          P style: paragraph_style, 
            "In its history, the Earth has been repeatedly struck by asteroids, large chunks of rock from space that can cause considerable damage in a collision. Can we—or should we—try to protect Earth from potentially hazardous impacts?"

          P style: paragraph_style, 
            "Sounds like stuff just for rocket scientists. But how would you like to be part of this discussion?"

          P style: paragraph_style, 
            "Now you can! NASA is collaborating with ECAST—Expert and Citizen Assessment of Science and Technology—to give citizens a say in decisions about the future of space exploration."

          P style: paragraph_style, 
            "Join the dialogue below about detecting asteroids and mitigating their potential impact. The five recommendations below emerged from ECAST public forums held in Phoenix and Boston last November." 

          P style: paragraph_style, 
            "Please take a few moments to review the background materials and the recommendations, and tell us what you think! Your input is important as we analyze the outcomes of the forums and make our final report to NASA." 

        ProfileMenu()

styles += """
[subdomain="ecastonline"] .simplehomepage a.proposal, [subdomain="ecast-demo"] .simplehomepage a.proposal{
  border-color: #{ecast_highlight_color} !important;
  color: #{ecast_highlight_color} !important;
}
"""


####################
# Bitcoin

customizations.bitcoin = 

  auth: 
    user_questions : [
      {
        tag: 'bitcoin_foundation_member.editable'
        question: 'I am a member of the Bitcoin Foundation'
        input: 'dropdown'
        options:['No', 'Yes']
        required: true
      }]


  # default proposal options
  show_proposer_icon: true
  homie_histo_title: "Members' Opinions"
  collapse_descriptions_at: 600

  'cluster/Candidates': 
    label: "Winter 2015 board election"
    description: 
      DIV null, 
        'Thanks for your opinions. Here are the '
        A
          href: 'https://blog.bitcoinfoundation.org/election-results/'
          style: textDecoration: 'underline'
          "results"
        '.'
    archived: false
    closed: true


  show_crafting_page_first: true

  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      homepage = fetch('location').url == '/'
      window.lefty = true

      # Entire header (the grey area)
      DIV
        style:
          backgroundColor: '#676766'
          height: if not homepage then 63
        onMouseEnter: => @local.hover=true;  save(@local)
        onMouseLeave: => @local.hover=false; save(@local)

        STYLE null,
          '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
             p {margin-bottom: 1em}'''

        # The top bar with the logo
        DIV
          style:
            cursor: if not homepage then 'pointer'
            paddingTop: if homepage then 18 else 17
          onClick: if not homepage then => loadPage('/')

          # Back arrow
          if not homepage
            DIV
              style:
                position: 'absolute'
                left: 20
                top: 0
                color: '#eee'
                fontSize: 43
                fontWeight: 400
                paddingLeft: 25 # Make the clickable target bigger
                width: 180      # Make the clickable target bigger
              '<'

          # Logo
          A
            href: if homepage then 'https://bitcoinfoundation.org'
            IMG
              style:
                height: if homepage then 40 else 26
                marginLeft: if homepage then 82 else 106
              src: asset('bitcoin/logo.svg')

          if not homepage
            SPAN
              style:
                color: 'cyan'
                fontSize: 26
                fontWeight: 500
                marginLeft: 40
              'The Distributed Opinion'

          # Text
          if homepage
            election_day = new Date('02/24/2015')
            today = new Date()
            _second = 1000
            _minute = _second * 60
            _hour = _minute * 60
            _day = _hour * 24
            days_remaining = Math.ceil((election_day - today) / _day)
            list_style =
              paddingLeft: '1em'
              textIndent: '-1em'
              margin: 0

            DIV
              style:
                paddingLeft: 200
                color: 'white'
                fontSize: 22
                fontWeight: 300
                paddingTop: 23
                paddingBottom: 20
                maxWidth: 915

              DIV
                style:
                  color: 'cyan'
                  fontSize: 63
                  fontWeight: 500
                  marginBottom: 15
                'The Distributed Opinion'

              P
                style: 
                  fontWeight: 600
                  fontSize: 35
                'We choose our own future.'

              P style: marginTop: 14, marginBottom: 20,
                'We must decide how we want our Foundation to evolve.'
                BR null, ''
                'Give your opinion to influence your peers. '
                A
                  href: '/proposal/new'
                  style: textDecoration: 'underline', fontWeight: 400
                  "Or submit a new direction."

        ProfileMenu()

customizations.bitcoin.NonHomepageHeader = customizations.bitcoin.HomepageHeader



####################
# Bitcoin demo

customizations['bitcoin-demo'] =
  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: -> 
      # Background image box
      DIV
        style:
          height: 300
          backgroundImage: "url(#{asset('bitcoin/bg.jpg')})"
          backgroundPosition: 'center'
          backgroundSize: 'cover'

        ProfileMenu()

        # Logo
        IMG
          style: { display: 'block'; margin: 'auto'; height: 150; paddingTop: 45 }
          src: asset('bitcoin/logo.svg')

        # The word "Demo"
        DIV
          style:
            textAlign: 'center'
            fontWeight: 600
            margin: 'auto'
            fontSize: 24
            color: 'white'
            padding: "10px 0px 0px 60px"
          'demo'


#####################
# Living Voters Guide

customizations.livingvotersguide = 

  Homepage: LearnDecideShareHomepage

  ProposalHeader: ProposalHeaderWithMenu
  docking_proposal_header : true

  homepage_heading_columns : [ 
    {heading: 'Learn', details: 'about your ballot'}, \
    {heading: 'Decide', details: 'how you\'ll vote'}, \
    {heading: 'Share', details: 'your opinion'}, \
    {heading: 'Join', details: 'the contributors'}]

  'cluster/Advisory votes': 
    description: "* Advisory Votes are not binding. They are a consequence of Initiative 960 passing in 2007"

  ThanksForYourOpinion: ReactiveComponent
    displayName: 'ThanksForYourOpinion'

    render: ->

      if @proposal.category && @proposal.designator
        tweet = "Flex your civic muscle on #{@proposal.category.substring(0,1)}-#{@proposal.designator}! Learn about the issue and decide here: "
      else 
        tweet = "Learn and decide whether you will support \'#{@proposal.name}\' on your Washington ballot here:"
      DIV 
        style: 
          position: 'fixed'
          left: 0
          bottom: 0
          width: '100%'
          backgroundColor: 'rgb(0,182,236)'
          padding: '5px 10px'
          color: 'white'
          zIndex: 999
          textAlign: 'center'
          fontWeight: 600
          fontSize: 18

        'Thanks for your opinion! Invite your friends and family: '
        SPAN style: {position: 'relative', top: 5, marginLeft: 5},
          FBShare()
          Tweet
            text: tweet
            url: "https://livingvotersguide.org/#{@proposal.slug}?results=true"


  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      logo_style =
        position: 'absolute'
        left: 40
        top: 11
        width: 252
        zIndex: 1

      DIV className: 'header', 
        STYLE null, 
          """
          .header { height: 275px; background-image: url(#{asset('livingvotersguide/bg.jpg')}); background-position: center; background-size: cover; }
          """

        DIV
          style:
            position: 'absolute'
            right: 17
            top: 17
          ProfileMenu({style: {height: 69, left: 0; top: 0, position: 'relative', display: 'inline-block'}})
          SPAN style: {color: 'white'}, '   |   '
          A href:'/about', style: {color: 'white', cursor: 'pointer'},
            'About'
          

        # Logo
        A href: (if fetch('location').url == '/' then '/about' else '/'),
          IMG className: 'logo', src: asset('livingvotersguide/logo.png'), style: logo_style

        DIV
          style:
            color: 'white'
            height: 137
            #marginBottom: 10
            clear: 'both'
            paddingTop: 69

          # Online Intelligence for Washington Voters
          DIV
            style:
              fontSize: 32
              padding: '22px 40px 0 332px'
              width: 838
              height: '100%'
              float: 'left'
              fontWeight: 600
            SPAN null, 'Created by the people '
            'and for the people of Washington state'
            DIV
              style: 
                marginBottom: 15
                marginTop: 10
                fontSize: 18
                fontWeight: 300
              "Thanks Washington! We'll see you again in 2015."

          DIV
            style:
              fontSize: 18
              padding: '14px 40px 0 36px'
              float: 'left'
              width: 290
              height: '100%'
            DIV null, 'Hosted by'
            A {href: 'http://seattlecityclub.org'}, B(style:{fontWeight:'bold', color: 'white'}, 'Seattle CityClub')
            DIV style: {marginTop: 8}, 'with fact-checks from'
            A {href: 'http://spl.org'}, B(style:{fontWeight:'bold', color: 'white'}, 'The Seattle Public Library')

  ZipcodeBox : ReactiveComponent
    displayName: 'ZipcodeBox'
    render: ->
      current_user = fetch('/current_user')
      extra_text = if Modernizr.input.placeholder then '' else ' Zip Code'
      onChange = (event) =>
        if event.target.value.match(/\d\d\d\d\d/)
          current_user.tags['zip.editable'] = event.target.value
          save(current_user)

        else if event.target.value.length == 0
          current_user.tags['zip.editable'] = undefined
          @local.stay_around = true
          save(current_user)
          save(@local)

      onBlur = =>
        @local.stay_around = false
        save(@local)

      if current_user.tags['zip.editable'] or @local.stay_around
        STYLE null,
          """
          .filled_zip:hover input, .filled_zip input:focus{
            border: 1px solid #767676;
            background-color: white;}
          """

        # Render the completed zip code box
        DIV 
          className: 'filled_zip'
          style: 
            padding: '13px 23px'
            backgroundColor: '#F5F4ED'
            fontSize: 18
            fontWeight: 400
            width: 245
            margin: 'auto'

          'Customized for:'
          INPUT
            style: 
              fontSize: 18
              fontWeight: 600
              border: '1px solid transparent'
              backgroundColor: 'transparent'
              width: 60
              marginLeft: 7
            type: 'text'
            key: 'zip_input'
            defaultValue: current_user.tags['zip.editable'] or ''
            onChange: onChange
            onBlur: onBlur

      else
        # Render the ragged input box
        DIV style: {margin: '55px 0'},
          DIV 
            style: 
              backgroundImage: "url(#{asset('greytriangle_up.png')})"
              backgroundRepeat: '(repeat-x)'
              backgroundSize: '18px 9px'
              height: 9

          DIV style: {backgroundColor: '#93928E' },
            DIV
              style:
                fontSize: 24
                width: PAGE_WIDTH
                color: 'white'
                margin: 'auto'
                padding: '35px 0'
                paddingLeft: '170px'
              'Customize this guide for your' + extra_text
              INPUT
                type: 'text'
                key: 'zip_input'
                placeholder: 'Zip Code'
                style: {margin: '0 0 0 12px', fontSize: 24, height: 42, width: 152, padding: '4px 20px'}
                onChange: onChange
              BR null
              SPAN style: {fontSize: 18}, 'Your local congressional race and measures will be revealed!'

          DIV 
            style: 
              backgroundImage: "url(#{asset('greytriangle_down.png')})"
              backgroundRepeat: '(repeat-x)'
              backgroundSize: '18px 9px'
              height: 9


  Footer : ReactiveComponent
    displayName: 'Footer'
    render: ->
      DIV 
        style: 
          position: 'relative'
          padding: '2.5em 0 .5em 0'
          textAlign: 'center'
          zIndex: 0

        DIV style: {color: 'white', backgroundColor: '#93928E', marginTop: 48, padding: 18},
          DIV style: {fontSize: 18, fontStyle: 'italic', textAlign: 'left', width: 690, fontStyle: 'italic', margin: 'auto'},
            'Unlike voter guides generated by government, newspapers or advocacy organizations, Living Voters Guide is created '
            SPAN style: {fontWeight: 600}, 'by the people'
            ' and '
            SPAN style: {fontWeight: 600}, 'for the people'
            ' of Washington State. It\'s your platform to learn about candidate and ballot measures, decide how to vote and express your ideas. We believe that sharing our diverse opinions leads to making wiser decisions together. '
            A style: {color: 'white', textDecoration: 'underline', fontWeight: 'normal'}, href: '/about', 'Learn more'
            '.'

          DIV style: {marginTop: 20},
            FBLike()
            Tweet
              hashtags: 'lvguide'
              referer: 'https%3A%2F%2Flivingvotersguide.org%2F'
              related: 'lvguide'
              text: 'I%20flexed%20my%20civic%20muscle%20%40lvguide.'
              url: 'https%3A%2F%2Flivingvotersguide.org%2F'


        DIV style: {paddingTop: 24, paddingBottom: 12, fontSize: 18, fontWeight: 500, color: 'rgb(77,76,71)'},
          'Bug to report? Have a comment? Confused? '
          A href: "mailto:admin@livingvotersguide.org", style: {color: 'rgb(77,76,71)'},
            'Email us'

        DIV style: {paddingBottom: 18},

          DIV style: {textAlign: 'left', padding: '0 12px', color: 'rgb(131,131,131)', display: 'inline-block', fontSize: 15},
            A href: "http://seattlecityclub.org", style: {position: 'relative', top: 3, fontWeight: 400},
              IMG src: asset('livingvotersguide/cityclub.svg')

          DIV style: {textAlign: 'left', padding: '0 12px', display: 'inline-block', fontSize: 11, position: 'relative', top: -5},
            #"Fact-checking by "
            A href: 'http://spl.org', style: {textTransform: 'uppercase', textDecoration: 'none', color: 'rgb(6, 61, 114)', display: 'block', fontWeight: 600, width: 100}, target: '_blank', 
              'The Seattle Public Library'

        DIV style: {padding: 9},
          TechnologyByConsiderit()

customizations.livingvotersguide.NonHomepageHeader = customizations.livingvotersguide.HomepageHeader

FBShare = ReactiveComponent
  displayName: 'FBShare'

  componentDidMount: ->
    FB.XFBML.parse document

  render: -> 
    layout = 'button'
    SPAN 
      style: {display: 'inline-block', marginRight: 5, position: 'relative', top: -6}
      dangerouslySetInnerHTML: { __html: "<fb:share-button data-layout='#{layout}'></fb:share-button>"}
    

FBLike = ReactiveComponent
  displayName: 'FBLike'
  render : -> 
    page = 'http://www.facebook.com/pages/Living-Voters-Guide/157151824312366'
    IFRAME 
      style: {border: 'none', overflow: 'hidden', width: 90, height: 21}
      src: "//www.facebook.com/plugins/like.php?href=#{page}&send=false&layout=button_count&width=450&show_faces=false&action=like&colorscheme=light&font=lucida+grande&height=21"
      scrolling: "no"
      frameBorder: "0"
      allowTransparency: "true"

Tweet = ReactiveComponent
  displayName: 'Tweet'

  render: ->
    url = "https://platform.twitter.com/widgets/tweet_button.1410542722.html#?_=1410827370943&count=none&id=twitter-widget-0&lang=en&size=m"
    for url_param in ['hashtags', 'original_referer', 'related', 'text', 'url']
      if @props[url_param]
        url += "&#{url_param}=#{@props[url_param]}"

    IFRAME 
      src: url
      scrolling: "no"
      frameBorder: "0"
      allowTransparency: "true"
      className: "twitter-share-button twitter-tweet-button twitter-share-button twitter-count-none"
      style: {width: 57; height: 20}


styles += """
[subdomain="livingvotersguide"] .endorser_group {
  width: 305px;
  display: inline-block;
  margin-bottom: 1em;
  vertical-align: top; }
  [subdomain="livingvotersguide"] .endorser_group.oppose {
    margin-left: 60px; }
  [subdomain="livingvotersguide"] .endorser_group li, [subdomain="livingvotersguide"] .endorser_group a {
    font-size: 12px; }
  [subdomain="livingvotersguide"] .endorser_group ul {
    margin-left: 0px;
    padding-left: 10px; }
[subdomain="livingvotersguide"] .total_money_raised {
  font-weight: 600;
  float: right; }
[subdomain="livingvotersguide"] .funders li {
  list-style: none; }
  [subdomain="livingvotersguide"] .funders li .funder_amount {
    float: right; }
[subdomain="livingvotersguide"] .news {
  padding-left: 0; }
  [subdomain="livingvotersguide"] .news li {
    font-size: 13px;
    list-style: none;
    padding-bottom: 6px; }
[subdomain="livingvotersguide"] .editorials ul {
  padding-left: 10px; }
  [subdomain="livingvotersguide"] .editorials ul li {
    list-style: none;
    padding-top: 6px; }

"""


#####################
# Tigard
customizations.tigard = 
  Homepage: LearnDecideShareHomepage
  ProposalHeader: ProposalHeaderWithMenu

  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: ->
      DIV style: {textAlign: 'center'},
        STYLE null, 
          '.banner_link {color: #78d18b; font-weight: 600; text-decoration: underline;}'

        ProfileMenu()
          
        DIV style: {color: '#707070', fontSize: 32, padding: '20px 0', margin: '0px auto 0 auto', fontWeight: 800, textTransform: 'uppercase', position: 'relative'}, 
          'Help plan '
          A className: 'banner_link', href: 'http://riverterracetigard.com/', 'River Terrace'
          ', Tigard\'s newest neighborhood' 


#customizations.tigard.NonHomepageHeader = customizations.tigard.HomepageHeader



#####################
# City of Tigard
customizations.cityoftigard = 
  
  HomepageHeader : ReactiveComponent
    displayName: 'HomepageHeader'

    render: -> 
      logo_style = {height: 117, backgroundColor: 'white', borderRight: '2px solid white'}
      DIV style: {backgroundColor: '#253967'},
        ProfileMenu()

        DIV style: {height: 48},
          A href: '/', style: {position: 'absolute', top:0, zIndex: 999999},
            IMG className: 'logo', src: asset('cityoftigard/logo.png'), style: logo_style 


customizations.cityoftigard.NonHomepageHeader = customizations.cityoftigard.HomepageHeader


customizations.mos = 

  slider_pole_labels :
    individual: 
      support: 'Support'
      support_sub: 'the ban'
      oppose: 'Oppose'
      oppose_sub: 'the ban'
    group: 
      support: 'Supporters'
      support_sub: 'of the ban'      
      oppose: 'Opposers'
      oppose_sub: 'of the ban'

  show_crafting_page_first: true

##########
# Fill in default values for each unspecified field for 
# each subdomain customization
for own k,v of customizations
  _.defaults customizations[k], customizations.default

  customizations[k].key = "customizations/#{k}"
  save customizations[k]
