feature_style = _.extend {}, small_text,
  fontWeight: 400


features = [{
  icon: 'bull',
  label: 'Branding',
  description: -> 
    DIV 
      style: feature_style

      """Tailor the look and feel of your Consider.it site to fit your brand."""
},{
  icon: 'flag',
  label: 'Moderation',
  description: -> 
    DIV 
      style: feature_style

      """Configure whether you wish to police content on your Consider.it site."""
},{
  icon: 'frame',
  label: 'Frame the discussion',
  description: -> 
    DIV 
      style: feature_style

      """
      Want Strengths/Weaknesses instead of Pros/Cons? Want the Slider 
      poles to read Ready/Not ready? No problem. You define the language.
      """
},{
  icon: 'lock',
  label: 'Private conversations',
  description: -> 
    DIV 
      style: feature_style

      """
      Invite only select people to participate in a conversation. 
      You can also specify who is allowed to contribute their opinion.
      """
},{
  icon: 'analyze',
  label: 'Advanced opinion analytics',
  description: -> 
    DIV 
      style: feature_style

      """
      Cross-tabulate opinions based on user attributes like job title, age, 
      or a response to a question you define. User attributes can be imported, 
      or you can prompt participants with custom questions.
      """
},{
  icon: 'group',
  label: 'Question grouping',
  description: -> 
    DIV 
      style: feature_style

      """Your Consider.it homepage organizes questions into groups. This 
      enables you to ask users to submit ideas in response to a prompt, or 
      see which proposals have greatest support.
      """
      A 
        href: 'https://bitcoin.consider.it'
        style: 
          textDecoration: 'underline'
          cursor: 'pointer'
          paddingTop: 10
          display: 'block'
        'Example'
},

]

for feature in features
  require "./svgs/#{feature.icon}"

window.Features = ReactiveComponent
  displayName: 'Features'

  render: -> 
    DIV 
      id: 'features'
      style: 
        width: SAAS_PAGE_WIDTH
        margin: '80px auto 0 auto'


      H1
        style: _.extend {}, h1, 
          marginBottom: '50px'

        'Additional features'


      UL
        style: 
          listStyle: 'none'

        for feature, idx in features 
          LI 
            key: idx
            style: 
              display: 'inline-block'
              width: SAAS_PAGE_WIDTH / 2 - 30
              paddingBottom: 40
              marginRight: if idx % 2 == 0 then 60
              paddingLeft: 120
              position: 'relative'
              verticalAlign: 'top'

            SPAN 
              style: 
                width: 80
                display: 'inline-block'
                verticalAlign: 'top'
                marginRight: 40
                position: 'absolute'
                left: 0
                top: 0

              window["#{feature.icon}SVG"]
                width: 80
                fill_color: 'black'

            SPAN 
              style: 
                display: 'inline-block'

              SPAN 
                style: _.extend {}, base_text,
                  color: logo_red
                  paddingBottom: 10
                feature.label

              BR null
              SPAN null,
                feature.description()
                







      
