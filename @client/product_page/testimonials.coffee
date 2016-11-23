window.TestimonialGrid = ReactiveComponent
  displayName: 'TestimonialGrid'

  render: -> 

    w = @props.maxWidth or 1100
    expanded = @local.expanded 
    if !@props.top?
      top = true 
    else 
      top = @props.top 

    odd = @props.testimonials.length % 2 == 1

    user_row = =>
      DIV 
        style: css.crossbrowserify
          display: 'flex'

        for t, idx in @props.testimonials

          DIV 
            style: css.crossbrowserify
              flex: 1
              padding: '0px 16px'
              opacity: if expanded && expanded != t then .1

            @user_credentials 
              testimonial: t
              left: odd || idx < @props.testimonials.length / 2
              top: top
              bg_color: @props.bubble_color or considerit_gray
              right_side: idx > @props.testimonials.length / 2

    quote_row = => 
      DIV 
        style: css.crossbrowserify
          display: 'flex'

        for t,idx in @props.testimonials
          continue if expanded && expanded != t

          @quote_bubble 
            key: @local.key
            testimonial: t
            top: top
            bg_color: @props.bubble_color or considerit_gray
            italic: @props.italic


    DIV 
      style: 
        margin: 'auto'
        maxWidth: w


      if top 
        [user_row(), quote_row()]
      else 
        [quote_row(), user_row()]



  user_credentials: (opts) ->
    t = opts.testimonial
    expanded = @local.expanded == t
    
    left = opts.left 
    mouth_dir_left = left && !(expanded && opts.right_side)
    top = opts.top 
    

    quote_img =
    
    avatar_and_mouth = => 
      size = 75
      DIV 
        style: 
          display: 'inline-block'

        IMG
          ref: "avatar-#{t.name.replace(' ', '-')}"
          src: t.avatar
          style: 
            height: size
            width: size
            verticalAlign: 'middle'   

        DIV
          style: css.crossbrowserify
            transform:  if !top 
                          "rotate(180deg) #{if mouth_dir_left then 'scaleX(-1)' else ''}"
                        else 
                          "#{if !mouth_dir_left then 'scaleX(-1)' else ''}"
                          # "scale(#{if left then -1 else 1},-1) #{if left then 'scaleX(-1)' else ''}"

            position: 'absolute'
            left: if left then size / 2 + (if mouth_dir_left then 20 else 0)
            right: if !left then size / 2 + 20
            bottom: if top then -30
            top: if !top then -30
            zIndex: 2

          Bubblemouth 
            apex_xfrac: 0
            width: 30
            height: 30
            fill: opts.bg_color
            stroke: 'transparent'
            stroke_width: 0
            box_shadow:   
              dx: if top then -3 else 3 
              dy: 0
              stdDeviation: if top then 1 else 2
              opacity: if top then .15 else .4


    DIV 
      style: 
        position: 'relative'
        top: 20
        padding: '12px 20px'
        float: if !left then 'right' 


      if left && t.avatar 
        avatar_and_mouth()

      DIV 
        style:
          display: 'inline-block'
          padding: '0 16px'
          verticalAlign: 'middle'  
          textAlign: if !left then 'right'

        DIV 
          style: 
            fontSize: 20
          t.name

        if t.organization
          DIV 
            style: 
              fontSize: 18        
            t.organization

        if t.role
          DIV 
            style: 
              fontSize: 12
            t.role


      if !left && t.avatar 
        avatar_and_mouth()



  quote_bubble: (opts) ->
    t = opts.testimonial
    

    expanded = @local.expanded == t

    quote = if expanded then (opts.long_quote or t.long_quote) else (opts.short_quote or t.short_quote)

    DIV
      style: css.crossbrowserify
        padding: '36px 50px'
        position: 'relative'
        backgroundColor: opts.bg_color
        boxShadow: '#b5b5b5 0 1px 1px 0px'
        borderRadius: 64
        marginTop: if top then 20 + 24
        marginBottom: if !top then 20 else 4
        flex: 1 #'1 auto' # '1 1 auto'
        marginRight: 16
        marginLeft: 16
   
      DIV
        className: 'embedded'
        style: 
          fontSize: if expanded then 18 else 16
          fontStyle: if !expanded && opts.italic then 'italic'

        DIV dangerouslySetInnerHTML: {__html: quote}

      if t.long_quote && !@props.hide_full
        @readmore
          testimonial: t




  readmore: (opts) -> 
    t = opts.testimonial
    
    onclick = => 
      if @local.expanded == t
        @local.expanded = null 
      else 
        @local.expanded = t 
      save @local 


    BUTTON 
      style: 
        backgroundColor: 'transparent'
        border: 'none'
        color: 'black' # primary_color()
        textDecoration: 'underline'
        paddingTop: 12
        paddingLeft: 0
      onClick: onclick
      onKeyPress: (e) => 
        if e.which == 16 || e.which == 32
          e.preventDefault()
          onclick()

      if @local.expanded == t
        'hide full testimonial'
      else 
        'show full testimonial'

  componentDidMount: -> 
    # trigger rerender so quote bubble is rendered with positions intact
    @local.dummy = true 
    save @local 



window.Testimonial = ReactiveComponent 
  displayName: 'Testimonial'

  render: -> 

    t = @props.testimonial 

    DIV 
      style: 
        paddingTop: 28
        position: 'relative'
        left: 0

      quote_bubble 
        key: @local.key
        testimonial: t
        left: true
        top: false
        bg_color: @props.bubble_color or considerit_gray

      user_credentials
        testimonial: t
        left: true








window.testimonials = 
  susie:
    name: 'Susie Philipsen' 
    role: "Senior Public Relations Specialist"
    organization: "City of Seattle"
    avatar: asset('product_page/susie.png')


    short_quote: """Working with the Consider.it team on <a href='https://hala.consider.it'>Seattle’s dialogue about Housing Affordability</a> has been a fantastic experience! We’ve created a great feedback loop with residents via Consider.it. Residents 
                    are acknowledging the information we are providing them, learning from it, and even thanking us! If you’re looking to create quality online dialogues, Consider.it is an excellent great choice."""

    long_quote: """
        <p>Working with the Consider.it team on <a href='https://hala.consider.it'>Seattle’s dialogue about Housing Affordability</a> has been a fantastic experience! They bring far more to the table than technical skills – they think deeply about how the tool is going to be received and help us build a better dialogue using that knowledge. Furthermore, the Consider.it team is very responsive - the back and forth communication has been very easy.</p> 

        <p>Some of the ways the Consider.it team helped our team include:</p>

        <ul>
        <li><strong>Framing content for a general audience</strong>. We spent a lot of time writing technically correct questions, but the Consider.it team helped us recognize how difficult these questions are to understand. They helped us refine all the content. This included setting expectations about how residents’ feedback fits into the larger process. </li>

        <li><strong>Translating our needs into a good digital experience</strong>. Being new to online dialogue, the consider.it team helped us focus our goals for information gathering. We wanted to collect demographic information so we could assess outreach effectiveness. We collaborated to identify the minimal information to collect from residents to answer critical questions.</li>

        <li><strong>Outreach and recruitment</strong>. The consider.it team helps us understand which populations are providing feedback. I can then focus our online advertising on recruiting people from underrepresented neighborhoods and groups.</li>

        <li><strong>How to engage with residents</strong>. The team encouraged direct engagement with residents online by responding to questions and concerns online. This support made me more proactive in answering questions. When I don’t know the answer, I reach out to the technical experts and ask them to respond that day so we can keep the conversation going. Residents are acknowledging the information we are providing them, learning from it, and even thanking us.</li>

        </ul>
        <p>If you’re looking to create quality online dialogues, Consider.it is an excellent choice.</p>
        """

  russ: 
    name: 'Russ Lehman' 
    role: "Executive Director"
    organization: "WSFFN"
    avatar: asset('product_page/Russ.png')

    # short_quote: """I was nervous about getting our board members and wider network on the same page about a 
    #                 pressing strategic change. The Consider.it team rescued us! They structured a quick 
    #                 Consider.it dialogue with all our stakeholders that gave legitimacy and momentum to 
    #                 our new direction, without the hassle of bringing everyone together physically."""
    short_quote: """When we embarked on rebranding, I was daunted with the task of engaging
                    constituents across the state. As a small non-profit, we didn’t have the funds to
                    reach everyone in-person. With Consider.it, we could engage far more people for a
                    cost we could afford. Beyond the great tool, the Consider.it team was incredibly
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
    role: 'Senior Wind Energy Researcher'
    organization: "Danish Technical University"
    avatar: asset('product_page/pierre.png')

    short_quote: """
                 We had a nearly 50/50 deadlocked split in our housing community. After we started using Consider.it, 
                 people could clearly express the reasons behind their opinions, and see other’s reasons. We were able 
                 to work out a compromise. That’s the first time where I felt like democracy was actually working.
                 """

  auryn: 
    name: 'Auryn Macmillan' 
    role: 'Cofounder'
    organization: "DAOhub"
    avatar: asset('product_page/auryn.png')

    short_quote: """
                 Consider.it’s careful design choices were critical for not only aggregating 
                 community opinions, but also in understanding the 
                 rationale. The ability to get a feel for both the gestalt and the 
                 granular details of an issue within the one view is an incredible 
                 achievement and was a vital part of our community’s decision making 
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


testimonials.susie_pricing = _.extend {}, testimonials.susie, 
  short_quote: """Their team thinks deeply about how Consider.it is going to be received and helped us build a better public dialogue using that knowledge, such as by:<ul><li>framing content for a general audience</li><li>teaching best practices for engaging residents</li><li>creating new features to support our use case</li></ul>"""

testimonials.auryn_pricing = _.extend {}, testimonials.auryn, 
  short_quote: """Consider.it is incredibly responsive and receptive to suggestions, and, as is evident by the nuance of their platform, they really have a fantastic grasp on the needs of web based and decentralised communities. They:<ul><li>helped restructure our organizational processes</li><li>designed a custom forum homepage</li><li>created a rich custom embed of consider.it</li></ul>"""

testimonials.russ_pricing = _.extend {}, testimonials.russ, 
  short_quote: """Beyond the great tool, the Consider.it team was extremely knowledgeable and available in helping craft an engagement strategy. They helped us:<ul><li>create clear, valuable questions</li><li>design a multi-phase engagement process</li><li>improve interactions with our network</li><li>interpret responses</li></ul>"""
