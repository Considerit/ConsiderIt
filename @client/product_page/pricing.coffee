require './svgs/collaboration'
require './svgs/price_tag'
require './svgs/design'
require './svgs/features'
require './svgs/server'
require './customer_signup'


plan_header = _.extend {}, h2, 
  color: logo_red
  fontSize: 48
  textAlign: 'center'

window.Pricing = ReactiveComponent
  displayName: 'Pricing'

  render: -> 
    DIV 
      id: 'price'
      style:
        marginTop: 60

      DIV 
        style: _.extend {}, h1,
          marginBottom: 30


        'Start using Consider.it'

      DIV 
        style: _.extend {}, base_text,
          width: SAAS_PAGE_WIDTH
          margin: 'auto'

        @drawPlans()

        if @local.sign_up_for
          CustomerSignup
            plan: @local.sign_up_for


  drawPlans : -> 
    plans = [
      {
        name: 'Basic'
        width: SAAS_PAGE_WIDTH / 3 - 70
        price: 'Free for everyone'
        call_to_action: 'Get me started'  
        features: [
          'Unlimited users',
          'Unlimited questions',
          #'One Consider.it site',
          'Basic branding',
          'Content moderation',
          'Question grouping'
        ]
        email:
          subject: "I'd like to start Consider.it's Free Public plan"
          body: "Hi, I'm _____ and I'd like to use Consider.it at https://_____.consider.it..."

      }, {
        name: 'Professional'
        highlight: true
        width: SAAS_PAGE_WIDTH / 3 + 60
        price: '$150 / month'
        call_to_action: 'Start free 30 day trial'  
        features: [
          'Private conversations',
          #'Unlimited administrators',
          #'Up to five Consider.it sites',
          'Export to spreadsheet',
          'Advanced opinion analytics',
          'Priority customer service',
          'One hour training'
        ]
        email:
          subject: "I'd like to start my 30 day trial of Consider.it's Professional plan"
          body: "Hi, I'm _____ and I'd like to use Consider.it at https://_____.consider.it..."      
      },{
        name: 'Custom'
        price: 'Why a custom plan?'
        call_to_action: "Contact us"
        width: SAAS_PAGE_WIDTH / 3 - 70
        reasons: [
          {
            icon: 'features'
            description: -> 
              DIV style: _.extend({}, small_text, {fontWeight: 400}),
                """
                If there is a feature you need developed that is not advertised. 
                 """
          }, {
            icon: 'design'
            description: ->
              DIV style: _.extend({}, small_text, {fontWeight: 400}),
                """
                If you want custom design work done, such as a custom homepage. 
                """
          }, {
            icon: 'priceTag'
            description: ->
              DIV style: _.extend({}, small_text, {fontWeight: 400}),
                """
                If our pricing model doesn't work for you. We are flexible. 
                """
          }, {
            icon: 'collaboration'
            description: ->
              DIV style: _.extend({}, small_text, {fontWeight: 400}),
                """
                If you want to collaborate with us. 
                Let us know what you're thinking.
                """
          }, {
            icon: 'server'
            description: ->
              DIV style: _.extend({}, small_text, {fontWeight: 400}),
                """
                If you have special hosting needs, like a private server.  
                """
          },
        ]
        email:
          subject: "Consider.it custom plan"
          body: "Hi, my name is _____, and I'd like to discuss a custom Consider.it plan because ____"      
        }
    ]

    for plan, idx in plans
      DIV 
        key: idx
        style: 
          width: plan.width
          margin: if plan.highlight then '0px 40px' else '40px 0'
          display: 'inline-block'
          verticalAlign: 'top'
          border: if plan.highlight then "1px solid #{logo_red}"
          padding: if plan.highlight then '40px 40px'

        H2
          style: plan_header

          plan.name

        DIV 
          style: 
            margin: '0px 0 30px 0'
            textAlign: 'center'

          plan.price

        if plan.name != 'Custom'
          UL
            style: 
              listStyle: 'none'
              textAlign: 'left'
              margin: 'auto'
              marginBottom: 46

            for feature in plan.features
              LI
                key: feature
                style: _.extend {}, small_text,
                  fontWeight: 400
                  position: 'relative'
                  marginBottom: 10

                I
                  className: 'fa fa-check'
                  style: 
                    position: 'relative'
                    left: 0
                    top: 0
                    width: 30

                feature
        else
          VisualTab
            tabs: plan.reasons
            stroke_color: logo_red
            description_height: 100
            icon_height: 40
            svg_padding: '10px 5px'

        @drawCallForAction plan


  drawCallForAction: (plan) -> 
    hovering = @local.hover_call == plan.name
    A
      href: if plan.name == 'Custom' then "mailto:admin@consider.it?subject=#{plan.email.subject}&body=#{plan.email.body}"
      style:
        backgroundColor: if hovering then logo_red else 'white'
        color: if hovering then 'white' else logo_red
        fontWeight: 500
        border: "1px solid #{if hovering then 'white' else logo_red}"
        borderRadius: 16
        padding: '8px 18px'
        fontSize: 24
        margin: 'auto'
        display: 'block'
        marginTop: 35
        textAlign: 'center'
      onMouseEnter: => 
        @local.hover_call = plan.name
        save @local

      onMouseLeave: => 
        @local.hover_call = null
        save @local

      onClick: if plan.name != 'Custom' then =>         
        @local.sign_up_for = plan.name
        save @local
        if @local.sign_up_for
          $(@getDOMNode()).moveToTop(-400, true)        

      plan.call_to_action