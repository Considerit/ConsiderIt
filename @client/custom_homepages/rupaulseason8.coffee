rupaul_header = ReactiveComponent
  displayName: 'ImageHeader'

  render: ->
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

        ProfileMenu()

        back_to_homepage_button
          position: 'relative'
          marginLeft: 20
          display: 'inline-block'
          color: if !is_light then 'white'
          fontSize: 43
          visibility: if homepage || !customization('has_homepage') then 'hidden'
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



window.HomepageHeader = rupaul_header
window.NonHomepageHeader = rupaul_header
