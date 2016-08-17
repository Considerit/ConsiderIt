
customizations['newa'] =
  SiteHeader: ShortHeader
    logo_height: 80


customizations['rupaulseason8'] =
  show_proposer_icon: false
  homepage_show_search_and_sort: false
  show_proposal_meta_data: false 

  point_labels: 
    pro: 'Love'
    pros: 'Love' 
    con: 'Shade'
    cons: 'Shade'
    your_header: "Throw your --valences--" 
    other_header: "Others' --valences--" 
    top_header: "Best --valences--" 
    
  slider_pole_labels: 
    support: 'YAAAAAAS'
    oppose: 'Hellz No!'

  SiteHeader: ->
    subdomain = fetch '/subdomain'   
    loc = fetch 'location'    
    homepage = loc.url == '/'

    masthead_style = 
      textAlign: 'left'
      backgroundColor: subdomain.branding.primary_color
      height: 45

    hsl = parseCssHsl(subdomain.branding.primary_color)
    is_light = hsl.l > .75

    if subdomain.branding.masthead
      _.extend masthead_style, 
        height: 300
        backgroundPosition: 'center'
        backgroundSize: 'cover'
        backgroundImage: "url(#{subdomain.branding.masthead})"

    else 
      throw 'ImageHeader can\'t be used without a branding masthead'

    DIV null,

      DIV
        style: masthead_style 

        back_to_homepage_button
          position: 'relative'
          marginLeft: 20
          display: 'inline-block'
          color: if !is_light then 'white'
          verticalAlign: 'middle'
          marginTop: 5


      DIV 
        style: 
          width: HOMEPAGE_WIDTH()
          margin: '40px auto'
          display: if !homepage then 'none'

        DIV 
          style: 
            fontSize: 52
            fontWeight: 300
            marginBottom: 20
            color: '#CE496E'

          "Welcome Hunties to season 8 of RuPaul's Drag Race!"

        DIV 
          style: 
            marginBottom: 12
            fontSize: 21

          """This is a space for you to serve the T, throw some shade, show some 
          love and share who you think has the Charisma, Uniqueness, Nerve and 
          Talent to be America's Next Drag Superstar! So, just between us 
          squirrel-friends, who do think will be win season 8?"""

        DIV 
          style: 
            fontSize: 21

          """You can change your votes each week. When a queen gets eliminated, we'll 
          Sashay away her from the list. Good luck! And Don't Fuck it Up!"""    




customizations['swotconsultants'] = 
  homepage_list_order: ['Strengths', 'Weaknesses', 'Opportunities', 'Threats']
  HomepageHeader: LegacyImageHeader()

customizations['carcd'] = customizations['carcd-demo'] = 
  show_proposer_icon: false
  homepage_show_search_and_sort: false

  slider_pole_labels: slider_labels.priority

  homepage_list_order: ['Serving Districts', 'Program Emphasis', 'Lagging Districts', 'Accreditation', \
                  'Questions', "CARCD's role in Emerging Resources", \
                  "CARCD's role in Regional Alignment", \
                  "CARCD's Role for the Community"]

  SiteHeader: -> 
    loc = fetch('location')

    homepage = loc.url == '/'

    DIV 
      style: 
        position: 'relative'
        width: HOMEPAGE_WIDTH()
        margin: 'auto'
        height: if !homepage then 180

      A
        href: 'http://carcd.consider.it'
        target: '_blank'
        style:
          position: 'absolute'
          top: 20
          left: -48 #(WINDOW_WIDTH() - 391) / 2
          zIndex: 5

        IMG
          src: asset('carcd/logo2.png')
          style:
            height: 145

      DIV
        style:
          # backgroundColor: "#F0F0F0"
          height: 82
          width: '100%'
          position: 'relative'
          top: 50
          left: 0
          #border: '1px solid #7D9DB5'
          #borderLeftColor: 'transparent'
          #borderRightColor: 'transparent'

        back_to_homepage_button 
          display: 'block'
          verticalAlign: 'top'
          left: -91
          top: 10
          color: 'black'
          position: 'relative'

      if homepage
        DIV 
          style: 
            paddingTop: 82
            width: HOMEPAGE_WIDTH()
            # paddingLeft: 70
            margin: 'auto'
            position: 'relative'

          DIV 
            style: 
              fontSize: 26
              fontWeight: 600
              # position: 'absolute'
              # top: -80
              color: '#746603'

            "We need your feedback!" 

          DIV 
            style: 
              fontSize: 20
              marginBottom: 18

            """This survey gives you a chance to influence the CARCD strategic plan and 
            our priorities for the next several years.  Please take the time to 
            respond to the questions below – elaborate, argue, tell us what you 
            really think!"""

          DIV 
            style: 
              fontSize: 20
              marginBottom: 6
            "Thank you for your time,"
            BR null
            "The CARCD team"



customizations['consider'] = 
  homepage_show_search_and_sort: false 
  opinion_filters: false 

  "list/Bug Reports" : 
    slider_pole_labels: slider_labels.relevance
    discussion_enabled: false
    list_one_line_desc: "Include your browser and device!"

  # opinion_filters: [ {
  #     label: 'consider.it staff'
  #     tooltip: null
  #     pass: (user) -> user.key in ['/user/1701', '/user/1707', '/user/30970']
  #   }]


  "list/Hard Tasks" : 
    slider_pole_labels: slider_labels.important_unimportant
    list_one_line_desc: "What tasks should we make significantly easier?"

  SiteHeader: -> 
    loc = fetch 'location'
    homepage = loc.url == '/'

    HEADER_HEIGHT = 30 
    DIV
      style:
        position: "relative"
        margin: "0 auto"
        backgroundColor: logo_red
        height: HEADER_HEIGHT
        zIndex: 1

      DIV
        style:
          width: CONTENT_WIDTH()
          margin: 'auto'

        back_to_homepage_button
          fontSize: 32
          color: 'white'
          position: 'absolute'
          top: -11
          left: 10

        SPAN 
          style:
            position: "relative"
            top: 4
            left: if window.innerWidth > 1055 then -23.5 else 0

          drawLogo HEADER_HEIGHT + 5, 
                  'white', 
                  (if @local.in_red then 'transparent' else logo_red), 
                  !@local.in_red,
                  false

        SPAN 
          style: 
            fontSize: 22
            position: 'relative'
            top: -5
            color: 'white'
            fontStyle: 'italic'

          'Issue Slate'


customizations['us'] = 
  show_proposer_icon: true

customizations['cimsec'] = 
  slider_pole_labels : slider_labels.effective_ineffective
  HomepageHeader: LegacyImageHeader()





customizations['monitorinstitute'] = 
  point_labels : point_labels.strengths_improvements
  slider_pole_labels : slider_labels.strong_weak

  homepage_list_order: ['Intellectual Agenda Items', 'Overall']

  HomepageHeader: ->
    section_style = 
      padding: '8px 0'
      fontSize: 16

    DIV
      style:
        position: 'relative'

      DIV 
        style: 
          width: CONTENT_WIDTH()
          margin: 'auto'
          paddingTop: 20
          position: 'relative'

        A 
          href: 'http://monitorinstitute.com/'
          target: '_blank'

          IMG 
            src: asset("monitorinstitute/logo.jpg")


        DIV 
          style: {}

          DIV 
            style:  
              color: "#BE0712"
              fontSize: 34
              marginTop: 40

            "The Monitor Institute intellectual agenda"

          DIV 
            style: 
              fontStyle: 'italic'
              marginBottom: 20
            'Spring 2015'

          DIV 
            style: 
              width: CONTENT_WIDTH() * .7
              borderRight: "1px solid #ddd"
              display: 'inline-block'
              paddingRight: 25

            P 
              style: section_style


              """
              Central to the Monitor Institute brand is the idea that we pursue 
              “next practice” in social impact. We do not simply master and teach 
              well‐established best practices, but treat those as table stakes and 
              focus our attention on the learning edges for the field. Our core 
              expertise is in helping social impact leaders and organizations 
              develop the skillsets they need to achieve greater progress than 
              in the past and prepare themselves for tomorrow’s context.
              """

            P 
              style: section_style

              """
              This document is a place for us to articulate two things: """
              SPAN
                style: 
                  fontStyle: 'italic'

                "what we believe"

              """ to be “next practice” today, and what """
              SPAN
                style: 
                  fontStyle: 'italic'

                "what we want to know"

              """ about how those practices can and will develop further. The former is our 
              point of view; the latter is the whitespace that is waiting to be 
              filled in over the coming three to five years.
              """





            P 
              style: section_style
              "It is designed to be used in a variety of ways:"

            UL
              style:
                listStylePosition: 'outside'
                paddingLeft: 30

              LI
                style: section_style
                """
                It is primarily a """

                SPAN
                  style: 
                    fontWeight: 600
                  "statement of strategy and vision"
                """. It does not contain 
                every next practice in the world, nor every important question to be 
                resolved, but only the ones that we believe are both (a) the most 
                transformative in the field of social impact and (b) those that we are 
                equipped and committed to working on. It must therefore be a living document, 
                revisited and revised often enough that it always reflects our most 
                up‐to‐date perspectives.
                """

              LI 
                style: section_style
                """
                Next, it is a """

                SPAN
                  style: 
                    fontWeight: 600
                  "rubric for making choices"

                """ that will keep us aligned and focused. 
                We will know we are doing well as a next‐practice consulting team when our 
                mix of commercial and eminence work promotes the points of view described 
                under """

                SPAN
                  style: 
                    fontStyle: 'italic'

                  "what we believe"

                " and helps us answer the questions listed under "

                SPAN
                  style: 
                    fontStyle: 'italic'

                  "what we want to know"

                """. When there is a question as to whether we should pursue an 
                opportunity that arrives or choose to focus resources in a given direction, 
                we can check our judgment by asking whether it will help us do either or both 
                of those things. That is equally true for scanning, for relationship‐building 
                and sales, for eminence projects, and for commercial work.
                """

          DIV 
            style: 
              display: 'inline-block'
              width: CONTENT_WIDTH() * .25
              verticalAlign: 'top'
              marginTop: 200
              paddingLeft: 25
              color: "#BE0712"
              fontWeight: 600

            """This is the intro to the draft intellectual agenda. Please provide 
               feedback on each proposed intellectual agenda item below."""





# customizations['hala'] = 
  show_proposer_icon: false
  show_proposal_meta_data: false 
  auth_require_pledge: true
  show_proposal_scores: true
  homepage_show_search_and_sort: false

  list_uncollapseable: true

  homepage_list_order: ['Preservation of Existing Affordable Housing',  'Urban Village Expansion', 'Historic Areas and Unique Conditions', 'Housing Options and Community Assets', 'Transitions', 'Urban Design Quality', 'Fair Chance Housing', 'Minimize Displacement']


  opinion_filters: ( -> 
    filters = 
      [ {
        label: 'focus group'
        tooltip: null
        pass: (user) -> passes_tags(user, 'hala_focus_group')
      }] 

    for home in ['Rented', 'Owned by me', 'Other']

      filters.push 
        label: "Home:#{home.replace(' ', '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['home.editable'] == home 

    for home in ['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']

      filters.push 
        label: "Housing_type:#{home.replace(' ', '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['housing_type.editable'] == home 

    for age in [0, 25, 35, 45, 55, 65]
      if age == 0 
        label = 'Age:0-25'
      else if age == 65
        label = 'Age:65+'
      else 
        label = "Age:#{age}-#{age+10}"

      filters.push 
        label: label
        tooltip: null 
        pass: do(age) -> (user) -> 
          u = fetch(user)
          u.tags['age.editable'] && parseInt(u.tags['age.editable']) >= age && parseInt(u.tags['age.editable']) < age + 10


    return filters 
    )()


  list_label_style: 
    color: seattle_vars.teal

  "list/Preservation of Existing Affordable Housing" : 

    list_items_title: 'Guidelines'
    list_label: "Preservation of Existing Affordable Housing"
    list_description: [
          """There are many buildings and other types of housing in Seattle that currently offer affordable rents. 
             In this set of questions, we are using the term "preservation" to describe retaining affordable rents 
             in existing buildings that are currently unsubsidized. In the next section, we address historic 
             preservation in the context of Mandatory Housing Affordability (MHA). We will be using the term AMI or Area Median Income. 
             For Seattle, here is a snapshot of those: 60% of AMI in 2016 is $37,980 annually for an individual, 
             $54,180 for a family of four. 
             See #{cluster_link('http://www.seattle.gov/Documents/Departments/Housing/PropertyManagers/IncomeRentLimits/Income-Rent-Limits_Rental-Housing-HOME.pdf','detailed numbers')}."""
          "What do you think of the following guidelines?"
        ]


  "list/Urban Village Expansion" : 

          
    list_items_title: 'Guidelines'
    list_label: "Urban Village Expansion Areas"
    list_description: [
      """Urban Villages are areas where there is a high density of essential services like 
         high quality transportation options, parks, employment, shopping and other amenities 
         that make it possible for residents to reduce their reliance on cars. It also means 
         that investments made in those neighborhoods are maximized because they are enjoyed 
         by the greatest number of people. Currently, the City is proposing to expand some 
         Urban Village boundaries to reflect improvements and increases in services in those 
         areas like the recent addition of light rail stations. To learn more about Urban 
         Villages, see the resources below:
         <ul style='padding-left:40px'>
            <li>#{cluster_link('http://seattlecitygis.maps.arcgis.com/apps/MapTools/index.html?appid=2c698e5c81164beb826ba448d00e5cf0', 'Interactive Map of Seattle’s Urban Villages')}</li>
            <li>#{cluster_link('http://www.seattle.gov/dpd/cs/groups/pan/@pan/documents/web_informational/dpdd016663.pdf', 'Urban Village Element in Seattle’s Comprehensive Plan' )}</li>
         </ul>
      """
      "What do you think of the following guidelines?"
    ]


  "list/Historic Areas and Unique Conditions" : 

          
    list_items_title: 'Guidelines'
    list_label: "Historic Areas and Unique Conditions"
    list_description: [
      """Seattle has many historic areas, some on the National Register and some known to locals 
         as places of historic or cultural significance.  As a community we have defined these areas, 
         in code and in practice, and their special heritage in our community."""

      "What do you think of the following guidelines?"
    ]



  "list/Housing Options and Community Assets" : 
    list_items_title: 'MHA Principles'    

    list_description: ->  
      DIV 
        style: 
          width: HOMEPAGE_WIDTH()

        DIV 
          style:
            color: seattle_vars.brown
            fontSize: 42
            fontWeight: 400
            marginBottom: 5
            

          SPAN 
            style: 
              borderBottom: "1px solid #{seattle_vars.brown}"
              color: seattle_vars.brown

            "Mandatory Housing Affordability "

            SPAN 
              style: 
                fontStyle: 'italic'
              "Principles"



        DIV 
          style: seattle_vars.section_description

          """Mandatory Housing Affordability (MHA) would require all new commercial and multifamily development either to 
             include affordable housing on site or make an in-lieu payment for affordable 
             housing using a State-approved approach. In exchange for the new affordable 
             housing requirement, additional development capacity will be granted in 
             the form of zoning changes. A community input process will help inform details 
             and location of the zoning changes to implement MHA. The MHA program is a 
             cornerstone of the """

          A 
            href: 'http://www.seattle.gov/hala/about'
            target: '_blank'
            style: 
              color: seattle_vars.teal
              textDecoration: 'underline'

            'Grand Bargain' 


          """ and is essential to achieving affordable 
             housing goals of 6,000 new affordable units over ten years. """

        DIV 
          style: _.extend {}, seattle_vars.section_description, 
            fontStyle: 'italic'
            marginTop: 20

          """The questions below assume that zoning changes will take place to fully implement MHA.  
             We are asking for input on how those zoning changes will look and feel.  These questions 
             are intended to get at the values that should drive these zoning changes.  What are the 
             important principles for us to keep in mind when we propose zoning changes in the next few months? 
             Bear in mind, the following elements are only a portion of the MHA. We will continue adding 
             pieces as they become available."""


        DIV 
          style:
            marginTop: 20
            fontSize: 42
            fontWeight: 300
            color: seattle_vars.teal
            marginBottom: 5

          "Housing Options and Community Assets"


        DIV 
          style: seattle_vars.section_description
            
          "What do you think of the following principles?"




  "list/Transitions" : 
    list_items_title: 'MHA Principles'    
    list_label: "Transitions"
    list_description: [
      """When taller buildings are constructed in areas that are zoned for more density, 
         neighboring buildings that are smaller sometimes feel out of place. Zoning 
         regulations can plan for transitions between higher- and lower-scale zones as 
         Seattle grows and accommodates new residents and growing families."""
      "What do you think of the following principles?"
    ]

  "list/Urban Design Quality" : 
    list_items_title: 'MHA Principles'    
    list_label: "Urban Design Quality"
    list_description: [
      """As Seattle builds new housing, we want to know what design features are 
         important to you. These elements address quality of life with design choices 
         for new residential buildings and landscaping."""
      "What do you think of the following principles?"
    ]


  "list/Minimize Displacement" : 

    list_is_archived: true
    list_uncollapseable: false
    list_items_title: 'Displacement proposal (archived)'
    list_label: "Minimize Displacement"
    list_description: """Displacement is happening throughout Seattle, and particular communities 
                    are at high risk of displacement. Data analysis and community outreach will 
                    help identify how growth may benefit or burden certain populations. We will 
                    use that data to make sure our strategies are reaching the communities most 
                    in need."""


  "list/Fair Chance Housing" : 
    list_is_archived: true
    list_items_title: 'Guidelines (archived)'    
    list_uncollapseable: false
    list_description: ->  
      DIV 
        style: 
          width: HOMEPAGE_WIDTH()

        DIV 
          style:
            color: seattle_vars.brown
            fontSize: 42
            fontWeight: 400
            marginBottom: 5
            

          SPAN 
            style: 
              borderBottom: "1px solid #{seattle_vars.brown}"
              color: seattle_vars.brown

            "HALA phase 1 discussion archive"

        DIV 
          style: _.extend {}, seattle_vars.section_description,
            marginBottom: 50

          "We're working on summarizing what we heard from phase 1, which will be posted "

          A 
            href: 'http://www.seattle.gov/hala/your-thoughts'
            target: '_blank'
            style: 
              color: seattle_vars.teal
              textDecoration: 'underline'

            'here'

          '.'


        DIV 
          style: 
            fontSize: 42
            fontWeight: 300
            color: seattle_vars.teal
            marginBottom: 5


          "Fair Chance Housing legislation"


        DIV 
          style: seattle_vars.section_description

          """Fair Chance Housing legislation is aimed at increasing access to Housing for 
             People with Criminal History. 
             An estimated one in every three adults in the United States has a criminal 
             record, and nearly half of all children in the U.S. have one parent with a 
             criminal record. Due to a rise in the use of criminal background checks during 
             the tenant screening process, people with arrest and conviction records face 
             major barriers to housing. Fair Chance Housing legislation could lessen some of 
             the barriers people face."""


  auth_questions : [
    { 
      tag: 'zip.editable'
      question: 'The zipcode where I live is'
      input: 'text'
      required: false
      input_style: 
        width: 85
      validation: (zip) ->
        return /(^\d{5}$)|(^\d{5}-\d{4}$)/.test(zip)
    }, {
      tag: 'age.editable'
      question: 'My age is'
      input: 'text'
      input_style: 
        width: 85        
      required: false
    }, {
      tag: 'race.editable'
      question: 'My race is'
      input: 'text'
      required: false
    }, {
    #   tag: 'hispanic.editable'
    #   question: "I'm of Hispanic origin"
    #   input: 'dropdown'
    #   options:['No', 'Yes']
    #   required: false
    # }, {
    #   tag: 'gender.editable'
    #   question: "My gender is"
    #   input: 'dropdown'
    #   options:['Female', 'Male', 'Transgender', 'Other']
    #   required: false
    # }, {
      tag: 'home.editable'
      question: "My home is"
      input: 'dropdown'
      options:['Rented', 'Owned by me', 'Other']
      required: false
    }, {
      tag: 'housing_type.editable'
      question: "I live in"
      input: 'dropdown'
      options:['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']
      required: false
    }



   ]

  auth_footer: """
    We are collecting this information to find out if this tool is 
    truly reaching the diverse population that reflects our city. Thank you!
    """


  HomepageHeader: SeattleHeader
    external_link: 'http://seattle.gov/hala'
    external_link_anchor: 'seattle.gov/hala'
    background_image_url: asset('hala/hala-header.png')
    image_style: 
      borderBottom: "7px solid #{seattle_vars.teal}"      
    quote: 
      who: 'Mayor Ed Murray'
      what: """
            We are facing our worst housing affordability crisis in decades. My vision is a city where 
            people who work in Seattle can afford to live here…We all share a responsibility in making Seattle 
            affordable. Together, HALA will take us there.
            """
    section_heading_style: 
      color: seattle_vars.brown

    sections: [
      {
        label: """Your thoughts on the Housing Affordability and Livability Agenda (HALA) are key to securing quality, 
                  affordable housing for Seattle for many years to come."""
        paragraphs: ["""HALA addresses Seattle's housing affordability crisis on many fronts. As we take proposals from idea 
                       to practice, we have been listening to the community to find out what matters to you. This online 
                       conversation reflects the diversity of ideas we've heard thus far and will continue 
                       to provide meaningful ideas on how to move forward."""]
      }, {
        label: """Please add your opinion below"""
        paragraphs: ["""
          We have listed many key recommendations below. This is an opportunity for you to shape the recommendations 
          before they are finalized. As the year progresses, we will be looking at other new programs, so check back often to weigh in on them. 
          The questions you see here are Phase 2 of this community conversation. Phase 1 questions that closed 
          recently can be found at the bottom of this page. We are also summarizing your feedback and posting it on 
          #{cluster_link('http://www.seattle.gov/hala/your-thoughts', 'our website')}.
          """
        ]
      }
    ]

    salutation: 
      text: 'Thanks for your time,'
      image: asset('hala/Seattle-Logo-and-signature2.jpg')
      from: 'HALA Team, City of Seattle'
      after: "p.s. Email us at #{cluster_link('mailto:halainfo@seattle.gov', 'halainfo@seattle.gov')} or visit our website at #{cluster_link('http://seattle.gov/HALA', 'seattle.gov/HALA')} if you want to know more."
    closed: false






customizations['bradywalkinshaw'] = 
  show_proposer_icon: true
  show_proposal_meta_data: false 
  auth_require_pledge: true
  show_proposal_scores: false
  homepage_show_search_and_sort: false

  list_label_style:
    color: seattle_vars.teal

  homepage_tabs: 
    'Economy': ['Economics']
    'Environment': ['Environment']
    'Education': ['Education']
    'Civil Rights': ['Civil Rights']

  "list/Civil Rights" : 
    list_items_title: 'Planks' 
    list_uncollapseable: true   

    list_label: "Civil Rights for the 21st Century"

    list_description: [
      "The son of a Cuban immigrant, Brady Piñero Walkinshaw will be Washington State’s first Latino and openly-gay member of Congress. He grew up in a rural farming community in Washington State, attended Princeton University with support from financial aid, and has worked professionally to create economic opportunity in the developing world.  As a State Representative, he brought together Republicans and Democrats to pass legislation to expand affordable housing, improve transportation, and increase healthcare and mental health services.  At 32 years old, Brady represents a new generation of positive Progressive leadership that will get things done in Congress for years to come. He’ll be a Progressive voice on national issues like climate change and focus on delivering for our local priorities."
      "Brady has the background and life experiences to represent this region’s unique diversity and be a voice for our community. His mother’s family were poor immigrants from Cuba seeking a better life and opportunity, and he will work to pass immigration reform to bring millions of immigrants out of the shadows. As a married gay man, Brady recognizes that the movement for social justice must continue to protect everyone’s civil rights. As the first person of color to represent our district in Congress, Brady will fight to end discrimination in the workplace, schools and our justice system."
      "The next generation of leadership in our country must continue the heroic efforts of those who have come before us to secure justice for every American, regardless of gender, orientation, race, economic status, or even citizenship status. We need leaders that reflect the diversity of our nation and understand from personal experience that our diversity is our greatest strength."
    ]


  "list/Economics" : 
    list_items_title: 'Planks' 
    list_uncollapseable: true   

    list_label: "Economic Leadership for the 21st Century"
    list_description: [
      "America’s next generation of leaders must balance our pace of growth with our core Progressive values, and there are few regions where this divide is more visible than Washington’s 7th district."
      "Our community has both an opportunity and the obligation to build innovative, community-based solutions to address the climate crisis. The first step in that process is supporting policies that transition our nation to a low-carbon economy – to halt the debilitating impact of climate change, keep our region pristine and beautiful, and spur a new wave of economic growth for the 21st Century."
      "Addressing climate change head on is a necessity. Our region has the values, the commitment, and the talent to build innovative reforms that can transform our economy and lead the global community in taking action."
      "Washington state is blessed with stunning nature, clean energy and an unparalleled quality of life that attracts innovative employers and highly skilled workers. We are fortunate to boast a strong economic base across diverse industries, and to serve as home to some of the world’s leading innovative companies. The next generation of leadership in this country must focus on continuing growth that generates prosperity while ensuring that every American has access to the opportunities and resources they need to share in prosperity."
      "Our economy should work for all of us, not just a wealthy few, and our region has all the tools we need to lead the nation in both innovation industries and equality for all our residents. We must generate a healthy economy that expands access to opportunity and jobs that pay a living wage."            
      "What do you think of the following planks? Click into any of them to read details and discuss."
    ]

  "list/Education" : 
    list_items_title: 'Planks' 
    list_uncollapseable: true   

    list_label: "Education Leadership for the 21st Century"
    list_description: [
      """Education and academic research are key to the future of our country, and we need to do everything in our power to support students as they prepare to compete in the global economy. Financial obstacles continue to restrict students from becoming the first in their families to go to college, and we must ensure that higher education is accessible for every single student."""
      "What do you think of the following planks? Click into any of them to read details and discuss."
    ]

  "list/Environment" : 
    list_items_title: 'Planks'    
    list_uncollapseable: true  
    list_label: "Environmental Leadership for the 21st Century"
    list_description: [
          """Brady is committed to forward-looking policies and will make fighting climate change his top priority.  He will fight for our Progressive values and bring Republicans and Democrats together to get things done, like investing in transportation and public transit improvements – such as light rail and express bus services – to reduce carbon emissions and improve our quality of life."""
          "What do you think of the following planks? Click into any of them to read details and discuss."
    ]

  SiteHeader: ->
    loc = fetch 'location'
    homepage = loc.url == '/'
    collapsed = WINDOW_WIDTH() < 1200

    DIV
      style:
        height: if homepage then 642 else 100
        margin: '0px auto'
        position: 'relative'
        overflow: 'hidden'
        backgroundColor: if !homepage then 'white'

      back_to_homepage_button
        verticalAlign: 'top'
        marginTop: 22
        marginRight: 15
        color: '#888'
        position: 'absolute'
        top: 10
        left: 10

      STYLE null,
        """
        header#main_header h1 {
          width: 230px;
          height: 130px;
          display: inline-block;
          margin-top: 16px;
          margin-bottom: #{if collapsed then '0' else '16'}px;
          margin-right: 12px;
          line-height: 1;
          font-family: 'futura-pt', 'Futura Std', Calibri, Verdana, sans-serif;
          }

        header#main_header h1 a {
          display: block;
          width: 100%;
          height: 100%;
          background-image: url(http://bradywalkinshaw.com/wp-content/themes/walkinshaw/images/logo_walk#{if !homepage then '_int' else ''}.png);
          background-size: contain;
          background-repeat: no-repeat;
          
          text-indent: -9999em;
          overflow: hidden;
          }


          header#main_header nav {
            vertical-align: top;
            display: inline-block;
            margin-top: #{if collapsed then '0' else '21'}px;
            }

          header#main_header nav ul {
            margin: 0;
            padding: 0;
            list-style: none;
            text-align: left;

            }

          header#main_header nav li {
            display: inline-block;
            position: relative;
            margin: 0 1px;
            text-transform: uppercase;
            font-size: 13.4px;
            font-weight: 900;
            }

          header#main_header nav li a {
            display: block;
            color: #{if homepage then '#fff' else '#777'};
            text-decoration: none;
            padding: 14px 19px;
            overflow: hidden;
            transition: .3s ease background, .3s ease color;
            }

          #hero {
            position: absolute;
            z-index: -1;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: black;
            background-image: url(http://bradywalkinshaw.com/wp-content/uploads/2016/07/hero_walkinshaw_v2_r3.jpg);
            background-position: center 70%;
            background-size: cover;
            }
        
        """


      if homepage 
        DIV 
          id: "hero" 


      HEADER 
        id: "main_header" 

        DIV 
          style: 
            textAlign: 'center'

          H1 null, 
            A 
              href: "http://bradywalkinshaw.com"
              "Brady Piñero Walkinshaw"

          if collapsed 
            BR null

          NAV 
            class: "topmenu"


            DIV null, 
              UL null, 
                LI null, 
                  A href: "http://bradywalkinshaw.com/meet_brady/",
                    'Meet Brady'
                LI null, 
                  A href: "http://bradywalkinshaw.com/endorsements/",
                    'Endorsements'
                LI null, 
                  A href: "http://bradywalkinshaw.com/#issues/",
                    'Issues'
                LI null, 
                  A href: "http://bradywalkinshaw.com/news/",
                    'News'
                LI null, 
                  A href: "http://bradywalkinshaw.com/results/",
                    'Results'
                LI null, 
                  A href: "http://bradywalkinshaw.com/resources/",
                    'Resources'
                LI null, 
                  A 
                    href: "http://bradywalkinshaw.com/donate/"
                    style: 
                      backgroundColor: '#db282e'
                      color: 'white'

                    'Donate'



      DIV 
        style: 
          fontSize: 24
          backgroundColor: 'rgba(0,0,0,.5)'
          position: 'absolute'
          bottom: 0
          width: '100%'
          textAlign: 'center'
          display: if !homepage then 'none'

        DIV style: textAlign: 'center',
          DIV 
            style:
              fontSize: 36
              fontWeight: 600
              #textAlign: 'right'
              color: 'white'
              #marginTop: 140
              #display: 'inline-block'
              #backgroundColor: 'rgba(0,0,0,.3)'
              padding: '0 10px 10px 0'
              # borderRadius: 26
              # border: "1px solid rgba(0,0,0,.8)"
              position: 'relative'
              top: 10

            SPAN 
              style: 
                color: '#7eef54'

              "What do you think about my platform?"
            
            # SPAN 
            #   style: 
            #     color: '#ffdd21'

            #   "I want to hear your opinion."


        HomepageTabs
          tab_style: 
            color: 'white'
            fontSize: 22




customizations['engageseattle'] = 
  show_proposer_icon: true
  show_proposal_meta_data: true 
  auth_require_pledge: true
  show_proposal_scores: true
  homepage_show_search_and_sort: false

  homepage_show_new_proposal_button: false

  list_uncollapseable: true

  homepage_list_order:          ['Value in engagement',  'Meeting preferences', 'Community Involvement Commission', 'Community Involvement Commission Roles', 'Engagement Ideas']
  homepage_lists_to_always_show: ['Value in engagement',  'Meeting preferences', 'Community Involvement Commission', 'Community Involvement Commission Roles', 'Engagement Ideas']

  list_label_style:
    color: seattle_vars.teal

  opinion_filters: ( -> 
    filters = [] 

    for home in ['Rented', 'Owned by me', 'Other']

      filters.push 
        label: "Home:#{home.replace(' ', '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['home.editable'] == home 

    for home in ['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']

      filters.push 
        label: "Housing_type:#{home.replace(' ', '_')}"
        tooltip: null 
        pass: do(home) -> (user) -> 
          u = fetch(user)
          u.tags['housing_type.editable'] == home 

    for age in [0, 25, 35, 45, 55, 65]
      if age == 0 
        label = 'Age:0-25'
      else if age == 65
        label = 'Age:65+'
      else 
        label = "Age:#{age}-#{age+10}"

      filters.push 
        label: label
        tooltip: null 
        pass: do(age) -> (user) -> 
          u = fetch(user)
          u.tags['age.editable'] && parseInt(u.tags['age.editable']) >= age && parseInt(u.tags['age.editable']) < age + 10


    return filters 
    )()



  "list/Value in engagement" : 
    ListHeader: -> 
      DIV style: height: 18

    list_show_new_button: false
    list_items_title: 'Values'
    list_label: "What do you value when engaging with the City about issues in your community, such as at public meetings?"


  "list/Meeting preferences" : 
    ListHeader: -> 
      DIV style: height: 18

    list_show_new_button: false
    list_items_title: 'Preferences'
    list_label: "How do you like to meet and what do you want to talk about?"


  "list/Community Involvement Commission" : 

    list_show_new_button: false
    ListHeader: -> 
      DIV style: height: 18

    list_label: 'Community Involvement Commission'
    list_description: """A Community Involvement Commission could be established to create a more inclusive and 
                   representative process for decision-making. Your comments are needed to help develop the 
                   charter and membership of the Commission. """


  "list/Community Involvement Commission Roles" : 
          
    list_items_title: 'Roles'

    list_label_style: 
      fontSize: 34
      fontWeight: 300
      color: '#666'
      marginBottom: 5

    list_label: "What additional roles, if any, should the Community Involvement Commission undertake?"


  "list/Engagement Ideas" : 
          
    list_items_title: 'Your ideas'
    list_label: "What’s your big idea on how the City can better engage with residents?"



  auth_questions : [
    { 
      tag: 'zip.editable'
      question: 'The zipcode where I live is'
      input: 'text'
      required: false
      input_style: 
        width: 85
      validation: (zip) ->
        return /(^\d{5}$)|(^\d{5}-\d{4}$)/.test(zip)
    }, {
      tag: 'age.editable'
      question: 'My age is'
      input: 'text'
      input_style: 
        width: 85        
      required: false
    }, {
      tag: 'race.editable'
      question: 'My race is'
      input: 'text'
      required: false
    }, {
    #   tag: 'hispanic.editable'
    #   question: "I'm of Hispanic origin"
    #   input: 'dropdown'
    #   options:['No', 'Yes']
    #   required: false
    # }, {
    #   tag: 'gender.editable'
    #   question: "My gender is"
    #   input: 'dropdown'
    #   options:['Female', 'Male', 'Transgender', 'Other']
    #   required: false
    # }, {
      tag: 'home.editable'
      question: "My home is"
      input: 'dropdown'
      options:['Rented', 'Owned by me', 'Other']
      required: false
    }, {
      tag: 'housing_type.editable'
      question: "I live in"
      input: 'dropdown'
      options:['A house or townhome', 'An apartment or condo', 'A single room', 'I\'m homeless']
      required: false
    }



   ]

  auth_footer: """
    We are collecting this information to find out if this tool is 
    truly reaching the diverse population that reflects our city. Thank you!
    """

  HomepageHeader: SeattleHeader
    external_link: 'http://www.seattle.gov/neighborhoods/equitable-outreach-and-engagement'
    external_link_anchor: 'seattle.gov/neighborhoods'
    background_image_url: asset('engageseattle/engageseattle_header.png')
    image_style: 
      borderBottom: "7px solid #{seattle_vars.turquoise}"      
    quote: 
      who: 'Mayor Ed Murray'
      what: """
            How we reach out to residents to bring them into the governing process reflects the City’s 
               fundamental commitment to equity and to democracy. We’re constantly looking to bring down barriers, 
               to open up more opportunities, and to reflect the face of our diverse and growing city.
            """
    section_heading_style: 
      color: seattle_vars.turquoise
      fontSize: 31

    external_link_style:
      display: 'none'
      
    sections: [
      {
        label: """Advancing Equitable Outreach and Engagement"""
        paragraphs: ["""Mayor Murray recently issued an #{cluster_link('http://www.seattle.gov/neighborhoods/equitable-outreach-and-engagement', 'Executive Order')} 
              directing the city to approach outreach and engagement in an equitable manner. 
              This directive to all City departments is based on a strong commitment to making 
              government more accessible, equitable and transparent."""]
      }, {
        label: """Please add your opinion below"""
        paragraphs: [
          """We need to hear from YOU about your experiences and what we can provide to make it easier for you to weigh in."""
          """At the heart of this #{cluster_link('http://www.seattle.gov/neighborhoods/equitable-outreach-and-engagement', 'Executive Order')} is a commitment to advance the effective deployment of equitable and inclusive community engagement strategies across all city departments. This is about making information and opportunities for participation more accessible to communities throughout the city."""
          """We need to bring more people into the conversations and create more opportunities for people to participate and be heard. We are striving toward making things easier and less exhaustive. This is about connecting communities to government and to one another."""
          """Your input will help guide this work moving forward.  In late-September the Mayor will propose legislation to the City Council advancing equitable outreach and engagement. Your input today will help shape this effort."""


        ]
      }
    ]

    salutation: 
      text: 'Thanks for your time,'
      image: asset('engageseattle/director_logo.png')
      from: 'City of Seattle'
    closed: false








customizations['cir'] = 
  slider_pole_labels : slider_labels.important_unimportant
  show_proposer_icon: false
  show_proposal_meta_data: true 
  auth_require_pledge: true
  show_proposal_scores: false
  homepage_show_search_and_sort: false

  list_uncollapseable: true

  list_label_style:
    color: '#159ed9'

  homepage_list_order: ['Questions']
  homepage_lists_to_always_show: ['Questions']


  "list/Questions" : 
          
    list_items_title: 'Your questions'

    list_label: 'Questions to pose to the Citizen Panel'

    list_description: """Now that you've heard the claims, its your turn to ask the questions! Below, 
                    you can ask questions. Furthermore, you can rate how important the answer to 
                    each question is to you. The most important question will be presented to the 
                    Citizen Initiative Review when it convenes."""


  auth_questions : [

    {
      tag: 'age.editable'
      question: 'My age is'
      input: 'text'
      input_style: 
        width: 85        
      required: false
    }, {
      tag: 'race.editable'
      question: 'My race is'
      input: 'text'
      required: false
    }, {
      tag: 'gender.editable'
      question: "My gender is"
      input: 'dropdown'
      options:['Female', 'Male', 'Transgender', 'Other']
      required: false
    }


   ]


  HomepageHeader: ->

    loc = fetch('location')

    homepage = loc.url == '/'

    section_style = 
      marginBottom: 20
      color: 'black'

    paragraph_heading_style = 
      display: 'block'
      fontWeight: 400
      fontSize: 40
      color: 'black'

    paragraph_style = 
      fontSize: 18
      color: '#666'
      paddingTop: 10
      display: 'block'


    statement = 
      Opponent: [
        "M97 would be the most costly and damaging tax increase in Oregon history.  Its $6 billion tax hike would hurt Oregon small businesses and consumers by increasing prices for almost all goods and services they buy, with no guarantee of how the funds would be spent."
        "Sponsors claim the tax only affects large corporations. But studies by the nonpartisan Legislative Revenue Office (LRO) and Northwest Economic Research Center (NERC) funded by M97’s sponsors, both found that most of the tax would be passed on to Oregon consumers through higher costs for everything from food, clothing, cars and housing to gas, electricity, insurance and healthcare. LRO estimated M97 would increase costs for a typical Oregon family by $600 per year."
        "Both studies also show the impacts would be regressive, by costing low- and middle-income families a higher percentage of their incomes than upper-income families. This would especially hurt rural counties, where average incomes are lower than urban/suburban counties."
        "Former State Economist Tom Potiowsky, who led the NERC study, said 97's tax is “like a sales tax on steroids.” A recent news story revealed that when sponsors tried pressuring him to say 97’s tax on C Corps wouldn’t be regressive for consumers Potiowsky said: “Applying [a gross receipts tax] to a narrow group of C corporations does not make regressivity go away.”"
        "Both studies also agreed that M97 would cause the loss of tens of thousands of private-sector jobs, by increasing operating costs for both large employers and small businesses statewide."
        "M97 would arbitrarily and unfairly make some businesses bigger losers than others.  It taxes C Corps but exempts S Corps and B Corps that sell the same products and make as much or more money. It would especially hurt businesses that have slim profit margins, like farms and grocery stores, and those that are already struggling. It would also burden startup companies that initially have little or no profit, making Oregon one of the worst states in which to locate a new business."
        "M97 also hurts nonprofits and local governments, since they would face increased costs of electricity, gas, insurance, healthcare and other goods and services."
        "We all want ample funding for education, healthcare and other vital services but M97 doesn’t provide a guarantee or accountability of where revenues will go. Legislative Counsel confirmed that the legislature “may appropriate revenues generated by the measure in any way it chooses.”  The July 20 Portland Tribune editorial noted: “The Legislature can spend the available money in any way it sees fit—on pensions, prisons or pet projects.”
        M97 is a damaging tax plan that would hurt small businesses, cause thousands of Oregon workers to lose their jobs and put the greatest burden on low- and middle-income families and seniors on fixed incomes.
        That’s why NO on 97 is urged by a broad coalition of small businesses, farmers, organizations, consumers, taxpayers and editorials in nearly every major newspaper."
      ],
      Proponent: [
        "Measure 97 makes large and out-of-state corporations pay more in taxes so Oregon families can have the schools, health care, and dignified retirement we deserve."
        "According to two separate independent studies, corporations pay lower taxes in Oregon than any other state. Large and out-of-state corporations like Bank of America, Comcast, Wal-Mart, and Monsanto make hundreds of millions of dollars from the business they do in Oregon but pay lower taxes here than anywhere else in the nation. "
        "At the same time, Oregon families are taking home $1,000 to $2,000 less each year, while corporate profits have risen 170% over the last decade. Oregon families are struggling and large corporations are not paying their fair share."
        "Low corporate taxes hurt schools and families. Oregon’s high school graduation rates are the 4th lowest in the country. 383,000 Oregonians still have no health insurance, and premiums are too expensive. 21,000 more seniors live in poverty today than a decade ago. If we pass Measure 97, we can address these problems."
        "Measure 97 increases the corporate tax only on C corporations and only on their sales above $25 million. 82% of the money raised comes from corporations headquartered outside Oregon. 85% of the money comes from corporations with more than $100 million in sales in Oregon. Less than 1% of Oregon businesses will be affected."
        "Measure 97 will hold big, out-of-state corporations accountable to paying their fair share of taxes. In 2013, 530 C corporations used tax credits to reduce their Oregon tax bill to $0, shorting the state by nearly $8.77 million in revenue. Additionally, because corporations hide profits overseas, Oregon loses $283 million per year in corporate income tax revenues. Measure 97’s simple, effective rate increase prevents corporations from exploiting off-shore loopholes." 
        "Money raised by Measure 97 is sorely needed, and will make a real difference in people’s lives. Oregon will be able to hire 6,000 new teachers, make sure every child in Oregon has health care, and allow 20,000 more Oregon seniors to afford to stay in their own homes when they retire by providing in-home care. "
        "Large corporations like Comcast and Kroger that oppose Measure 97 say Oregonians and not corporations will pay this new tax. Whenever we ask corporations to do their part they use scare tactics and threaten higher prices — economic data shows those threats are empty. Corporations charge the same for their products in every state, regardless of state taxes." 
        "Measure 97 gives Oregon families a chance for a better life. It will improve our schools and graduation rates, make healthcare affordable, and help our aging parents and grandparents retire with dignity."
      ]


    claims = 
      Opponent: [{
        statement: 'M97 would impose $6 billion in new taxes on sales of goods and services in Oregon: everything from food, clothing, cars and housing to gas, utilities, prescriptions and healthcare. It would be the largest, most damaging tax increase in state history.', 
        sources: [
          {text: 'Measure 97 Section 1'}, 
          {text: 'Portland Tribune, July 21', link: 'http://bit.ly/portlandtribune_tax-increase-threatens-family-budgets'},
          {text: 'LRO impact brief', link: 'http://bit.ly/CIRsources'}
        ]},{
        statement: 'M97 unfairly taxes sales, not profits. It would require businesses to pay 2.5% on sales even when they make no profit or lose money. That would especially hurt businesses that have slim profit margins, like grocery stores, medical clinics and farms.'
        sources: [
          {text: 'Measure 97 Section 1'}, 
          {text: 'Forbes', link: 'http://bit.ly/forbes_least-profitable-businesses'},
          {text: 'LRO impact brief', link: 'http://bit.ly/CIRsources'}
        ]},{
        statement: 'A nonpartisan study by the Legislative Revenue Office says M97\'s tax would increase costs consumers pay for essential goods and services, costing a typical family $600 more per year. A former State Economist said it\'s "like a sales tax on steroids."'
        sources: [
          {text: 'Legislative Revenue Office IP 28 Description and Analysis, table 1', link: 'http://bit.ly/OregonLRO_IP28-Research-Report'},
          {text: 'East Oregonian July 30', link: 'http://bit.ly/capitalbureau_gross-receipts-tax-on-steroids'},
          {text: 'LRO cost estimate to households', link: 'http://bit.ly/CIRsources'},
          {text: 'Shopping cart study', link: 'http://bit.ly/taxfoundation_IP28-would-raise-prices'}
        ]},{
        statement: 'A nonpartisan Legislative Revenue Office study shows 97\'s tax is regressive. It would increase consumer costs for food, medicine, clothing, housing, utilities and other essential goods and services, hurting families who can least afford it the most.'
        sources: [
          {text: 'Legislative Revenue Office IP 28 Description and Analysis, page 12 and table 11', link: 'http://bit.ly/OregonLRO_IP28-Research-Report'},
          {text: 'Shopping cart study', link: 'http://bit.ly/taxfoundation_IP28-would-raise-prices'},
          {text: 'ECONorthwest comparison of studies', link: 'http://bit.ly/CIRsources'},
        ]},{
        statement: 'M97 would hurt all Oregon employers, large and small, by increasing their operating costs and making them less competitive. The sponsors\' own study and the legislative study agree: M97 would cause the loss of tens of thousands of private sector jobs.'
        sources: [
          {text: 'Legislative Revenue Office IP 28 Description and Analysis, page 14', link: 'http://bit.ly/OregonLRO_IP28-Research-Report'},
          {text: 'ECONorthwest comparison of studies', link: 'http://bit.ly/CIRsources'},
        ]},{
        statement: '97 doesn’t guarantee the revenues will go to schools, healthcare or anything else. The Legislative Counsel Committee confirmed that the legislature “may appropriate revenues generated by the measure in any way it chooses.” It’s a blank check.'
        sources: [
          {text: 'Legislative Counsel Committee letter', link: 'http://bit.ly/CIRsources'},
          {text: 'Portland Tribune, July 2', link: 'http://bit.ly/portlandtribune_tax-increase-threatens-family-budgets'},
          {text: 'ECONorthwest testimony before the Fiscal Impact Statement Committee', link: 'http://bit.ly/CIRsources'},
          {text: 'Attorney General opinion, 37 Op Atty gen 599 (1975)', link: 'http://bit.ly/CIRsources'},

        ]},{
        statement: 'M97 makes it harder for local stores to compete with big chains. Chains ship and sell their own products and would pay 2.5%. Local stores get products via manufacturers and distributors who\'d each pay the tax, so their costs could go up 7.5% or more.'
        sources: [
          {text: 'Legislative Revenue Office IP 28 Description and Analysis, pages 11-12', link: 'http://bit.ly/OregonLRO_IP28-Research-Report'},
          {text: '"Tax on a Tax"" chart', link: 'http://bit.ly/CIRsources'},
          {text: 'Analysis by RCG Economics', link: 'http://bit.ly/CIRsources'},
        ]}
      ]

      Proponent: [{
        statement: 'M97 raises the corporate minimum tax on sales above $25 million on large and out-of-state C corporations, affecting less than 1% of businesses in Oregon. Money raised must fund Oregon’s early childhood education, K-12, healthcare, and senior services', 
        sources: [
          {link: 'http://oregonvotes.org/irr/2016/028text.pdf'}, 
          {link: 'https://www.oregonlegislature.gov/lro/Documents/IP%2028%20-%20RR%203-16.pdf'}, 
        ]},{
        statement: 'Oregon’s schools and critical services have been underfunded for decades, because large and out-of-state corporations don’t pay their fair share in taxes. In fact, Oregon ranks 50th in corporate taxes nationwide. Oregon families deserve better', 
        sources: [
          {link: 'http://www.ode.state.or.us/superintendent/priorities/2014-qem-report-volume-i-final--corrected.pdf'}, 
          {link: 'http://www.andersoneconomicgroup.com/Portals/0/AEG%20Tax%20Burden%20Study_2016_FINAL.pdf'}, 
          {link: 'http://www.ocpp.org/media/uploads/pdf/2016/06/rpt20160629-corporate-tax-shift_fnl.pdf'}, 
        ]},{
        statement: 'M97 would raise $3B annually, allowing for major investments in education, healthcare and senior services. This revenue could improve Oregon’s low graduation rates, make healthcare more accessible, and provide 20,000 more seniors with in-home care', 
        sources: [
          {link: 'https://www.oregonlegislature.gov/lro/Documents/IP%2028%20-%20RR%203-16.pdf'}, 
          {link: 'http://www.ode.state.or.us/superintendent/priorities/2014-qem-report-volume-i-final--corrected.pdf'}, 
          {link: 'http://www.oregonhealthequity.org/wp-content/uploads/2015/11/OHEA_MendtheGap_Web.pdf'}, 
          {link: 'https://www.pdx.edu/nerc/sites/www.pdx.edu.nerc/files/Retirement%20Security%20Final%20Report.pdf'},             
        ]},{
        statement: 'Without new taxes from large corporations, Oregon faces an estimated $750M a year of new budget cuts. This means deep cuts in every department and every school district. M97 would raise $3B a year to fund education, healthcare, and senior services', 
        sources: [
          {link: 'http://voteyeson97.org/wp-content/uploads/2016/08/A-Better-Oregon-report-8-1-16-final.pdf'}, 
          {link: 'http://www.statesmanjournal.com/story/news/politics/2016/07/11/why-oregon-budgeting-feast-and-famine/86944656'}, 
        ]},{
        statement: 'Because only large corporations pay M97, it will help small businesses be more competitive. M97 sets new corporate minimums that close corporate tax loopholes. A better educated workforce also means more qualified workers — which bolsters the economy', 
        sources: [
          {link: 'http://oregonvotes.org/irr/2016/028text.pdf'}, 
          {link: 'http://voteyeson97.org/oregon-families-pay-so-why-dont-corporations'}, 
          {link: 'http://www.oregonlive.com/education/index.ssf/2015/01/lack_of_technical_education_pr.html'},             
        ]},{
        statement: 'Oregon’s schools and critical services have faced cuts for decades. Since 1990, every OR governor has tried to fix budget shortfalls and stop the cuts. Oregonians can’t afford to wait any longer. Research and polls show M97 can finally fix this', 
        sources: [
          {link: 'https://icitizen.com/insights/oregon-poll-results-june-2016/'}, 
          {link: 'http://www.statesmanjournal.com/story/news/politics/2016/07/11/why-oregon-budgeting-feast-and-famine/86944656/'}, 
          {link: 'http://ouroregon.org/cuts-are-not-the-solution/'},     
          {link: 'http://klcc.org/post/oregon-school-funding-still-challenge-25-years-after-measure-5'}
        ]},{
        statement: 'Voters should ask themselves: Should large and out of state corporations pay their fair share in Oregon taxes? Do Oregon kids deserve good schools? Should all families have affordable health care? Should seniors get a dignified retirement?', 
        sources: []},
      ]

    DIV
      style:
        position: 'relative'
        width: HOMEPAGE_WIDTH()
        margin: 'auto'

      A 
        href: 'http://healthydemocracy.org'

        IMG
          style: 
            paddingTop: 10
            width: '296px'
            display: 'block'
            position: 'relative'
            left: -42

          src: asset('CIR/healthy-democracy-logo.png')


      if homepage 

        DIV 
          style: 
            padding: '20px 0'
            #marginTop: 50

          DIV 
            style: 
              width: HOMEPAGE_WIDTH()
              margin: 'auto'


            DIV 
              style: section_style


              SPAN 
                style: _.extend {}, paragraph_heading_style, 
                  marginTop: 10

                """Please help identify the most important question for our Citizen Panel to 
                   answer about Ballot Measure 97"""
              
              SPAN 
                style: paragraph_style
                """Below you will find official information about this measure, as well as claims that 
                   supporters and opposers of the measure are making. Additional information can be 
                   found on """

                A 
                  href: 'https://ballotpedia.org/Oregon_Business_Tax_Increase_Initiative_(2016)'
                  target: '_blank'
                  style: 
                    textDecoration: 'underline'
                    color: '#159ed9'

                  'ballotpedia.org'
                '.'


              SPAN 
                style: paragraph_style
                """After perusing this information, please give us your opinion about the question whose 
                   answer will make the biggest impact on whether you will vote for or against this 
                   measure. We will be ending the online input on Tuesday, August 16 in time to have 
                   your question printed in the official CIR Citizen Panel Manual."""

            DIV 
              style: section_style


              SPAN 
                style: 
                  display: 'block'
                  fontWeight: 400
                  fontSize: 28
                  color: 'black'

                """Measure 97: Oregon Business Tax Increase Initiative"""
        
              SPAN 
                style: paragraph_style

                """Increases corporate minimum tax when sales exceed $25 million; funds education, healthcare, senior services"""

              ExpandableSection
                label: 'Explanatory Statement'
                text: 
                  DIV null,
                    DIV style: paragraph_style,
                      "Ballot Measure 97 increases the corporate minimum tax for corporations with at least $25 million in Oregon sales. Currently, Oregon C corporations pay the higher of either an excise tax or a minimum tax based on the corporation’s sales in Oregon."
                    DIV style: paragraph_style,
                      "Ballot Measure 97 increases the annual minimum tax on corporations with Oregon sales of more than $25 million. It imposes a minimum tax of $30,001 plus 2.5 percent of amount of sales above $25 million. Oregon sales under $25 million would not be affected."
                    DIV style: paragraph_style,
                      "Ballot Measure 97 exempts “benefit companies” from the increased rate of minimum tax. “Benefit companies” are defined under Oregon law."
                    DIV style: paragraph_style,
                      "Ballot Measure 97 states that revenues generated from the increase in the corporate minimum tax are to be used to provide additional funding for education, healthcare and services for senior citizens."                    


              ExpandableSection
                label: 'Estimate of Financial Impact'
                text: 
                  DIV null,
                    DIV style: paragraph_style,
                      "The financial impact on state revenues is anticipated to be $548 million in new revenue in the 2015-17 biennium; $6.1 billion in the 2017-19 biennium and $6.0 million in the 2019-21 biennium. The annual financial impact on revenue would be approximately half of the biennial revenue amount."
                    DIV style: paragraph_style,
                      "The financial impact on state expenditures is indeterminate. The increased revenue will trigger increased expenditures by the state in the areas of public early childhood and kindergarten through grade 12 education, health care, and senior services, but the exact amount and the specific uses within the three identified programs cannot be determined."
                    DIV style: paragraph_style,
                      "There is no direct financial effect on local government expenditures or revenues."




              for section in ['Proponent', 'Opponent']


                ExpandableSection
                  label: "#{section} Claims"
                  text: 
                    DIV null,
                      for claim, idx in claims[section]
                        DIV 
                          style: _.extend {}, paragraph_style, 
                            marginLeft: 22
                            marginTop: 10

                          DIV 
                            style: 
                              fontWeight: 600
                              textDecoration: 'underline'
                            "Claim #{idx + 1}"
                          DIV 
                            style: {}

                            claim.statement

                          if claim.sources?.length > 0                           
                            UL 
                              style: 
                                marginLeft: 28
                                marginTop: 5

                              for src in claim.sources
                                LI 
                                  style: 
                                    listStyle: 'outside'

                                  if src.link 
                                    A 
                                      href: src.link 
                                      target: '_blank'
                                      style: 
                                        textDecoration: 'underline'
                                        color: '#159ed9'

                                      src.text or src.link
                                  else 
                                    src.text 
                      DIV 
                        style: 
                          marginLeft: 22
                          marginTop: 10
                        ExpandableSection
                          label: "#{section} Position Statement"
                          text: 
                            DIV 
                              style: 
                                marginLeft: 22

                              for para in statement[section]
                                DIV style: paragraph_style,
                                  para 




customizations['seattle2035'] = 
  show_proposer_icon: true
  auth_require_pledge: true

  homepage_list_order: ['Key Proposals', 'Big Changes', 'Overall']

  "list/Overall" : 
    point_labels: point_labels.strengths_weaknesses
    slider_pole_labels: slider_labels.yes_no


  auth_questions : [
    { 
      tag: 'zip.editable'
      question: 'The zipcode where I live is'
      input: 'text'
      required: false
      input_style: 
        width: 85
      validation: (zip) ->
        return /(^\d{5}$)|(^\d{5}-\d{4}$)/.test(zip)
    }, {
      tag: 'age.editable'
      question: 'My age is'
      input: 'text'
      input_style: 
        width: 85        
      required: false
    }, {
      tag: 'race.editable'
      question: 'My race is'
      input: 'text'
      required: false
    }, {
      tag: 'hispanic.editable'
      question: "I'm of Hispanic origin"
      input: 'dropdown'
      options:['No', 'Yes']
      required: false
    }, {
      tag: 'gender.editable'
      question: "My gender is"
      input: 'dropdown'
      options:['Female', 'Male', 'Transgender', 'Other']
      required: false
    }, {
      tag: 'home.editable'
      question: "My home is"
      input: 'dropdown'
      options:['Rented', 'Owned by me', 'Other']
      required: false
    }]


  HomepageHeader: SeattleHeader
    external_link: 'http://2035.seattle.gov/'
    external_link_anchor: '2035.seattle.gov'
    background_image_url: asset('seattle2035/banner.png')
    image_style: 
      borderBottom: "4px solid #{seattle_vars.pink}"      

    section_heading_style: 
      color: seattle_vars.pink
      fontSize: 28

    external_link_style:
      color: seattle_vars.pink
      
    sections: [
      {
        label: """Let’s talk about how Seattle is changing"""
        label_style: 
          fontSize: 44
          marginTop: 10

        paragraphs: ["""
          Seattle is one of the fastest growing cities in America, expecting to add 
          120,000 people and 115,000 jobs by 2035. We must plan for how 
          and where that growth occurs.
          """]
      }, {
        label: """The Seattle 2035 draft plan addresses Seattle’s growth"""
        paragraphs: [
          """We are pleased to present a #{cluster_link('http://2035.seattle.gov', 'Draft Plan')} 
            for public discussion. The Draft Plan contains hundreds of 
            policies that guide decisions about our city, including 
            Key Proposals for addressing growth and change. 
            These Key Proposals have emerged from conversations among 
            City agencies and through 
            #{cluster_link('http://www.seattle.gov/dpd/cs/groups/pan/@pan/documents/web_informational/p2262500.pdf', 'public input')}.
          """
        ]
      }, {
        label: """We need your feedback on the Key Proposals in the Draft Plan"""
        paragraphs: [
          """
          We have listed below some Key Proposals in the draft.
          Do these Key Proposals make sense for Seattle over the coming twenty years? 
          Please tell us by adding your opinion below. Your input will influence 
          the Mayor’s Recommended Plan, 
          #{cluster_link('http://2035.seattle.gov/about/faqs/#how-long', 'coming in 2016 ')}!
          """
        ]
      }
    ]

    salutation: 
      text: 'Thanks for your time,'
      image: asset('seattle2035/DPD Logo.svg')
      from: 'City of Seattle'
      after:  """p.s. Email us at #{cluster_link("mailto:2035@seattle.gov", "2035@seattle.gov")}
                 if you would like us to add another Key Proposal below for 
                 discussion or you have a comment about another issue in the Draft Plan.
              """
    closed: true





customizations['foodcorps'] = 
  point_labels : point_labels.strengths_weaknesses
  slider_pole_labels : slider_labels.ready_not_ready

  SiteHeader: -> 
    loc = fetch('location')

    homepage = loc.url == '/'

    DIV 
      style: 
        position: 'relative'
        height: 200

      IMG
        src: asset('foodcorps/logo.png')
        style:
          height: 160
          position: 'absolute'
          top: 10
          left: (WINDOW_WIDTH() - CONTENT_WIDTH()) / 2
          zIndex: 5


      DIV
        style:
          background: "url(#{asset('foodcorps/bg.gif')}) repeat-x"
          height: 68
          width: '100%'
          position: 'relative'
          top: 116
          left: 0

      back_to_homepage_button
        top: 52
        left: 15
        color: 'white'
        position: 'relative'


customizations['sosh'] = 
  point_labels : point_labels.strengths_weaknesses
  slider_pole_labels : slider_labels.yes_no
  SiteHeader: LegacyImageHeader()

customizations['schools'] = 
  list_opinions_title: "Students' opinions"
  slider_pole_labels : slider_labels.agree_disagree


customizations['allsides'] = 
'list/Classroom Discussions':
  list_opinions_title: "Students' opinions"
'list/Civics':
  list_opinions_title: "Citizens' opinions"

show_crafting_page_first: true
show_histogram_on_crafting: false
has_homepage: false




customizations['humanities-los'] = 

  point_labels : point_labels.strengths_weaknesses
  slider_pole_labels : slider_labels.yes_no
  list_opinions_title: "Students' feedback"

  "list/Essential Questions 8-2": 
    list_opinions_title: "Student responses"
    slider_pole_labels: slider_labels.agree_disagree
    point_labels: point_labels.challenge_justify


  "list/Essential Questions 8-1": 
    list_opinions_title: "Student responses"
    slider_pole_labels: slider_labels.agree_disagree
    point_labels: point_labels.challenge_justify


  "list/Monuments 8-2" : 
    point_labels : point_labels.strengths_weaknesses
    slider_pole_labels : slider_labels.ready_not_ready
    list_opinions_title: "Students' feedback"

  "list/Monuments 8-1" : 

    point_labels : point_labels.strengths_weaknesses
    slider_pole_labels : slider_labels.ready_not_ready
    list_opinions_title: "Students' feedback"


customizations['collective'] = 
  show_proposal_meta_data: false 
  homepage_show_search_and_sort: false 

  "/list/Contributions": 
    slider_pole_labels: slider_labels.important_unimportant  

  "/list/Licenses":
    slider_pole_labels: slider_labels.yes_no


customizations['anup2015'] = 
  slider_pole_labels :
    support: 'Accept'
    oppose: 'Reject'

  list_opinions_title: "PC's ratings"

  homepage_list_order: ['Submissions', 'Under Review', 'Probably Accept', 
                  'Accepted', 'Probably Reject', 'Rejected']



customizations['random2015'] = _.extend {}, 
  slider_pole_labels :
    support: 'Accept'
    oppose: 'Reject'

  list_opinions_title: "PC's ratings"

  homepage_list_order: ['Submissions', 'Under Review', 'Probably Accept', 
                  'Accepted', 'Probably Reject', 'Rejected']


  opinion_value: (o) -> 3 * o.stance,
  "/proposal/2638" : 
    point_labels: point_labels.strengths_limitations
    slider_pole_labels: slider_labels.yes_no
  "/proposal/2639" : 
    point_labels: point_labels.strengths_weaknesses
    slider_pole_labels: slider_labels.yes_no
    
customizations['program-committee-demo'] = 
  slider_pole_labels :
    support: 'Accept'
    oppose: 'Reject'

  list_opinions_title: "PC's ratings"

  homepage_list_order: ['Submissions', 'Under Review', 'Probably Accept', 
                  'Accepted', 'Probably Reject', 'Rejected']


customizations.enviroissues = 
  show_crafting_page_first: true

  SiteHeader: ->
    loc = fetch 'location'
    homepage = loc.url == '/'

    DIV
      style:
        width: CONTENT_WIDTH()
        margin: '20px auto'
        position: 'relative'

      back_to_homepage_button
        display: 'inline-block'
        verticalAlign: 'top'
        marginTop: 22
        marginRight: 15
        color: '#888'


      IMG
        src: asset('enviroissues/logo.png')

customizations.fidoruk = 
  collapse_proposal_description_at: 300

  auth_require_pledge: true

  show_proposal_scores: false

  opinion_filters: [ 
    {
      label: 'Account holder'
      tooltip: null
      pass: (user) -> passes_tags(user, 'fidor_account_holder')
      icon: "<span style='color:green'>account-holder</span>"

    }, {
      label: 'Community member'
      tooltip: null
      pass: (user) -> passes_tags(user, 'fidor_community_member')
      icon: "<span style='color:blue'>community</span>"      
    },{
      label: 'Business member'
      tooltip: null
      pass: (user) -> passes_tags(user, 'fidor_business_member')
      icon: "<span style='color:orange'>business</span>"      
    }, {
      label: 'Fidor staff'
      tooltip: null
      pass: (user) -> passes_tags(user, 'fidor_staff')
      icon: "<span style='gray'>staff</span>"      
    },     
  ]

  SiteHeader: ->
    subdomain = fetch '/subdomain'   
    loc = fetch 'location'

    hsl = parseCssHsl(subdomain.branding.primary_color)
    is_light = hsl.l > .75

    homepage = loc.url == '/'

    DIV 
      style:
        minHeight: 70


      DIV
        style: 
          width: (if homepage then HOMEPAGE_WIDTH() else BODY_WIDTH() ) + 130
          margin: 'auto'


        back_to_homepage_button
          display: 'inline-block'
          color: if !is_light then 'white'
          verticalAlign: 'middle'
          marginTop: 5


        if subdomain.branding.logo
          A 
            href: if subdomain.external_project_url then subdomain.external_project_url
            style: 
              verticalAlign: 'middle'
              #marginLeft: 35
              display: 'inline-block'
              fontSize: 0
              cursor: if !subdomain.external_project_url then 'default'

            IMG 
              src: subdomain.branding.logo
              style: 
                height: 80

        DIV 
          style: 
            color: if !is_light then 'white'
            marginLeft: 35
            fontSize: 32
            fontWeight: 400
            display: 'inline-block'
            verticalAlign: 'middle'
            marginTop: 5

          if homepage 
            DIV
              style: 
                paddingBottom: 10
                fontSize: 16
                color: '#444'

              "Please first put your proposal into the Fidor Community platform, and link to it in your consider.it proposal.
              This allows us to converse, update our opinions, and track progress over a longer period of time."

customizations.bitcoin = 
  show_proposer_icon: true
  collapse_proposal_description_at: 300

  auth_require_pledge: true

  slider_pole_labels: slider_labels.support_oppose

  show_proposal_scores: true

  homepage_list_order: ['Blocksize Survey', 'Proposals']   

  'list/Blocksize Survey': 
    show_crafting_page_first: false

    slider_handle: slider_handle.triangley
    discussion_enabled: false
    show_proposal_scores: false
    slider_pole_labels: 
      support: ''
      oppose: ''

    slider_regions:[{
        label: '1mb', 
        abbrev: '1mb'
      },{
        label: '2mb', 
        abbrev: '2mb'
      },{
        label: '4mb', 
        abbrev: '4mb'
      },{
        label: '8mb', 
        abbrev: '8mb'
      },{
        label: '16mb', 
        abbrev: '16mb'
      }]


  tawkspace: 'https://tawk.space/embedded-space/bitcoin'

  auth_questions : [
    {
      tag: 'bitcoin_developer.editable'
      question: 'Others consider me a bitcoin developer'
      input: 'dropdown'
      options:['No', 'Yes']
      required: false
    },{
      tag: 'bitcoin_business.editable'
      question: 'I operate these bitcoin businesses (urls)'
      input: 'text'
      required: false
    }
  ]


  opinion_filters: [ {
      label: 'users'
      tooltip: 'User sent in verification image.'
      pass: (user) -> passes_tags(user, 'verified')
      icon: "<span style='color:green'>\u2713 verified</span>"

    }, {
      label: 'miners'
      tooltip: 'Controls > 1% hashrate.'
      pass: (user) -> passes_tags(user, ['bitcoin_large_miner', 'verified'])
      icon: "<span style=''>\u26CF miner</span>"      
    }, {
      label: 'developers'
      tooltip: 'Self reported in user profile.'
      pass: (user) -> passes_tags(user, ['bitcoin_developer.editable', 'verified'])
      icon: "<span style=''><img src='https://dl.dropboxusercontent.com/u/3403211/dev.png' style='width:20px' /> developer</span>"            
    },{
      label: 'businesses'
      tooltip: 'Self reported in user profile'
      pass: (user) -> passes_tags(user, ['bitcoin_business.editable', 'verified'])
      icon: (user) -> "<span style=''>operates: #{fetch(user).tags['bitcoin_business.editable']}</span>"            

    }
  ]


customizations['kulahawaiinetwork'] = 
  show_proposer_icon: true
  collapse_proposal_description_at: 300

  homepage_lists_to_always_show: ['Leadership', 'Advocacy & Public Relations', 'Building Kula Resources & Sustainability', \
                           'Cultivating Kumu', 'Relevant Assessments', 'Teacher Resources', \
                           '‘Ōlelo Hawai’i', '3C Readiness'] 

  homepage_tabs: 
    'Advocacy & Public Relations': ['Advocacy & Public Relations']
    'Building Kula Resources & Sustainability': ['Building Kula Resources & Sustainability']
    'Cultivating Kumu': ['Cultivating Kumu']
    'Relevant Assessments': ['Relevant Assessments']
    'Teacher Resources': ['Teacher Resources']
    '‘Ōlelo Hawai’i': ['‘Ōlelo Hawai’i']
    '3C Readiness': ['3C Readiness']
    'Leadership': ['Leadership']


  'list/Advocacy & Public Relations':
    list_items_title: 'Ideas'

    list_label: 'Advocacy & Public Relations'
    list_description: [
      """A space to discuss ideas about two things:
         <ul style='list-style:outside;padding-left:40px'>
           <li>Sharing information and activating kula communities to improve policies 
               related to (1) ʻŌlelo Hawaiʻi, culture, and ʻāina-based education and 
               (2) Positions on issues supported by the network</li>
           <li>Creating and sharing stories of kula and network successes to improve 
               public perceptions and gain support for Hawaiian-focused education & outcomes.</li>
         </ul>
      """
    ]

  'list/Building Kula Resources & Sustainability':
    list_items_title: 'Ideas'
    list_label: 'Building Kula Resources & Sustainability'
    list_description: "A space to discuss ideas around joining efforts across kula to enhance opportunities to increase kula resources and sustainability."


  'list/Cultivating Kumu':
    list_items_title: 'Ideas'
    list_label: 'Cultivating Kumu'
    list_description: [
      """A space to discuss ideas about two things:
         <ul style='list-style:outside;padding-left:40px'>
           <li>Attracting, training, recruiting, growing, retaining, and supporting the preparation of novice teachers, excellent kula leaders, kumu, and staff for learning contexts where ʻōlelo Hawaiʻi, culture, and ʻāina-based experiences are foundational.</li>
           <li>Growing two related communities of kumu and kula leaders who interact regularly, share and learn from one another, develop pilina with one another, and provide support ot one another.</li>
         </ul>
      """
    ]

  'list/Relevant Assessments':
    list_items_title: 'Ideas'

    list_label: 'Relevant Assessments'
    list_description: "A space to discuss ideas around the development of shared assessments that honor the many dimensions of student growth involved in learning contexts where ʻōlelo Hawaiʻi, culture, and ʻāina-based experiences are foundational. Are we willing to challenge the mainstream concep to education success?"


  'list/Teacher Resources':
    list_items_title: 'Ideas'
    list_label: 'Teacher Resources'
    list_description: "A space to discuss ideas around the creation of new (and compiling existing) ʻōlelo Hawaiʻi, culture, and ʻāina-based teaching resources to share widely in an online waihona."


  'list/‘Ōlelo Hawai’i':
    list_items_title: 'Ideas'
    list_label: '‘Ōlelo Hawai’i'
    list_description: "A space to discuss ideas around the way we use our network of Hawaiian Educational Organizationsʻ Synergy to increase the amount of Hawaiian Language speakers so that the language will again be thriving!"

  'list/3C Readiness':
    list_items_title: 'Ideas'
    list_label: '3C Readiness'
    list_description: "A space to discuss ideas around nurturing college, career, and community readiness in haumāna. How do we provide experiences for haumāna that integrate and bridge high-school, college, career, and community engagement experiences?"

  'list/Leadership':
    list_items_title: 'Ideas'
    list_label: 'Leadership'
    list_description: "A space for network leaders to gather mana’o."

  SiteHeader: HawaiiHeader
    background_image_url: asset('hawaii/KulaHawaiiNetwork.jpg')
    title: "Envision the Kula Hawai’i Network"
    subtitle: 'Please share your opinion. Click any proposal below to get started.'
    # background_color: '#78d18b'
    # logo_width: 100




customizations.dao = _.extend {}, 
  show_proposer_icon: true
  collapse_proposal_description_at: 300

  homepage_show_search_and_sort: true

  auth_require_pledge: true

  homepage_show_new_proposal_button: false 

  show_crafting_page_first: false

  homepage_default_sort_order: 'trending'

  homepage_list_order: ['Proposed to DAO', 'Under development', 'New', 'Needs more description', 'Funded', 'Rejected', 'Archived', 'Proposals', 'Ideas', 'Meta', 'DAO 2.0 Wishlist', 'Hack', 'Hack meta']
  homepage_lists_to_always_show: ['Proposed to DAO', 'Under development',  'Proposals', 'Meta']

  new_proposal_tips: [
    'Describe your idea in sufficient depth for others to evaluate it. The title is usually not enough.'
    'Link to any contract code, external resources, or videos.'
    'Link to any forum.daohub.org or /r/thedao where more free-form discussion about your idea is happening.'
    'Take responsibility for improving your idea given feedback.'
  ]

  homepage_tabs: 
    'Inspire Us': ['Ideas', 'Proposals']
    'Proposal Pipeline': ['New', 'Proposed to DAO', 'Under development',  'Needs more description', 'Funded', 'Rejected', 'Archived']
    'Meta Proposals': ['Meta', 'Hack', '*']
    'Hack Response': ['Hack', 'Hack meta']
  #homepage_default_tab: 'Hack Response'


  'list/Under development':
    list_is_archived: false

  'list/Proposed to DAO':
    list_one_line_desc: 'Proposals submitted to The Dao\'s smart contract'

  'list/Needs more description':
    list_is_archived: true
    list_one_line_desc: 'Proposals needing more description to evaluate'

  'list/Funded':
    list_is_archived: true 
    list_one_line_desc: 'Proposals already funded by The DAO'

  'list/Rejected':
    list_is_archived: true   
    list_one_line_desc: 'Proposals formally rejected by The DAO'
  
  'list/Archived':
    list_is_archived: true 

  'list/Done':
    list_is_archived: true

  'list/Proposals':
    list_items_title: 'Ideas'

  'list/Name the DAO':
    list_is_archived: true

  SiteHeader: ->
    homepage = fetch('location').url == '/'

    DIV
      style:
        position: 'relative'
        background: "linear-gradient(-45deg, #{dao_vars.purple}, #{dao_vars.blue})"
        paddingBottom: if !homepage then 20
        borderBottom: "2px solid #{dao_vars.yellow}"


      onMouseEnter: => @local.hover=true;  save(@local)
      onMouseLeave: => @local.hover=false; save(@local)




      STYLE null,
        '''.profile_anchor.login {font-size: 26px; padding-top: 16px;}
           p {margin-bottom: 1em}'''


      DIV 
        style: 
          marginLeft: 70


        back_to_homepage_button            
          display: 'inline-block'
          color: 'white'
          opacity: .7
          position: 'relative'
          left: -60
          top: 4
          fontWeight: 400
          paddingLeft: 25 # Make the clickable target bigger
          paddingRight: 25 # Make the clickable target bigger
          cursor: if fetch('location').url != '/' then 'pointer'

        # Logo
        A
          href: if homepage then 'https://forum.daohub.org/c/theDAO' else '/'


          IMG
            style:
              height: 30
              width: 30
              marginLeft: -44
              marginRight: 10
              marginTop: -10
              verticalAlign: 'middle'

            src: asset('ethereum/the_dao.jpg')

          SPAN 
            style:
              #fontFamily: "Montserrat, 'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Helvetica Neue', Helvetica, Verdana, sans-serif"
              fontSize: 24
              color: 'white'
              fontWeight: 500

            "The DAO"


      # The top bar with the logo
      DIV
        style:
          width: HOMEPAGE_WIDTH()
          margin: 'auto'



        if homepage

          DIV 
            style: 
              #paddingBottom: 50
              position: 'relative'

            DIV 
              style: 
                #backgroundColor: '#eee'
                # marginTop: 10
                padding: "0 8px"
                fontSize: 46
                fontWeight: 200
                color: 'white'
                marginTop: 20

              
              'Deliberate Proposals about The DAO'            


            DIV 
              style: 
                backgroundColor: 'rgba(255,255,255,.2)'
                marginTop: 10
                marginBottom: 16
                padding: '4px 12px'
                float: 'right'
                fontSize: 18
                color: 'white'

              SPAN 
                style: 
                  opacity: .8
                "join meta discussion on Slack at "

              A 
                href: 'https://thedao.slack.com/messages/consider_it/'
                target: '_blank'
                style: 
                  #textDecoration: 'underline'
                  color: dao_vars.yellow
                  fontWeight: 600

                "#dao_consider_it"


            DIV 
              style: 
                clear: 'both'

            DIV 
              style: 
                float: 'right'
                fontSize: 12
                color: 'white'
                opacity: .9
                padding: '0px 10px'
                position: 'relative'

              "Donate ETH to fuel "

              A 
                href: 'https://dao.consider.it/donate_to_considerit?results=true'
                target: '_blank'
                style: 
                  textDecoration: 'underline'
                  fontWeight: 600

                "our work"

              " evolving consider.it to meet The DAO’s needs."


            DIV 
              style: 
                clear: 'both'

            DIV 
              style: 
                #backgroundColor: 'rgba(255,255,255,.2)'
                #marginBottom: 20
                padding: '0px 10px'
                float: 'right'
                fontSize: 15
                fontWeight: 500
                #color: 'white'
                color: dao_vars.yellow
                #border: "1px solid #{dao_vars.yellow}"
                opacity: .8
                fontFamily: '"Courier New",Courier,"Lucida Sans Typewriter","Lucida Typewriter",monospace'
              "0xc7e165ebdad9eeb8e5f5d94eef3e96ea9739fdb2"


            DIV 
              style: 
                clear: 'both'
                marginBottom: 70


            DIV 
              style: 
                position: 'relative'
                color: 'white'
                fontSize: 20

              DIV 
                style: 
                  position: 'relative'
                  left: 60
                DIV 
                  style: 
                    width: 260
                    position: 'relative'

                  SPAN style: opacity: .7,
                    'Ideas that inspire the community & contractors.'

                  BR null

                  A 
                    style: 
                      opacity: if !@local.hover_idea then .7
                      display: 'inline-block'
                      marginTop: 6
                      color: dao_vars.yellow
                      border: "1px solid #{dao_vars.yellow}"
                      #textDecoration: 'underline'
                      fontSize: 14
                      fontWeight: 600
                      #backgroundColor: "rgba(255,255,255,.2)"
                      padding: '4px 12px'
                      borderRadius: 8
                    onMouseEnter: => @local.hover_idea = true; save @local
                    onMouseLeave: => @local.hover_idea = null; save @local

                    href: '/proposal/new?category=Proposals'

                    t("add new")

                  SVG 
                    style: 
                      position: 'absolute'
                      top: 75
                      left: '35%'
                      opacity: .5

                    width: 67 * 1.05
                    height: 204 * 1.05
                    viewBox: "0 0 67 204" 

                    G                       
                      fill: 'none'

                      PATH
                        strokeWidth: 1 / 1.05 
                        stroke: 'white' 
                        d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"

              DIV 
                style: 
                  position: 'relative'
                  left: 260
                  marginTop: 0 #30

                DIV 
                  style: 
                    width: 260
                    position: 'relative'

                  SPAN style: opacity: .7,
                    'Proposals working toward a smart contract.'
                  BR null

                  A 
                    style: 
                      opacity: if !@local.hover_new then .7
                      display: 'inline-block'
                      marginTop: 6
                      color: dao_vars.yellow
                      border: "1px solid #{dao_vars.yellow}"
                      #textDecoration: 'underline'
                      fontSize: 14
                      fontWeight: 600
                      #backgroundColor: "rgba(255,255,255,.2)"
                      padding: '4px 12px'
                      borderRadius: 8
                    onMouseEnter: => @local.hover_new = true; save @local
                    onMouseLeave: => @local.hover_new = null; save @local

                    href: '/proposal/new?category=New'

                    t("add new")

                  SVG 
                    style: 
                      position: 'absolute'
                      top: 75
                      left: '35%'
                      opacity: .5

                    width: 67 * .63
                    height: 204 * .63
                    viewBox: "0 0 67 204" 

                    G                       
                      fill: 'none'

                      PATH
                        strokeWidth: 1 / .63
                        stroke: 'white' 
                        d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"

              DIV 
                style: 
                  position: 'relative'
                  left: 490
                  marginTop: 0 #30

                DIV 
                  style: 
                    width: 260
                    position: 'relative'

                  SPAN style: opacity: .7,
                    'Issues related to the operation of The DAO.'

                  BR null
                  A 
                    style: 
                      opacity: if !@local.hover_meta then .7
                      display: 'inline-block'
                      marginTop: 6
                      color: dao_vars.yellow
                      border: "1px solid #{dao_vars.yellow}"
                      #textDecoration: 'underline'
                      fontSize: 14
                      fontWeight: 600
                      #backgroundColor: "rgba(255,255,255,.2)"
                      padding: '4px 12px'
                      borderRadius: 8
                    onMouseEnter: => @local.hover_meta = true; save @local
                    onMouseLeave: => @local.hover_meta = null; save @local

                    href: '/proposal/new?category=Meta'

                    t("add new")

                  SVG 
                    style: 
                      position: 'absolute'
                      top: 75
                      left: '35%'
                      opacity: .5
                    width: 67 * .21
                    height: 204 * .21
                    viewBox: "0 0 67 204" 

                    G                       
                      fill: 'none'

                      PATH
                        strokeWidth: 1 / .21
                        stroke: 'white' 
                        d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"


              DIV 
                style: 
                  position: 'absolute'
                  left: 750
                  marginTop: 0 #30
                  bottom: -15

                DIV 
                  style: 
                    width: 260
                    position: 'relative'

                  # SPAN style: opacity: .7,
                  #   'Issues related to the operation of The DAO.'

                  BR null
                  A 
                    style: 
                      opacity: if !@local.hover_hack then .7
                      display: 'inline-block'
                      marginTop: 6
                      color: dao_vars.yellow
                      border: "1px solid #{dao_vars.yellow}"
                      #textDecoration: 'underline'
                      fontSize: 14
                      fontWeight: 600
                      #backgroundColor: "rgba(255,255,255,.2)"
                      padding: '4px 12px'
                      borderRadius: 8
                    onMouseEnter: => @local.hover_hack = true; save @local
                    onMouseLeave: => @local.hover_hack = null; save @local

                    href: '/proposal/new?category=Hack'

                    t("add new")

                  # SVG 
                  #   style: 
                  #     position: 'absolute'
                  #     top: 75
                  #     left: '35%'
                  #     opacity: .5
                  #   width: 67 * .21
                  #   height: 204 * .21
                  #   viewBox: "0 0 67 204" 

                  #   G                       
                  #     fill: 'none'

                  #     PATH
                  #       strokeWidth: 1 / .21
                  #       stroke: 'white' 
                  #       d: "M1.62120606,0.112317888 C1.62120606,0.112317888 -3.81550783,47.7673271 15.7617242,109.624892 C35.3389562,171.482458 65.9279782,203.300407 65.9279782,203.300407"






            if customization('homepage_tabs')
              HomepageTabs()

customizations['ynpn'] = 
  homepage_show_search_and_sort: false


customizations['bitcoinfoundation'] = 
  homepage_list_order: ['Proposals', 'Trustees', 'Members']
  homepage_show_new_proposal_button: false 

  opinion_filters: [ {
      label: 'members'
      tooltip: 'Verified member of the Second Foundation.'
      pass: (user) -> passes_tags(user, 'second_foundation_member')
      icon: "<span style='color:green'>\u2713 member</span>"

    }, {
      label: 'miners'
      tooltip: 'Controls > 1% hashrate.'
      pass: (user) -> passes_tags(user, ['bitcoin_large_miner', 'verified'])
      icon: "<span style=''>\u26CF miner</span>"      
    }, {
      label: 'developers'
      tooltip: 'Self reported in user profile.'
      pass: (user) -> passes_tags(user, ['bitcoin_developer.editable', 'verified'])
      icon: "<span style=''><img src='https://dl.dropboxusercontent.com/u/3403211/dev.png' style='width:20px' /> developer</span>"            
    }
  ]

  #   auth_questions : [
  #     {
  #       tag: 'bitcoin_foundation_member.editable'
  #       question: 'I am a member of the Bitcoin Foundation'
  #       input: 'dropdown'
  #       options:['No', 'Yes']
  #       required: true
  #     }]
  auth_require_pledge: true

  # default proposal options
  show_proposer_icon: true
  list_opinions_title: "Votes"
  collapse_proposal_description_at: 300

  slider_pole_labels: slider_labels.support_oppose  

  'list/First Foundation': 
    list_one_line_desc: 'Archived proceedings of the First Foundation'        
    list_is_archived: true

  show_crafting_page_first: true



customizations.livingvotersguide = 

  auth_require_pledge: true

  slider_pole_labels: slider_labels.support_oppose

  'list/Advisory votes': 
    list_is_archived: true
    list_one_line_desc: "Advisory Votes are not binding."


  SiteFooter : ReactiveComponent
    displayName: 'SiteFooter'
    render: ->
      DIV 
        style: 
          position: 'relative'
          textAlign: 'center'
          zIndex: 0

        DIV style: {color: 'white', backgroundColor: '#93928E', marginTop: 48, padding: 18, maxHeight: 400},
          DIV style: {fontSize: 18, textAlign: 'left', width: 690, margin: 'auto'},
            """Unlike voter guides generated by government, newspapers or 
               advocacy organizations, Living Voters Guide is created """
            SPAN style: {fontWeight: 600}, 'by the people'
            ' and '
            SPAN style: {fontWeight: 600}, 'for the people'
            """ of Washington State. It\'s your platform to learn about candidate and ballot measures, 
                decide how to vote and express your ideas. We believe that sharing our diverse opinions 
                leads to making wiser decisions together."""
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


        DefaultFooter()

  SiteHeader: ->
    LVG_blue = '#063D72'
    LVG_green = '#A5CE39'


    homepage = fetch('location').url == '/'

    if homepage 
      ZipcodeBox = =>
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

        if current_user.tags['zip.editable'] or @local.stay_around
          # Render the completed zip code box

          DIV
            style: 
              textAlign: 'center'
              padding: '13px 23px'
              fontSize: 20
              fontWeight: 400
              margin: 'auto'
              color: 'white'
            className: 'filled_zip'

            'Customized for:'
            INPUT

              style: 
                fontSize: 20
                fontWeight: 600
                border: '1px solid transparent'
                borderColor: if @local.focused || @local.hovering then '#767676' else 'transparent'
                backgroundColor: if @local.focused || @local.hovering then 'white' else 'transparent'
                width: 80
                marginLeft: 7
                color: if @local.focused || @local.hovering then 'black' else 'white'
                display: 'inline-block'
              type: 'text'
              key: 'zip_input'
              defaultValue: current_user.tags['zip.editable'] or ''
              onChange: onChange
              onFocus: => 
                @local.focused = true
                save(@local)
              onBlur: =>
                @local.focused = false
                @local.stay_around = false
                save(@local)
              onMouseEnter: => 
                @local.hovering = true
                save @local
              onMouseLeave: => 
                @local.hovering = false
                save @local

        else
          # zip code entry
          DIV 
            style: 
              backgroundColor: 'rgba(0,0,0,.1)'
              fontSize: 22
              fontWeight: 700
              width: 720
              color: 'white'
              padding: '15px 40px'
              marginLeft: (WINDOW_WIDTH() - 720) / 2
              #borderRadius: 16

            'Customize this guide for your' + extra_text
            INPUT
              type: 'text'
              key: 'zip_input'
              placeholder: 'Zip Code'
              style: {margin: '0 0 0 12px', fontSize: 22, height: 42, width: 152, padding: '4px 20px'}
              onChange: onChange

    DIV 
      style: 
        position: 'relative'

      STYLE null, 
        """[subdomain="livingvotersguide"] .endorser_group {
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
              padding-top: 6px; }"""


      DIV 
        style: 
          height: if !homepage then 150 else 455 
          backgroundImage: "url(#{asset('livingvotersguide/bg.png')})"
          backgroundPosition: 'center'
          backgroundSize: 'cover'
          backgroundColor: LVG_blue
          textAlign: if homepage then 'center'


        if !homepage 
          back_to_homepage_button            
            position: 'absolute'
            display: 'inline-block'
            top: 40
            left: 22
            color: 'white'

        # Logo
        A 
          style: 
            marginTop: if homepage then 40 else 10
            display: 'inline-block'
            marginLeft: if !homepage then 80
            marginRight: if !homepage then 30

          href: (if fetch('location').url == '/' then '/about' else '/'),
          IMG 
            src: asset('livingvotersguide/logo.svg')
            style:
              width: if homepage then 220 else 120
              height: if homepage then 220 else 120


        # Tagline
        DIV 
          style:
            display: if !homepage then 'inline-block'
            position: 'relative'
            top: if !homepage then -32
          DIV
            style:
              fontSize: if homepage then 32 else 24
              fontWeight: 700
              color: LVG_green
              margin: '12px 0 4px 0'

            SPAN null, 
              'Washington\'s Citizen Powered Voters Guide'

          DIV 
            style: 
              color: 'white'
              fontSize: if homepage then 20 else 18

            'Learn about your ballot, decide how you’ll vote, and share your opinion.'

        if homepage



          DIV
            style:
              color: 'white'
              fontSize: 20
              marginTop: 30

            DIV
              style: 
                position: 'relative'
                display: 'inline'
                marginRight: 50
                height: 46

              SPAN 
                style: 
                  paddingRight: 12
                  position: 'relative'
                  top: 4
                  verticalAlign: 'top'
                'brought to you by'
              A 
                style: 
                  verticalAlign: 'top'

                href: 'http://seattlecityclub.org'
                IMG 
                  src: asset('livingvotersguide/cityclub.svg')

            DIV 
              style: 
                position: 'relative'
                display: 'inline'
                height: 46
                #display: 'none'

              SPAN 
                style: 
                  paddingRight: 12
                  verticalAlign: 'top'
                  position: 'relative'
                  top: 4

                'fact-checks by'
              
              A 
                style: 
                  verticalAlign: 'top'
                  position: 'relative'
                  top: -6

                href: 'http://spl.org'
                IMG
                  style: 
                    height: 31

                  src: asset('livingvotersguide/spl.png')

      if homepage
        DIV 
          style: 
            backgroundColor: LVG_green

          DIV 
            style: 
              color: 'white'
              margin: 'auto'
              padding: '40px'
              width: 720


            DIV
              style: 
                fontSize: 24
                fontWeight: 600
                textAlign: 'center'

              """The Living Voters Guide has passed on..."""

            DIV 
              style: 
                fontSize: 18
              """We have made the difficult decision to discontinue the Living Voters Guide 
                 after six years of service. Thank you for your contributions through the years!"""

          DIV 
            style: 
              paddingBottom: 15

            ZipcodeBox()

      else
        DIV 
          style: 
            backgroundColor: LVG_green
            paddingTop: 5



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
      src: """//www.facebook.com/plugins/like.php?href=#{page}&send=false&layout=button_count&width=450&
              show_faces=false&action=like&colorscheme=light&font=lucida+grande&height=21"""
      scrolling: "no"
      frameBorder: "0"
      allowTransparency: "true"

Tweet = ReactiveComponent
  displayName: 'Tweet'

  render: ->
    url = """https://platform.twitter.com/widgets/tweet_button.1410542722.html#?_=
          1410827370943&count=none&id=twitter-widget-0&lang=en&size=m"""
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


customizations.mos = 

  slider_pole_labels :
    support: 'Support'
    support_sub: 'the ban'
    oppose: 'Oppose'
    oppose_sub: 'the ban'

  show_crafting_page_first: true
