require '../customizations'


styles += """

.AllYourForums h1 {
  margin: 36px 0px 18px 0px;
  font-size: 24px;
}

.AllYourForums .forum {
  list-style: none;
  align-items: center;
  display: flex;
  margin-bottom: 24px;
  min-height: 70px;
}

.AllYourForums .logo {
  width: 120px;
  text-align: right;

  margin-right: 24px;
}

.AllYourForums .text {

}

.AllYourForums .forum_title {
  display: block;
  font-size: 18px;
  text-decoration: none;
}

.AllYourForums .forum_link {
  color: #888;
  font-weight: 400;
  font-size: 15px;
}

"""


window.AllYourForums = ReactiveComponent
  displayName: 'AllYourForums'


  drawForums : (forums, is_host) -> 
    UL null,
      for forum in forums
        LI 
          className: 'forum'

          DIV 
            className: 'logo'

            if forum.logo 
              IMG 
                src: forum.logo
                style: 
                  maxWidth: 120
                  maxHeight: 70
            else 
              DIV 
                style: 
                  border: '1px dashed #ccc'
                  borderRadius: 8
                  width: 120
                  height: 70

          DIV 
            className: 'text'


            A
              className: 'forum_title'
              href: "https://#{forum.name}.consider.it"
              forum.title or forum.name

            A
              className: 'forum_link'
              href: "https://#{forum.name}.consider.it"
              "https://#{forum.name}.consider.it"

  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'


    forums = fetch '/your_forums'

    hosted = forums.hosted
    participated_in = forums.participated_in

    return SPAN null if !hosted? || !participated_in?


    DIV 
      className: 'AllYourForums'

      H1 null, 
        'Forums you\'ve hosted'

      if hosted.length > 0 
        @drawForums(hosted, true)

      else 
        DIV null,
          "You have not yet hosted a forum. "
          A 
            href: 'https://consider.it/create_forum'
            'Create your own'
          " if you wish."


      H1 null,
        'Forums you\'ve participated in'


      if participated_in.length > 0 
        @drawForums(participated_in, false)

      else 
        "You have not yet participated in a forum"



