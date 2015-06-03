require './svgs/collaboration'
require './svgs/price_tag'
require './svgs/design'
require './svgs/features'
require './svgs/server'

PLAN_WIDTH = 300


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
        style: h1

        'Start using Consider.it'

      DIV 
        style: _.extend {}, base_text,
          width: PLAN_WIDTH * 2 + 62
          margin: 'auto'

        @drawPlans()

        @drawCustomPlan()



  drawPlans : -> 
    plans = [{
      name: 'Basic'
      width: 228
      marginTop: 72
      price: 'Free for everyone'
      call_to_action: 'Get me started!'  
      features: [
        'Unlimited users',
        'Unlimited questions',
        'One Consider.it site',
        'Basic branding',
        'Content moderation',
        'Idea grouping'
      ]
      email:
        subject: "I'd like to start Consider.it's Free Public plan"
        body: "Hi, I'm _____ and I'd like to use Consider.it at https://_____.consider.it..."

    }, {
      name: 'Professional'
      width: PLAN_WIDTH
      marginTop: 35
      price: '$150 / month'
      call_to_action: 'Start Free 30 day trial!'  
      features: [
        'Private conversations',
        'Unlimited administrators',
        'Up to five Consider.it sites',
        'Export data to a spreadsheet',
        'Demographic questions',
        'Priority customer service',
        'One hour training'
      ]
      email:
        subject: "I'd like to start my 30 day trial of Consider.it's Professional plan"
        body: "Hi, I'm _____ and I'd like to use Consider.it at https://_____.consider.it..."      
    }]

    for plan, idx in plans
      DIV 
        style: 
          width: PLAN_WIDTH
          marginRight: if idx == 0 then 60 
          marginTop: 40
          display: 'inline-block'
          verticalAlign: 'top'

        H2
          style: plan_header

          plan.name

        DIV 
          style: 
            margin: '40px 0'
            textAlign: 'center'

          plan.price

        UL
          style: 
            listStyle: 'none'
            textAlign: 'left'
            width: plan.width 
            margin: 'auto'

          for feature in plan.features
            LI
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

        @drawCallToAction(plan)

  drawCustomPlan : -> 
    plan =
      name: 'Custom plan'
      price: 'Common reasons for a custom plan:'
      call_to_action: 'I want to discuss a custom plan'  
      width: 450
      reasons: [
        {
          icon: 'features'
          reason: """
                  We don’t advertise a feature or service integration that you 
                  need. We may already have it, or may be able to make it for you.
                  """
        }, {
          icon: 'design'
          reason: """
                  You want custom design work done. For example, maybe you want 
                  deep branding for the header. Or a custom component.
                  """
        }, {
          icon: 'priceTag'
          reason: """
                  The pricing is tricky for your situation and you want to 
                  discuss options. We understand that our customers' needs are
                  unique. We are flexible. 
                  """
        }, {
          icon: 'collaboration'
          reason: """
                  You are leading a project and want to collaborate with us. 
                  We enjoy partnering.
                  """
        }, {
          icon: 'server'
          reason: """
                  You have special hosting needs, like a private server 
                  or one hosted in a particular country. We prefer not to do 
                  self-hosting, but maybe we can work something out. 
                  """
        },

      ]
      email:
        subject: "Consider.it custom plan"
        body: "Hi, I'm _____ and I'd like to discuss a custom Consider.it plan because ____"      


    position = 0
    if !@local.custom_reason_hover
      @local.custom_reason_hover = plan.reasons[0].icon
      save @local

    DIV 
      style: 
        marginTop: 60

      H2
        style: plan_header

        plan.name

      DIV 
        style: 
          margin: '30px 0'
          textAlign: 'center'

        plan.price

      UL 
        style: 
          listStyle: 'none'
          textAlign: 'center'

        for reason, idx in plan.reasons
          do (reason, idx) => 
            hovering = @local.custom_reason_hover == reason.icon
            if hovering
              position = idx
            LI 
              style: 
                padding: '10px 20px'
                display: 'inline-block'
                opacity: if !hovering then .25

              onMouseEnter : => 
                @local.custom_reason_hover = reason.icon
                save @local

              DIV 
                style: 
                  #cursor: 'pointer'
                  #borderBottom: "3px solid #{if hovering then logo_red else 'transparent'}"
                  paddingBottom: 10

                window["#{reason.icon}SVG"]
                  height: 70
                  fill_color: if hovering then logo_red else 'black'


      DIV 
        style: _.extend {}, base_text, 
          width: 600
          height: 96
          margin: '0px auto 40px auto'   
          paddingTop: 10
          borderTop: "1px solid #{logo_red}"
          position: 'relative'

        SVG 
          height: 8
          width: 30

          style:
            position: 'absolute'
            left: "#{position / plan.reasons.length * 100 + .5 * 100 / plan.reasons.length}%"
            marginLeft: - 30 / 2
            top: -8

          POLYGON
            points: "0,8 15,0 30,8" 
            fill: logo_red

          POLYGON
            points: "0,9 15,1 30,9" 
            fill: 'white'

        for reason, idx in plan.reasons
          if @local.custom_reason_hover == reason.icon
            reason.reason

      @drawCallToAction plan

  drawCallToAction : (plan) -> 
    hovering = @local.hover_call == plan.name
    A
      href: "mailto:admin@consider.it?subject=#{plan.email.subject}&body=#{plan.email.body}"
      style:
        backgroundColor: if hovering then logo_red else 'white'
        color: if hovering then 'white' else logo_red
        fontWeight: 500
        border: "1px solid #{if hovering then 'white' else logo_red}"
        borderRadius: 16
        padding: '8px 18px'
        fontSize: 24
        margin: 'auto'
        width: plan.width
        display: 'block'
        marginTop: plan.marginTop
        textAlign: 'center'
      onMouseEnter: => @local.hover_call = plan.name; save @local
      onMouseLeave: => @local.hover_call = null; save @local
      plan.call_to_action