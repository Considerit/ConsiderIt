qs = []

window.FAQ = ReactiveComponent
  displayName: 'FAQ'

  render : -> 
    questions = qs
    if !@local.show_all_questions
      questions = questions.slice(0,4)

    DIV 
      id: 'faq'
      style:
        marginTop: 60


      H1
        style: _.extend {}, h1, 
          marginBottom: 30

        "Frequently Asked Questions"

      DIV 
        style: 
          postion: 'relative'

        for q in questions
          ExpandingQuestion q


      DIV 
        style: 
          width: TEXT_WIDTH
          backgroundColor: '#F7F7F7'
          textAlign: 'center'
          textDecoration: 'underline'
          cursor: 'pointer'
          padding: '5px 0'
          margin: 'auto'
        onClick: =>
          @local.show_all_questions = !@local.show_all_questions
          save @local

        if @local.show_all_questions
          "Collapse questions"
        else
          "Show more questions"


ExpandingQuestion = ReactiveComponent
  displayName: 'ExpandingQuestion'

  render : -> 
    DIV
      style:
        paddingLeft: 30
        position: "relative"
        margin: "30px auto"
        width: TEXT_WIDTH



      I
        className: "fa fa-chevron-#{if @local.active then 'down' else 'right'}"
        style: 
          fontSize: 30
          position: "absolute"
          left: -15
          top: 6
          color: logo_red
          cursor: 'pointer'

        onClick: => 
          @local.active = !@local.active
          save @local

      DIV
        style: _.extend {}, base_text, 
          fontWeight: if @local.active then 600
          cursor: 'pointer'
        onClick: => 
          @local.active = !@local.active
          save @local

        @props.question

      DIV 
        style: _.extend {}, small_text, 
          #fontWeight: 300
          display: if !@local.active then 'none'

        @props.answer()


p = 
  marginTop: 15

qs = [{
  question: 'What happens when I sign up for Consider.it?'
  answer: ->
    DIV null,
      P style: p,
        'You\'ll get your very own customizable Consider.it site. '
      P style: p,
        """
        Say that you’re a fantasy football fan and want to use Consider.it 
        to debate fantasy football decisions with other rabid fans. When 
        you sign up for Consider.it, you 
        specify a name like "fantasy-football". Congratulations, you are 
        now the proud administrator of https://fantasy-football.consider.it! 
        """
      P style: p,
        """
        First, you might want to give it the look and feel you desire by 
        adding a custom logo and fancy homepage banner image you 
        designed. You might also want to configure who can access 
        the site (in this case, everyone) and who can post content (any 
        registered user). A variety of options are available to make 
        your Consider.it site work the way you wish. 
        """
      P style: p,
        """
        Next you'll want to add a question or two. Or ten. You create a 
        section of questions that allow people to debate whether it is a 
        good idea to start a particular player, and another section that 
        solicits suggestions about the best strategies for managing your 
        fantasy team. Each section is shown on the homepage and you 
        configure it so that any user can add new suggestions. 
        """
      P style: p,
        """Finally, invite your friends and family, or whomever you want 
        to participate!"""

  }, {
  question: 'Can I solicit responses to open ended questions like "Which policies should we revise?"'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Can I moderate user content? Is it hard?'
  answer: ->
    DIV null,
      P style: p,
        'You\'ll get your very own customizable Consider.it site. '
      P style: p,
        """
        Say that you’re a fantasy football fan and want to use Consider.it 
        to debate fantasy football decisions with other rabid fans. When 
        you sign up for Consider.it, you 
        specify a name like "fantasy-football". Congratulations, you are 
        now the proud administrator of https://fantasy-football.consider.it! 
        """
      P style: p,
        """
        First, you might want to give it the look and feel you desire by 
        adding a custom logo and fancy homepage banner image you 
        designed. You might also want to configure who can access 
        the site (in this case, everyone) and who can post content (any 
        registered user). A variety of options are available to make 
        your Consider.it site work the way you wish. 
        """
      P style: p,
        """
        Next you'll want to add a question or two. Or ten. You create a 
        section of questions that allow people to debate whether it is a 
        good idea to start a particular player, and another section that 
        solicits suggestions about the best strategies for managing your 
        fantasy team. Each section is shown on the homepage and you 
        configure it so that any user can add new suggestions. 
        """
      P style: p,
        """Finally, invite your friends and family, or whomever you want 
        to participate!"""

  }, {
  question: 'Can I create a private discussion and send out invitations?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Is it possible to set different permissions for who can, for example, post a new idea or write a new pro/con point?'
  answer: ->
    DIV null,
      P style: p,
        'You\'ll get your very own customizable Consider.it site. '
      P style: p,
        """
        Say that you’re a fantasy football fan and want to use Consider.it 
        to debate fantasy football decisions with other rabid fans. When 
        you sign up for Consider.it, you 
        specify a name like "fantasy-football". Congratulations, you are 
        now the proud administrator of https://fantasy-football.consider.it! 
        """
      P style: p,
        """
        First, you might want to give it the look and feel you desire by 
        adding a custom logo and fancy homepage banner image you 
        designed. You might also want to configure who can access 
        the site (in this case, everyone) and who can post content (any 
        registered user). A variety of options are available to make 
        your Consider.it site work the way you wish. 
        """
      P style: p,
        """
        Next you'll want to add a question or two. Or ten. You create a 
        section of questions that allow people to debate whether it is a 
        good idea to start a particular player, and another section that 
        solicits suggestions about the best strategies for managing your 
        fantasy team. Each section is shown on the homepage and you 
        configure it so that any user can add new suggestions. 
        """
      P style: p,
        """Finally, invite your friends and family, or whomever you want 
        to participate!"""

  }, {
  question: 'Can I ask custom questions of users of my site?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Can I style my Consider.it site so that it fits with my brand?'
  answer: ->
    DIV null,
      P style: p,
        'You\'ll get your very own customizable Consider.it site. '
      P style: p,
        """
        Say that you’re a fantasy football fan and want to use Consider.it 
        to debate fantasy football decisions with other rabid fans. When 
        you sign up for Consider.it, you 
        specify a name like "fantasy-football". Congratulations, you are 
        now the proud administrator of https://fantasy-football.consider.it! 
        """
      P style: p,
        """
        First, you might want to give it the look and feel you desire by 
        adding a custom logo and fancy homepage banner image you 
        designed. You might also want to configure who can access 
        the site (in this case, everyone) and who can post content (any 
        registered user). A variety of options are available to make 
        your Consider.it site work the way you wish. 
        """
      P style: p,
        """
        Next you'll want to add a question or two. Or ten. You create a 
        section of questions that allow people to debate whether it is a 
        good idea to start a particular player, and another section that 
        solicits suggestions about the best strategies for managing your 
        fantasy team. Each section is shown on the homepage and you 
        configure it so that any user can add new suggestions. 
        """
      P style: p,
        """Finally, invite your friends and family, or whomever you want 
        to participate!"""

  }, {
  question: 'Does Consider.it work on mobile devices?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'What browsers do you support?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Can we self-host Consider.it on our own servers?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Can we use our own URL?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Is Consider.it open source? Can we use and modify the source code?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Consider.it is missing X feature that I need. What do can I do?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Do you support Single-Sign On (SSO)?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }, {
  question: 'Do you integrate with X service?'
  answer: ->
    DIV null,
      P style: p,
        'Yes.'

      P style: p,
        """
        Say that you are using https://startup-inc.consider.it to help your startup 
        of 25 employees (and soon 30) deliberate about how to improve process 
        given rapid growth. You want to help maintain the fun, casual atmosphere, 
        but you also recognize that some formalization of policy may be necessary.
        """

      P style: p,
        'You decide to solicit ideas from your employees. '

  }]
