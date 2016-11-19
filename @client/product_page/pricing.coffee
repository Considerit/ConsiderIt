require './svgs/collaboration'
require './svgs/price_tag'
require './svgs/design'
require './svgs/features'
require './svgs/server'




background_swosh = -> 
  SVG 
    width: window.innerWidth 
    height: 1430
    viewBox: "0 0 1440 1430" 

    G 
      transform: "translate(0.000000, -374.000000)" 
      fill: "#9968D4" 
      fillOpacity: "0.26000002"
      PATH 
        d: "M-1.6640625,369.640625 C-1.6640625,369.640625 63.1989495,554.640744 303.054688,719.8125 C542.910426,884.984256 1440,1037.32031 1440,1037.32031 L1440,1803.60938 L-1.6640625,1576.3125 L-1.6640625,369.640625 Z"


window.Pricing = ReactiveComponent
  displayName: 'Pricing'

  render: -> 


    DIV 
      style: {}

      @heading()

      @plans()

      @consulting()

      DIV style: paddingTop: 40, backgroundColor: 'white',
        @consultant_partnership()

      FAQ()

  heading: -> 
    DIV 
      style: 
        paddingTop: 40
        width: SAAS_PAGE_WIDTH()
        margin: 'auto'
        textAlign: 'center'

      H1
        style: 
          fontSize: 50
          fontWeight: 400
          color: 'white'

        "Invest in your community’s opinions"

      DIV 
        style: 
          fontSize: 18
          color: 'white'
          marginTop: 8

        'Try for as long as you want for free. Pay only when we help you engage your stakeholders.'

  plans: -> 
    mobile = SAAS_PAGE_WIDTH() < 1000

    plan_style = 
      padding: '32px 36px'
      backgroundColor: 'white' 
      width: if mobile then '80%'
      maxWidth: if !mobile then 340
      display: if mobile then 'block' else 'inline-block'
      margin: "#{if mobile then 20 else 0}px #{if mobile then 'auto' else '10px'}" 
      verticalAlign: 'top'
      flex: '1 1 auto'

    plan_name_style = 
      fontWeight: 800
      fontSize: 32
      textAlign: 'center'

    plan_name_subtitle = 
      fontStyle: 'italic'
      fontSize: 16
      textAlign: 'center'

    base_text = 
      fontSize: 16
      fontWeight: 400

    details_paragraph = _.extend {}, base_text,
      paddingBottom: 30
      textAlign: 'left'

    plan_button_style = _.extend {}, big_button(), 
      fontSize: 18
      fontWeight: 600
      padding: '10px 0'
      width: '100%'
      maxWidth: 300
      margin: 'auto'
      textAlign: 'center'
      display: 'block'

    payment_container_style = 
      paddingTop: 24
      textAlign: 'center'

    money_style = 
      fontSize: 75
      fontWeight: 800
      lineHeight: '75px'
      position: 'relative'

    dollar_style = 
      fontSize: 32
      position: 'absolute'
      top: 10
      left: -20
      fontWeight: 400




    UL
      style: 
        listStyle: 'none'
        display: 'flex'
        justifyContent: 'center'
        paddingTop: 60
        flexDirection: if mobile then 'column'

      # FREE
      LI 
        style: plan_style

        H2 
          style: plan_name_style

          'Free Forum'

        DIV 
          style: plan_name_subtitle

          'Use for as long as you wish'

        DIV 
          style: _.extend {}, payment_container_style, 
            paddingBottom: 60
            

          SPAN 
            style: money_style
            SPAN 
              style: dollar_style
              '$'

            '0'


        DIV 
          style: 
            paddingBottom: 60

          A 
            href: '/create_forum'
            target: '_blank'
            style: plan_button_style
            'Create Free Forum'        


        P 
          style: details_paragraph
          """Engage as many stakeholders about any number of issues for as long as you 
             wish. Your forum can be public or private."""

        P 
          style: _.extend {}, details_paragraph, 
            fontStyle: 'italic'

          """Limitation: only the most recent 25 questions are visible on your forum’s homepage."""

      # UNLIMITED
      LI 
        style: plan_style

        H2 
          style: plan_name_style

          'Unlimited Forum'

        DIV 
          style: plan_name_subtitle

          'All opinions, beautifully visualized'


        DIV 
          style: _.extend {}, payment_container_style, 
            paddingBottom: 26
            

          SPAN 
            style: money_style
            SPAN 
              style: dollar_style
              '$'

            '250'

          DIV 
            style: _.extend {}, base_text,
              marginTop: -18
              paddingBottom: 8
            'one-time setup fee'

          DIV 
            style: base_text

            '+$1.25 per opinion'


        DIV 
          style: 
            paddingBottom: 60 - 26
            
          A 
            href: '/contact?form=upgrade_to_unlimited'
            target: '_blank'
            style: plan_button_style
            'Upgrade to Unlimited'      

          DIV 
            style: 
              fontSize: 10
              textAlign: 'center'
              paddingTop: 12

            "Special circumstance? "
            A 
              href: '/contact?form=discount'
              style: 
                textDecoration: 'underline'
              "Apply for a discount"

            "."  



        P 
          style: details_paragraph
          """We build you a customized forum homepage tailored to your brand and goal, and modify it 
             as your community grows. You also get:"""

        UL 
          style: _.extend {}, details_paragraph, 
            listStyle: 'outside'
            paddingLeft: 18

          for feature in [
                            'Data Export'
                            'Custom User Information'
                            'Content Moderation'
                            'Google Translate'
                            'Google Analytics integration'
                            'One hour training & setup call'
                          ]
            LI 
              style: {}
              feature

        P 
          className: 'embedded'
          style: details_paragraph

          dangerouslySetInnerHTML: {__html: """You only <a href='#pay_per_opinion'>pay for the opinions you collect</a>. We can arrange a monthly budget to cap your costs."""}


          


      # ENTERPRISE
      LI 
        style: plan_style

        H2 
          style: plan_name_style

          'Enterprise'

        DIV 
          style: plan_name_subtitle

          'Unite all of your Consider.it forums'


        DIV 
          style: _.extend {}, payment_container_style, 
            paddingBottom: 26
            

          SPAN 
            style: money_style
            SPAN 
              style: dollar_style
              '$'

            '1000'

          DIV 
            style: _.extend {}, base_text,
              marginTop: -18
              paddingBottom: 8
            'per month'

          DIV 
            style: base_text

            '+$0.80 per opinion'



        DIV 
          style: 
            paddingBottom: 60
            
          A 
            href: '/contact?form=start_enterprise'
            target: '_blank'
            style: plan_button_style
            'Contact Us'        


        P 
          style: details_paragraph
          """Create multiple Consider.it forums linked under a shared header customized for your 
             organization."""

        P 
          style: details_paragraph
          """Three hours initial training and consulting package included. One hour per month thereafter."""

        P 
          style: details_paragraph
          """Access to dedicated community engagement specialist."""

        P 
          style: details_paragraph
          """Enterprise features such as SAML Single Sign On and custom URLs available."""

  consulting: -> 
    small_para_style = 
      fontSize: 16

    plan_button_style = _.extend {}, big_button(), 
      fontSize: 18
      fontWeight: 500
      padding: '10px 32px'
      textAlign: 'center'

    susie_quote = -> 
      Testimonial
        left: true
        short_quote: """The Consider.it team has been a great partner for directly engaging residents 
                        online--and it is working. Residents are acknowledging the information we are 
                        providing them, learning from it, and even thanking us. We’ve created a great 
                        feedback loop via Consider.it!"""

        avatar: asset('product_page/susie.png')

        credentials: -> 
          DIV 
            style: 
              fontSize: 16
            'Susie Philipsen' 

            DIV 
              style: 
                fontSize: 12

              "Senior Public Relations Specialist"
              BR null
              "City of Seattle"

        long_quote: -> 
          html = """
            <style>
              .long_quote p { padding-bottom: 12px;}
              .long_quote a { text-decoration: underline;}
              .long_quote ul { list-style: outside;}
              .long_quote li { padding-bottom: 12px; }
            </style>
            <div class='long_quote'><p>Working with the Consider.it team on <a href='https://hala.consider.it'>Seattle’s dialogue about Housing Affordability</a> has been a great experience! They bring far more to the table than technical skills – they think deeply about how the tool is going to be received and help us build a better dialogue using that knowledge. Furthermore, the Consider.it team is very responsive - the back and forth communication has been very easy.</p> 

            <p>Some of the ways the Consider.it team helped our team include:</p>

            <ul>
            <li><strong>Framing content for a general audience</strong>. We spent a lot of time writing technically correct questions, but the Consider.it team helped us recognize how difficult these questions are to understand. They helped us refine all the content. This included setting expectations about how residents’ feedback fits into the larger process. </li>

            <li><strong>Translating our needs into a good digital experience</strong>. Being new to online dialogue, the consider.it team helped us focus our goals for information gathering. We wanted to collect demographic information so we could assess outreach effectiveness. We collaborated to identify the minimal information to collect from residents to answer critical questions.</li>

            <li><strong>Outreach and recruitment</strong>. The consider.it team provided what populations were providing feedback. I was then able to focus our online advertising on recruiting people from underrepresented neighborhoods and groups.</li>

            <li><strong>How to engage with residents</strong>. The team encouraged direct engagement with residents online by responding to questions and concerns online. This support made me more proactive in answering questions. When I don’t know the answer, I reach out to the technical experts and ask them to respond that day so we can keep the conversation going. Residents are acknowledging the information we are providing them, learning from it, and even thanking us.</li>

            </ul>
            <p>If you’re looking to create quality online dialogues, Consider.it is a great choice.</p>
            </div>
            """


          DIV dangerouslySetInnerHTML: {__html: html}



    russ_quote = -> 
      Testimonial 
        left: false
        # short_quote: """I was nervous about getting our board members and wider network on the same page about a 
        #                 pressing strategic change. The Consider.it team rescued us! They structured a quick 
        #                 Consider.it dialogue with all our stakeholders that gave legitimacy and momentum to 
        #                 our new direction, without the hassle of bringing everyone together physically."""
        short_quote: """When we embarked on rebranding, I was daunted with the task of engaging
                        constituents across the state. As a small non-profit, we didn’t have the funds to
                        reach everyone in-person. With Consider.it, we could engage far more people for a
                        cost we could afford. Beyond being a great tool, the Consider.it team was incredibly
                        knowledgeable, creative, thoughtful, and available in helping craft an engagement strategy.
                     """

        avatar: asset('product_page/Russ.png')
        credentials: -> 
          DIV 
            style: 
              fontSize: 16
            'Russ Lehman' 

            DIV 
              style: 
                fontSize: 12


              "Executive Director"
              BR null
              "WA Sustainable Food and Farming Network"

        long_quote: -> 
          html = """
            <style>
              .long_quote p { padding-bottom: 12px;}
              .long_quote a { text-decoration: underline;}
              .long_quote ul { list-style: outside;}
              .long_quote li { padding-bottom: 12px; }
            </style>
            <div class='long_quote'><p>
              The Consider.it team helped us structure a lightweight dialogue with all our stakeholders. We got legitimacy and momentum for 
              our new direction, without the hassle of bringing everyone together physically.</p> 

            <p>Some of the ways the Consider.it team helped us include:</p>

            <ul>
            <li><strong>Creation of questions</strong> to yield the most valuable information.</li>

            <li><strong>Designing a multi-phase process</strong> that first used Consider.it to engage our statewide stakeholders, then to discuss results with our board and eventually leading to a board vote at our annual retreat.</li>

            <li><strong>Advice on how to interact with stakeholders</strong> to yield even more substantive results and maintain civil discourse.</li>

            <li><strong>Interpretation of responses</strong> to gain deeper insight and assist with reporting lessons back to our board and stakeholders.</li>

            </ul>
            </div>
            """

          DIV dangerouslySetInnerHTML: {__html: html}


    DIV 
      style: 
        backgroundColor: 'white'
        boxShadow: '0px -17px 27px 0px rgba(0,0,0,.14)'
        position: 'relative'
        zIndex: 1
        paddingTop: 50
        paddingBottom: 50

      A name: 'consulting'
      A name: 'testimonials'


      DIV 
        style: 
          maxWidth: SAAS_PAGE_WIDTH()
          margin: 'auto'

        H2 
          style: _.extend {}, h1, 
            color: '#303030'
            fontSize: 50
            margin: '0 auto 40px auto'
            maxWidth: 930
            textAlign: 'center'


          'Hire us if you need extra help creating the conversation you need.'

      TABLE 
        style: 
          margin: 'auto'

        TBODY null, 

          TR null, 

            TD null, 
              susie_quote()          

            TD null,

              DIV 
                style: 
                  width: 400
                  margin: 'auto'
                  padding: '0px 40px'

                UL 
                  style: 
                    listStyle: 'outside'
                    paddingLeft: 18
                    marginBottom: 28
                  
                  for service in [
                                    'Process advice about your dialogue'
                                    'Help creating clear and concise proposals'
                                    'Training in Consider.it best practices'
                                    'Creating new functionality for your forum' 
                                  ]
                    LI 
                      style: small_para_style
                      service

                A 
                  href: '/contact?form=consulting_inquiry'
                  target: '_blank'
                  style: plan_button_style
                  'Get a quote for your project' 


            TD null, 
              russ_quote()




  consultant_partnership: -> 
    DIV 
      style: 
        backgroundColor: '#F4F4F4'
        borderTop:    '1px solid #B1B1B1'
        borderBottom: '1px solid #B1B1B1'
        padding: '36px 0 44px 0'

      A name: 'partnership'

      H2
        style: 
          fontWeight: 800
          color: 'black'
          fontSize: 24
          textAlign: 'center'
          color: '#303030'
          marginBottom: 14

        'Consultant Partnership'

      DIV 
        style: 
          fontSize: 16
          color: '#303030'
          maxWidth: 420
          margin: 'auto'

        "Are you a consultant? We "
        SPAN
          style: 
            color: '#EF3084'
          "💖"
        """ consultants. We offer special pricing and support for 
        consultants looking to use Consider.it with their clients. Please """
        A 
          href: '/contact?form=consultant_partnership'
          style: 
            textDecoration: 'underline'
          "introduce yourself"
        "."



Testimonial = ReactiveComponent 
  displayName: 'Testimonial'

  render: -> 

    quote_bubble =  
      padding: '36px 50px'
      position: 'relative'
      backgroundColor: considerit_gray
      boxShadow: '#b5b5b5 0 1px 1px 0px'
      borderRadius: 64
      marginBottom: 20
      maxWidth: 350

    long_quote_bubble = _.extend {}, quote_bubble,
      padding: '36px 50px'
      position: 'absolute'
      backgroundColor: considerit_gray
      boxShadow: '#b5b5b5 0 1px 1px 0px'
      borderRadius: 64
      marginBottom: 20
      width: 650
      maxWidth: 650
      top: 75
      zIndex: 1
      left: if @props.left then 0 else null
      right: if !@props.left then 0 else null



    quote_text = 
      fontSize: 16
      fontStyle: 'italic'

    long_quote_text = _.extend {}, quote_text,
      fontStyle: 'normal'


    quote_mouth = 
      apex_xfrac: 0
      width: 30
      height: 30
      fill: considerit_gray
      stroke: 'transparent'
      stroke_width: 0
      box_shadow:   
        dx: '3'
        dy: '0'
        stdDeviation: "2"
        opacity: .5      

    quote_img =
      height: 75
      width: 75
      verticalAlign: 'middle'   

    quote_cred = 
      display: 'inline-block'
      padding: '0 16px'
      verticalAlign: 'middle'  
      textAlign: if !@props.left then 'right'

    readmore = => 
      onclick = => 
        @local.show_long = !@local.show_long
        save @local

      BUTTON 
        style: 
          backgroundColor: 'transparent'
          border: 'none'
          color: primary_color()
          textDecoration: 'underline'
          paddingTop: 12
          paddingLeft: 0
        onClick: onclick
        onKeyPress: (e) => 
          if e.which == 16 || e.which == 32
            e.preventDefault()
            onclick()

        if @local.show_long
          'read less'
        else 
          'read more'

    DIV 
      style: 
        paddingTop: 28
        position: 'relative'
        left: 0
        minHeight: if @local.show_long then 1200

      

      DIV
        style: quote_bubble
          
        DIV
          style: quote_text 

          @props.short_quote

        if @props.long_quote
          readmore()

        DIV
          style: css.crossbrowserify
            transform: "rotate(180deg) #{if @props.left then 'scaleX(-1)' else ''}"
            position: 'absolute'
            left: if @props.left then 60 else null 
            right: if !@props.left then 60 else null 

            bottom: -30

          Bubblemouth quote_mouth

      DIV 
        style: 
          position: 'relative'
          top: 20
          left: 20

        if @props.left 
          IMG
            src: @props.avatar
            style: quote_img

        DIV 
          style: quote_cred

          @props.credentials()

        if !@props.left 
          IMG
            src: @props.avatar
            style: quote_img


      if @local.show_long
        DIV 
          style: 
            position: 'relative'

          DIV
            style: long_quote_bubble
              
            DIV
              style: long_quote_text 

              @props.long_quote()

            readmore()

            DIV
              style: css.crossbrowserify
                transform: "rotate(180deg) scale(#{if @props.left then -1 else 1}, -1)"
                position: 'absolute'
                left: if @props.left then 60
                right: if !@props.left then 60
                top: -30

              Bubblemouth _.extend {}, quote_mouth, 
                box_shadow:   
                  dx: '-1'
                  dy: '-1'
                  stdDeviation: "2"
                  opacity: .2      

styles += """
  .embedded p {
    margin-bottom: 8px;
  }

  .embedded emph {
    font-style: italic;
  }

  .embedded strong {
    font-weight: 700;
  }
  .embedded a {
    text-decoration: underline;
  }

"""

FAQ = ReactiveComponent
  displayName: 'FAQ'
  render: -> 

    mobile = SAAS_PAGE_WIDTH() < 900
    DIV 
      style: 
        backgroundColor: 'white'
        padding: '80px 40px 40px 40px'
      A name: 'faq'
      DIV  
        style: 
          margin: 'auto'
          maxWidth: 1100

        for set in [['Tech Questions',tech_qs], ['Pricing Questions', pricing_qs]]
          header = set[0]
          question_set = set[1]

          DIV 
            style: 
              display: if mobile then 'block' else 'inline-block'
              width: if mobile then '100%' else '48%'
              padding: '0 20px'
              verticalAlign: 'top'

            H1 
              style: 
                fontSize: 36
                fontWeight: 800
                marginBottom: 20
              header

            UL 
              style: 
                listStyle: 'none'

              for faq in question_set 
                LI 
                  style: 
                    marginBottom: 20

                  H2 
                    style: 
                      fontWeight: 700
                      fontSize: 20
                      marginBottom: 12
                    faq.q 

                  DIV 
                    style: 
                      fontSize: 16
                      color: '#303030'
                    DIV 
                      className: 'embedded'
                      dangerouslySetInnerHTML: {__html: faq.a}
                        


tech_qs = [
  {
    q: """How can I brand my forum and give it my organization’s look and feel?"""
    a: """When you upgrade to an Unlimited or Enterprise plan, you have the option to work with us to create a customized look and feel. We cover that in the one hour setup call that comes with every Unlimited forum. See some <a href='/tour#customized'>examples</a>."""
  }
  {
    q: """Can we moderate the forum and maintain civil discourse?"""
    a: """Yes. As a forum administrator, you have a number of options for hiding in-civil and/or offtopic user posts. We’ve found an even more powerful mechanism though: a customizable user pledge that you can ask all participants in your forum to agree to when creating an account. It is amazing what setting expectations can do. Overall, we have found the structure of our forums lend themselves to more civil discourse. We have hosted city dialogues on very contentious issues without having to moderate a single comment. We also provide consulting services to help set best practices for facilitating civil, online discourse. """
  }
  {
    q: """Can I make my Forum invite-only so only certain people can access it?"""
    a: """Yes. Once you create your forum you will be able to set the forum as private. Then only people who you invite can participate in the forum. You can set user roles to give people view-only access or the ability to respond. Furthermore, you can make specific questions invite-only."""
  }
  {
    q: """I want to know more about participants in my Forum so I can analyze the opinions. Can I ask about their age? If they’re a homeowner? If they’re a board member?"""
    a: """Yes, with an Unlimited forum. We can configure your forum to ask any number of specific questions when a participant creates a new account. This information can then be used to cross-tabulate the results to explore the opinions of segments of your stakeholders. More info <a href='/tour#profile_questions'>here</a>."""
  }
  {
    q: """Will my forum work in languages other than English?"""
    a: """Yes. First, Google Translate is enabled in the footer for all forums. This allows your participants to view your forum in any language that Google supports. It even supports multi-lingual forums. If you upgrade to Unlimited, we can make the Google Translate functionality more prominent. Second, we also have interface translations for a number of languages. This can provide for higher-quality experience for forums targeted whose prefered primary language isn’t English. The biggest language limitation is that our email notifications are currently not translated. """
  }
  {
    q: """How can I know what kind of traffic my Forum is receiving?"""
    a: """At this time, we support integration with Google Analytics in our Unlimited Plan. All you do is set your Google Analytics tracking code. If you use a different analytics system, contact us and we can figure out if we can integrate with that system as well."""
  }
  {
    q: """Is Consider.it compliant with accessibility standards?"""
    a: """Yes, Consider.it is <a href='https://www.w3.org/WAI/intro/wcag.php'>WCAG</a> Level A compliant."""
  }
  {
    q: """Can I use a custom URL? Can I host the forum on my own server?"""
    a: """We can setup your forum to use a custom URL, but it will incur a monthly fee. At this time, we do not support self-hosting on your own server. """
  }
  {
    q: """Do you support SAML single sign-on?"""
    a: """Yes, SAML is available for enterprise clients."""
  }
  {
    q: """Does Consider.it work on mobile?"""
    a: """Yes. The Consider.it website is responsive and works on most mobile devices. We do not currently offer a stand alone mobile app."""
  }
  {
    q: """How is this different than a survey or a web forum?"""
    a: """<p>Some people think of a Consider.it forum as a combination of a survey and a forum. A survey is a one way flow of information. People respond in isolation and don’t interact with other survey takers. They don’t learn from each other. In a web forum, people interact with each other, but it’s hard to visualize the aggregate opinions of everyone on the forum. Standard web forums don’t provide focus to a conversation and can reward those who make the most contentious points. People can feel like their voice is being lost in the cacophony.</p><p>In a Consider.it forum, people can interact and discuss issues with structure <emph>and</emph> focus. Each person can quickly see the overall opinions of the group and consider pros and cons on each side of the argument. It’s hard to hijack a Consider.it conversation. The format encourages civil conversation. Give it a shot and see for yourself!</p>"""
  }

]

pricing_qs = [
  {
    q: """Can you explain how the Free Forum works?"""
    a: """You can <a href='/create_forum'>create a free forum</a> and use it for as long as you want. This forum is public by default, but you can make it invite-only. The forum comes with most of the standard features. The main limitation is that only the most recent 25 questions will be listed on the forum homepage. <a href='/contact?form=upgrade_to_unlimited'>Upgrade to the Unlimited Forum</a> if you want access to all the questions posted in your forum (or any of the other additional features with Unlimited, like a branded homepage)."""
  }
  {
    q: """What counts as an opinion? Why do you charge "per opinion" in the paid plans?"""
    a: """An opinion is collected when someone slides and saves their position on a question in your forum. We charge per opinion collected because it is fair to you (you only pay for the service when you’re getting value from it) and fair to us (we get compensated for some fraction of the value we provide you). This allows small communities to pay less; larger communities, who are getting more value, pay more. It also accommodates forums whose use ebbs and flows."""
  }
  {
    q: """How much can I expect to pay per month on the Unlimited plan? Can I set a monthly budget? """
    a: """Yes, we can work with you to set a monthly budget that makes sense for your use case if you need a hard cap. A monthly budget is the total amount you are willing to spend collecting opinions in a month. You will never be charged more than this monthly budget. You only pay for how much you use. For reference, a small non-profit engaging stakeholders for strategic planning might collect around 750 opinions over three months. A large city hosting a dialogue about an important topic may collect closer to 5000 opinions."""
  }
  {
    q: """I only need the forum for a short period of time. How much will I pay?"""
    a: """For an Unlimited forum, you will pay a $250 setup fee to customize. Then you only pay for the opinions you collect. When you no longer need the forum, you can stop collecting opinions. You won’t pay anything while you’re not collecting opinions. """
  }
  {
    q: """I’m a consultant and want to set up forums for multiple clients. Can you help me? """
    a: """Yes. We work with consultants all the time. We can help you customize forums for each of your clients, or create a branded look for your consulting firm. <a href="/contact?form=consultant_partnership">Get in touch</a> and we can talk. """
  }
  {
    q: """Can I speak with someone about the plan options and get a demo?"""
    a: """Absolutely! We’re happy to <a href="/contact?form=request_demo">set up a time to talk</a>."""
  }
  {
    q: """I want to use Consider.it for an innovative project that will benefit society but can’t afford the price. Can you offer a discount? """
    a: """Yes, we offer discounts for certain types of projects. We find that the free version meets most needs. We screen for projects that: (1) Can’t suffice with a free version and need an Unlimited plan; (2) Have some type of public benefit; and (3) Does not have a sponsoring organization with a budget that could afford our regular pricing. For reference, we find that even small nonprofit organizations can afford our pricing for most uses. Large open source projects without an anchoring company are a good example of a community to which we grant discounts. <a href="/contact?form=discount">Apply here</a>."""
  }
  {
    q: """Can I cancel my plan at any time?"""
    a: """Yes. You can either close your forum and stop collecting opinions or contact us to delete your forum entirely. Either way, we don’t believe in locking customers into contracts. You only pay for the opinions you collect. """
  }
  {
    q: """Can I switch my Unlimited plan to a free plan?"""
    a: """Yes, just <a href="/contact?form=general_inquiry">contact us</a>. If you downgrade, the Free Forum’s 25 most recent question limitation will be applied to your forum, and you will lose access to the additional features. Any customizations will also be deactivated. If you later decide you want to switch back to Unlimited, you can do so at a 25% discount on the setup fee. """
  }
  {
    q: """What is your refund policy?"""
    a: """We don’t offer refunds on the setup fee or opinions you have collected. You can cancel your plan at anytime. If you feel we have made an error in billing or haven’t provided the service we promised, please let us know. """
  }
  {
    q: """Can you issue invoices and receive checks instead of a credit card? """
    a: """Yes, for customers spending more than $500 per month, we can issue invoices and receive checks."""
  }

]



