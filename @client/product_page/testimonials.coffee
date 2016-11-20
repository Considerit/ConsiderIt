window.Testimonial = ReactiveComponent 
  displayName: 'Testimonial'

  render: -> 

    t = @props.testimonial 

    quote_bubble =  
      padding: '36px 50px'
      position: 'relative'
      backgroundColor: @props.bubble_color or considerit_gray
      boxShadow: '#b5b5b5 0 1px 1px 0px'
      borderRadius: 64
      marginBottom: 20
      #maxWidth: 350

    long_quote_bubble = _.extend {}, quote_bubble,
      padding: '36px 50px'
      position: 'absolute'
      backgroundColor: @props.bubble_color or considerit_gray
      boxShadow: '#b5b5b5 0 1px 1px 0px'
      borderRadius: 64
      marginBottom: 20
      #width: 650
      maxWidth: 650
      top: 75
      zIndex: 1
      left: if @props.left then 0 else null
      right: if !@props.left then 0 else null      


    quote_mouth = 
      apex_xfrac: 0
      width: 30
      height: 30
      fill: @props.bubble_color or considerit_gray
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
          style: 
            fontSize: 16
            fontStyle: 'italic'


          t.short_quote

        if t.long_quote
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
          padding: '12px 20px'
          float: if !@props.left then 'right' 


        if @props.left && t.avatar 
          IMG
            src: t.avatar
            style: quote_img

        DIV 
          style:
            display: 'inline-block'
            padding: '0 16px'
            verticalAlign: 'middle'  
            textAlign: if !@props.left then 'right'

          DIV 
            style: 
              fontSize: 16
            t.name

            DIV 
              style: 
                fontSize: 12

              t.role if t.role
              BR null if t.role && t.organization
              t.organization if t.organization

        if !@props.left && t.avatar 
          IMG
            src: t.avatar
            style: quote_img


      if @local.show_long
        DIV 
          style: 
            position: 'relative'

          DIV
            style: long_quote_bubble
              
            DIV
              className: 'embedded'
              style: 
                fontSize: 16               

              DIV dangerouslySetInnerHTML: {__html: t.long_quote}

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




window.testimonials = 
  susie:
    name: 'Susie Philipsen' 
    role: "Senior Public Relations Specialist"
    organization: "City of Seattle"
    avatar: asset('product_page/susie.png')


    short_quote: """The Consider.it team has been a great partner for directly engaging residents 
                    online--and it is working. Residents are acknowledging the information we are 
                    providing them, learning from it, and even thanking us. We’ve created a great 
                    feedback loop via Consider.it!"""

    long_quote: """
        <p>Working with the Consider.it team on <a href='https://hala.consider.it'>Seattle’s dialogue about Housing Affordability</a> has been a great experience! They bring far more to the table than technical skills – they think deeply about how the tool is going to be received and help us build a better dialogue using that knowledge. Furthermore, the Consider.it team is very responsive - the back and forth communication has been very easy.</p> 

        <p>Some of the ways the Consider.it team helped our team include:</p>

        <ul>
        <li><strong>Framing content for a general audience</strong>. We spent a lot of time writing technically correct questions, but the Consider.it team helped us recognize how difficult these questions are to understand. They helped us refine all the content. This included setting expectations about how residents’ feedback fits into the larger process. </li>

        <li><strong>Translating our needs into a good digital experience</strong>. Being new to online dialogue, the consider.it team helped us focus our goals for information gathering. We wanted to collect demographic information so we could assess outreach effectiveness. We collaborated to identify the minimal information to collect from residents to answer critical questions.</li>

        <li><strong>Outreach and recruitment</strong>. The consider.it team provided what populations were providing feedback. I was then able to focus our online advertising on recruiting people from underrepresented neighborhoods and groups.</li>

        <li><strong>How to engage with residents</strong>. The team encouraged direct engagement with residents online by responding to questions and concerns online. This support made me more proactive in answering questions. When I don’t know the answer, I reach out to the technical experts and ask them to respond that day so we can keep the conversation going. Residents are acknowledging the information we are providing them, learning from it, and even thanking us.</li>

        </ul>
        <p>If you’re looking to create quality online dialogues, Consider.it is a great choice.</p>
        """

  russ: 
    name: 'Russ Lehman' 
    role: "Executive Director"
    organization: "WA Sustainable Food and Farming Network"
    avatar: asset('product_page/Russ.png')

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
    long_quote: """
        <p>
          The Consider.it team helped us structure a lightweight dialogue with all our stakeholders. We got legitimacy and momentum for 
          our new direction, without the hassle of bringing everyone together physically.</p> 

        <p>Some of the ways the Consider.it team helped us include:</p>

        <ul>
        <li><strong>Creation of questions</strong> to yield the most valuable information.</li>

        <li><strong>Designing a multi-phase process</strong> that first used Consider.it to engage our statewide stakeholders, then to discuss results with our board and eventually leading to a board vote at our annual retreat.</li>

        <li><strong>Advice on how to interact with stakeholders</strong> to yield even more substantive results and maintain civil discourse.</li>

        <li><strong>Interpretation of responses</strong> to gain deeper insight and assist with reporting lessons back to our board and stakeholders.</li>

        </ul>
        """

  pierre: 
    name: 'Pierre-Elouan Réthoré' 
    role: 'Wind Energy Researcher'
    #organization: "DAOhub.org"
    avatar: asset('product_page/pierre.png')

    short_quote: """
                 We had a nearly 50/50 deadlocked split in our housing community. After we started using Consider.it, 
                 people could clearly express the reasons behind their opinions, and see other’s reasons. We were able 
                 to work out a compromise. That’s the first time where I felt like democracy was actually working.
                 """

  auryn: 
    name: 'Auryn Macmillan' 
    role: 'Cofounder of DAOhub.org'
    #organization: "DAOhub.org"
    avatar: asset('product_page/auryn.png')

    short_quote: """
                 Consider.it’s careful design choices were instrumental for us not only in 
                 terms of aggregating community opinions, but also in understanding the 
                 rationale. This ability to get a feel for both the gestalt and the 
                 granular details of an issue within the one view is an incredible 
                 achievement and was a vital part in our community’s decision making 
                 process.
                 """

    long_quote: """

        <p>At DAOhub a group of volunteers came together to create a home for the communities of a radical new form of human interaction, Decentralised Autonomous Organisations (or DAOs for short). We set up a <a href='http://discourse.org' target="_blank">Discourse</a> forum to act as our base means of communication. However one of the major challenges we faced was effectively aggregating community sentiment on issues and proposals. This was vital for the DAO to function properly. The simple polls that ship with Discourse were somewhat limited and did not quite fulfill the need.</p>
        <p>Luckily, Consider.it beats the hell out of simple polls! It is a fantastic tool for gauging the opinion of a large number of users, while not losing sight of the individuals.</p>
        <p>If effectively gauging the opinion/sentiment of your community is something that is important or necessary for your business/product/community, then the team at Consider.it would be an invaluable partner. Their product and advice is second to none. Seriously, these guys are flat out awesome. Incredibly responsive and receptive to suggestions, and, as is evident by the nuance of their platform, they really have a fantastic grasp on the needs of web based and decentralised communities.</p>
        """

  sheri: 
    name: 'Sheri'
    role: 'Seattle resident'
    organization: 'Captain of her blind softball team'
    short_quote: 'I am blind and use assistive technology to read information on a computer screen. Consider.it works well with my screen reading software and allows me the opportunity to fully participate in my city’s decision making process in the same way all others can. I appreciate Consider.it’s willingness to work hard to make their website fully accessible to me and all other blind computer users!'


